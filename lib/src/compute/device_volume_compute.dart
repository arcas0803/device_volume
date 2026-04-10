import 'package:flutter/foundation.dart';

import '../backends/backend_selector.dart';
import '../models/volume_channel.dart';

/// Runs [DeviceVolumeBackend.getVolume] on a background isolate via
/// [compute].
Future<int> getVolumeCompute({VolumeChannel channel = VolumeChannel.media}) {
  return compute(_getVolume, channel);
}

/// Runs [DeviceVolumeBackend.setVolume] on a background isolate via
/// [compute].
Future<int> setVolumeCompute(
  int value, {
  VolumeChannel channel = VolumeChannel.media,
  bool showSystemUi = false,
}) {
  return compute(
    _setVolume,
    _SetVolumeArgs(value: value, channel: channel, showSystemUi: showSystemUi),
  );
}

/// Runs [DeviceVolumeBackend.incrementVolume] on a background isolate via
/// [compute].
Future<int> incrementVolumeCompute({
  VolumeChannel channel = VolumeChannel.media,
  bool showSystemUi = false,
}) {
  return compute(
    _adjustVolume,
    _AdjustVolumeArgs(
      increment: true,
      channel: channel,
      showSystemUi: showSystemUi,
    ),
  );
}

/// Runs [DeviceVolumeBackend.decrementVolume] on a background isolate via
/// [compute].
Future<int> decrementVolumeCompute({
  VolumeChannel channel = VolumeChannel.media,
  bool showSystemUi = false,
}) {
  return compute(
    _adjustVolume,
    _AdjustVolumeArgs(
      increment: false,
      channel: channel,
      showSystemUi: showSystemUi,
    ),
  );
}

// ── Top-level functions required by compute() ───────────────────────────────

int _getVolume(VolumeChannel channel) {
  return backendForCurrentPlatform().getVolume(channel: channel);
}

int _setVolume(_SetVolumeArgs args) {
  return backendForCurrentPlatform().setVolume(
    args.value,
    channel: args.channel,
    showSystemUi: args.showSystemUi,
  );
}

int _adjustVolume(_AdjustVolumeArgs args) {
  final backend = backendForCurrentPlatform();
  if (args.increment) {
    return backend.incrementVolume(
      channel: args.channel,
      showSystemUi: args.showSystemUi,
    );
  }
  return backend.decrementVolume(
    channel: args.channel,
    showSystemUi: args.showSystemUi,
  );
}

// ── Argument carriers (must be top-level for compute) ───────────────────────

class _SetVolumeArgs {
  final int value;
  final VolumeChannel channel;
  final bool showSystemUi;

  const _SetVolumeArgs({
    required this.value,
    required this.channel,
    required this.showSystemUi,
  });
}

class _AdjustVolumeArgs {
  final bool increment;
  final VolumeChannel channel;
  final bool showSystemUi;

  const _AdjustVolumeArgs({
    required this.increment,
    required this.channel,
    required this.showSystemUi,
  });
}
