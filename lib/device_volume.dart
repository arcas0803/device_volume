/// Control the device volume from Flutter.
///
/// All volume values are normalized to an **integer 0–100** scale regardless
/// of the platform's native range.
///
/// ```dart
/// import 'package:device_volume/device_volume.dart';
///
/// // Read
/// final volume = DeviceVolume.getVolume();
/// print('Volume: $volume%');
///
/// // Write
/// DeviceVolume.setVolume(50);
///
/// // Observe
/// DeviceVolume.streamVolume().listen((v) => print('$v%'));
/// ```
library;

import 'src/backends/backend_selector.dart';
import 'src/compute/device_volume_compute.dart' as vol_compute;
import 'src/exceptions/device_volume_exception.dart';
import 'src/models/volume_channel.dart';

export 'src/exceptions/device_volume_exception.dart';
export 'src/models/volume_channel.dart';

/// Unified façade for controlling the device volume.
///
/// All volume values are normalized to an integer **0–100** scale.
///
/// All synchronous methods execute on the calling isolate. For each one there
/// is a `*Compute` counterpart that runs the operation on a background isolate
/// via `Flutter.compute`, useful when the caller wants to avoid any potential
/// jank on the UI thread.
///
/// [streamVolume] uses a native observer and does **not** have a Compute
/// variant because `compute` cannot sustain a live stream.
abstract final class DeviceVolume {
  // ── Synchronous API ─────────────────────────────────────────────────────

  /// Returns the current volume (0–100) for [channel].
  static int getVolume({VolumeChannel channel = VolumeChannel.media}) {
    return backendForCurrentPlatform().getVolume(channel: channel);
  }

  /// Sets the volume to [value] (0–100) for [channel] and returns the
  /// resulting volume.
  ///
  /// Throws [InvalidVolumeValueException] if [value] is not in the 0–100
  /// range. When [showSystemUi] is `true`, the platform's volume overlay is
  /// shown (where supported).
  static int setVolume(
    int value, {
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    if (value < 0 || value > 100) {
      throw InvalidVolumeValueException(
        message: 'Volume must be between 0 and 100, got $value.',
        details: {'value': value},
      );
    }
    return backendForCurrentPlatform().setVolume(
      value,
      channel: channel,
      showSystemUi: showSystemUi,
    );
  }

  /// Increases volume by one platform step for [channel].
  ///
  /// Returns the resulting volume (0–100).
  static int incrementVolume({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    return backendForCurrentPlatform().incrementVolume(
      channel: channel,
      showSystemUi: showSystemUi,
    );
  }

  /// Decreases volume by one platform step for [channel].
  ///
  /// Returns the resulting volume (0–100).
  static int decrementVolume({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    return backendForCurrentPlatform().decrementVolume(
      channel: channel,
      showSystemUi: showSystemUi,
    );
  }

  // ── Compute variants ──────────────────────────────────────────────────

  /// Like [getVolume] but executed on a background isolate.
  static Future<int> getVolumeCompute({
    VolumeChannel channel = VolumeChannel.media,
  }) {
    return vol_compute.getVolumeCompute(channel: channel);
  }

  /// Like [setVolume] but executed on a background isolate.
  ///
  /// Throws [InvalidVolumeValueException] if [value] is not in the 0–100
  /// range.
  static Future<int> setVolumeCompute(
    int value, {
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    if (value < 0 || value > 100) {
      throw InvalidVolumeValueException(
        message: 'Volume must be between 0 and 100, got $value.',
        details: {'value': value},
      );
    }
    return vol_compute.setVolumeCompute(
      value,
      channel: channel,
      showSystemUi: showSystemUi,
    );
  }

  /// Like [incrementVolume] but executed on a background isolate.
  static Future<int> incrementVolumeCompute({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    return vol_compute.incrementVolumeCompute(
      channel: channel,
      showSystemUi: showSystemUi,
    );
  }

  /// Like [decrementVolume] but executed on a background isolate.
  static Future<int> decrementVolumeCompute({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    return vol_compute.decrementVolumeCompute(
      channel: channel,
      showSystemUi: showSystemUi,
    );
  }

  // ── Stream ────────────────────────────────────────────────────────────

  /// Emits the current volume (0–100) immediately, then emits on every change.
  ///
  /// There is no `streamVolumeCompute` variant because `compute` cannot
  /// sustain a live stream. The stream is backed by a native observer or a
  /// dedicated isolate depending on the platform.
  static Stream<int> streamVolume({
    VolumeChannel channel = VolumeChannel.media,
  }) {
    return backendForCurrentPlatform().streamVolume(channel: channel);
  }
}
