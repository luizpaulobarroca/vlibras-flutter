import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vlibras_flutter/src/vlibras_value.dart';
import 'package:vlibras_flutter/src/vlibras_web_platform.dart';

// ---------------------------------------------------------------------------
// Fake player for unit tests
//
// Implements VLibrasPlayerAdapter so it can be injected via playerFactory.
// Captures callbacks registered via on() so tests can fire them synchronously.
// ---------------------------------------------------------------------------
class FakePlayer implements VLibrasPlayerAdapter {
  final Map<String, void Function()> _handlers = {};

  @override
  void on(String event, void Function() callback) {
    _handlers[event] = callback;
  }

  @override
  void off(String event, void Function() callback) {
    _handlers.remove(event);
  }

  @override
  void load(Object? element) {}
  @override
  void translate(String text) {}
  @override
  void pause() {}
  @override
  void stop() {}
  @override
  void resume() {}
  @override
  void repeat() {}
  @override
  void setSpeed(double speed) {}
  @override
  void changeAvatar(String _) {}
  @override
  void toggleSubtitle() {}

  /// Fire a registered event synchronously.
  void fire(String event) {
    _handlers[event]?.call();
  }
}

// ---------------------------------------------------------------------------
// Helper: build a platform with an injected FakePlayer.
//
// The playerFactory callback is invoked inside attachToElement(), so we need
// a way for the test to capture the player instance. We do that by having the
// factory store it in a local variable accessible to the test.
// ---------------------------------------------------------------------------
VLibrasWebPlatform buildPlatform({
  required FakePlayer fakePlayer,
  required void Function(VLibrasStatus) onStatus,
  Duration timeout = const Duration(seconds: 30),
}) {
  return VLibrasWebPlatform(
    onStatus: onStatus,
    timeout: timeout,
    playerFactory: () => fakePlayer as VLibrasPlayerAdapter,
  );
}

void main() {
  group('VLibrasWebPlatform', () {
    late FakePlayer fakePlayer;
    late List<VLibrasStatus> statusLog;
    late VLibrasWebPlatform platform;

    setUp(() {
      fakePlayer = FakePlayer();
      statusLog = [];
      platform = buildPlatform(
        fakePlayer: fakePlayer,
        onStatus: (s) => statusLog.add(s),
      );
      // Simulate VLibrasView calling attachToElement() so the player is wired.
      platform.attachToElement(null);
    });

    tearDown(() {
      platform.dispose();
    });

    // -----------------------------------------------------------------------
    // 1. onStatus receives VLibrasStatus.playing when 'animation:play' fires
    // -----------------------------------------------------------------------
    test(
        'onStatus receives VLibrasStatus.playing when mock player fires '
        'animation:play', () {
      fakePlayer.fire('animation:play');
      expect(statusLog, contains(VLibrasStatus.playing));
    });

    // -----------------------------------------------------------------------
    // 2. onStatus receives VLibrasStatus.ready when 'animation:end' fires
    // -----------------------------------------------------------------------
    test(
        'onStatus receives VLibrasStatus.ready when mock player fires '
        'animation:end', () {
      fakePlayer.fire('animation:end');
      expect(statusLog, contains(VLibrasStatus.ready));
    });

    // -----------------------------------------------------------------------
    // 3. translate() Future completes when 'animation:end' fires
    // -----------------------------------------------------------------------
    test('translate() Future completes when animation:end fires', () async {
      final future = platform.translate('Olá');
      fakePlayer.fire('animation:end');
      await expectLater(future, completes);
    });

    // -----------------------------------------------------------------------
    // 4. translate() Future completes with TimeoutException when timeout elapses
    // -----------------------------------------------------------------------
    test(
        'translate() Future completes with TimeoutException when timeout '
        'elapses with no animation:end', () async {
      final shortTimeout = VLibrasWebPlatform(
        onStatus: (_) {},
        timeout: const Duration(milliseconds: 10),
        playerFactory: () => fakePlayer,
      );
      shortTimeout.attachToElement(null);

      try {
        await expectLater(
          shortTimeout.translate('Hello'),
          throwsA(isA<TimeoutException>()),
        );
      } finally {
        shortTimeout.dispose();
      }
    });

    // -----------------------------------------------------------------------
    // 5. Second translate() cancels the in-flight translate (cancel-and-restart)
    // -----------------------------------------------------------------------
    test(
        'calling translate() a second time cancels the in-flight translate '
        'and starts fresh', () async {
      bool firstCompleted = false;
      bool firstErrored = false;

      // Start first translate and leave it in-flight.
      final firstFuture = platform.translate('primeiro').then((_) {
        firstCompleted = true;
      }).catchError((_) {
        firstErrored = true;
      });

      // Immediately start second translate — cancels the first.
      final secondFuture = platform.translate('segundo');

      // Complete the second via animation:end.
      fakePlayer.fire('animation:end');

      await secondFuture;
      await firstFuture; // ensure first settles

      // First must have errored (cancelled), second completed normally.
      expect(firstCompleted, isFalse);
      expect(firstErrored, isTrue);
    });

    // -----------------------------------------------------------------------
    // 6. dispose() cancels in-flight translate Future
    // -----------------------------------------------------------------------
    test('dispose() cancels in-flight translate Future', () async {
      bool errored = false;

      final future = platform.translate('Olá').catchError((_) {
        errored = true;
      });

      platform.dispose();
      await future;

      expect(errored, isTrue);
    });

    // -----------------------------------------------------------------------
    // 7. initialize() Future completes when 'load' event fires
    // -----------------------------------------------------------------------
    test('initialize() Future completes when load event fires', () async {
      // Rebuild without auto-attach so we control the sequence.
      final fp2 = FakePlayer();
      final p2 = VLibrasWebPlatform(
        onStatus: (_) {},
        playerFactory: () => fp2,
      );

      final initFuture = p2.initialize();
      p2.attachToElement(null); // triggers player creation → registers callbacks
      fp2.fire('load');

      await expectLater(initFuture, completes);
      p2.dispose();
    });

    // -----------------------------------------------------------------------
    // 8. initialize() is idempotent — second call while already ready returns
    //    without re-initializing
    // -----------------------------------------------------------------------
    test('initialize() is idempotent — second call when already ready returns '
        'without re-initializing', () async {
      final fp = FakePlayer();
      final p = buildPlatform(
        fakePlayer: fp,
        onStatus: (_) {},
      );

      // First initialize: call initialize(), attach element, fire load.
      final initFuture = p.initialize();
      p.attachToElement(null);
      fp.fire('load');
      await initFuture;

      // Second initialize: should return immediately (completer already completed).
      // No 'load' event needed — it must resolve without any external trigger.
      await expectLater(p.initialize(), completes);

      p.dispose();
    });

    // -----------------------------------------------------------------------
    // 9. translate() cancel-and-restart while playing — animation:end from
    //    first is attributed to second; final status is ready
    // -----------------------------------------------------------------------
    test(
        'second translate() while playing supersedes the first; single '
        'animation:end completes the second translate', () async {
      // Capture the first future's error immediately to prevent unhandled error.
      bool firstErrored = false;
      final firstFuture = platform
          .translate('primeiro')
          .catchError((_) => firstErrored = true);

      fakePlayer.fire('animation:play'); // player is now playing

      // Immediately start second translation — cancels the first.
      final secondFuture = platform.translate('segundo');

      // Fire animation:end once — should complete the second translate.
      fakePlayer.fire('animation:end');

      // Second translate completes normally.
      await expectLater(secondFuture, completes);

      // Await first to ensure its error handler has run.
      await firstFuture;
      expect(firstErrored, isTrue);

      // Final status after animation:end is ready, not error.
      expect(statusLog.last, equals(VLibrasStatus.ready));
    });

    // -----------------------------------------------------------------------
    // 10. Timeout fires without animation:end — platform emits
    //     VLibrasStatus.error via onStatus
    // -----------------------------------------------------------------------
    test(
        'timeout without animation:end causes platform to emit '
        'VLibrasStatus.error via onStatus', () async {
      final timeoutStatusLog = <VLibrasStatus>[];
      final fp = FakePlayer();
      final p = buildPlatform(
        fakePlayer: fp,
        onStatus: (s) => timeoutStatusLog.add(s),
        timeout: const Duration(milliseconds: 100),
      );
      p.attachToElement(null);

      // Start translate — timer begins.
      final translateFuture = p.translate('texto').catchError((_) {});

      // Wait longer than the timeout to let the timer fire.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await translateFuture;

      // Platform must have emitted VLibrasStatus.error.
      expect(timeoutStatusLog, contains(VLibrasStatus.error));

      p.dispose();
    });
  });
}
