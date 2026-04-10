import 'volume_channel.dart';

/// Immutable snapshot of the device volume for a specific [channel].
class VolumeState {
  /// Current absolute volume level.
  final int value;

  /// Minimum volume level reported by the platform.
  final int min;

  /// Maximum volume level reported by the platform.
  final int max;

  /// Volume normalized to `[0.0, 1.0]`.
  ///
  /// Calculated as `(value - min) / (max - min)`.
  /// Returns `0.0` when `max == min`.
  final double normalized;

  /// Whether the stream is currently muted.
  final bool isMuted;

  /// The channel this state refers to.
  final VolumeChannel channel;

  /// Creates a [VolumeState] with pre-computed [normalized] value.
  const VolumeState({
    required this.value,
    required this.min,
    required this.max,
    required this.normalized,
    required this.isMuted,
    required this.channel,
  });

  /// Creates a [VolumeState] and computes [normalized] automatically.
  factory VolumeState.fromRaw({
    required int value,
    required int min,
    required int max,
    required bool isMuted,
    required VolumeChannel channel,
  }) {
    final range = max - min;
    final normalized = range > 0 ? (value - min) / range : 0.0;
    return VolumeState(
      value: value,
      min: min,
      max: max,
      normalized: normalized,
      isMuted: isMuted,
      channel: channel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VolumeState &&
          value == other.value &&
          min == other.min &&
          max == other.max &&
          isMuted == other.isMuted &&
          channel == other.channel;

  @override
  int get hashCode => Object.hash(value, min, max, isMuted, channel);

  @override
  String toString() =>
      'VolumeState(channel: $channel, value: $value, '
      'min: $min, max: $max, normalized: ${normalized.toStringAsFixed(2)}, '
      'isMuted: $isMuted)';
}
