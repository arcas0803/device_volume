import '../models/volume_channel.dart';

/// Internal contract that every platform backend must implement.
///
/// All volume values are normalized to a **0–100** integer scale regardless
/// of the platform's native range. Backends are not exposed publicly; the
/// [DeviceVolume] façade delegates to the backend selected by
/// [backendForCurrentPlatform].
abstract class DeviceVolumeBackend {
  /// Returns the current volume (0–100) for [channel].
  int getVolume({VolumeChannel channel = VolumeChannel.media});

  /// Sets the volume to [value] (0–100) for [channel] and returns the
  /// resulting volume.
  int setVolume(
    int value, {
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  });

  /// Increases volume by one platform step and returns the resulting
  /// volume (0–100).
  int incrementVolume({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  });

  /// Decreases volume by one platform step and returns the resulting
  /// volume (0–100).
  int decrementVolume({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  });

  /// Emits the current volume (0–100) followed by subsequent changes.
  ///
  /// Implementations must emit the current value immediately upon
  /// subscription and then only emit when the volume actually changes.
  Stream<int> streamVolume({VolumeChannel channel = VolumeChannel.media});
}
