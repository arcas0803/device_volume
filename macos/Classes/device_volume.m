// macOS implementation using CoreAudio + AudioToolbox.
// Controls the default output device volume.

#import "../../src/device_volume.h"
#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioServices.h>

// ── Helpers ─────────────────────────────────────────────────────────────────

static DeviceVolumeResult dv_error(int32_t code) {
  DeviceVolumeResult r = {0, 0, 0, 0, code};
  return r;
}

// macOS 12 renamed kAudioObjectPropertyElementMaster → …ElementMain.
#ifndef kAudioObjectPropertyElementMain
#define kAudioObjectPropertyElementMain kAudioObjectPropertyElementMaster
#endif

static AudioDeviceID dv_default_output_device(void) {
  AudioDeviceID device = 0;
  UInt32 size = sizeof(device);
  AudioObjectPropertyAddress addr = {
    kAudioHardwarePropertyDefaultOutputDevice,
    kAudioObjectPropertyScopeGlobal,
    kAudioObjectPropertyElementMain
  };
  OSStatus st = AudioObjectGetPropertyData(kAudioObjectSystemObject, &addr,
                                           0, NULL, &size, &device);
  return (st == noErr) ? device : 0;
}

// Read volume scalar (0.0–1.0).
// Strategy: VirtualMainVolume → master element → average L+R channels.
static int dv_read_volume(AudioDeviceID device, float *out) {
  Float32 vol = 0;
  UInt32 size = sizeof(vol);

  // 1) VirtualMainVolume — works for built-in speakers & most devices.
  AudioObjectPropertyAddress addr = {
    kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
    kAudioObjectPropertyScopeOutput,
    kAudioObjectPropertyElementMain
  };
  if (AudioObjectGetPropertyData(device, &addr, 0, NULL, &size, &vol) == noErr) {
    *out = vol;
    return 1;
  }

  // 2) Raw scalar on master element.
  addr.mSelector = kAudioDevicePropertyVolumeScalar;
  if (AudioObjectGetPropertyData(device, &addr, 0, NULL, &size, &vol) == noErr) {
    *out = vol;
    return 1;
  }

  // 3) Average channels 1 and 2.
  float total = 0;
  int count = 0;
  for (UInt32 ch = 1; ch <= 2; ch++) {
    addr.mElement = ch;
    if (AudioObjectGetPropertyData(device, &addr, 0, NULL, &size, &vol) == noErr) {
      total += vol;
      count++;
    }
  }
  if (count > 0) { *out = total / count; return 1; }
  return 0;
}

static int dv_write_volume(AudioDeviceID device, float value) {
  Float32 vol = value;
  UInt32 size = sizeof(vol);

  // 1) VirtualMainVolume
  AudioObjectPropertyAddress addr = {
    kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
    kAudioObjectPropertyScopeOutput,
    kAudioObjectPropertyElementMain
  };
  if (AudioObjectSetPropertyData(device, &addr, 0, NULL, size, &vol) == noErr) {
    return 1;
  }

  // 2) Raw scalar on master element
  addr.mSelector = kAudioDevicePropertyVolumeScalar;
  if (AudioObjectSetPropertyData(device, &addr, 0, NULL, size, &vol) == noErr) {
    return 1;
  }

  // 3) Try per-channel
  int ok = 0;
  for (UInt32 ch = 1; ch <= 2; ch++) {
    addr.mElement = ch;
    if (AudioObjectSetPropertyData(device, &addr, 0, NULL, size, &vol) == noErr) {
      ok = 1;
    }
  }
  return ok;
}

static int dv_read_mute(AudioDeviceID device) {
  UInt32 muted = 0;
  UInt32 size = sizeof(muted);
  AudioObjectPropertyAddress addr = {
    kAudioDevicePropertyMute,
    kAudioDevicePropertyScopeOutput,
    kAudioObjectPropertyElementMain
  };
  AudioObjectGetPropertyData(device, &addr, 0, NULL, &size, &muted);
  return (int)muted;
}

// ── Public API ──────────────────────────────────────────────────────────────

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_get(int32_t channel) {
  (void)channel;
  DeviceVolumeResult r = {0, 0, 100, 0, DV_OK};

  AudioDeviceID device = dv_default_output_device();
  if (device == 0) return dv_error(DV_BACKEND_NOT_AVAILABLE);

  float vol = 0;
  if (!dv_read_volume(device, &vol)) return dv_error(DV_NATIVE_FAILURE);

  r.value    = (int32_t)(vol * 100.0f + 0.5f);
  r.is_muted = dv_read_mute(device);
  return r;
}

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_set(int32_t channel,
                                                       int32_t value,
                                                       int32_t show_system_ui) {
  (void)channel; (void)show_system_ui;
  if (value < 0 || value > 100) return dv_error(DV_INVALID_VALUE);

  AudioDeviceID device = dv_default_output_device();
  if (device == 0) return dv_error(DV_BACKEND_NOT_AVAILABLE);

  float scalar = value / 100.0f;
  if (!dv_write_volume(device, scalar)) return dv_error(DV_NATIVE_FAILURE);

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
