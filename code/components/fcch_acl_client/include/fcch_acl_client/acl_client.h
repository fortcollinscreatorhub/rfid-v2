// Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
// SPDX-License-Identifier: MIT

#pragma once

#include <esp_err.h>

extern void acl_client_register_conf();
extern void acl_client_init();
extern esp_err_t acl_client_check_id(uint32_t rfid, bool *allowed);
