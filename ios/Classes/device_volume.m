// iOS implementation using AVAudioSession (read) + MPVolumeView (write).
//
// Apple does not expose a public API to set the system volume directly.
// The standard workaround — used by many App Store apps — is to add a
// hidden MPVolumeView to the window hierarchy and drive its internal
// UISlider.  The view must NOT have `hidden = YES`; it is placed far
// off-screen instead so the user never sees it.
//
// This technique works on real devices.  On the simulator the hardware
// volume stack is not wired up, so reads work but writes are silently
// ignored by the OS.

#import "../../src/device_volume.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <UIKit/UIKit.h>

// ── Helpers ─────────────────────────────────────────────────────────────────

static DeviceVolumeResult dv_error(int32_t code) {
  DeviceVolumeResult r = {0, 0, 0, 0, code};
  return r;
}

// ── MPVolumeView singleton ───────────────────────────────────────────────────
// Created once and kept alive for the app's lifetime.

static MPVolumeView *gMPVolumeView = nil;
static UISlider    *gVolumeSlider  = nil;

/// Must be called from the **main thread**.
static void dv_ensure_slider(void) {
  if (gVolumeSlider) return;

  // Locate the foreground window scene.
  UIWindow *window = nil;
  for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
    if (scene.activationState == UISceneActivationStateForegroundActive) {
      window = scene.windows.firstObject;
      break;
    }
  }
  if (!window) return;

  // Place the view far off-screen.  `hidden = NO` is required — a hidden
  // MPVolumeView does not forward slider events to the system.
  gMPVolumeView = [[MPVolumeView alloc]
      initWithFrame:CGRectMake(-2000, -2000, 1, 1)];
  gMPVolumeView.hidden = NO;
  [window addSubview:gMPVolumeView];

  // Force layout so the slider subview is populated immediately.
  [gMPVolumeView layoutIfNeeded];

  for (UIView *sub in gMPVolumeView.subviews) {
    if ([sub isKindOfClass:[UISlider class]]) {
      gVolumeSlider = (UISlider *)sub;
      break;
    }
  }
}

/// Set system volume on the main thread and return the new state.
static DeviceVolumeResult dv_set_volume_main(int32_t value) {
  dv_ensure_slider();
  if (!gVolumeSlider) return dv_error(DV_NATIVE_FAILURE);

  float scalar = (float)value / 100.0f;
  [gVolumeSlider setValue:scalar animated:NO];
  [gVolumeSlider sendActionsForControlEvents:UIControlEventValueChanged];

  // Small yield so AVAudioSession.outputVolume reflects the change.
  [NSThread sleepForTimeInterval:0.05];
  return device_volume_get(0);
}

// ── Public API ──────────────────────────────────────────────────────────────

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_get(int32_t channel) {
  (void)channel;
  DeviceVolumeResult r = {0, 0, 100, 0, DV_OK};

  AVAudioSession *session = [AVAudioSession sharedInstance];
  NSError *error = nil;
  [session setActive:YES error:&error];
  if (error) return dv_error(DV_NATIVE_FAILURE);

  float vol = session.outputVolume; // 0.0 – 1.0
  r.value    = (int32_t)(vol * 100.0f + 0.5f);
  r.is_muted = (vol < 0.01f) ? 1 : 0;
  return r;
}

FFI_PLUGIN_EXPORT DeviceVolumeResult device_volume_set(int32_t channel,
                                                       int32_t value,
                                                       int32_t show_system_ui) {
  (void)channel; (void)show_system_ui;
  if (value < 0 || value > 100) return dv_error(DV_INVALID_VALUE);

  __block DeviceVolumeResult r = {0, 0, 100, 0, DV_OK};
  if ([NSThread isMainThread]) {
    r = dv_set_volume_main(value);
  } else {
    dispatch_sync(dispatch_get_main_queue(), ^{
      r = dv_set_volume_main(value);
    });
  }
  return r;
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
