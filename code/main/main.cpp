// Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
// SPDX-License-Identifier: MIT

#include <inttypes.h>
#include <string.h>
#include <stdio.h>
#include <sys/param.h>
#include <sys/poll.h>
#include <sys/socket.h>
#include <unistd.h>

#include <esp_event.h>
#include <esp_log.h>
#include <nvs.h>
#include <nvs_flash.h>

#include "fcch_acl_client/acl_client.h"
#include "fcch_connmgr/cm.h"
#include "fcch_rfid/rfid.h"
#include "lcd.h"
#include "momentary.h"
#include "mqtt.h"
#include "relay.h"

enum main_event {
    MAIN_EVENT_RFID_PRESENT,
    MAIN_EVENT_RFID_ABSENT,
};

static const char *TAG = "main";

static esp_event_loop_handle_t main_event_loop;
ESP_EVENT_DEFINE_BASE(MAIN_EVENT);

static void main_rfid_present(uint32_t rfid) {
    ESP_ERROR_CHECK(esp_event_post_to(main_event_loop,
        MAIN_EVENT, MAIN_EVENT_RFID_PRESENT,
        &rfid, sizeof(rfid), 10 / portTICK_PERIOD_MS));
}

static void main_rfid_absent() {
    ESP_ERROR_CHECK(esp_event_post_to(main_event_loop,
        MAIN_EVENT, MAIN_EVENT_RFID_ABSENT,
        NULL, 0, 10 / portTICK_PERIOD_MS));
}

static void main_event_handler(
    void *arg,
    esp_event_base_t event_base,
    int32_t event_id,
    void *event_data
) {
    if (event_base != MAIN_EVENT) {
        ESP_LOGE(TAG, "main_event_handler: event_base != MAIN_EVENT");
        return;
    }

    switch (event_id) {
        case MAIN_EVENT_RFID_PRESENT: {
            uint32_t rfid = *(uint32_t *)event_data;
            ESP_LOGI(TAG, "MAIN_EVENT_RFID_PRESENT: %lu", rfid);
            bool momentary_debug_active = false;
#ifdef MOMENTARY_DEBUG_BYPASS_ACL
            momentary_debug_active = true;
#endif
            if (!momentary_debug_active) {
                momentary_debug_active = (momentary_get_debug_enabled() != 0);
            }

            if (momentary_debug_active) {
                ESP_LOGI(TAG, "Momentary debug active: granting access for RFID %lu", rfid);
                relay_on_rfid_ok();
                lcd_on_rfid_ok(rfid);
            } else {
                // FIXME: Might want our own event loop task since
                // acl_client_check_id might take a while.
                // rfid_init should take an event loop handle to post to.
                bool allowed;
                esp_err_t err = acl_client_check_id(rfid, &allowed);
                if (err != ESP_OK) {
                    ESP_LOGW(TAG, "ACL check error: %d", err);
                    lcd_on_rfid_err(rfid);
                    mqtt_on_rfid_err(rfid);
                    break;
                }
                ESP_LOGI(TAG, "ACL check: %d", (int)allowed);
                if (allowed) {
                    relay_on_rfid_ok();
                    lcd_on_rfid_ok(rfid);
                    mqtt_on_rfid_ok(rfid);
                } else {
                    lcd_on_rfid_bad(rfid);
                    mqtt_on_rfid_bad(rfid);
                }
            }
            break;
        }
        case MAIN_EVENT_RFID_ABSENT: {
            ESP_LOGI(TAG, "MAIN_EVENT_RFID_ABSENT");
#ifndef MOMENTARY_DEBUG_BYPASS_ACL
            bool allowed;
            // Ignore errors in ACL check; this is only performed to create a
            // log entry for offline stats reporting.
            acl_client_check_id(0, &allowed);
#endif
            relay_on_rfid_none();
            lcd_on_rfid_none();
#ifndef MOMENTARY_DEBUG_BYPASS_ACL
            mqtt_on_rfid_none();
#endif
            break;
        }
        default:
            ESP_LOGI(TAG, "MAIN_EVENT_? %" PRId32, event_id);
            break;
    }
}

extern "C" void app_main() {
    // These values match the default event loop, other than task_name.
    const esp_event_loop_args_t event_loop_args = {
        .queue_size = CONFIG_ESP_SYSTEM_EVENT_QUEUE_SIZE,
        .task_name = "main",
        .task_priority = ESP_TASKD_EVENT_PRIO,
        .task_stack_size = ESP_TASKD_EVENT_STACK,
        .task_core_id = 0
    };
    ESP_ERROR_CHECK(esp_event_loop_create(&event_loop_args, &main_event_loop));
    cm_register_conf();
    acl_client_register_conf();
    momentary_register_conf();
    lcd_register_conf();
    cm_init();
    mqtt_init();
    lcd_init();
    relay_init();
    acl_client_init();
    momentary_init(&main_rfid_present,  &main_rfid_absent);
    rfid_init(&momentary_on_rfid_present, &momentary_on_rfid_absent);
    ESP_ERROR_CHECK(esp_event_handler_register_with(main_event_loop,
        MAIN_EVENT, ESP_EVENT_ANY_ID, main_event_handler, NULL));
}
