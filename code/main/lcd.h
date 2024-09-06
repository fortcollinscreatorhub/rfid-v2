// Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
// SPDX-License-Identifier: MIT

#pragma once

extern void lcd_register_conf();
extern void lcd_init();
extern void lcd_on_rfid_err(uint32_t rfid);
extern void lcd_on_rfid_ok(uint32_t rfid);
extern void lcd_on_rfid_bad(uint32_t rfid);
extern void lcd_on_rfid_none();
