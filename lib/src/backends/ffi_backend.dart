import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import '../../device_volume_bindings_generated.dart';
import '../exceptions/device_volume_exception.dart';
import '../models/volume_channel.dart';
import 'device_volume_backend.dart';

/// FFI backend used on iOS, macOS, Linux, and Windows.
///
/// Loads the native library via [DynamicLibrary] and delegates to the
/// generated [DeviceVolumeBindings].
class FfiBackend implements DeviceVolumeBackend {
  late final DeviceVolumeBindings _bindings;

  FfiBackend() {
    _bindings = DeviceVolumeBindings(_openLibrary());
  }

  // ── Library loading ──────────────────────────────────────────────────────

  static DynamicLibrary _openLibrary() {
    if (Platform.isMacOS || Platform.isIOS) {
      return DynamicLibrary.process();
    }
    if (Platform.isLinux) {
      return DynamicLibrary.open('libdevice_volume.so');
    }
    if (Platform.isWindows) {
      return DynamicLibrary.open('device_volume.dll');
    }
    throw const BackendNotAvailableException(
      message: 'FFI backend is not available on this platform.',
    );
  }

  // ── Channel mapping ──────────────────────────────────────────────────────

  static int _channelIndex(VolumeChannel channel) {
    switch (channel) {
      case VolumeChannel.media:
        return 0;
      case VolumeChannel.ring:
        return 1;
      case VolumeChannel.alarm:
        return 2;
      case VolumeChannel.notification:
        return 3;
      case VolumeChannel.voiceCall:
        return 4;
      case VolumeChannel.system:
        return 5;
    }
  }

  // ── Result translation ───────────────────────────────────────────────────

  int _toInt(DeviceVolumeResult r) {
    _checkError(r);
    return r.value;
  }

  void _checkError(DeviceVolumeResult r) {
    switch (r.error_code) {
      case DV_OK:
        return;
      case DV_UNSUPPORTED_OPERATION:
        throw const UnsupportedOperationException(
          message: 'This operation is not supported on the current platform.',
        );
      case DV_PERMISSION_DENIED:
        throw const PermissionDeniedException(
          message: 'Permission denied by the operating system.',
        );
      case DV_NATIVE_FAILURE:
        throw const NativeBackendException(
          message: 'The native audio backend reported an error.',
        );
      case DV_INVALID_VALUE:
        throw const InvalidVolumeValueException(
          message: 'The volume value is outside the valid range (0–100).',
        );
      case DV_BACKEND_NOT_AVAILABLE:
        throw const BackendNotAvailableException(
          message: 'No audio backend available on this system.',
        );
      default:
        throw NativeBackendException(
          message: 'Unknown native error code: ${r.error_code}',
        );
    }
  }

  // ── Public API ───────────────────────────────────────────────────────────

  @override
  int getVolume({VolumeChannel channel = VolumeChannel.media}) {
    final r = _bindings.device_volume_get(_channelIndex(channel));
    return _toInt(r);
  }

  @override
  int setVolume(
    int value, {
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    final r = _bindings.device_volume_set(
      _channelIndex(channel),
      value,
      showSystemUi ? 1 : 0,
    );
    return _toInt(r);
  }

  @override
  int incrementVolume({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    final r = _bindings.device_volume_increment(
      _channelIndex(channel),
      showSystemUi ? 1 : 0,
    );
    return _toInt(r);
  }

  @override
  int decrementVolume({
    VolumeChannel channel = VolumeChannel.media,
    bool showSystemUi = false,
  }) {
    final r = _bindings.device_volume_decrement(
      _channelIndex(channel),
      showSystemUi ? 1 : 0,
    );
    return _toInt(r);
  }

  @override
  Stream<int> streamVolume({VolumeChannel channel = VolumeChannel.media}) {
    late StreamController<int> controller;
    Timer? timer;
    int? lastValue;

    controller = StreamController<int>(
      onListen: () {
        lastValue = getVolume(channel: channel);
        controller.add(lastValue!);

        timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
          try {
            final current = getVolume(channel: channel);
            if (current != lastValue) {
              lastValue = current;
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
