/// Control the device volume from Flutter.
///
/// ```dart
/// import 'package:device_volume/device_volume.dart';
///
/// // Read
/// final state = DeviceVolume.getVolume();
/// print('Volume: ${state.value}/${state.max}');
///
/// // Write
/// DeviceVolume.setVolume(10);
///
/// // Observe
/// DeviceVolume.streamVolume().listen(print);
/// ```
library;

import 'src/backends/backend_selector.dart';
import 'src/compute/device_volume_compute.dart' as vol_compute;
import 'src/models/volume_channel.dart';
import 'src/models/volume_state.dart';

export 'src/exceptions/device_volume_exception.dart';
export 'src/models/volume_channel.dart';
export 'src/models/volume_state.dart';

/// Unified façade for controlling the device volume.
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

  /// Returns the current volume state for [channel].
  static VolumeState getVolume({VolumeChannel channel = VolumeChannel.media}) {
    return backendForCurrentPlatform().getVolume(channel: channel);
  }

  /// Sets the volume to [value] for [channel].
  ///
  /// When [showSystemUi] is `true`, the platform's volume overlay is shown
  /// (where supported).
  static VolumeState setVolume(
    int value, {
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    return backendForCurrentPlatform().setVolume(
      value,
      channel: channel,
      showSystemUi: showSystemUi,
    );
  }

  /// Increases volume by one platform step for [channel].
  static VolumeState incrementVolume({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    return backendForCurrentPlatform().incrementVolume(
      channel: channel,
      showSystemUi: showSystemUi,
    );
  }

  /// Decreases volume by one platform step for [channel].
  static VolumeState decrementVolume({
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
  static Future<VolumeState> getVolumeCompute({
    VolumeChannel channel = VolumeChannel.media,
  }) {
    return vol_compute.getVolumeCompute(channel: channel);
  }

  /// Like [setVolume] but executed on a background isolate.
  static Future<VolumeState> setVolumeCompute(
    int value, {
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    return vol_compute.setVolumeCompute(
      value,
      channel: channel,
      showSystemUi: showSystemUi,
    );
  }

  /// Like [incrementVolume] but executed on a background isolate.
  static Future<VolumeState> incrementVolumeCompute({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    return vol_compute.incrementVolumeCompute(
      channel: channel,
      showSystemUi: showSystemUi,
    );
  }

  /// Like [decrementVolume] but executed on a background isolate.
  static Future<VolumeState> decrementVolumeCompute({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    return vol_compute.decrementVolumeCompute(
      channel: channel,
      showSystemUi: showSystemUi,
    );
  }

  // ── Stream ────────────────────────────────────────────────────────────

  /// Emits the current volume state immediately, then emits on every change.
  ///
  /// There is no `streamVolumeCompute` variant because `compute` cannot
  /// sustain a live stream. The stream is backed by a native observer or a
  /// dedicated isolate depending on the platform.
  static Stream<VolumeState> streamVolume({
    VolumeChannel channel = VolumeChannel.media,
  }) {
    return backendForCurrentPlatform().streamVolume(channel: channel);
  }
}
