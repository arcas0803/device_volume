# device_volume

[![pub.dev](https://img.shields.io/pub/v/device_volume.svg)](https://pub.dev/packages/device_volume)
[![CI](https://github.com/arcas0803/device_volume/actions/workflows/ci.yml/badge.svg)](https://github.com/arcas0803/device_volume/actions)

Control the device volume from Flutter. All volume values are normalized to an **integer 0–100** scale regardless of the platform's native range. Provides read, write, increment, decrement and a live stream — with both synchronous and `compute`-based async variants.

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
  device_volume: ^0.1.1
```

## Quick start

```dart
import 'package:device_volume/device_volume.dart';

// Read current volume (0–100)
final volume = DeviceVolume.getVolume();
print('$volume%');

// Set volume (0–100)
DeviceVolume.setVolume(50);

// Increment / decrement by one platform step
DeviceVolume.incrementVolume(showSystemUi: true);
DeviceVolume.decrementVolume(showSystemUi: true);

// Mute
DeviceVolume.setVolume(0);

// Observe changes
DeviceVolume.streamVolume().listen((v) {
  print('Volume changed: $v%');
});
```

## API reference

### `DeviceVolume`

All methods are static. Every synchronous method has an async `*Compute` counterpart that runs on a background isolate via `flutter/foundation.dart compute()`.

All volume values are normalized to an **integer 0–100** scale.

#### Synchronous

```dart
// Returns the current volume (0–100).
int getVolume({ VolumeChannel channel = VolumeChannel.media })

// Sets volume to [value] (0–100). Throws InvalidVolumeValueException if out of range.
int setVolume(int value, { VolumeChannel channel, bool showSystemUi })

// Increases by one platform step. Returns resulting volume (0–100).
int incrementVolume({ VolumeChannel channel, bool showSystemUi })

// Decreases by one platform step. Returns resulting volume (0–100).
int decrementVolume({ VolumeChannel channel, bool showSystemUi })
```

#### Async (background isolate)

```dart
Future<int> getVolumeCompute({ VolumeChannel channel })
Future<int> setVolumeCompute(int value, { VolumeChannel channel, bool showSystemUi })
Future<int> incrementVolumeCompute({ VolumeChannel channel, bool showSystemUi })
Future<int> decrementVolumeCompute({ VolumeChannel channel, bool showSystemUi })
```

#### Stream

```dart
// Emits the current volume (0–100) immediately, then on every change.
Stream<int> streamVolume({ VolumeChannel channel })
```

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
  // Value out of range (must be 0–100)
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
| `InvalidVolumeValueException`   | `invalid_volume_value`    | Value outside 0–100 range |
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

