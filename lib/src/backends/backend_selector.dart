import 'dart:io' show Platform;

import '../exceptions/device_volume_exception.dart';
import 'android_backend.dart';
import 'device_volume_backend.dart';
import 'ffi_backend.dart';

/// Returns the [DeviceVolumeBackend] for the current platform.
///
/// Android uses the [AndroidBackend] (JNIgen / AudioManager).
/// iOS, macOS, Linux and Windows use the [FfiBackend] (FFIgen / native C).
DeviceVolumeBackend backendForCurrentPlatform() {
  return _backend ??= _resolve();
}

DeviceVolumeBackend? _backend;

DeviceVolumeBackend _resolve() {
  if (Platform.isAndroid) {
    return AndroidBackend();
  }
  if (Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isLinux ||
      Platform.isWindows) {
    return FfiBackend();
  }
  throw BackendNotAvailableException(
    message:
        'No device_volume backend available for '
        '${Platform.operatingSystem}.',
    details: {
      'platform': Platform.operatingSystem,
      'suggestedAction': 'This platform is not yet supported by device_volume.',
    },
  );
}
