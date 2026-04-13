// dart:js_interop bindings for VLibras Player API.
// CONFIDENCE: MEDIUM — derived from source inspection of vlibras-player-webjs.
// All method names and signatures must be validated empirically during spike execution.
// See .planning/research/phase-01-findings.md for confirmed vs. unconfirmed entries.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Access window.VLibras namespace after vlibras-plugin.js loads.
@JS('VLibras')
external VLibrasNamespace get vLibras;

extension type VLibrasNamespace._(JSObject _) implements JSObject {
  /// Raw player constructor (use this, not Widget).
  external JSFunction get Player;
}

/// Options passed to the VLibras.Player constructor.
extension type VLibrasPlayerOptions._(JSObject _) implements JSObject {
  external factory VLibrasPlayerOptions({
    String translator,
    String targetPath,
  });
}

/// Instance returned by `new VLibras.Player(options)`.
/// Call player.load(element) to attach to DOM, then player.translate(text).
extension type VLibrasPlayerInstance._(JSObject _) implements JSObject {
  /// Attach the Unity WebGL player to a DOM element.
  /// Must be called after the element is in the DOM.
  external void load(JSObject element);

  /// Send text for LIBRAS translation and animation.
  external void translate(String text);

  /// Resume paused playback.
  @JS('continue')
  external void resume();

  /// Pause animation playback.
  external void pause();

  /// Stop animation playback.
  external void stop();

  /// Replay current animation.
  external void repeat();

  /// Adjust playback speed. 1.0 = normal.
  external void setSpeed(double speed);

  /// Register an event callback. Events: 'load', 'translate:start',
  /// 'translate:end', 'animation:play', 'animation:pause', 'animation:end',
  /// 'animation:progress', 'error', 'stateChange'.
  external void on(String event, JSFunction callback);

  /// Remove an event callback.
  external void off(String event, JSFunction callback);
}

/// Instantiate a VLibras Player.
/// Caller is responsible for calling player.load(element) once the
/// DOM container element is ready.
VLibrasPlayerInstance createVLibrasPlayer() {
  final options = VLibrasPlayerOptions(
    targetPath: 'https://vlibras.gov.br/app',
  );
  // Construct via JS: new VLibras.Player(options)
  return vLibras.Player.callAsConstructor(options) as VLibrasPlayerInstance;
}
