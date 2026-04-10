# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(device_volume_library VERSION 0.0.1 LANGUAGES C)

add_library(device_volume SHARED
  "device_volume.c"
)

set_target_properties(device_volume PROPERTIES
  PUBLIC_HEADER device_volume.h
  OUTPUT_NAME "device_volume"
)

target_compile_definitions(device_volume PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(device_volume PRIVATE "-Wl,-z,max-page-size=16384")
elseif(WIN32)
  target_link_libraries(device_volume PRIVATE ole32)
elseif(UNIX AND NOT APPLE)
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(PULSE REQUIRED libpulse)
  target_include_directories(device_volume PRIVATE ${PULSE_INCLUDE_DIRS})
  target_link_libraries(device_volume PRIVATE ${PULSE_LIBRARIES})
endif()
