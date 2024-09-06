# Copyright 2024-2025 Stephen Warren <swarren@wwwdotorg.org>
# SPDX-License-Identifier: MIT

idf_component_register(
    PRIV_REQUIRES
        fcch_connmgr
        esp_http_client
    SRCS
        acl_client.cpp
    INCLUDE_DIRS
        include
)
