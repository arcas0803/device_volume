import 'dart:async';

import 'package:jni/jni.dart';

import '../exceptions/device_volume_exception.dart';
import '../jni/device_volume_helper.dart';
import '../models/volume_channel.dart';
import '../models/volume_state.dart';
import 'device_volume_backend.dart';

/// Android backend using JNIgen-generated bindings to AudioManager.
class AndroidBackend implements DeviceVolumeBackend {
  late final DeviceVolumeHelper _helper;

  AndroidBackend() {
    // Get application context via ActivityThread.currentApplication().
    final activityThread = JClass.forName(r'android/app/ActivityThread');
    final methodId = activityThread.staticMethodId(
      r'currentApplication',
      r'()Landroid/app/Application;',
    );
    final context = methodId.call<JObject, JObject>(
      activityThread,
      JObject.type,
      [],
    );
    activityThread.release();
    _helper = DeviceVolumeHelper(context);
  }

  // ── Channel mapping ──────────────────────────────────────────────────────

  static int _streamType(VolumeChannel channel) {
    switch (channel) {
      case VolumeChannel.media:
        return DeviceVolumeHelper.STREAM_MUSIC;
      case VolumeChannel.ring:
        return DeviceVolumeHelper.STREAM_RING;
      case VolumeChannel.alarm:
        return DeviceVolumeHelper.STREAM_ALARM;
      case VolumeChannel.notification:
        return DeviceVolumeHelper.STREAM_NOTIFICATION;
      case VolumeChannel.voiceCall:
        return DeviceVolumeHelper.STREAM_VOICE_CALL;
      case VolumeChannel.system:
        return DeviceVolumeHelper.STREAM_SYSTEM;
    }
  }

  VolumeState _query(VolumeChannel channel) {
    final stream = _streamType(channel);
    try {
      final value = _helper.getStreamVolume(stream);
      final max = _helper.getStreamMaxVolume(stream);
      final min = _helper.getStreamMinVolume(stream);
      final muted = _helper.isStreamMute(stream);
      return VolumeState.fromRaw(
        value: value,
        min: min,
        max: max,
        isMuted: muted,
        channel: channel,
      );
    } on Exception catch (e) {
      throw NativeBackendException(
        message: 'AudioManager error: $e',
        details: {'platform': 'android', 'channel': channel.name},
      );
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────

  @override
  VolumeState getVolume({VolumeChannel channel = VolumeChannel.media}) {
    return _query(channel);
  }

  @override
  VolumeState setVolume(
    int value, {
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    final stream = _streamType(channel);
    final max = _helper.getStreamMaxVolume(stream);
    final min = _helper.getStreamMinVolume(stream);
    if (value < min || value > max) {
      throw InvalidVolumeValueException(
        message: 'Value $value is out of range [$min, $max].',
        details: {'value': value, 'min': min, 'max': max},
      );
    }
    final flags = showSystemUi ? DeviceVolumeHelper.FLAG_SHOW_UI : 0;
    _helper.setStreamVolume(stream, value, flags);
    return _query(channel);
  }

  @override
  VolumeState incrementVolume({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    final stream = _streamType(channel);
    final flags = showSystemUi ? DeviceVolumeHelper.FLAG_SHOW_UI : 0;
    _helper.adjustStreamVolume(stream, DeviceVolumeHelper.ADJUST_RAISE, flags);
    return _query(channel);
  }

  @override
  VolumeState decrementVolume({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    final stream = _streamType(channel);
    final flags = showSystemUi ? DeviceVolumeHelper.FLAG_SHOW_UI : 0;
    _helper.adjustStreamVolume(stream, DeviceVolumeHelper.ADJUST_LOWER, flags);
    return _query(channel);
  }

  @override
  Stream<VolumeState> streamVolume({
    VolumeChannel channel = VolumeChannel.media,
  }) {
    late StreamController<VolumeState> controller;
    Timer? timer;
    VolumeState? lastState;

    controller = StreamController<VolumeState>(
      onListen: () {
        lastState = _query(channel);
        controller.add(lastState!);

        timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
          try {
            final current = _query(channel);
            if (current != lastState) {
              lastState = current;
              controller.add(current);
            }
          } on DeviceVolumeException catch (e) {
            controller.addError(e);
          }
        });
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }
}
