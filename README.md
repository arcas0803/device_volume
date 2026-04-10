# device_volume

[![pub.dev](https://img.shields.io/pub/v/device_volume.svg)](https://pub.dev/packages/device_volume)
[![CI](https://github.com/arcas0803/device_volume/actions/workflows/ci.yml/badge.svg)](https://github.com/arcas0803/device_volume/actions)

Control the device volume from Flutter. Provides read, write, increment, decrement and a live stream — with both synchronous and `compute`-based async variants.

## Platform support

| Platform | Read | Write | Stream | Notes |
|----------|------|-------|--------|-------|
| Android  | ✅   | ✅    | ✅     | Per-channel (media, ring, alarm…) via AudioManager |
| iOS      | ✅   | ✅    | ✅     | Write via MPVolumeView; simulator shows correct value but write is ignored by the OS |
| macOS    | ✅   | ✅    | ✅     | CoreAudio + AudioToolbox (VirtualMainVolume) |
| Windows  | ✅   | ✅    | ✅     | IAudioEndpointVolume (WASAPI) |
| Linux    | ✅   | ✅    | ✅     | PulseAudio / PipeWire |

## Installation

```yaml
dependencies:
  device_volume: ^0.1.0
```

## Quick start

```dart
import 'package:device_volume/device_volume.dart';

// Read current volume
final state = DeviceVolume.getVolume();
print('${state.value} / ${state.max}  (${(state.normalized * 100).round()}%)');

// Set volume
DeviceVolume.setVolume(50);

// Increment / decrement
DeviceVolume.incrementVolume(showSystemUi: true);
DeviceVolume.decrementVolume(showSystemUi: true);

// Mute (set to minimum)
DeviceVolume.setVolume(state.min);

// Observe changes
DeviceVolume.streamVolume().listen((s) {
  print('Volume changed: ${s.value}');
});
```

## API reference

### `DeviceVolume`

All methods are static. Every synchronous method has an async `*Compute` counterpart that runs on a background isolate via `flutter/foundation.dart compute()`.

#### Synchronous

```dart
// Returns the current volume state.
VolumeState getVolume({ VolumeChannel channel = VolumeChannel.media })

// Sets volume to [value] (absolute, in platform units: min–max).
VolumeState setVolume(int value, { VolumeChannel channel, bool showSystemUi })

// Increases by one platform step (5 units on most platforms).
VolumeState incrementVolume({ VolumeChannel channel, bool showSystemUi })

// Decreases by one platform step.
VolumeState decrementVolume({ VolumeChannel channel, bool showSystemUi })
```

#### Async (background isolate)

```dart
Future<VolumeState> getVolumeCompute({ VolumeChannel channel })
Future<VolumeState> setVolumeCompute(int value, { VolumeChannel channel, bool showSystemUi })
Future<VolumeState> incrementVolumeCompute({ VolumeChannel channel, bool showSystemUi })
Future<VolumeState> decrementVolumeCompute({ VolumeChannel channel, bool showSystemUi })
```

#### Stream

```dart
// Emits the current state immediately, then on every change.
Stream<VolumeState> streamVolume({ VolumeChannel channel })
```

### `VolumeState`

Immutable snapshot returned by all API methods.

| Property     | Type            | Description |
|--------------|-----------------|-------------|
| `value`      | `int`           | Current absolute volume level |
| `min`        | `int`           | Minimum level reported by the platform |
| `max`        | `int`           | Maximum level reported by the platform |
| `normalized` | `double`        | `value` mapped to `[0.0, 1.0]` |
| `isMuted`    | `bool`          | Whether the stream is muted |
| `channel`    | `VolumeChannel` | The channel this state refers to |

### `VolumeChannel`

Represents the audio stream to control. Not all channels are supported on every platform — unsupported channels throw `UnsupportedOperationException`.

| Value         | Description |
|---------------|-------------|
| `media`       | Music, video, games (default) |
| `ring`        | Ringtone |
| `alarm`       | Alarm |
| `notification`| Notification sounds |
| `voiceCall`   | In-call voice |
| `system`      | System UI sounds |

> **Android only** supports per-channel control. On iOS/macOS/Windows/Linux there is a single output volume; passing any channel reads/writes that same volume.

## Error handling

All errors extend `DeviceVolumeException`. Catch the base class or a specific subclass:

```dart
try {
  DeviceVolume.setVolume(80);
} on UnsupportedOperationException catch (e) {
  // Operation not available on this platform
} on InvalidVolumeValueException catch (e) {
  // Value out of range (below min or above max)
} on PermissionDeniedException catch (e) {
  // OS denied the request
} on BackendNotAvailableException catch (e) {
  // No audio backend found (e.g. headless Linux without PulseAudio)
} on NativeBackendException catch (e) {
  // Unexpected native error
} on DeviceVolumeException catch (e) {
  // Catch-all
  print(e.code);     // stable machine-readable code
  print(e.message);  // human-readable description
  print(e.details);  // structured diagnostic data
}
```

| Exception                      | Code                      | When |
|-------------------------------|---------------------------|------|
| `UnsupportedOperationException` | `unsupported_operation`   | Operation not available on this platform |
| `InvalidVolumeValueException`   | `invalid_volume_value`    | Value outside min–max range |
| `PermissionDeniedException`     | `permission_denied`       | OS denied the request |
| `BackendNotAvailableException`  | `backend_not_available`   | No audio backend present |
| `NativeBackendException`        | `native_backend_failure`  | Unexpected native error |
| `VolumeObservationException`    | `volume_observation_failure` | Stream setup failed |

## Platform-specific notes

### iOS

Write operations use `MPVolumeView` (MediaPlayer framework) placed off-screen. This is the standard App Store-compliant workaround — `AVAudioSession.outputVolume` is read-only by design.

On the **simulator** the hardware volume stack is not emulated, so reads return a fixed value and writes are silently discarded by the OS. Test write operations on a **real device**.

### Android

Requires no additional permissions for `media`, `alarm`, `notification`, and `system` streams. Modifying the `ring` stream may require `android.permission.ACCESS_NOTIFICATION_POLICY` on Android 6+ if Do Not Disturb is active.

### Linux

Requires PulseAudio or a PipeWire PulseAudio compatibility layer (`pipewire-pulse`). On headless systems without a running audio server, all calls throw `BackendNotAvailableException`.

### Windows

Uses WASAPI (`IAudioEndpointVolume`). Controls the default output device. COM is initialized automatically per call.
For example, see `sum` in `lib/device_volume.dart`.

Longer-running functions should be invoked on a helper isolate to avoid
dropping frames in Flutter applications.
For example, see `sumAsync` in `lib/device_volume.dart`.

## Flutter help

For help getting started with Flutter, view our
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

