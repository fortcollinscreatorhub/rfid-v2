// Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
// SPDX-License-Identifier: MIT

#pragma once

#include <stdint.h>

typedef void momentary_callback_present(uint32_t rfid);
typedef void momentary_callback_absent();

extern void momentary_register_conf();
extern void momentary_init(
    momentary_callback_present *present,
    momentary_callback_absent *absent
);
extern void momentary_on_rfid_present(uint32_t rfid);
extern void momentary_on_rfid_absent();

/* Return the configured momentary duration in milliseconds (0 = disabled) */
extern uint32_t momentary_get_milliseconds();

/* Return non-zero if momentary debug bypass is enabled via config (0 = disabled) */
extern uint16_t momentary_get_debug_enabled();
