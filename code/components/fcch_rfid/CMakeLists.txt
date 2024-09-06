# Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
# SPDX-License-Identifier: MIT

idf_component_register(
    PRIV_REQUIRES
        esp_driver_gpio
        esp_driver_uart
        esp_event
        fcch_connmgr
    SRCS
        rfid.cpp
    INCLUDE_DIRS
        include
)
