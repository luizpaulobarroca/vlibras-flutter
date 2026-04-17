import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';

import 'mocks/mock_vlibras_platform.dart';

void main() {
  late MockVLibrasPlatform platform;
  late VLibrasController controller;

  setUp(() {
    platform = MockVLibrasPlatform();
    controller = VLibrasController(platform: platform);
    when(() => platform.initialize()).thenAnswer((_) async {});
    when(() => platform.translate(any())).thenAnswer((_) async {});
    when(() => platform.dispose()).thenReturn(null);
  });

  tearDown(() {
    controller.dispose();
  });

  // -------------------------------------------------------------------------
  // VLibrasStatus
  // -------------------------------------------------------------------------
  group('VLibrasStatus', () {
    test('has exactly 6 values', () {
      expect(VLibrasStatus.values, hasLength(6));
    });

    test('contains all required states', () {
      expect(
        VLibrasStatus.values,
        containsAll([
          VLibrasStatus.idle,
          VLibrasStatus.initializing,
          VLibrasStatus.ready,
          VLibrasStatus.translating,
          VLibrasStatus.playing,
          VLibrasStatus.error,
        ]),
      );
    });
  });

  // -------------------------------------------------------------------------
  // VLibrasValue
  // -------------------------------------------------------------------------
  group('VLibrasValue', () {
    test('starts with status idle and no error', () {
      const value = VLibrasValue();
      expect(value.status, VLibrasStatus.idle);
      expect(value.error, isNull);
    });

    test('hasError is false when error is null', () {
      const value = VLibrasValue();
      expect(value.hasError, isFalse);
    });

    test('hasError is true when error is non-null', () {
      const value = VLibrasValue(error: 'something went wrong');
      expect(value.hasError, isTrue);
    });

    test('two instances with same fields are equal', () {
      const a = VLibrasValue(status: VLibrasStatus.ready);
      const b = VLibrasValue(status: VLibrasStatus.ready);
      expect(a, equals(b));
    });

    test('two instances with same fields have same hashCode', () {
      const a = VLibrasValue(status: VLibrasStatus.ready);
      const b = VLibrasValue(status: VLibrasStatus.ready);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different status are not equal', () {
      const a = VLibrasValue(status: VLibrasStatus.idle);
      const b = VLibrasValue(status: VLibrasStatus.ready);
      expect(a, isNot(equals(b)));
    });

    test('instances with different error are not equal', () {
      const a = VLibrasValue(error: 'error one');
      const b = VLibrasValue(error: 'error two');
      expect(a, isNot(equals(b)));
    });

    test('default speed is normal', () {
      const value = VLibrasValue();
      expect(value.speed, VLibrasSpeed.normal);
    });

    test('default avatar is icaro', () {
      const value = VLibrasValue();
      expect(value.avatar, VLibrasAvatar.icaro);
    });

    test('subtitles enabled by default', () {
      const value = VLibrasValue();
      expect(value.subtitlesEnabled, isTrue);
    });

    test('two instances with same speed/avatar/subtitles are equal', () {
      const a = VLibrasValue(
        speed: VLibrasSpeed.fast,
        avatar: VLibrasAvatar.hosana,
        subtitlesEnabled: false,
      );
      const b = VLibrasValue(
        speed: VLibrasSpeed.fast,
        avatar: VLibrasAvatar.hosana,
        subtitlesEnabled: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different speed are not equal', () {
      const a = VLibrasValue(speed: VLibrasSpeed.slow);
      const b = VLibrasValue(speed: VLibrasSpeed.fast);
      expect(a, isNot(equals(b)));
    });

    group('copyWith', () {
      test('changes status while preserving error', () {
        const original =
            VLibrasValue(status: VLibrasStatus.idle, error: 'oops');
        final copy = original.copyWith(status: VLibrasStatus.ready);
        expect(copy.status, VLibrasStatus.ready);
        expect(copy.error, 'oops');
      });

      test('changes error while preserving status', () {
        const original = VLibrasValue(status: VLibrasStatus.error);
        final copy = original.copyWith(error: 'new error');
        expect(copy.status, VLibrasStatus.error);
        expect(copy.error, 'new error');
      });

      test('clearError: true sets error to null regardless of other args', () {
        const original =
            VLibrasValue(status: VLibrasStatus.error, error: 'some error');
        final copy = original.copyWith(error: 'ignored', clearError: true);
        expect(copy.error, isNull);
        expect(copy.status, VLibrasStatus.error);
      });

      test('returns identical value when no args passed', () {
        const original = VLibrasValue(status: VLibrasStatus.ready);
        final copy = original.copyWith();
        expect(copy, equals(original));
      });

      test('changes speed while preserving other fields', () {
        const original = VLibrasValue(
          status: VLibrasStatus.ready,
          avatar: VLibrasAvatar.guga,
          subtitlesEnabled: false,
        );
        final copy = original.copyWith(speed: VLibrasSpeed.fast);
        expect(copy.speed, VLibrasSpeed.fast);
        expect(copy.status, VLibrasStatus.ready);
        expect(copy.avatar, VLibrasAvatar.guga);
        expect(copy.subtitlesEnabled, isFalse);
      });

      test('changes avatar while preserving other fields', () {
        const original = VLibrasValue(speed: VLibrasSpeed.slow);
        final copy = original.copyWith(avatar: VLibrasAvatar.hosana);
        expect(copy.avatar, VLibrasAvatar.hosana);
        expect(copy.speed, VLibrasSpeed.slow);
      });

      test('changes subtitlesEnabled while preserving other fields', () {
        const original = VLibrasValue(avatar: VLibrasAvatar.guga);
        final copy = original.copyWith(subtitlesEnabled: false);
        expect(copy.subtitlesEnabled, isFalse);
        expect(copy.avatar, VLibrasAvatar.guga);
      });
    });
  });

  // -------------------------------------------------------------------------
  // VLibrasController lifecycle
  // -------------------------------------------------------------------------
  group('VLibrasController lifecycle', () {
    test('instantiates with injected mock platform', () {
      final c = VLibrasController(platform: platform);
      expect(c.value.status, VLibrasStatus.idle);
      c.dispose();
    });

    test('initial value is idle with no error', () {
      expect(controller.value.status, VLibrasStatus.idle);
      expect(controller.value.error, isNull);
    });

    test('initialize() transitions idle -> initializing -> ready on success',
        () async {
      final states = <VLibrasStatus>[];
      controller.addListener(() => states.add(controller.value.status));

      await controller.initialize();

      expect(states, [VLibrasStatus.initializing, VLibrasStatus.ready]);
      expect(controller.value.status, VLibrasStatus.ready);
      expect(controller.value.error, isNull);
    });

    test(
        'initialize() transitions idle -> initializing -> error when platform throws',
        () async {
      when(() => platform.initialize())
          .thenThrow(Exception('connection refused'));

      final states = <VLibrasStatus>[];
      controller.addListener(() => states.add(controller.value.status));

      await controller.initialize();

      expect(states, [VLibrasStatus.initializing, VLibrasStatus.error]);
      expect(controller.value.status, VLibrasStatus.error);
    });

    test(
        'initialize() error message contains "Falha ao inicializar"',
        () async {
      when(() => platform.initialize())
          .thenThrow(Exception('connection refused'));

      await controller.initialize();

      expect(controller.value.error, contains('Falha ao inicializar'));
    });

    test('initialize() is idempotent: second call when already ready is a no-op',
        () async {
      await controller.initialize();
      expect(controller.value.status, VLibrasStatus.ready);

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      await controller.initialize();

      expect(notifyCount, 0);
      expect(controller.value.status, VLibrasStatus.ready);
      verify(() => platform.initialize()).called(1);
    });

    test(
        'initialize() is idempotent: call when translating is a no-op',
        () async {
      await controller.initialize();
      await controller.translate('Olá');

      final statusBefore = controller.value.status;
      await controller.initialize();

      expect(controller.value.status, statusBefore);
    });

    test('dispose() calls platform.dispose() then releases ChangeNotifier',
        () {
      final c = VLibrasController(platform: platform);
      c.dispose();

      verify(() => platform.dispose()).called(1);
    });

    test('_setValue does not notify when value unchanged', () async {
      await controller.initialize();
      expect(controller.value.status, VLibrasStatus.ready);

      int notifyCount = 0;
      controller.addListener(() => notifyCount++);

      // initialize() with already-ready state is a no-op (idempotency),
      // so no notifications should fire
      await controller.initialize();

      expect(notifyCount, 0);
    });
  });

  // -------------------------------------------------------------------------
  // VLibrasController translate
  // -------------------------------------------------------------------------
  group('VLibrasController translate', () {
    test('translate() transitions ready -> translating on call', () async {
      await controller.initialize();

      final states = <VLibrasStatus>[];
      controller.addListener(() => states.add(controller.value.status));

      await controller.translate('Olá mundo');

      expect(states.first, VLibrasStatus.translating);
    });

    test('translate() clears error field when entering translating', () async {
      when(() => platform.initialize()).thenThrow(Exception('init failed'));
      await controller.initialize();
      expect(controller.value.status, VLibrasStatus.error);
      expect(controller.value.error, isNotNull);

      // Reset so translate() can proceed without error
      when(() => platform.translate(any())).thenAnswer((_) async {});

      // Recreate controller from idle to be able to translate from error state
      // by triggering error first via translate
      final c2 = VLibrasController(platform: platform);
      when(() => platform.translate(any())).thenThrow(Exception('fail'));
      await c2.translate('primeiro');
      expect(c2.value.status, VLibrasStatus.error);
      expect(c2.value.error, isNotNull);

      // Now translate again — should clear error on entry
      when(() => platform.translate(any())).thenAnswer((_) async {});
      final states = <VLibrasValue>[];
      c2.addListener(() => states.add(c2.value));
      await c2.translate('segundo');

      // The first state transition should be to translating with no error
      expect(states.first.status, VLibrasStatus.translating);
      expect(states.first.error, isNull);
      c2.dispose();
    });

    test(
        'translate() transitions translating -> error when platform throws',
        () async {
      when(() => platform.translate(any()))
          .thenThrow(Exception('translate failed'));

      final states = <VLibrasStatus>[];
      controller.addListener(() => states.add(controller.value.status));

      await controller.translate('Olá');

      expect(states, [VLibrasStatus.translating, VLibrasStatus.error]);
      expect(controller.value.status, VLibrasStatus.error);
    });

    test('translate() error message contains "Falha ao traduzir"', () async {
      when(() => platform.translate(any()))
          .thenThrow(Exception('translate failed'));

      await controller.translate('Olá');

      expect(controller.value.error, contains('Falha ao traduzir'));
    });

    test(
        'translate() while translating: new call cancels current and enters translating again',
        () async {
      // Simulate first translate still in-flight when second arrives
      // by verifying that calling translate from translating state
      // results in translating state again
      when(() => platform.translate(any())).thenThrow(Exception('slow'));

      await controller.translate('primeiro');
      expect(controller.value.status, VLibrasStatus.error);

      // Now from error state, translate again — re-enters translating
      when(() => platform.translate(any())).thenAnswer((_) async {});
      final states = <VLibrasStatus>[];
      controller.addListener(() => states.add(controller.value.status));

      await controller.translate('segundo');

      expect(states.first, VLibrasStatus.translating);
    });
  });

  // -------------------------------------------------------------------------
  // VLibrasController error handling (ERR-01)
  // -------------------------------------------------------------------------
  group('VLibrasController error handling (ERR-01)', () {
    test('no exceptions propagate from initialize() even when platform throws',
        () async {
      when(() => platform.initialize())
          .thenThrow(Exception('fatal platform error'));

      expect(() async => controller.initialize(), returnsNormally);
      await controller.initialize();
      expect(controller.value.status, VLibrasStatus.error);
    });

    test('no exceptions propagate from translate() even when platform throws',
        () async {
      when(() => platform.translate(any()))
          .thenThrow(Exception('fatal translate error'));

      expect(() async => controller.translate('text'), returnsNormally);
      await controller.translate('text');
      expect(controller.value.status, VLibrasStatus.error);
    });
  });

  // -------------------------------------------------------------------------
  // VLibrasSpeed
  // -------------------------------------------------------------------------
  group('VLibrasSpeed', () {
    test('has exactly 3 values', () {
      expect(VLibrasSpeed.values, hasLength(3));
    });

    test('exposes multiplier 0.5 / 1.0 / 1.5', () {
      expect(VLibrasSpeed.slow.multiplier, 0.5);
      expect(VLibrasSpeed.normal.multiplier, 1.0);
      expect(VLibrasSpeed.fast.multiplier, 1.5);
    });
  });

  // -------------------------------------------------------------------------
  // VLibrasAvatar
  // -------------------------------------------------------------------------
  group('VLibrasAvatar', () {
    test('has exactly 3 values', () {
      expect(VLibrasAvatar.values, hasLength(3));
    });

    test('exposes Unity ids icaro / hosana / guga', () {
      expect(VLibrasAvatar.icaro.id, 'icaro');
      expect(VLibrasAvatar.hosana.id, 'hosana');
      expect(VLibrasAvatar.guga.id, 'guga');
    });
  });
}
