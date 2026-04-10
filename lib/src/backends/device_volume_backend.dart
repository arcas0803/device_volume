import '../models/volume_channel.dart';
import '../models/volume_state.dart';

/// Internal contract that every platform backend must implement.
///
/// Backends are not exposed publicly; the [DeviceVolume] façade delegates to
/// the backend selected by [backendForCurrentPlatform].
abstract class DeviceVolumeBackend {
  /// Returns the current volume state for [channel].
  VolumeState getVolume({VolumeChannel channel = VolumeChannel.media});

  /// Sets the volume to [value] for [channel] and returns the resulting state.
  VolumeState setVolume(
    int value, {
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  });

  /// Increases volume by one platform step and returns the resulting state.
  VolumeState incrementVolume({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  });

  /// Decreases volume by one platform step and returns the resulting state.
  VolumeState decrementVolume({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  });

  /// Emits the initial volume state followed by subsequent changes.
  ///
  /// Implementations must emit the current state immediately upon
  /// subscription and then only emit when the volume actually changes.
  Stream<VolumeState> streamVolume({
    VolumeChannel channel = VolumeChannel.media,
  });
}
