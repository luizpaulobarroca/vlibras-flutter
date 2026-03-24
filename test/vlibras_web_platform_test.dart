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

  void on(String event, void Function() callback) {
    _handlers[event] = callback;
  }

  void off(String event, void Function() callback) {
    _handlers.remove(event);
  }

  @override
  void load(Object? element) {}
  void translate(String text) {}
  void pause() {}
  void stop() {}
  void resume() {}
  void repeat() {}
  void setSpeed(double speed) {}

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
  });
}
