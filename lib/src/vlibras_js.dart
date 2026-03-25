import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('VLibras')
external VLibrasNamespace get vLibras;

extension type VLibrasNamespace._(JSObject _) implements JSObject {
  @JS('Player')
  external JSFunction get player;
}

extension type VLibrasPlayerOptions._(JSObject _) implements JSObject {
  external factory VLibrasPlayerOptions({
    String translator,
    String targetPath,
  });
}

extension type VLibrasPlayerInstance._(JSObject _) implements JSObject {
  external void load(JSObject element);
  external void translate(String text);
  external void pause();
  external void stop();
  @JS('continue') external void resume();
  external void repeat();
  external void setSpeed(double speed);
  external void on(String event, JSFunction callback);
  external void off(String event, JSFunction callback);
}

VLibrasPlayerInstance createVLibrasPlayer() {
  final options = VLibrasPlayerOptions(
    translator: 'https://vlibras.gov.br/api',
    targetPath: '/vlibras/target',
  );
  return vLibras.player.callAsConstructor(options) as VLibrasPlayerInstance;
}
