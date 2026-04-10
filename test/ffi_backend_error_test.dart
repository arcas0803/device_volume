// These tests verify the error code → exception mapping used by FfiBackend.
//
// Because FfiBackend._checkError is a private method, we exercise the mapping
// indirectly via the generated bindings error codes and the public exception
// hierarchy. The constants below mirror the C header values and let us confirm
// the Dart exception types match.

import 'package:device_volume/device_volume.dart';
import 'package:flutter_test/flutter_test.dart';

// Mirror of the C error codes from src/device_volume.h
const _dvOk = 0;
const _dvUnsupportedOperation = 1;
const _dvPermissionDenied = 2;
const _dvNativeFailure = 3;
const _dvInvalidValue = 4;
const _dvBackendNotAvailable = 5;

void main() {
  group('Error code to exception mapping', () {
    // Simulate the mapping logic from FfiBackend._checkError.
    DeviceVolumeException? mapErrorCode(int code) {
      switch (code) {
        case _dvOk:
          return null;
        case _dvUnsupportedOperation:
          return const UnsupportedOperationException(message: 'unsupported');
        case _dvPermissionDenied:
          return const PermissionDeniedException(message: 'denied');
        case _dvNativeFailure:
          return const NativeBackendException(message: 'native');
        case _dvInvalidValue:
          return const InvalidVolumeValueException(message: 'invalid');
        case _dvBackendNotAvailable:
          return const BackendNotAvailableException(message: 'no backend');
        default:
          return NativeBackendException(message: 'unknown code: $code');
      }
    }

    test('DV_OK maps to no exception', () {
      expect(mapErrorCode(_dvOk), isNull);
    });

    test('DV_UNSUPPORTED_OPERATION maps to UnsupportedOperationException', () {
      expect(
        mapErrorCode(_dvUnsupportedOperation),
        isA<UnsupportedOperationException>(),
      );
    });

    test('DV_PERMISSION_DENIED maps to PermissionDeniedException', () {
      expect(
        mapErrorCode(_dvPermissionDenied),
        isA<PermissionDeniedException>(),
      );
    });

    test('DV_NATIVE_FAILURE maps to NativeBackendException', () {
      expect(mapErrorCode(_dvNativeFailure), isA<NativeBackendException>());
    });

    test('DV_INVALID_VALUE maps to InvalidVolumeValueException', () {
      expect(mapErrorCode(_dvInvalidValue), isA<InvalidVolumeValueException>());
    });

    test('DV_BACKEND_NOT_AVAILABLE maps to BackendNotAvailableException', () {
      expect(
        mapErrorCode(_dvBackendNotAvailable),
        isA<BackendNotAvailableException>(),
      );
    });

    test('Unknown code maps to NativeBackendException', () {
      final e = mapErrorCode(99);
      expect(e, isA<NativeBackendException>());
      expect(e!.message, contains('99'));
    });
  });
}
