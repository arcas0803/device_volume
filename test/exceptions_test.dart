import 'package:device_volume/device_volume.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeviceVolumeException subclasses', () {
    test('UnsupportedOperationException has correct code', () {
      const e = UnsupportedOperationException(message: 'not supported');
      expect(e.code, 'unsupported_operation');
      expect(e.message, 'not supported');
      expect(e.details, isEmpty);
    });

    test('InvalidVolumeValueException has correct code and details', () {
      const e = InvalidVolumeValueException(
        message: 'out of range',
        details: {'value': 200},
      );
      expect(e.code, 'invalid_volume_value');
      expect(e.message, 'out of range');
      expect(e.details, {'value': 200});
    });

    test('NativeBackendException has correct code', () {
      const e = NativeBackendException(message: 'native error');
      expect(e.code, 'native_backend_failure');
    });

    test('VolumeObservationException has correct code', () {
      const e = VolumeObservationException(message: 'stream failed');
      expect(e.code, 'volume_observation_failure');
    });

    test('BackendNotAvailableException has correct code', () {
      const e = BackendNotAvailableException(message: 'no backend');
      expect(e.code, 'backend_not_available');
    });

    test('PermissionDeniedException has correct code', () {
      const e = PermissionDeniedException(message: 'denied');
      expect(e.code, 'permission_denied');
    });
  });

  group('DeviceVolumeException.toString', () {
    test('includes code and message', () {
      const e = NativeBackendException(message: 'boom');
      expect(e.toString(), contains('native_backend_failure'));
      expect(e.toString(), contains('boom'));
    });

    test('includes details when present', () {
      const e = InvalidVolumeValueException(
        message: 'bad',
        details: {'value': -1},
      );
      final str = e.toString();
      expect(str, contains('details'));
      expect(str, contains('-1'));
    });

    test('omits details section when empty', () {
      const e = NativeBackendException(message: 'simple');
      expect(e.toString(), isNot(contains('details')));
    });
  });

  group('Facade validation', () {
    test('setVolume rejects value below 0', () {
      expect(
        () => DeviceVolume.setVolume(-1),
        throwsA(isA<InvalidVolumeValueException>()),
      );
    });

    test('setVolume rejects value above 100', () {
      expect(
        () => DeviceVolume.setVolume(101),
        throwsA(isA<InvalidVolumeValueException>()),
      );
    });

    test('setVolumeCompute rejects value below 0', () {
      expect(
        () => DeviceVolume.setVolumeCompute(-5),
        throwsA(isA<InvalidVolumeValueException>()),
      );
    });

    test('setVolumeCompute rejects value above 100', () {
      expect(
        () => DeviceVolume.setVolumeCompute(150),
        throwsA(isA<InvalidVolumeValueException>()),
      );
    });
  });
}
