#include "device_volume.h"

// This file is compiled by CMake for Android, Linux, and Windows.
// iOS and macOS use separate .m files in their respective Classes/ folders.

// ── Helper ──────────────────────────────────────────────────────────────────

static DeviceVolumeResult dv_error(int32_t code) {
  DeviceVolumeResult r = {0, 0, 0, 0, code};
  return r;
}

// ═══════════════════════════════════════════════════════════════════════════
// ANDROID — stubs (volume control via JNIgen in Dart, not FFI)
// ═══════════════════════════════════════════════════════════════════════════
#if defined(__ANDROID__)

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_get(int32_t channel) {
  return dv_error(DV_UNSUPPORTED_OPERATION);
}
FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_set(int32_t channel,
                                                       int32_t value,
                                                       int32_t show_system_ui) {
  return dv_error(DV_UNSUPPORTED_OPERATION);
}
FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_increment(int32_t channel,
                                                              int32_t show_system_ui) {
  return dv_error(DV_UNSUPPORTED_OPERATION);
}
FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_decrement(int32_t channel,
                                                              int32_t show_system_ui) {
  return dv_error(DV_UNSUPPORTED_OPERATION);
}

// ═══════════════════════════════════════════════════════════════════════════
// LINUX — PulseAudio
// ═══════════════════════════════════════════════════════════════════════════
#elif defined(__linux__)

#include <pulse/pulseaudio.h>
#include <string.h>

// Synchronous PulseAudio helper using a threaded mainloop.

typedef struct {
  DeviceVolumeResult result;
  int done;
  char default_sink[256];
} dv_pa_data;

static void dv_pa_server_info_cb(pa_context *c, const pa_server_info *i,
                                 void *userdata) {
  dv_pa_data *d = (dv_pa_data *)userdata;
  if (i && i->default_sink_name) {
    strncpy(d->default_sink, i->default_sink_name, sizeof(d->default_sink) - 1);
  }
  d->done = 1;
}

static void dv_pa_sink_info_cb(pa_context *c, const pa_sink_info *i, int eol,
                               void *userdata) {
  dv_pa_data *d = (dv_pa_data *)userdata;
  if (eol > 0 || !i) {
    d->done = 1;
    return;
  }
  pa_volume_t avg = pa_cvolume_avg(&i->volume);
  d->result.value = (int32_t)((double)avg * 100.0 / PA_VOLUME_NORM);
  d->result.min = 0;
  d->result.max = 100;
  d->result.is_muted = i->mute;
  d->result.error_code = DV_OK;
}

static void dv_pa_set_done_cb(pa_context *c, int success, void *userdata) {
  dv_pa_data *d = (dv_pa_data *)userdata;
  if (!success) d->result.error_code = DV_NATIVE_FAILURE;
  d->done = 1;
}

static void dv_pa_ctx_state_cb(pa_context *c, void *userdata) {
  (void)userdata;
  // no-op, we poll state in the loop below
}

// Run a PulseAudio operation synchronously using a simple mainloop.
static int dv_pa_run(pa_mainloop *ml, dv_pa_data *d) {
  while (!d->done) {
    if (pa_mainloop_iterate(ml, 1, NULL) < 0) return -1;
  }
  return 0;
}

// Connect, query/set, disconnect.  Allocates a mainloop per call—
// acceptable for infrequent volume operations.
static DeviceVolumeResult dv_pa_query(void) {
  dv_pa_data d;
  memset(&d, 0, sizeof(d));
  d.result.error_code = DV_NATIVE_FAILURE;

  pa_mainloop *ml = pa_mainloop_new();
  if (!ml) return dv_error(DV_BACKEND_NOT_AVAILABLE);

  pa_context *ctx = pa_context_new(pa_mainloop_get_api(ml), "device_volume");
  if (!ctx) { pa_mainloop_free(ml); return dv_error(DV_BACKEND_NOT_AVAILABLE); }

  pa_context_set_state_callback(ctx, dv_pa_ctx_state_cb, NULL);
  if (pa_context_connect(ctx, NULL, PA_CONTEXT_NOFLAGS, NULL) < 0) {
    pa_context_unref(ctx); pa_mainloop_free(ml);
    return dv_error(DV_BACKEND_NOT_AVAILABLE);
  }

  // Wait for context ready
  while (1) {
    pa_mainloop_iterate(ml, 1, NULL);
    pa_context_state_t s = pa_context_get_state(ctx);
    if (s == PA_CONTEXT_READY) break;
    if (!PA_CONTEXT_IS_GOOD(s)) {
      pa_context_unref(ctx); pa_mainloop_free(ml);
      return dv_error(DV_BACKEND_NOT_AVAILABLE);
    }
  }

  // Get default sink name
  d.done = 0;
  pa_context_get_server_info(ctx, dv_pa_server_info_cb, &d);
  dv_pa_run(ml, &d);

  // Get sink info
  d.done = 0;
  pa_context_get_sink_info_by_name(ctx, d.default_sink, dv_pa_sink_info_cb, &d);
  dv_pa_run(ml, &d);

  pa_context_disconnect(ctx);
  pa_context_unref(ctx);
  pa_mainloop_free(ml);
  return d.result;
}

static DeviceVolumeResult dv_pa_set_volume(int32_t value) {
  dv_pa_data d;
  memset(&d, 0, sizeof(d));
  d.result.error_code = DV_NATIVE_FAILURE;

  pa_mainloop *ml = pa_mainloop_new();
  if (!ml) return dv_error(DV_BACKEND_NOT_AVAILABLE);
  pa_context *ctx = pa_context_new(pa_mainloop_get_api(ml), "device_volume");
  if (!ctx) { pa_mainloop_free(ml); return dv_error(DV_BACKEND_NOT_AVAILABLE); }

  pa_context_set_state_callback(ctx, dv_pa_ctx_state_cb, NULL);
  if (pa_context_connect(ctx, NULL, PA_CONTEXT_NOFLAGS, NULL) < 0) {
    pa_context_unref(ctx); pa_mainloop_free(ml);
    return dv_error(DV_BACKEND_NOT_AVAILABLE);
  }
  while (1) {
    pa_mainloop_iterate(ml, 1, NULL);
    pa_context_state_t s = pa_context_get_state(ctx);
    if (s == PA_CONTEXT_READY) break;
    if (!PA_CONTEXT_IS_GOOD(s)) {
      pa_context_unref(ctx); pa_mainloop_free(ml);
      return dv_error(DV_BACKEND_NOT_AVAILABLE);
    }
  }

  d.done = 0;
  pa_context_get_server_info(ctx, dv_pa_server_info_cb, &d);
  dv_pa_run(ml, &d);

  pa_cvolume cv;
  pa_cvolume_set(&cv, 2, (pa_volume_t)(value * PA_VOLUME_NORM / 100));
  d.done = 0;
  pa_context_set_sink_volume_by_name(ctx, d.default_sink, &cv,
                                     dv_pa_set_done_cb, &d);
  dv_pa_run(ml, &d);

  pa_context_disconnect(ctx);
  pa_context_unref(ctx);
  pa_mainloop_free(ml);

  if (d.result.error_code == DV_OK || d.result.error_code == DV_NATIVE_FAILURE) {
    // Re-query to get the actual state
    return dv_pa_query();
  }
  return d.result;
}

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_get(int32_t channel) {
  (void)channel; // Linux PulseAudio controls the default sink, not per-stream
  return dv_pa_query();
}

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_set(int32_t channel,
                                                       int32_t value,
                                                       int32_t show_system_ui) {
  (void)channel;
  (void)show_system_ui;
  if (value < 0 || value > 100) return dv_error(DV_INVALID_VALUE);
  return dv_pa_set_volume(value);
}

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_increment(int32_t channel,
                                                              int32_t show_system_ui) {
  (void)show_system_ui;
  DeviceVolumeResult cur = device_volume_get(channel);
  if (cur.error_code != DV_OK) return cur;
  int32_t next = cur.value + 5;
  if (next > 100) next = 100;
  return dv_pa_set_volume(next);
}

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_decrement(int32_t channel,
                                                              int32_t show_system_ui) {
  (void)show_system_ui;
  DeviceVolumeResult cur = device_volume_get(channel);
  if (cur.error_code != DV_OK) return cur;
  int32_t next = cur.value - 5;
  if (next < 0) next = 0;
  return dv_pa_set_volume(next);
}

// ═══════════════════════════════════════════════════════════════════════════
// WINDOWS — Core Audio COM (IAudioEndpointVolume)
// ═══════════════════════════════════════════════════════════════════════════
#elif defined(_WIN32)

#define COBJMACROS
#include <windows.h>
#include <mmdeviceapi.h>
#include <endpointvolume.h>

// The WASAPI GUIDs are not always available via uuid.lib or initguid.h
// depending on the compiler/linker configuration.  Define them explicitly
// using their well-known values from the Windows SDK headers.
#ifdef __cplusplus
#define DV_DEFINE_GUID(name, l, w1, w2, b1, b2, b3, b4, b5, b6, b7, b8) \
    static const GUID name = { l, w1, w2, { b1, b2, b3, b4, b5, b6, b7, b8 } }
#else
#define DV_DEFINE_GUID(name, l, w1, w2, b1, b2, b3, b4, b5, b6, b7, b8) \
    static const GUID name = { l, w1, w2, { b1, b2, b3, b4, b5, b6, b7, b8 } }
#endif

DV_DEFINE_GUID(DV_CLSID_MMDeviceEnumerator,
    0xBCDE0395, 0xE52F, 0x467C,
    0x8E, 0x3D, 0xC4, 0x57, 0x92, 0x91, 0x69, 0x2E);

DV_DEFINE_GUID(DV_IID_IMMDeviceEnumerator,
    0xA95664D2, 0x9614, 0x4F35,
    0xA7, 0x46, 0xDE, 0x8D, 0xB6, 0x36, 0x17, 0xE6);

DV_DEFINE_GUID(DV_IID_IAudioEndpointVolume,
    0x5CDF2C82, 0x841E, 0x4546,
    0x97, 0x22, 0x0C, 0xF7, 0x40, 0x78, 0x22, 0x9A);

// Helpers to get/release IAudioEndpointVolume from the default output device.

static HRESULT dv_get_endpoint_volume(IAudioEndpointVolume **ppVol,
                                      IMMDevice **ppDev,
                                      IMMDeviceEnumerator **ppEnum) {
  HRESULT hr = CoInitializeEx(NULL, COINIT_MULTITHREADED);
  if (FAILED(hr) && hr != RPC_E_CHANGED_MODE) return hr;

  hr = CoCreateInstance(&DV_CLSID_MMDeviceEnumerator, NULL, CLSCTX_ALL,
                        &DV_IID_IMMDeviceEnumerator, (void **)ppEnum);
  if (FAILED(hr)) return hr;

  hr = IMMDeviceEnumerator_GetDefaultAudioEndpoint(*ppEnum, eRender,
                                                   eConsole, ppDev);
  if (FAILED(hr)) { IMMDeviceEnumerator_Release(*ppEnum); return hr; }

  hr = IMMDevice_Activate(*ppDev, &DV_IID_IAudioEndpointVolume, CLSCTX_ALL,
                           NULL, (void **)ppVol);
  if (FAILED(hr)) {
    IMMDevice_Release(*ppDev);
    IMMDeviceEnumerator_Release(*ppEnum);
  }
  return hr;
}

static void dv_release_endpoint(IAudioEndpointVolume *pVol,
                                IMMDevice *pDev,
                                IMMDeviceEnumerator *pEnum) {
  if (pVol) IAudioEndpointVolume_Release(pVol);
  if (pDev) IMMDevice_Release(pDev);
  if (pEnum) IMMDeviceEnumerator_Release(pEnum);
  CoUninitialize();
}

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_get(int32_t channel) {
  (void)channel;
  DeviceVolumeResult r = {0, 0, 100, 0, DV_OK};
  IAudioEndpointVolume *pVol = NULL;
  IMMDevice *pDev = NULL;
  IMMDeviceEnumerator *pEnum = NULL;

  if (FAILED(dv_get_endpoint_volume(&pVol, &pDev, &pEnum)))
    return dv_error(DV_BACKEND_NOT_AVAILABLE);

  float vol = 0;
  if (SUCCEEDED(IAudioEndpointVolume_GetMasterVolumeLevelScalar(pVol, &vol)))
    r.value = (int32_t)(vol * 100.0f);
  else
    r.error_code = DV_NATIVE_FAILURE;

  BOOL muted = FALSE;
  IAudioEndpointVolume_GetMute(pVol, &muted);
  r.is_muted = muted ? 1 : 0;

  dv_release_endpoint(pVol, pDev, pEnum);
  return r;
}

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_set(int32_t channel,
                                                       int32_t value,
                                                       int32_t show_system_ui) {
  (void)channel;
  (void)show_system_ui;
  if (value < 0 || value > 100) return dv_error(DV_INVALID_VALUE);

  IAudioEndpointVolume *pVol = NULL;
  IMMDevice *pDev = NULL;
  IMMDeviceEnumerator *pEnum = NULL;
  if (FAILED(dv_get_endpoint_volume(&pVol, &pDev, &pEnum)))
    return dv_error(DV_BACKEND_NOT_AVAILABLE);

  float scalar = value / 100.0f;
  IAudioEndpointVolume_SetMasterVolumeLevelScalar(pVol, scalar, NULL);
  dv_release_endpoint(pVol, pDev, pEnum);

  return device_volume_get(channel);
}

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_increment(int32_t channel,
                                                              int32_t show_system_ui) {
  DeviceVolumeResult cur = device_volume_get(channel);
  if (cur.error_code != DV_OK) return cur;
  int32_t next = cur.value + 5;
  if (next > 100) next = 100;
  return device_volume_set(channel, next, show_system_ui);
}

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_decrement(int32_t channel,
                                                              int32_t show_system_ui) {
  DeviceVolumeResult cur = device_volume_get(channel);
  if (cur.error_code != DV_OK) return cur;
  int32_t next = cur.value - 5;
  if (next < 0) next = 0;
  return device_volume_set(channel, next, show_system_ui);
}

// ═══════════════════════════════════════════════════════════════════════════
// UNKNOWN PLATFORM
// ═══════════════════════════════════════════════════════════════════════════
#else

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_get(int32_t channel) {
  return dv_error(DV_BACKEND_NOT_AVAILABLE);
}
FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_set(int32_t channel,
                                                       int32_t value,
                                                       int32_t show_system_ui) {
  return dv_error(DV_BACKEND_NOT_AVAILABLE);
}
FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_increment(int32_t channel,
                                                              int32_t show_system_ui) {
  return dv_error(DV_BACKEND_NOT_AVAILABLE);
}
FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_decrement(int32_t channel,
                                                              int32_t show_system_ui) {
  return dv_error(DV_BACKEND_NOT_AVAILABLE);
}

#endif
