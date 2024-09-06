// Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
// SPDX-License-Identifier: MIT

#pragma once

extern void mqtt_init();
extern void mqtt_on_rfid_err(uint32_t rfid);
extern void mqtt_on_rfid_ok(uint32_t rfid);
extern void mqtt_on_rfid_bad(uint32_t rfid);
extern void mqtt_on_rfid_none();
