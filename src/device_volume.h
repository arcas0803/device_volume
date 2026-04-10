#ifndef DEVICE_VOLUME_H
#define DEVICE_VOLUME_H

#include <stdint.h>

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

// ── Error codes ─────────────────────────────────────────────────────────────

#define DV_OK                     0
#define DV_UNSUPPORTED_OPERATION  1
#define DV_PERMISSION_DENIED      2
#define DV_NATIVE_FAILURE         3
#define DV_INVALID_VALUE          4
#define DV_BACKEND_NOT_AVAILABLE  5

// ── Result struct ───────────────────────────────────────────────────────────

typedef struct {
  int32_t value;
  int32_t min;
  int32_t max;
  int32_t is_muted;
  int32_t error_code;
} DeviceVolumeResult;

// ── Public API ──────────────────────────────────────────────────────────────

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_get(int32_t channel);

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_set(int32_t channel,
                                                       int32_t value,
                                                       int32_t show_system_ui);

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_increment(int32_t channel,
                                                              int32_t show_system_ui);

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_decrement(int32_t channel,
                                                              int32_t show_system_ui);

#endif // DEVICE_VOLUME_H
