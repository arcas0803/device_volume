import 'package:flutter/foundation.dart';

import '../backends/backend_selector.dart';
import '../models/volume_channel.dart';
import '../models/volume_state.dart';

/// Runs [DeviceVolumeBackend.getVolume] on a background isolate via
/// [compute].
Future<VolumeState> getVolumeCompute({
  VolumeChannel channel = VolumeChannel.media,
}) {
  return compute(_getVolume, channel);
}

/// Runs [DeviceVolumeBackend.setVolume] on a background isolate via
/// [compute].
Future<VolumeState> setVolumeCompute(
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
Future<VolumeState> incrementVolumeCompute({
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
Future<VolumeState> decrementVolumeCompute({
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

VolumeState _getVolume(VolumeChannel channel) {
  return backendForCurrentPlatform().getVolume(channel: channel);
}

VolumeState _setVolume(_SetVolumeArgs args) {
  return backendForCurrentPlatform().setVolume(
    args.value,
    channel: args.channel,
    showSystemUi: args.showSystemUi,
  );
}

VolumeState _adjustVolume(_AdjustVolumeArgs args) {
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
