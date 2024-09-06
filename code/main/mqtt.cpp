// Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
// SPDX-License-Identifier: MIT

#include <esp_log.h>
#include <freertos/FreeRTOS.h>
#include <stdio.h>

#include "fcch_connmgr/cm_mqtt.h"
#include "fcch_connmgr/cm_util.h"
#include "mqtt.h"

static const char *TAG = "mqtt";

enum mqtt_message_id {
    MQTT_MESSAGE_TIMER,
    MQTT_MESSAGE_RFID_ERR,
    MQTT_MESSAGE_RFID_OK,
    MQTT_MESSAGE_RFID_BAD,
    MQTT_MESSAGE_RFID_NONE,
};

struct mqtt_message {
    mqtt_message_id id;
    union {
        uint32_t rfid;
        uint32_t timer_epoch;
    };
};

#define BLOCK_TIME (10 / portTICK_PERIOD_MS)

static QueueHandle_t mqtt_queue;
static TimerHandle_t mqtt_timer;
static uint32_t mqtt_timer_epoch;
static const char* mqtt_last_status;
static const char* mqtt_last_rfid_status;
static uint32_t mqtt_last_rfid;

static void mqtt_publish_status() {
    AutoFree<char> data;
    asprintf(
        &data.val,
        "{\"status\":\"%s\",\"rfid_status\":\"%s\",\"rfid\":%lu}",
        mqtt_last_status, mqtt_last_rfid_status, mqtt_last_rfid);
    assert(data.val != NULL);

    cm_mqtt_publish_stat(data.val);
}

static void mqtt_stop_timer() {
    if (mqtt_timer == NULL)
        return;
    mqtt_timer_epoch++;
    assert(xTimerStop(mqtt_timer, BLOCK_TIME) == pdPASS);
}

static void mqtt_start_timer() {
    if (mqtt_timer == NULL)
        return;
    mqtt_timer_epoch++;
    assert(xTimerStart(mqtt_timer, BLOCK_TIME) == pdPASS);
}

static void mqtt_on_msg_timer(mqtt_message &msg) {
    if (msg.timer_epoch != mqtt_timer_epoch) {
        ESP_LOGW(TAG, "epoch mismatch: msg:%" PRIu32 ", state:%" PRIu32,
            msg.timer_epoch, mqtt_timer_epoch);
        return;
    }
    mqtt_publish_status();
}

static void mqtt_on_msg_rfid_err(mqtt_message &msg) {
    mqtt_stop_timer();

    mqtt_last_rfid = msg.rfid;
    mqtt_last_status = "OFF";
    mqtt_last_rfid_status = "ERROR";
    mqtt_publish_status();
}

static void mqtt_on_msg_rfid_ok(mqtt_message &msg) {
    mqtt_last_rfid = msg.rfid;
    mqtt_last_status = "ON";
    mqtt_last_rfid_status = "GRANT";
    mqtt_publish_status();

    mqtt_start_timer();
}

static void mqtt_on_msg_rfid_bad(mqtt_message &msg) {
    mqtt_stop_timer();

    mqtt_last_rfid = msg.rfid;
    mqtt_last_status = "OFF";
    mqtt_last_rfid_status = "DENY";
    mqtt_publish_status();
}

static void mqtt_on_msg_rfid_none(mqtt_message &msg) {
    mqtt_stop_timer();

    mqtt_last_rfid = msg.rfid;
    mqtt_last_status = "OFF";
    mqtt_last_rfid_status = "ABSENT";
    mqtt_publish_status();
}

static void mqtt_task(void *pvParameters) {
    for (;;) {
        mqtt_message msg;
        assert(xQueueReceive(mqtt_queue, &msg, portMAX_DELAY) == pdTRUE);
        ESP_LOGI(TAG, "msg.id %d", msg.id);
        switch (msg.id) {
        case MQTT_MESSAGE_TIMER:
            mqtt_on_msg_timer(msg);
            break;
        case MQTT_MESSAGE_RFID_ERR:
            mqtt_on_msg_rfid_err(msg);
            break;
        case MQTT_MESSAGE_RFID_OK:
            mqtt_on_msg_rfid_ok(msg);
            break;
        case MQTT_MESSAGE_RFID_BAD:
            mqtt_on_msg_rfid_bad(msg);
            break;
        case MQTT_MESSAGE_RFID_NONE:
            mqtt_on_msg_rfid_none(msg);
            break;
        default:
            ESP_LOGE(TAG, "Unknown message: %d", (int)msg.id);
            break;
        }
    }
}

static void mqtt_on_timer(TimerHandle_t xTimer) {
    ESP_LOGI(TAG, "mqtt_on_timer()");
    mqtt_message msg{
        .id = MQTT_MESSAGE_TIMER,
        .timer_epoch = mqtt_timer_epoch,
    };
    assert(xQueueSend(mqtt_queue, &msg, BLOCK_TIME) == pdTRUE);
}

void mqtt_init() {
    mqtt_queue = xQueueCreate(8, sizeof(mqtt_message));
    assert(mqtt_queue != NULL);

    if (cm_mqtt_status_period) {
        mqtt_timer = xTimerCreate(
            "mqtt",
            (cm_mqtt_status_period * 1000) / portTICK_PERIOD_MS,
            pdTRUE,
            NULL,
            mqtt_on_timer);
        assert(mqtt_timer != NULL);
    } else {
        mqtt_timer = NULL;
    }

    BaseType_t xRet = xTaskCreate(mqtt_task, "mqtt", 4096, NULL, 5, NULL);
    assert(xRet == pdPASS);
}

void mqtt_on_rfid_err(uint32_t rfid) {
    mqtt_message msg{
        .id = MQTT_MESSAGE_RFID_ERR,
        .rfid = rfid,
    };
    assert(xQueueSend(mqtt_queue, &msg, BLOCK_TIME) == pdTRUE);
}

void mqtt_on_rfid_ok(uint32_t rfid) {
    mqtt_message msg{
        .id = MQTT_MESSAGE_RFID_OK,
        .rfid = rfid,
    };
    assert(xQueueSend(mqtt_queue, &msg, BLOCK_TIME) == pdTRUE);
}

void mqtt_on_rfid_bad(uint32_t rfid) {
    mqtt_message msg{
        .id = MQTT_MESSAGE_RFID_BAD,
        .rfid = rfid,
    };
    assert(xQueueSend(mqtt_queue, &msg, BLOCK_TIME) == pdTRUE);
}

void mqtt_on_rfid_none() {
    mqtt_message msg{
        .id = MQTT_MESSAGE_RFID_NONE,
        .rfid = 0,
    };
    assert(xQueueSend(mqtt_queue, &msg, BLOCK_TIME) == pdTRUE);
}
