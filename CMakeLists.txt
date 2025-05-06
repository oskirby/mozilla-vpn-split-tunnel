# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

cmake_minimum_required(VERSION 3.20)

project(split-tunnel VERSION 0.1 LANGUAGES C CXX OBJC
        DESCRIPTION "Mozilla VPN Split Tunnel"
        HOMEPAGE_URL "https://vpn.mozilla.org"
)

# Set some variables when we are building this extension standalone.
if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
    if (NOT CMAKE_OSX_DEPLOYMENT_TARGET)
        set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0" CACHE STRING "Minimum OSX version to target for deployment")
    endif()
    if (NOT BUILD_OSX_APP_IDENTIFIER)
        set(BUILD_OSX_APP_IDENTIFIER org.mozilla.macos.FirefoxVPN.split-tunnel CACHE STRING "OSX Application identifier")
    endif()
    if(NOT BUILD_VPN_DEVELOPMENT_TEAM)
        set(BUILD_VPN_DEVELOPMENT_TEAM 43AQ936H96 CACHE STRING "Mozilla VPN Development Team")
    endif()
    set(CMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ${BUILD_VPN_DEVELOPMENT_TEAM})
endif()

find_library(FW_FOUNDATION Foundation)
find_library(FW_NW_EXTENSION NetworkExtension)
find_library(FW_SYS_EXTENSION SystemExtensions)

# The VPN Split Tunnel extension
add_executable(split-tunnel)
set_target_properties(split-tunnel PROPERTIES
    OUTPUT_NAME "${BUILD_OSX_APP_IDENTIFIER}.sysex"
    BUNDLE_EXTENSION systemextension
    MACOSX_BUNDLE ON
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/src/Info.plist.in
    MACOSX_BUNDLE_BUNDLE_NAME "${BUILD_OSX_APP_IDENTIFIER}.sysex"
    MACOSX_BUNDLE_BUNDLE_VERSION "${CMAKE_PROJECT_VERSION}"
    MACOSX_BUNDLE_COPYRIGHT "MPL-2.0"
    MACOSX_BUNDLE_GUI_IDENTIFIER "${BUILD_OSX_APP_IDENTIFIER}.sysex"
    MACOSX_BUNDLE_INFO_STRING "${BUILD_OSX_APP_IDENTIFIER}.sysex"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${BUILD_OSX_APP_IDENTIFIER}.sysex"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_PACKAGE_TYPE "SYSX"
    XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME YES
    XCODE_ATTRIBUTE_CLANG_ENABLE_MODULES YES
    XCODE_ATTRIBUTE_ENABLE_BITCODE NO
    XCODE_ATTRIBUTE_GCC_ENABLE_OBJC_ARC YES
    XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC YES
    XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS ${CMAKE_CURRENT_SOURCE_DIR}/src/MozillaVPNSplitTunnel.entitlements
)

target_link_libraries(split-tunnel PRIVATE ${FW_FOUNDATION})
target_link_libraries(split-tunnel PRIVATE ${FW_NW_EXTENSION})
target_sources(split-tunnel PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/main.mm
    ${CMAKE_CURRENT_SOURCE_DIR}/src/VPNSplitTunnelProvider.mm
)

# The VPN Split Tunnel Loader Tool for testing.
add_executable(split-tunnel-loader)
set_target_properties(split-tunnel-loader PROPERTIES
    OUTPUT_NAME "MozillaVPNSplitTunnelLoader"
    MACOSX_BUNDLE ON
    #MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/loader/Info.plist.in
    MACOSX_BUNDLE_BUNDLE_NAME "MozillaVPNSplitTunnelLoader"
    MACOSX_BUNDLE_BUNDLE_VERSION "${CMAKE_PROJECT_VERSION}"
    MACOSX_BUNDLE_COPYRIGHT "MPL-2.0"
    MACOSX_BUNDLE_GUI_IDENTIFIER "${BUILD_OSX_APP_IDENTIFIER}"
    MACOSX_BUNDLE_INFO_STRING "MozillaVPNSplitTunnelLoader"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "${BUILD_OSX_APP_IDENTIFIER}"
    XCODE_GENERATE_SCHEME TRUE
    XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS ${CMAKE_CURRENT_SOURCE_DIR}/loader/VPNSplitTunnelLoader.entitlements
    # Do not strip debug symbols on copy
    XCODE_ATTRIBUTE_COPY_PHASE_STRIP "NO"
    XCODE_ATTRIBUTE_STRIP_INSTALLED_PRODUCT "NO"
)

target_link_libraries(split-tunnel-loader PRIVATE ${FW_FOUNDATION})
target_link_libraries(split-tunnel-loader PRIVATE ${FW_NW_EXTENSION})
target_link_libraries(split-tunnel-loader PRIVATE ${FW_SYS_EXTENSION})
target_sources(split-tunnel-loader PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/loader/main.mm
    ${CMAKE_CURRENT_SOURCE_DIR}/loader/VPNSplitTunnelLoader.h
    ${CMAKE_CURRENT_SOURCE_DIR}/loader/VPNSplitTunnelLoader.mm
)

# Install the system extension into the loader's bundle. We have to do this
# manually since CMake doesn't really have any helpers for System Extensions.
add_custom_command(TARGET split-tunnel-loader POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E echo "Bundling $<TARGET_NAME:split-tunnel>"
    COMMAND ${CMAKE_COMMAND} -E copy_directory $<TARGET_BUNDLE_DIR:split-tunnel> $<TARGET_BUNDLE_CONTENT_DIR:split-tunnel-loader>/Library/SystemExtensions/$<TARGET_BUNDLE_DIR_NAME:split-tunnel>
)

add_dependencies(split-tunnel-loader split-tunnel)
