// Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
// SPDX-License-Identifier: MIT

#include <esp_log.h>
#include <freertos/FreeRTOS.h>
#include <LovyanGFX.hpp>

#include "fcch_connmgr/cm.h"
#include "fcch_connmgr/cm_conf.h"
#include "fcch_connmgr/cm_net.h"
#include "fcch_connmgr/cm_mqtt.h"
#include "fcch_connmgr/cm_util.h"
#include "lcd.h"

#define DISPLAY_RST 4
#define DISPLAY_DC 2
#define DISPLAY_MOSI 23
#define DISPLAY_CS 15
#define DISPLAY_SCLK 18
#define DISPLAY_LEDA 32
#define DISPLAY_MISO -1
#define DISPLAY_BUSY -1

#if 1 // ideaspark® ESP32 Development Board 1.14 inch 135x240 LCD Display,CH340,WiFi+BL
#define DISPLAY_WIDTH 240
#define DISPLAY_HEIGHT 135
#define DISPLAY_OFFSET_X 40
#define DISPLAY_OFFSET_Y 53
#define DISPLAY_FONT_SIZE 2
#elif 1 // ideaspark® ESP32 Development Board 16MB 1.9 in 170x320 LCD Display,CH340,WiFi+BL
#define DISPLAY_WIDTH 320
#define DISPLAY_HEIGHT 170
#define DISPLAY_OFFSET_X 0
#define DISPLAY_OFFSET_Y 35
#define DISPLAY_FONT_SIZE 3
#else
#error No LCD definition enabled
#endif

static const char *TAG = "lcd";

static uint16_t lcd_show_rfids;
static cm_conf_item lcd_item_lcd_show_rfids = {
    .slug_name = "sr", // Show Rfids
    .text_name = "Show RFIDs? (0: no, other: yes)",
    .type = CM_CONF_ITEM_TYPE_U16,
    .p_val = {.u16 = &lcd_show_rfids },
    .default_func = &cm_conf_default_u16_0,
};

static cm_conf_item *lcd_items[] = {
    &lcd_item_lcd_show_rfids,
};

static cm_conf_page lcd_conf_page = {
    .slug_name = "lc", // LCd
    .text_name = "LCD",
    .items = lcd_items,
    .items_count = ARRAY_SIZE(lcd_items),
};

static bool lcd_show_rfids_override;

static void lcd_http_action_show_rfids_toggle() {
    lcd_show_rfids_override = !lcd_show_rfids_override;
}

static const char *lcd_http_action_show_rfids_toggle_description() {
    if (lcd_show_rfids_override) {
        return "Toggle Show RFIDs Override (Is On)";
    } else {
        return "Toggle Show RFIDs Override (Is Off)";
    }
}

enum lcd_message_id {
    LCD_MESSAGE_TIMER,
    LCD_MESSAGE_RFID_ERR,
    LCD_MESSAGE_RFID_OK,
    LCD_MESSAGE_RFID_BAD,
    LCD_MESSAGE_RFID_NONE,
};

struct lcd_message {
    lcd_message_id id;
    union {
        uint32_t rfid;
        uint32_t timer_epoch;
    };
};

enum lcd_page {
    LCD_PAGE_IDENT,
    LCD_PAGE_AP,
    LCD_PAGE_STA,
    LCD_PAGE_MQTT,
    LCD_PAGE_RFID,
    LCD_PAGE_NUM,
};

#define BLOCK_TIME (10 / portTICK_PERIOD_MS)

class LcdDevice : public lgfx::LGFX_Device {
    lgfx::Panel_ST7735S m_panel_instance;
    lgfx::Bus_SPI m_bus_instance;
    lgfx::Light_PWM m_light_instance;

public:
    LcdDevice() {
        auto bus_cfg = m_bus_instance.config();
        bus_cfg.spi_host = SPI2_HOST;
        bus_cfg.spi_mode = 2;
        bus_cfg.freq_write = 27000000;
        bus_cfg.freq_read = 16000000;
        bus_cfg.spi_3wire = true;
        bus_cfg.use_lock = false;
        bus_cfg.dma_channel = SPI_DMA_CH_AUTO;
        bus_cfg.pin_sclk = DISPLAY_SCLK;
        bus_cfg.pin_mosi = DISPLAY_MOSI;
        bus_cfg.pin_miso = DISPLAY_MISO;
        bus_cfg.pin_dc = DISPLAY_DC;
        m_bus_instance.config(bus_cfg);
        m_panel_instance.setBus(&m_bus_instance);

        auto panel_cfg = m_panel_instance.config();
        panel_cfg.pin_cs = DISPLAY_CS;
        panel_cfg.pin_rst = DISPLAY_RST;
        panel_cfg.pin_busy = DISPLAY_BUSY;
        panel_cfg.panel_width = DISPLAY_WIDTH;
        panel_cfg.panel_height = DISPLAY_HEIGHT;
        panel_cfg.offset_x = DISPLAY_OFFSET_X;
        panel_cfg.offset_y = DISPLAY_OFFSET_Y;
        panel_cfg.offset_rotation = 0;
        panel_cfg.dummy_read_pixel = 8;
        panel_cfg.dummy_read_bits = 1;
        panel_cfg.readable = false;
        panel_cfg.invert = true;
        panel_cfg.rgb_order = false;
        panel_cfg.dlen_16bit = false;
        panel_cfg.bus_shared = false;
        m_panel_instance.config(panel_cfg);

        auto light_cfg = m_light_instance.config();
        light_cfg.pin_bl = DISPLAY_LEDA;
        light_cfg.invert = false;
        light_cfg.freq = 12000;
        light_cfg.pwm_channel = 7;
        m_light_instance.config(light_cfg);
        m_panel_instance.setLight(&m_light_instance);

        setPanel(&m_panel_instance);
    }
};

static QueueHandle_t lcd_queue;
static TimerHandle_t lcd_timer;
static uint32_t lcd_timer_epoch;
static int lcd_page;
static TickType_t lcd_last_rfid_time;
static lcd_message lcd_last_rfid_message{
    .id = LCD_MESSAGE_RFID_NONE,
    .rfid = 0,
};
static LcdDevice lcd;

// Within a uint16_t, 5 bit per channel: b@11, g@6, grey@5, r@0
// CONFUSING: Colors are interpreted differently if within a uint32_t.
// CONFUSING: Color bit/channel order appears reverse of TFT_xxx constants.
#define gen_color_u16(r, g, b) (uint16_t( \
    ((uint16_t(r) & 0x1f) <<  0) | \
    ((uint16_t(g) & 0x1f) <<  6) | \
    ((uint16_t(b) & 0x1f) << 11)))

static const uint16_t lcd_color_err = gen_color_u16(0x1f, 0x01, 0);;
static const uint16_t lcd_color_ok = gen_color_u16(0, 0x1f, 0);
static const uint16_t lcd_color_bad = gen_color_u16(0x1f, 0, 0);
static const uint16_t lcd_color_none = gen_color_u16(0, 0, 0);

static bool lcd_sta_connected;
static bool lcd_mqtt_connected;

static void lcd_msg(const char *s) {
    uint16_t bg;
    switch (lcd_last_rfid_message.id) {
    case LCD_MESSAGE_RFID_ERR:
        bg = lcd_color_err;
        break;
    case LCD_MESSAGE_RFID_OK:
        bg = lcd_color_ok;
        break;
    case LCD_MESSAGE_RFID_BAD:
        bg = lcd_color_bad;
        break;
    case LCD_MESSAGE_RFID_NONE:
        bg = lcd_color_none;
        break;
    default:
        ESP_LOGE(TAG, "Unknown last RFID message %d", lcd_last_rfid_message.id);
        bg = gen_color_u16(0x1f, 0, 0x1f);
        break;
    }

    lcd.clear(bg);
    uint16_t stat_bar_color;
    if (!lcd_sta_connected || !lcd_mqtt_connected)
        stat_bar_color = lcd_color_err;
    else
        stat_bar_color = lcd_color_ok;
    lcd.setColor(stat_bar_color);
    lcd.fillRect(0, DISPLAY_HEIGHT - 8, DISPLAY_WIDTH, 8);
    lcd.setCursor(0, 0);
    lcd.setTextSize(DISPLAY_FONT_SIZE);
    lcd.setTextColor(TFT_WHITE);
    lcd.println(s);
}

static void lcd_on_timer(TimerHandle_t xTimer) {
    lcd_message msg{
        .id = LCD_MESSAGE_TIMER,
        .timer_epoch = lcd_timer_epoch,
    };
    assert(xQueueSend(lcd_queue, &msg, BLOCK_TIME) == pdTRUE);
}

char *stpcat_trunc(char *p, const char *s, size_t len) {
    p = stpncpy(p, s, 16);
    if (strlen(s) > 16) {
        p[-1] = '.';
        p[-2] = '.';
        p[-3] = '.';
    }
    return p;
}

static void lcd_draw_page_ident() {
    bool is_protected = cm_admin_is_protected();

    char buf[64];
    char *p = stpcpy(buf, "ID\n");
    p = stpcat_trunc(p, cm_net_hostname, 16);
    if (is_protected)
        p = stpcpy(p, "\nadmin protected");
    else
        p = stpcpy(p, "\nadmin open");
    *p = '\0';
    lcd_msg(buf);
}

#define U32IP2STR(ip) \
    uint32_t(((ip) >>  0) & 0xff), \
    uint32_t(((ip) >>  8) & 0xff), \
    uint32_t(((ip) >> 16) & 0xff), \
    uint32_t(((ip) >> 24) & 0xff)

static void lcd_draw_page_ap() {
    auto ap_info = cm_net_get_ap_info();

    char buf[64];
    char *p = stpcpy(buf, "AP ");
    if (ap_info.enabled) {
        p = stpcpy(p, "enabled\n");
        p = stpcat_trunc(p, ap_info.network, 16);
        p += sprintf(p, "\n%lu.%lu.%lu.%lu", U32IP2STR(ap_info.ip));
    } else {
        p = stpcpy(p, "disabled\n");
    }
    *p = '\0';
    lcd_msg(buf);
}

static void lcd_draw_page_sta() {
    auto sta_info = cm_net_get_sta_info();
    lcd_sta_connected = sta_info.connected;

    char buf[64];
    char *p = stpcpy(buf, "STA ");
    if (sta_info.connected) {
        p = stpcpy(p, "connected\n");
        p = stpcat_trunc(p, sta_info.network, 16);
    } else {
        p = stpcpy(p, "disconnected\n");
    }
    if (sta_info.has_ip) {
        p += sprintf(p, "\n%lu.%lu.%lu.%lu", U32IP2STR(sta_info.ip));
    }
    *p = '\0';
    lcd_msg(buf);
}

static void lcd_draw_page_mqtt() {
    auto mqtt_info = cm_mqtt_get_info();
    lcd_mqtt_connected = (!mqtt_info.enabled) || mqtt_info.connected;

    char buf[64];
    char *p = stpcpy(buf, "MQTT ");
    if (mqtt_info.connected) {
        p = stpcpy(p, "connected\n");
    } else {
        p = stpcpy(p, "disconnected\n");
    }
    p = stpcat_trunc(p, cm_mqtt_client_name, 16);
    *p = '\0';
    lcd_msg(buf);
}

static void lcd_draw_page_rfid() {
    char buf[64];
    char *p = stpcpy(buf, "RFID ");
    switch (lcd_last_rfid_message.id) {
    case LCD_MESSAGE_RFID_ERR:
        p = stpcpy(p, "comms error");
        break;
    case LCD_MESSAGE_RFID_OK:
        p = stpcpy(p, "granted");
        break;
    case LCD_MESSAGE_RFID_BAD:
        p = stpcpy(p, "denied");
        break;
    case LCD_MESSAGE_RFID_NONE:
        p = stpcpy(p, "not present");
        break;
    default:
        p = stpcpy(p, "???");
        break;
    }
    switch (lcd_last_rfid_message.id) {
    case LCD_MESSAGE_RFID_ERR:
    case LCD_MESSAGE_RFID_OK:
    case LCD_MESSAGE_RFID_BAD:
        if (lcd_show_rfids || lcd_show_rfids_override) {
            p += sprintf(p, "\n%lu", lcd_last_rfid_message.rfid);
        } else {
            p = stpcpy(p, "\n<hidden>");
        }
        break;
    default:
        break;
    }
    *p = '\0';
    lcd_msg(buf);
}

static void lcd_draw_page() {
    switch (lcd_page) {
    case LCD_PAGE_IDENT:
        lcd_draw_page_ident();
        break;
    case LCD_PAGE_AP:
        lcd_draw_page_ap();
        break;
    case LCD_PAGE_STA:
        lcd_draw_page_sta();
        break;
    case LCD_PAGE_MQTT:
        lcd_draw_page_mqtt();
        break;
    case LCD_PAGE_RFID:
        lcd_draw_page_rfid();
        break;
    default:
        ESP_LOGE(TAG, "Don't know how to draw page %d", lcd_page);
        break;
    }
}

static void lcd_on_msg_timer(lcd_message &msg) {
    if (msg.timer_epoch != lcd_timer_epoch) {
        ESP_LOGW(TAG, "epoch mismatch: msg:%" PRIu32 ", state:%" PRIu32,
            msg.timer_epoch, lcd_timer_epoch);
        return;
    }
    lcd_page++;
    if (lcd_page >= LCD_PAGE_NUM)
        lcd_page = 0;
}

static void lcd_on_msg_rfid_any(lcd_message &msg) {
    if (lcd_last_rfid_message.id == LCD_MESSAGE_RFID_NONE &&
        msg.id == LCD_MESSAGE_RFID_NONE
    ) {
        return;
    }
    lcd_last_rfid_time = xTaskGetTickCount();
    lcd_last_rfid_message = msg;
    assert(xTimerStop(lcd_timer, BLOCK_TIME) == pdPASS);
    lcd_timer_epoch++;
    lcd_page = LCD_PAGE_RFID;
    assert(xTimerStart(lcd_timer, BLOCK_TIME) == pdPASS);
}

static void lcd_on_msg_rfid_err(lcd_message &msg) {
    lcd_on_msg_rfid_any(msg);
}

static void lcd_on_msg_rfid_ok(lcd_message &msg) {
    lcd_on_msg_rfid_any(msg);
}

static void lcd_on_msg_rfid_bad(lcd_message &msg) {
    lcd_on_msg_rfid_any(msg);
}

static void lcd_on_msg_rfid_none(lcd_message &msg) {
    lcd_on_msg_rfid_any(msg);
}

static void lcd_task(void *pvParameters) {
    assert(lcd.init());
    lcd.setBrightness(255);

    assert(xTimerStart(lcd_timer, BLOCK_TIME));

    for (;;) {
        lcd_draw_page();

        lcd_message msg;
        assert(xQueueReceive(lcd_queue, &msg, portMAX_DELAY) == pdTRUE);
        ESP_LOGD(TAG, "msg.id %d", msg.id);
        switch (msg.id) {
        case LCD_MESSAGE_TIMER:
            lcd_on_msg_timer(msg);
            break;
        case LCD_MESSAGE_RFID_ERR:
            lcd_on_msg_rfid_err(msg);
            break;
        case LCD_MESSAGE_RFID_OK:
            lcd_on_msg_rfid_ok(msg);
            break;
        case LCD_MESSAGE_RFID_BAD:
            lcd_on_msg_rfid_bad(msg);
            break;
        case LCD_MESSAGE_RFID_NONE:
            lcd_on_msg_rfid_none(msg);
            break;
        default:
            ESP_LOGE(TAG, "Unknown message: %d", (int)msg.id);
            break;
        }
    }
}

void lcd_register_conf() {
    cm_conf_register_page(&lcd_conf_page);
}

void lcd_init() {
    lcd_queue = xQueueCreate(8, sizeof(lcd_message));
    assert(lcd_queue != NULL);

    lcd_timer = xTimerCreate(
        "lcd",
        (2 * 1000) / portTICK_PERIOD_MS,
        pdTRUE,
        NULL,
        lcd_on_timer);
    assert(lcd_timer != NULL);

    BaseType_t xRet = xTaskCreate(lcd_task, "lcd", 4096, NULL, 5, NULL);
    assert(xRet == pdPASS);

    cm_http_register_home_action(
        "toggle-show-rfids",
        lcd_http_action_show_rfids_toggle_description,
        lcd_http_action_show_rfids_toggle
    );
}

void lcd_on_rfid_err(uint32_t rfid) {
    lcd_message msg{
        .id = LCD_MESSAGE_RFID_ERR,
        .rfid = rfid,
    };
    assert(xQueueSend(lcd_queue, &msg, BLOCK_TIME) == pdTRUE);
}

void lcd_on_rfid_ok(uint32_t rfid) {
    lcd_message msg{
        .id = LCD_MESSAGE_RFID_OK,
        .rfid = rfid,
    };
    assert(xQueueSend(lcd_queue, &msg, BLOCK_TIME) == pdTRUE);
}

void lcd_on_rfid_bad(uint32_t rfid) {
    lcd_message msg{
        .id = LCD_MESSAGE_RFID_BAD,
        .rfid = rfid,
    };
    assert(xQueueSend(lcd_queue, &msg, BLOCK_TIME) == pdTRUE);
}

void lcd_on_rfid_none() {
    lcd_message msg{
        .id = LCD_MESSAGE_RFID_NONE,
        .rfid = 0,
    };
    assert(xQueueSend(lcd_queue, &msg, BLOCK_TIME) == pdTRUE);
}
