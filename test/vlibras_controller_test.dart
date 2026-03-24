import 'package:flutter_test/flutter_test.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';

import 'mocks/mock_vlibras_platform.dart';

void main() {
  late MockVLibrasPlatform platform;

  setUp(() {
    platform = MockVLibrasPlatform();
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
        final copy =
            original.copyWith(error: 'ignored', clearError: true);
        expect(copy.error, isNull);
        expect(copy.status, VLibrasStatus.error);
      });

      test('returns identical value when no args passed', () {
        const original = VLibrasValue(status: VLibrasStatus.ready);
        final copy = original.copyWith();
        expect(copy, equals(original));
      });
    });
  });

  // -------------------------------------------------------------------------
  // VLibrasController — skipped until Plan 02 implements the controller
  // -------------------------------------------------------------------------
  group('VLibrasController (skipped — Plan 02)', () {
    test(
      'instantiates without error using default platform',
      () {
        // VLibrasController() — Plan 02 will implement
      },
      skip: 'VLibrasController not yet implemented',
    );

    test(
      'instantiates with injected mock platform',
      () {
        // VLibrasController(platform: platform) — Plan 02 will implement
        expect(platform, isNotNull); // suppress unused variable warning
      },
      skip: 'VLibrasController not yet implemented',
    );

    test(
      'initialize() transitions idle -> initializing -> ready on success',
      () async {},
      skip: 'VLibrasController not yet implemented',
    );

    test(
      'initialize() transitions idle -> initializing -> error when platform throws',
      () async {},
      skip: 'VLibrasController not yet implemented',
    );

    test(
      'initialize() is idempotent: second call when already ready is a no-op',
      () async {},
      skip: 'VLibrasController not yet implemented',
    );

    test(
      'translate() transitions ready -> translating on call',
      () async {},
      skip: 'VLibrasController not yet implemented',
    );

    test(
      'translate() clears error field when entering translating',
      () async {},
      skip: 'VLibrasController not yet implemented',
    );

    test(
      'translate() transitions translating -> error when platform throws',
      () async {},
      skip: 'VLibrasController not yet implemented',
    );

    test(
      'translate() while translating: new call cancels current and enters translating again',
      () async {},
      skip: 'VLibrasController not yet implemented',
    );

    test(
      'dispose() calls platform.dispose() then releases ChangeNotifier',
      () {},
      skip: 'VLibrasController not yet implemented',
    );

    test(
      'no exceptions propagate from initialize() even when platform throws',
      () async {},
      skip: 'VLibrasController not yet implemented',
    );

    test(
      'no exceptions propagate from translate() even when platform throws',
      () async {},
      skip: 'VLibrasController not yet implemented',
    );

    test(
      'error message from initialize() contains "Falha ao inicializar"',
      () async {},
      skip: 'VLibrasController not yet implemented',
    );

    test(
      'error message from translate() contains "Falha ao traduzir"',
      () async {},
      skip: 'VLibrasController not yet implemented',
    );
  });
}
