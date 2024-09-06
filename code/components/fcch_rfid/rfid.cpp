// Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
// SPDX-License-Identifier: MIT

#include <string.h>

#include <driver/uart.h>
#include <driver/gpio.h>
#include <esp_log.h>

#include "fcch_connmgr/cm_util.h"
#include "fcch_rfid/rfid.h"

static const char *TAG = "rfid";

static const uart_port_t cm_rfid_uart_num = UART_NUM_1;
static const int cm_rfid_pin_txd = UART_PIN_NO_CHANGE;
static const int cm_rfid_pin_rxd = GPIO_NUM_13;
static const int cm_rfid_pin_rts = UART_PIN_NO_CHANGE;
static const int cm_rfid_pin_cts = UART_PIN_NO_CHANGE;

static rfid_callback_present *rfid_cb_present;
static rfid_callback_absent *rfid_cb_absent;

static void rfid_init_uart() {
    ESP_ERROR_CHECK(uart_driver_install(
        /* uart_num */ cm_rfid_uart_num,
        /* rx_buffer_size */ 256,
        /* tx_buffer_size */ 0,
        /* queue_size */ 0,
        /* uart_queue */ NULL,
        /* intr_alloc_flags */ 0));

    uart_config_t uart_config{};
    uart_config.baud_rate  = 9600;
    uart_config.data_bits  = UART_DATA_8_BITS;
    uart_config.parity     = UART_PARITY_DISABLE;
    uart_config.stop_bits  = UART_STOP_BITS_1;
    uart_config.flow_ctrl  = UART_HW_FLOWCTRL_DISABLE;
    uart_config.source_clk = UART_SCLK_DEFAULT;
    ESP_ERROR_CHECK(uart_param_config(cm_rfid_uart_num, &uart_config));

    ESP_ERROR_CHECK(uart_set_pin(cm_rfid_uart_num,
        cm_rfid_pin_txd, cm_rfid_pin_rxd, cm_rfid_pin_rts, cm_rfid_pin_cts));
}

static const int rfid_len = 12; // excluding STX, ETX

static uint32_t last_rfid;
static TickType_t last_rfid_time;

static void rfid_send_present(uint32_t rfid) {
    last_rfid = rfid;
    ESP_LOGD(TAG, "RFID present %lu", rfid);
    rfid_cb_present(rfid);
}

static void rfid_send_removed() {
    last_rfid = 0;
    ESP_LOGD(TAG, "RFID removed");
    rfid_cb_absent();
}

static void rfid_handle(uint32_t rfid) {
    if (last_rfid && last_rfid != rfid)
        rfid_send_removed();

    TickType_t now = xTaskGetTickCount();
    last_rfid_time = now;

    if (rfid == last_rfid)
        return;

    rfid_send_present(rfid);
}

static void rfid_check_timeout() {
    if (last_rfid == 0)
        return;

    TickType_t now = xTaskGetTickCount();
    TickType_t time_since_rfid = now - last_rfid_time;
    static const TickType_t rfid_timeout = 300 / portTICK_PERIOD_MS;
    if (time_since_rfid < rfid_timeout)
        return;

    rfid_send_removed();
}

static void rfid_handle_raw(char *buf) {
    uint8_t ibuf[rfid_len / 2];

    // String to int
    for (int i = 0; i < rfid_len; i += 2)
        ibuf[i / 2] =
            (cm_util_hex_char_to_uint(buf[i    ]) << 4) |
            (cm_util_hex_char_to_uint(buf[i + 1]) << 0);

    // CRC check
    uint8_t crc = 0;
    for (int i = 0; i < rfid_len / 2; i++) {
        crc ^= ibuf[i];
    }
    if (crc) {
        buf[rfid_len] = '\0';
        ESP_LOGW(TAG, "RFID bad CRC (%s, %02x)", buf, (unsigned int)crc);
        return;
    }

    uint32_t rfid = 0;
    for (int i = 1; i <= 4; i++)
        rfid = (rfid << 8) | ibuf[i];
    ESP_LOGD(TAG, "RFID present %lu", rfid);
    rfid_handle(rfid);
}

static void rfid_task(void *pvParameters) {
    char rfid_buf[rfid_len + 1]; // +1 is for NUL
    int rfid_buf_len = 0;
    TickType_t stx_time = 0;
    for (;;) {
        char rx_buf[1 + rfid_len + 1 + 1]; // STX, rfid data, ETX, NUL
        int rx_buf_len = uart_read_bytes(cm_rfid_uart_num,
            rx_buf, sizeof(rx_buf) - 1, 100 / portTICK_PERIOD_MS);
        if (rx_buf_len) {
            rx_buf[rx_buf_len] = '\0';
            ESP_LOGD(TAG, "Raw TX (%s)", rx_buf);
        }
        for (int i = 0; i < rx_buf_len; i++) {
            char ch = rx_buf[i];
            if (ch == 0x02) {
                ESP_LOGD(TAG, "RFID starts now");
                rfid_buf_len = 0;
                stx_time = xTaskGetTickCount();
            } else if (ch == 0x03) {
                rfid_buf[rfid_buf_len] = '\0';
                ESP_LOGD(TAG, "RFID RX complete (%s)", rfid_buf);
                rfid_handle_raw(rfid_buf);
                rfid_buf_len = 0;
            } else if (rfid_buf_len >= rfid_len) {
                rfid_buf[rfid_buf_len] = '\0';
                ESP_LOGW(TAG, "RFID too long and no ETX (%s)", rfid_buf);
                rfid_buf_len = 0;
            } else {
                rfid_buf[rfid_buf_len++] = ch;
            }
        }
        if (rfid_buf_len) {
            TickType_t now = xTaskGetTickCount();
            TickType_t time_since_stx = now - stx_time;
            static const TickType_t max_rfid_recv_time =
                200 / portTICK_PERIOD_MS;
            if (time_since_stx >= max_rfid_recv_time) {
                rfid_buf[rfid_buf_len] = '\0';
                ESP_LOGW(TAG, "RFID RX timeout (%s)", rfid_buf);
                rfid_buf_len = 0;
            }
        }
        rfid_check_timeout();
    }
}

void rfid_init(
    rfid_callback_present *cb_present,
    rfid_callback_absent *cb_absent
) {
    ESP_LOGI(TAG, "rfid_init: start");
    rfid_cb_present = cb_present;
    rfid_cb_absent = cb_absent;
    rfid_init_uart();
    xTaskCreate(&rfid_task, "rfid", 4096, NULL, 5, NULL);
    ESP_LOGI(TAG, "rfid_init: done");
}
