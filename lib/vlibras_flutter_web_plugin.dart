import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Stub web plugin registrar for flutter_tools compatibility.
///
/// VLibras web support is implemented via conditional imports
/// (dart.library.js_interop) in vlibras_controller.dart. This class satisfies
/// the `flutter: plugin: platforms: web: pluginClass:` requirement in
/// pubspec.yaml so that flutter_tools' WebPlugin.fromYaml can parse the
/// plugin declaration without error.
class VLibrasFlutterWebPlugin {
  /// Called by the generated web_plugin_registrant.dart on web builds.
  ///
  /// No-op: registration is handled by the conditional import of
  /// VLibrasWebPlatform, not by a plugin channel registrar.
  static void registerWith(Registrar registrar) {}
}
