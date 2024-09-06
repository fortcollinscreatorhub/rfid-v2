// Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
// SPDX-License-Identifier: MIT

#pragma once

#include <stdint.h>

typedef void rfid_callback_present(uint32_t rfid);
typedef void rfid_callback_absent();

extern void rfid_init(
    rfid_callback_present *cb_present,
    rfid_callback_absent *cb_absent
);
