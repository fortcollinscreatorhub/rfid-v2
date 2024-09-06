# Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
# SPDX-License-Identifier: MIT

idf_component_register(
    REQUIRES
        fcch_acl_client
        fcch_connmgr
        fcch_rfid
        LovyanGFX
    SRCS
        lcd.cpp
        main.cpp
        momentary.cpp
        mqtt.cpp
        relay.cpp
)
