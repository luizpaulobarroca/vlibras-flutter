import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../vlibras_platform.dart';
import '../vlibras_value.dart';

VLibrasPlatform createDefaultPlatform(void Function(VLibrasStatus) onStatus) {
  return VLibrasMobilePlatform(onStatus: onStatus);
}

class VLibrasMobilePlatform implements VLibrasPlatform {
  VLibrasMobilePlatform({required void Function(VLibrasStatus) onStatus})
      : _onStatus = onStatus {
    _controller = _buildController();
    _loadHtml();
  }

  final void Function(VLibrasStatus) _onStatus;
  late final WebViewController _controller;
  Completer<void>? _initCompleter;
  bool _loaded = false;
  String? _pendingText;

  Widget buildView() => WebViewWidget(controller: _controller);

  WebViewController _buildController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('VLibrasBridge', onMessageReceived: _onBridge)
      ..setOnConsoleMessage((msg) {
        debugPrint('[VLibras WebView] ${msg.level.name}: ${msg.message}');
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) => debugPrint('[VLibras WebView] page finished: $url'),
        onWebResourceError: (err) => debugPrint(
          '[VLibras WebView] resource error: ${err.errorCode} ${err.description} ${err.url}',
        ),
      ));
  }

  Future<void> _loadHtml() async {
    final vlibrasJs = await rootBundle
        .loadString('packages/vlibras_flutter/assets/vlibras.js');
    await _controller.loadHtmlString(
      _buildHtml(vlibrasJs),
      baseUrl: 'https://vlibras.gov.br/',
    );
  }

  static String _buildHtml(String vlibrasJs) => '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; }
    body { width: 100vw; height: 100vh; overflow: hidden; background: #000; }
    #vp { width: 100%; height: 100%; }
  </style>
</head>
<body>
  <div id="vp"></div>
  <script>$vlibrasJs</script>
  <script>
    window.addEventListener('error', function(e) {
      VLibrasBridge.postMessage('js_error:' + (e.message || '') + ' | src:' + (e.filename || '') + ':' + (e.lineno || ''));
    }, true);
    window.addEventListener('unhandledrejection', function(e) {
      VLibrasBridge.postMessage('js_error:promise:' + (e.reason ? e.reason.toString() : 'unknown'));
    });
    var player = null;
    window.addEventListener('load', function() {
      try {
        player = new VLibras.Player({ targetPath: 'https://cdn.jsdelivr.net/gh/spbgovbr-vlibras/vlibras-portal@dev/app/target' });
        player.on('load', function() { VLibrasBridge.postMessage('load'); });
        player.on('animation:play', function() { VLibrasBridge.postMessage('animation:play'); });
        player.on('animation:end', function() { VLibrasBridge.postMessage('animation:end'); });
        player.on('error', function(err) { VLibrasBridge.postMessage('player_error:' + (err || 'unknown')); });
        VLibrasBridge.postMessage('debug:calling player.load');
        player.load(document.getElementById('vp'));
      } catch(e) {
        VLibrasBridge.postMessage('js_error:init:' + e.message);
      }
    });
    function vlibrasTranslate(t) { if (player) player.translate(t); }
  </script>
</body>
</html>
''';

  void _onBridge(JavaScriptMessage msg) {
    final message = msg.message;
    if (message.startsWith('debug:') || message.startsWith('js_error:') || message.startsWith('player_error:')) {
      debugPrint('[VLibras JS] $message');
      return;
    }
    switch (message) {
      case 'load':
        _loaded = true;
        if (_initCompleter != null && !_initCompleter!.isCompleted) {
          _initCompleter!.complete();
        }
        _onStatus(VLibrasStatus.ready);
        if (_pendingText != null) {
          final text = _pendingText!;
          _pendingText = null;
          translate(text);
        }
      case 'animation:play':
        _onStatus(VLibrasStatus.playing);
      case 'animation:end':
        _onStatus(VLibrasStatus.ready);
    }
  }

  @override
  Future<void> initialize() {
    if (_initCompleter != null) return _initCompleter!.future;
    _initCompleter = Completer<void>();
    // Guard against the rare case where the player 'load' event fired before
    // initialize() was called (e.g. very fast CDN response).
    if (_loaded && !_initCompleter!.isCompleted) {
      _initCompleter!.complete();
    }
    return _initCompleter!.future;
  }

  @override
  Future<void> translate(String text) async {
    _onStatus(VLibrasStatus.translating);
    final escaped = text.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    await _controller.runJavaScript('vlibrasTranslate("$escaped")');
  }

  @override
  Future<void> pause() => _controller.runJavaScript('if(player)player.pause()');

  @override
  Future<void> stop() => _controller.runJavaScript('if(player)player.stop()');

  @override
  Future<void> resume() =>
      _controller.runJavaScript('if(player)player.continue()');

  @override
  Future<void> repeat() =>
      _controller.runJavaScript('if(player)player.repeat()');

  @override
  Future<void> setSpeed(double speed) =>
      _controller.runJavaScript('if(player)player.setSpeed($speed)');

  @override
  void dispose() {
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      _initCompleter!.completeError(Exception('disposed'));
    }
  }
}
