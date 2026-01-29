// Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
// SPDX-License-Identifier: MIT

#include <memory>
#include <string.h>

#include <esp_http_client.h>
#include <esp_log.h>

#include "fcch_acl_client/acl_client.h"
#include "fcch_connmgr/cm.h"
#include "fcch_connmgr/cm_conf.h"
#include "fcch_connmgr/cm_net.h"
#include "fcch_connmgr/cm_util.h"

static const char *TAG = "acl_client";

static const char *acl_client_hostname;
static cm_conf_item acl_client_item_hostname = {
    .slug_name = "h", // Host name
    .text_name = "ACL Server Host Name",
    .type = CM_CONF_ITEM_TYPE_STR,
    .p_val = {.str = &acl_client_hostname },
    .default_func = &cm_conf_default_str_empty,
};

static uint16_t acl_client_port;
static cm_conf_item acl_client_item_port = {
    .slug_name = "p", // Port
    .text_name = "ACL Server Port",
    .type = CM_CONF_ITEM_TYPE_U16,
    .p_val = {.u16 = &acl_client_port },
    .default_func = &cm_conf_default_u16_0,
};

static const char *acl_client_acl_name;
static cm_conf_item acl_client_item_acl_name = {
    .slug_name = "a", // ACL
    .text_name = "ACL Name",
    .type = CM_CONF_ITEM_TYPE_STR,
    .p_val = {.str = &acl_client_acl_name },
    .default_func = &cm_conf_default_str_empty,
};

static cm_conf_item *acl_client_items[] = {
    &acl_client_item_hostname,
    &acl_client_item_port,
    &acl_client_item_acl_name,
};

static cm_conf_page access_control_page_acc = {
    .slug_name = "acl", // Access Control List (Client)
    .text_name = "Access Control",
    .items = acl_client_items,
    .items_count = ARRAY_SIZE(acl_client_items),
};

static const char *acl_client_user_agent;
static bool acl_allow_any;

static void acl_http_action_allow_any() {
    acl_allow_any = !acl_allow_any;
}

static const char *acl_http_action_allow_any_description() {
    if (acl_allow_any) {
        return "ACL allow any RFID (Is On)";
    } else {
        return "ACL allow any RFID (Is Off)";
    }
}

void acl_client_register_conf() {
    cm_conf_register_page(&access_control_page_acc);
}

esp_err_t acl_client_check_id(uint32_t rfid, bool *allowed) {
    if (acl_allow_any) {
        *allowed = true;
        return ESP_OK;
    }

    *allowed = false;

    if (acl_client_hostname[0] == '\0' ||
        acl_client_acl_name[0] == '\0'
    ) {
        return ESP_ERR_INVALID_STATE;
    }

    AutoFree<char> path;
    asprintf(&path.val, "/api/check-access-0/%s/%lu",
        acl_client_acl_name, rfid);
    if (path.val == NULL)
        return ESP_ERR_NO_MEM;
    esp_http_client_config_t config{};
    config.host = acl_client_hostname;
    config.port = acl_client_port;
    config.path = path.val;
    config.user_agent = acl_client_user_agent;
    config.method = HTTP_METHOD_GET;
    config.timeout_ms = 1000;
    esp_http_client_handle_t client = esp_http_client_init(&config);
    AutoCleanup<esp_http_client_handle_t> clientCleanup{
        [] (auto client) {
            esp_http_client_cleanup(client);
        },
        client
    };

    esp_err_t err = esp_http_client_open(client, 0);
    if (err != ESP_OK) {
        ESP_LOGE(TAG, "esp_http_client_open: %s", esp_err_to_name(err));
        return err;
    }
    AutoCleanup<esp_http_client_handle_t> clientClose{
        [] (auto client) {
            esp_http_client_close(client);
        },
        client
    };

    int64_t content_length = esp_http_client_fetch_headers(client);
    if (content_length < 0) {
        ESP_LOGE(TAG, "content_length: %" PRId64, content_length);
        return ESP_ERR_INVALID_SIZE;
    }
    // 8 is large enough for "True" or "False", plus NUL
    char buf[8] = {0};
    if (content_length >= sizeof(buf)) {
        ESP_LOGE(TAG, "content_length: %" PRId64, content_length);
        return ESP_ERR_INVALID_SIZE;
    }
    // -1 for NUL
    int data_read = esp_http_client_read_response(client, buf, sizeof(buf) - 1);
    if (data_read != content_length) {
        ESP_LOGE(TAG, "data_read: %d", data_read);
        return ESP_ERR_INVALID_SIZE;
    }
    buf[data_read] = '\0';
    ESP_LOGI(TAG, "HTTP GET Status = %d, content_length = %" PRId64,
        esp_http_client_get_status_code(client),
        content_length);

    *allowed = !strcmp(buf, "True");
    return ESP_OK;
}

void acl_client_init() {
    char *user_agent;
    asprintf(&user_agent, "%s FCCH ACL Client", cm_net_hostname);
    acl_client_user_agent = user_agent;

    cm_http_register_home_action(
        "acl-allow-any",
        acl_http_action_allow_any_description,
        acl_http_action_allow_any
    );
}
