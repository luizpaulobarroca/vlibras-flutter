import 'dart:async';

import 'vlibras_platform.dart';
import 'vlibras_value.dart';

// ---------------------------------------------------------------------------
// Internal player adapter
//
// Decouples VLibrasWebPlatform from the JS extension type so unit tests can
// inject a fake without requiring a browser or JS runtime.
// ---------------------------------------------------------------------------
abstract class VLibrasPlayerAdapter {
  void load(Object? element);
  void translate(String text);
  void pause();
  void stop();
  void resume();
  void repeat();
  void setSpeed(double speed);

  /// Register a plain-Dart callback for [event].
  void on(String event, void Function() callback);

  /// Unregister a plain-Dart callback for [event].
  void off(String event, void Function() callback);
}

// ---------------------------------------------------------------------------
// VLibrasWebPlatform
// ---------------------------------------------------------------------------

/// Web implementation of [VLibrasPlatform] using vlibras-player-webjs.
///
/// Bridges JS event callbacks (load, animation:play, animation:end) to Dart
/// [Future]s via Completer/Timer pattern.
///
/// Not part of the public API — instantiated via [createDefaultPlatform].
class VLibrasWebPlatform implements VLibrasPlatform {
  /// Creates a [VLibrasWebPlatform].
  ///
  /// [onStatus] is called whenever the player transitions state.
  /// [timeout] is the max time to wait for animation:end after translate().
  /// [playerFactory] is injected in tests; production uses [_defaultFactory].
  VLibrasWebPlatform({
    required void Function(VLibrasStatus) onStatus,
    Duration timeout = const Duration(seconds: 30),
    VLibrasPlayerAdapter Function()? playerFactory,
  })  : _onStatus = onStatus,
        _timeout = timeout,
        _playerFactory = playerFactory ?? _defaultFactory;

  final void Function(VLibrasStatus) _onStatus;
  final Duration _timeout;
  final VLibrasPlayerAdapter Function() _playerFactory;

  VLibrasPlayerAdapter? _player;
  Completer<void>? _initCompleter;
  Completer<void>? _translateCompleter;
  Timer? _timeoutTimer;

  // -------------------------------------------------------------------------
  // Public surface used by VLibrasView
  // -------------------------------------------------------------------------

  /// Called by VLibrasView once the host element is available.
  ///
  /// Creates the player, registers event listeners, then calls player.load().
  void attachToElement(Object? element) {
    final player = _playerFactory();
    _registerEvents(player);
    player.load(element);
    _player = player;
  }

  // -------------------------------------------------------------------------
  // VLibrasPlatform interface
  // -------------------------------------------------------------------------

  @override
  Future<void> initialize() {
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();
    return _initCompleter!.future;
  }

  @override
  Future<void> translate(String text) {
    // cancel-and-restart: cancel any in-flight translate
    _completeTranslate(Exception('cancelled'));

    _translateCompleter = Completer<void>();
    _timeoutTimer = Timer(_timeout, () {
      _completeTranslate(
        TimeoutException(
          'animation:end not received within $_timeout',
          _timeout,
        ),
      );
    });

    _player?.translate(text);
    return _translateCompleter!.future;
  }

  @override
  Future<void> pause() async => _player?.pause();

  @override
  Future<void> stop() async => _player?.stop();

  @override
  Future<void> resume() async => _player?.resume();

  @override
  Future<void> repeat() async => _player?.repeat();

  @override
  Future<void> setSpeed(double speed) async => _player?.setSpeed(speed);

  @override
  void dispose() {
    _completeTranslate(Exception('disposed'));
    // Complete init completer if it is still pending to avoid leaks.
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      _initCompleter!.complete();
    }
    _player = null;
  }

  // -------------------------------------------------------------------------
  // Internal event handling
  // -------------------------------------------------------------------------

  void _registerEvents(VLibrasPlayerAdapter player) {
    player.on('load', _onLoad);
    player.on('animation:play', _onPlay);
    player.on('animation:end', _onEnd);
  }

  void _onLoad() {
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      _initCompleter!.complete();
    }
  }

  void _onPlay() {
    _onStatus(VLibrasStatus.playing);
  }

  void _onEnd() {
    _onStatus(VLibrasStatus.ready);
    _completeTranslate(null);
  }

  /// Pops and completes (or errors) the current translate completer.
  ///
  /// Safe to call when no translate is in flight (no-op in that case).
  void _completeTranslate(Object? error) {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    final c = _translateCompleter;
    _translateCompleter = null;
    if (c == null || c.isCompleted) return;
    if (error != null) {
      c.completeError(error);
    } else {
      c.complete();
    }
  }

  // -------------------------------------------------------------------------
  // Default (production) player factory — only referenced on web
  // -------------------------------------------------------------------------

  /// Production factory — provided by [createDefaultPlatform] in
  /// platform/web_platform.dart (web-only). Never called in VM tests because
  /// tests always inject their own [playerFactory].
  static VLibrasPlayerAdapter Function() get _defaultFactory => () {
    throw UnsupportedError(
      'No playerFactory provided. On Flutter Web, use createDefaultPlatform().',
    );
  };
}
