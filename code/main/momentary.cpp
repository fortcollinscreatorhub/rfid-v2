// Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
// SPDX-License-Identifier: MIT

#include <esp_log.h>
#include <freertos/FreeRTOS.h>

#include "fcch_connmgr/cm_conf.h"
#include "fcch_connmgr/cm_util.h"
#include "momentary.h"

static const char *TAG = "momentary";

enum momentary_message_id {
    MOMENTARY_MESSAGE_TIMER,
    MOMENTARY_MESSAGE_RFID_PRESENT,
    MOMENTARY_MESSAGE_RFID_ABSENT,
};

struct momentary_message {
    momentary_message_id id;
    union {
        uint32_t dummy;
        uint32_t rfid;
        uint32_t timer_epoch;
    };
};

#define BLOCK_TIME (10 / portTICK_PERIOD_MS)

static uint16_t momentary_seconds;
static cm_conf_item momentary_item_momentary_seconds = {
    .slug_name = "mt", // Momentary Time
    .text_name = "Momentary Time (Seconds, 0 to disable)",
    .type = CM_CONF_ITEM_TYPE_U16,
    .p_val = {.u16 = &momentary_seconds },
    .default_func = &cm_conf_default_u16_0,
};

static cm_conf_item *momentary_items[] = {
    &momentary_item_momentary_seconds,
};

static cm_conf_page momentary_page = {
    .slug_name = "m", // Momentary
    .text_name = "Momentary",
    .items = momentary_items,
    .items_count = ARRAY_SIZE(momentary_items),
};

static QueueHandle_t momentary_queue;
static TimerHandle_t momentary_timer;
static uint32_t momentary_timer_epoch;
static momentary_callback_present *momentary_cb_present;
static momentary_callback_absent *momentary_cb_absent;

static void momentary_on_msg_timer(momentary_message &msg) {
    assert(momentary_seconds > 0);

    if (msg.timer_epoch != momentary_timer_epoch) {
        ESP_LOGW(TAG, "epoch mismatch: msg:%" PRIu32 ", state:%" PRIu32,
            msg.timer_epoch, momentary_timer_epoch);
        return;
    }
    momentary_cb_absent();
}

static void momentary_on_msg_rfid_present(momentary_message &msg) {
    momentary_cb_present(msg.rfid);

    if (momentary_seconds > 0) {
        assert(xTimerStop(momentary_timer, BLOCK_TIME) == pdPASS);
        momentary_timer_epoch++;
        assert(xTimerStart(momentary_timer, BLOCK_TIME) == pdPASS);
    }
}

static void momentary_on_msg_rfid_absent(momentary_message &msg) {
    if (momentary_seconds == 0) {
        momentary_cb_absent();
    }
}

static void momentary_task(void *pvParameters) {
    for (;;) {
        momentary_message msg;
        assert(xQueueReceive(momentary_queue, &msg, portMAX_DELAY) == pdTRUE);
        ESP_LOGD(TAG, "msg.id %d", msg.id);
        switch (msg.id) {
        case MOMENTARY_MESSAGE_TIMER:
            momentary_on_msg_timer(msg);
            break;
        case MOMENTARY_MESSAGE_RFID_PRESENT:
            momentary_on_msg_rfid_present(msg);
            break;
        case MOMENTARY_MESSAGE_RFID_ABSENT:
            momentary_on_msg_rfid_absent(msg);
            break;
        default:
            ESP_LOGE(TAG, "Unknown message: %d", (int)msg.id);
            break;
        }
    }
}

static void momentary_on_timer(TimerHandle_t xTimer) {
    assert(momentary_seconds > 0);

    momentary_message msg{
        .id = MOMENTARY_MESSAGE_TIMER,
        .timer_epoch = momentary_timer_epoch,
    };
    assert(xQueueSend(momentary_queue, &msg, BLOCK_TIME) == pdTRUE);
}

void momentary_register_conf() {
    cm_conf_register_page(&momentary_page);
}

void momentary_init(
    momentary_callback_present *present,
    momentary_callback_absent *absent
) {
    momentary_cb_present = present;
    momentary_cb_absent = absent;

    momentary_queue = xQueueCreate(8, sizeof(momentary_message));
    assert(momentary_queue != NULL);

    if (momentary_seconds > 0) {
        momentary_timer = xTimerCreate(
            "momentary",
            (momentary_seconds * 1000) / portTICK_PERIOD_MS,
            pdFALSE,
            NULL,
            momentary_on_timer);
        assert(momentary_timer != NULL);
    }

    BaseType_t xRet = xTaskCreate(momentary_task, "momentary", 1024, NULL, 5, NULL);
    assert(xRet == pdPASS);
}

void momentary_on_rfid_present(uint32_t rfid) {
    momentary_message msg{
        .id = MOMENTARY_MESSAGE_RFID_PRESENT,
        .rfid = rfid,
    };
    assert(xQueueSend(momentary_queue, &msg, BLOCK_TIME) == pdTRUE);
}

void momentary_on_rfid_absent() {
    momentary_message msg{
        .id = MOMENTARY_MESSAGE_RFID_ABSENT,
        .dummy = 0,
    };
    assert(xQueueSend(momentary_queue, &msg, BLOCK_TIME) == pdTRUE);
}
