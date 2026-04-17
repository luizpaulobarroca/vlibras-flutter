import 'package:flutter_test/flutter_test.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';

void main() {
  group('VLibrasSettings', () {
    test('defaults match VLibrasValue defaults', () {
      const s = VLibrasSettings();
      expect(s.speed, VLibrasSpeed.normal);
      expect(s.avatar, VLibrasAvatar.icaro);
      expect(s.subtitlesEnabled, isTrue);
    });

    test('equal instances have same hashCode', () {
      const a = VLibrasSettings(
        speed: VLibrasSpeed.fast,
        avatar: VLibrasAvatar.hosana,
        subtitlesEnabled: false,
      );
      const b = VLibrasSettings(
        speed: VLibrasSpeed.fast,
        avatar: VLibrasAvatar.hosana,
        subtitlesEnabled: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toJson emits string keys for enums and bool for subtitlesEnabled', () {
      const s = VLibrasSettings(
        speed: VLibrasSpeed.slow,
        avatar: VLibrasAvatar.guga,
        subtitlesEnabled: false,
      );
      expect(s.toJson(), {
        'speed': 'slow',
        'avatar': 'guga',
        'subtitlesEnabled': false,
      });
    });

    test('fromJson parses a well-formed map', () {
      final s = VLibrasSettings.fromJson(const {
        'speed': 'fast',
        'avatar': 'hosana',
        'subtitlesEnabled': true,
      });
      expect(s.speed, VLibrasSpeed.fast);
      expect(s.avatar, VLibrasAvatar.hosana);
      expect(s.subtitlesEnabled, isTrue);
    });

    test('fromJson falls back to defaults for missing/unknown keys', () {
      final s = VLibrasSettings.fromJson(const {'speed': 'invalid'});
      expect(s.speed, VLibrasSpeed.normal);
      expect(s.avatar, VLibrasAvatar.icaro);
      expect(s.subtitlesEnabled, isTrue);
    });

    test('toJson -> fromJson round-trips', () {
      const original = VLibrasSettings(
        speed: VLibrasSpeed.slow,
        avatar: VLibrasAvatar.guga,
        subtitlesEnabled: false,
      );
      final roundTrip = VLibrasSettings.fromJson(original.toJson());
      expect(roundTrip, equals(original));
    });
  });
}
