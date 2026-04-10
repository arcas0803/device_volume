import 'package:device_volume/src/models/volume_channel.dart';
import 'package:device_volume/src/models/volume_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VolumeState.fromRaw', () {
    test('computes normalized correctly for typical range', () {
      final s = VolumeState.fromRaw(
        value: 7,
        min: 0,
        max: 15,
        isMuted: false,
        channel: VolumeChannel.media,
      );
      expect(s.value, 7);
      expect(s.min, 0);
      expect(s.max, 15);
      expect(s.normalized, closeTo(7 / 15, 0.001));
      expect(s.isMuted, false);
      expect(s.channel, VolumeChannel.media);
    });

    test('normalized is 0.0 when value equals min', () {
      final s = VolumeState.fromRaw(
        value: 0,
        min: 0,
        max: 100,
        isMuted: false,
        channel: VolumeChannel.media,
      );
      expect(s.normalized, 0.0);
    });

    test('normalized is 1.0 when value equals max', () {
      final s = VolumeState.fromRaw(
        value: 100,
        min: 0,
        max: 100,
        isMuted: false,
        channel: VolumeChannel.media,
      );
      expect(s.normalized, 1.0);
    });

    test('normalized is 0.0 when max equals min (degenerate range)', () {
      final s = VolumeState.fromRaw(
        value: 5,
        min: 5,
        max: 5,
        isMuted: false,
        channel: VolumeChannel.alarm,
      );
      expect(s.normalized, 0.0);
    });

    test('handles non-zero min correctly', () {
      final s = VolumeState.fromRaw(
        value: 7,
        min: 2,
        max: 12,
        isMuted: true,
        channel: VolumeChannel.ring,
      );
      expect(s.normalized, closeTo(0.5, 0.001));
      expect(s.isMuted, true);
    });
  });

  group('VolumeState equality', () {
    test('equal states compare as equal', () {
      final a = VolumeState.fromRaw(
        value: 50,
        min: 0,
        max: 100,
        isMuted: false,
        channel: VolumeChannel.media,
      );
      final b = VolumeState.fromRaw(
        value: 50,
        min: 0,
        max: 100,
        isMuted: false,
        channel: VolumeChannel.media,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different value → not equal', () {
      final a = VolumeState.fromRaw(
        value: 50,
        min: 0,
        max: 100,
        isMuted: false,
        channel: VolumeChannel.media,
      );
      final b = VolumeState.fromRaw(
        value: 51,
        min: 0,
        max: 100,
        isMuted: false,
        channel: VolumeChannel.media,
      );
      expect(a, isNot(equals(b)));
    });

    test('different channel → not equal', () {
      final a = VolumeState.fromRaw(
        value: 50,
        min: 0,
        max: 100,
        isMuted: false,
        channel: VolumeChannel.media,
      );
      final b = VolumeState.fromRaw(
        value: 50,
        min: 0,
        max: 100,
        isMuted: false,
        channel: VolumeChannel.ring,
      );
      expect(a, isNot(equals(b)));
    });

    test('different muted → not equal', () {
      final a = VolumeState.fromRaw(
        value: 50,
        min: 0,
        max: 100,
        isMuted: false,
        channel: VolumeChannel.media,
      );
      final b = VolumeState.fromRaw(
        value: 50,
        min: 0,
        max: 100,
        isMuted: true,
        channel: VolumeChannel.media,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('VolumeState.toString', () {
    test('includes all fields', () {
      final s = VolumeState.fromRaw(
        value: 42,
        min: 0,
        max: 100,
        isMuted: false,
        channel: VolumeChannel.media,
      );
      final str = s.toString();
      expect(str, contains('42'));
      expect(str, contains('media'));
      expect(str, contains('0.42'));
    });
  });
}
