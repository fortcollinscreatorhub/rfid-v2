// Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
// SPDX-License-Identifier: MIT

#include <driver/gpio.h>
#include <esp_log.h>
#include <freertos/FreeRTOS.h>
#include <string.h>

#include "fcch_connmgr/cm.h"
#include "relay.h"

#define RELAY_GPIO GPIO_NUM_14

// static const char *TAG = "relay";

static int relay_level = 0;

static void relay_write(int new_relay_level) {
    relay_level = new_relay_level;
    ESP_ERROR_CHECK(gpio_set_level(RELAY_GPIO, relay_level));
}

static void relay_http_action_toggle() {
    relay_write(!relay_level);
}

static const char *relay_http_action_toggle_description() {
    if (relay_level) {
        return "Toggle Relay (Is On)";
    } else {
        return "Toggle Relay (Is Off)";
    }
}

void relay_init() {
    ESP_ERROR_CHECK(gpio_reset_pin(RELAY_GPIO));
    ESP_ERROR_CHECK(gpio_set_direction(RELAY_GPIO, GPIO_MODE_OUTPUT));
    relay_on_rfid_none();
    cm_http_register_home_action(
        "toggle-relay",
        relay_http_action_toggle_description,
        relay_http_action_toggle
    );
}

void relay_on_rfid_ok() {
    relay_write(1);
}

void relay_on_rfid_none() {
    relay_write(0);
}
