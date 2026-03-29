import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../vlibras_js.dart';
import '../vlibras_platform.dart';
import '../vlibras_value.dart';
import '../vlibras_web_platform.dart';

VLibrasPlatform createDefaultPlatform(void Function(VLibrasStatus) onStatus) {
  return VLibrasWebPlatform(
    onStatus: onStatus,
    playerFactory: _WebPlayerAdapter.create,
  );
}

// ---------------------------------------------------------------------------
// Adapter that wraps the real JS VLibrasPlayerInstance.
//
// Lives here (not vlibras_web_platform.dart) so that dart:js_interop is only
// imported on web — this file is selected by the conditional import guard
// in vlibras_controller.dart and is never compiled on non-web targets.
// ---------------------------------------------------------------------------
class _WebPlayerAdapter implements VLibrasPlayerAdapter {
  _WebPlayerAdapter._(this._instance);

  final VLibrasPlayerInstance _instance;

  // Keeps the JSFunction wrappers created by .toJS so off() can unregister
  // the exact same JS reference that was registered.
  final Map<String, JSFunction> _jsCallbacks = {};

  static VLibrasPlayerAdapter create() =>
      _WebPlayerAdapter._(createVLibrasPlayer());

  @override
  void load(Object? element) {
    _disableCanvasRotation();
    _instance.load(element as JSObject);
  }

  /// Injects a CSS rule that sets pointer-events:none on the Unity canvas so
  /// mousemove events never reach it, preventing the avatar from rotating.
  static bool _rotationDisabled = false;
  static void _disableCanvasRotation() {
    if (_rotationDisabled) return;
    _rotationDisabled = true;
    final style = web.document.createElement('style') as web.HTMLStyleElement;
    style.id = 'vlibras-no-rotation';
    style.textContent =
        '#gameContainer canvas { pointer-events: none !important; }';
    (web.document.head ?? web.document.body)?.appendChild(style);
  }

  @override
  void translate(String text) => _instance.translate(text);

  @override
  void pause() => _instance.pause();

  @override
  void stop() => _instance.stop();

  @override
  void resume() => _instance.resume();

  @override
  void repeat() => _instance.repeat();

  @override
  void setSpeed(double speed) => _instance.setSpeed(speed);

  @override
  void on(String event, void Function() callback) {
    final jsCallback = callback.toJS;
    _jsCallbacks[event] = jsCallback;
    _instance.on(event, jsCallback);
  }

  @override
  void off(String event, void Function() callback) {
    final jsCallback = _jsCallbacks.remove(event);
    if (jsCallback != null) _instance.off(event, jsCallback);
  }
}
