// Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
// SPDX-License-Identifier: MIT

#include <driver/gpio.h>
#include <esp_log.h>
#include <freertos/FreeRTOS.h>

#include "relay.h"

#define RELAY_GPIO GPIO_NUM_14

// static const char *TAG = "relay";

void relay_init() {
    ESP_ERROR_CHECK(gpio_reset_pin(RELAY_GPIO));
    ESP_ERROR_CHECK(gpio_set_direction(RELAY_GPIO, GPIO_MODE_OUTPUT));
    relay_on_rfid_none();
}

void relay_on_rfid_ok() {
    ESP_ERROR_CHECK(gpio_set_level(RELAY_GPIO, 1));
}

void relay_on_rfid_none() {
    ESP_ERROR_CHECK(gpio_set_level(RELAY_GPIO, 0));
}
