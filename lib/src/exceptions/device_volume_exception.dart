/// Base exception for all device_volume errors.
///
/// Every public exception extends this class and carries a stable [code] for
/// programmatic matching, a human-readable [message] aimed at debugging, and
/// an optional [details] map with structured diagnostic data.
///
/// ### Details contract
///
/// When available, [details] should contain:
/// - `platform`  – e.g. `'iOS'`, `'android'`, `'linux'`.
/// - `operation` – the API method that failed, e.g. `'setVolume'`.
/// - `backend`   – native subsystem involved, e.g. `'CoreAudio'`, `'PulseAudio'`.
/// - `channel`   – the [VolumeChannel] name, e.g. `'media'`.
/// - `nativeCode`    – raw error code from the native layer.
/// - `nativeMessage` – raw error message from the native layer.
/// - `suggestedAction` – a hint for the developer on how to resolve the issue.
abstract class DeviceVolumeException implements Exception {
  /// Stable, machine-readable error code.
  final String code;

  /// Human-readable description aimed at developers debugging the issue.
  final String message;

  /// Structured diagnostic data for logging and telemetry.
  final Map<String, Object?> details;

  const DeviceVolumeException(
    this.code,
    this.message, [
    this.details = const {},
  ]);

  @override
  String toString() {
    final buffer = StringBuffer('DeviceVolumeException($code): $message');
    if (details.isNotEmpty) {
      buffer.write(' | details: $details');
    }
    return buffer.toString();
  }
}

/// Thrown when an operation is not supported on the current platform.
///
/// Example: calling `setVolume` on iOS where Apple does not expose a public
/// API for writing the system volume.
final class UnsupportedOperationException extends DeviceVolumeException {
  const UnsupportedOperationException({
    required String message,
    Map<String, Object?> details = const {},
  }) : super('unsupported_operation', message, details);
}

/// Thrown when the caller supplies a volume value outside the valid range.
final class InvalidVolumeValueException extends DeviceVolumeException {
  const InvalidVolumeValueException({
    required String message,
    Map<String, Object?> details = const {},
  }) : super('invalid_volume_value', message, details);
}

/// Thrown when the native backend reports an unexpected failure.
///
/// [details] should include `nativeCode` and `nativeMessage` when available.
final class NativeBackendException extends DeviceVolumeException {
  const NativeBackendException({
    required String message,
    Map<String, Object?> details = const {},
  }) : super('native_backend_failure', message, details);
}

/// Thrown when setting up or maintaining a volume observation stream fails.
final class VolumeObservationException extends DeviceVolumeException {
  const VolumeObservationException({
    required String message,
    Map<String, Object?> details = const {},
  }) : super('volume_observation_failure', message, details);
}

/// Thrown when the required audio backend is not available on the system.
///
/// Example: PulseAudio/PipeWire missing on a headless Linux server.
final class BackendNotAvailableException extends DeviceVolumeException {
  const BackendNotAvailableException({
    required String message,
    Map<String, Object?> details = const {},
  }) : super('backend_not_available', message, details);
}

/// Thrown when the application lacks the required permission to control volume.
final class PermissionDeniedException extends DeviceVolumeException {
  const PermissionDeniedException({
    required String message,
    Map<String, Object?> details = const {},
  }) : super('permission_denied', message, details);
}
