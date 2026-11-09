import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Protege o app da queda do processo de renderização do WebView (Android).
///
/// O Android encerra o renderer do WebView quando falta memória (o player
/// Unity ocupa centenas de MB) ou quando ele trava. Se o `WebViewClient` não
/// tratar `onRenderProcessGone`, o Chromium encerra o app inteiro junto. O
/// `webview_flutter` não trata esse evento, então o plugin nativo do pacote
/// instala o tratamento no WebView do player e avisa por este canal. Depois do
/// aviso, aquele WebView não pode mais ser usado e precisa ser substituído.
class RenderProcessGuard {
  RenderProcessGuard._();

  static const MethodChannel _channel =
      MethodChannel('vlibras_flutter/render_process');

  static final Map<int, VoidCallback> _listeners = {};
  static bool _handlerInstalled = false;

  /// Passa a vigiar o WebView de [controller] e chama [onGone] se o renderer
  /// dele cair.
  ///
  /// Retorna o identificador a passar para [unwatch], ou `null` quando não há
  /// como vigiar (fora do Android, Android anterior ao 8.0 ou plugin nativo
  /// ausente). Nesses casos o comportamento é o de antes: sem proteção.
  static Future<int?> watch(
    WebViewController controller,
    VoidCallback onGone,
  ) async {
    if (!Platform.isAndroid) return null;
    final platform = controller.platform;
    if (platform is! AndroidWebViewController) return null;

    final id = platform.webViewIdentifier;
    if (!_handlerInstalled) {
      _channel.setMethodCallHandler(_handleCall);
      _handlerInstalled = true;
    }
    _listeners[id] = onGone;

    try {
      final installed = await _channel.invokeMethod<bool>('watch', {'id': id});
      if (installed == true) return id;
    } on MissingPluginException {
      // Plugin nativo não registrado (ex.: testes): segue sem proteção.
    } on PlatformException catch (e) {
      debugPrint('[VLibras] não foi possível vigiar o renderer: $e');
    }
    _listeners.remove(id);
    return null;
  }

  /// Deixa de avisar sobre o WebView [id].
  ///
  /// O tratamento nativo continua instalado de propósito: um WebView descartado
  /// só some quando é coletado, e enquanto existir ainda divide o renderer com
  /// os outros WebViews do app. Se o renderer cair nesse meio-tempo, o
  /// tratamento evita que o app seja encerrado.
  static void unwatch(int id) => _listeners.remove(id);

  static Future<void> _handleCall(MethodCall call) async {
    if (call.method != 'renderProcessGone') return;
    final args = (call.arguments as Map).cast<String, Object?>();
    final id = args['id'] as int;
    debugPrint(
      '[VLibras] renderer do WebView encerrado '
      '(didCrash: ${args['didCrash']}); o avatar será recriado',
    );
    _listeners.remove(id)?.call();
  }
}
