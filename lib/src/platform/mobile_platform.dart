import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../vlibras_platform.dart';
import '../vlibras_value.dart';

VLibrasPlatform createDefaultPlatform(
  void Function(VLibrasStatus) onStatus,
  String targetPath,
) {
  return VLibrasMobilePlatform(onStatus: onStatus, targetPath: targetPath);
}

class VLibrasMobilePlatform implements VLibrasPlatform {
  VLibrasMobilePlatform({
    required void Function(VLibrasStatus) onStatus,
    String targetPath = '',
  })  : _onStatus = onStatus,
        _requestedTargetPath = targetPath {
    _controller = _buildController();
    _initialize();
  }

  final void Function(VLibrasStatus) _onStatus;

  /// Raw targetPath as provided by the caller. If empty or relative (doesn't
  /// start with http:// or https://), local bundled assets are served via a
  /// loopback HTTP server — no CDN required, no CORS or ORB issues.
  final String _requestedTargetPath;

  late final WebViewController _controller;
  Completer<void>? _initCompleter;
  bool _loaded = false;
  String? _pendingText;
  HttpServer? _assetServer;

  bool get _useLocalAssets =>
      !_requestedTargetPath.startsWith('http://') &&
      !_requestedTargetPath.startsWith('https://');

  Widget buildView() => WebViewWidget(controller: _controller);

  WebViewController _buildController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('VLibrasBridge', onMessageReceived: _onBridge)
      ..setOnConsoleMessage((msg) {
        debugPrint('[VLibras WebView] ${msg.level.name}: ${msg.message}');
      })
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) =>
            debugPrint('[VLibras WebView] page finished: $url'),
        onWebResourceError: (err) => debugPrint(
          '[VLibras WebView] resource error: '
          '${err.errorCode} ${err.description} ${err.url}',
        ),
      ));
  }

  Future<void> _initialize() async {
    final vlibrasJs = await rootBundle
        .loadString('packages/vlibras_flutter/assets/vlibras.js');
    final unityLoaderJs = await rootBundle
        .loadString('packages/vlibras_flutter/assets/unity_loader.js');

    final String targetPath;
    final String baseUrl;

    if (_useLocalAssets) {
      // Bind to a random loopback port so all Unity asset requests stay
      // on 127.0.0.1 — same origin as the page, no CORS or mixed-content.
      _assetServer =
          await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = _assetServer!.port;
      _serveAssets(_assetServer!);
      targetPath =
          'http://127.0.0.1:$port/packages/vlibras_flutter/assets/vlibras/target';
      baseUrl = 'http://127.0.0.1:$port/';
    } else {
      targetPath = _requestedTargetPath;
      baseUrl = 'https://vlibras.gov.br/';
    }

    await _controller.loadHtmlString(
      _buildHtml(vlibrasJs, unityLoaderJs, targetPath),
      baseUrl: baseUrl,
    );
  }

  /// Serves flutter assets from the loopback HTTP server.
  /// Requests arrive as e.g. GET /packages/vlibras_flutter/assets/vlibras/target/playerweb.json
  static void _serveAssets(HttpServer server) {
    server.listen((HttpRequest req) async {
      // Strip leading slash to get the rootBundle asset key.
      final key = req.uri.path.replaceFirst(RegExp('^/'), '');
      try {
        final data = await rootBundle.load(key);
        final bytes = data.buffer.asUint8List();
        String ct = 'application/octet-stream';
        if (key.endsWith('.json')) ct = 'application/json; charset=utf-8';
        if (key.endsWith('.js')) ct = 'application/javascript; charset=utf-8';
        req.response
          ..statusCode = HttpStatus.ok
          ..headers.set(HttpHeaders.contentTypeHeader, ct)
          ..headers.set(HttpHeaders.contentLengthHeader, bytes.length)
          ..headers.set('Access-Control-Allow-Origin', '*')
          ..add(bytes);
      } catch (_) {
        req.response.statusCode = HttpStatus.notFound;
      }
      await req.response.close();
    });
  }

  static String _buildHtml(
          String vlibrasJs, String unityLoaderJs, String targetPath) =>
      '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; overflow: hidden; background: #000; }
    #vp { width: 100%; height: 100%; }
    /* Force the Unity container and its canvas to fill the WebView */
    #gameContainer {
      width: 100% !important;
      height: 100% !important;
    }
    #gameContainer canvas {
      width: 100% !important;
      height: 100% !important;
      display: block;
    }
  </style>
</head>
<body>
  <div id="vp"></div>
  <script>$unityLoaderJs</script>
  <script>$vlibrasJs</script>
  <script>
    // Keep vlibras.gov.br as location.host so the translation API receives
    // the expected domain even when the page is served from 127.0.0.1.
    try {
      Object.defineProperty(window.location, 'host', {
        get: function() { return 'vlibras.gov.br'; }
      });
    } catch(e) {}
    window.addEventListener('error', function(e) {
      VLibrasBridge.postMessage('js_error:' + (e.message || '') + ' | src:' + (e.filename || '') + ':' + (e.lineno || ''));
    }, true);
    window.addEventListener('unhandledrejection', function(e) {
      VLibrasBridge.postMessage('js_error:promise:' + (e.reason ? e.reason.toString() : 'unknown'));
    });
    var player = null;
    window.addEventListener('load', function() {
      try {
        player = new VLibras.Player({ targetPath: '$targetPath' });
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
    function vlibrasChangeAvatar(name) { if (player) player.changeAvatar(name); }
    function vlibrasToggleSubtitle() { if (player) player.toggleSubtitle(); }
  </script>
</body>
</html>
''';

  void _onBridge(JavaScriptMessage msg) {
    final message = msg.message;
    if (message.startsWith('debug:') ||
        message.startsWith('js_error:') ||
        message.startsWith('player_error:')) {
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
    if (_loaded && !_initCompleter!.isCompleted) {
      _initCompleter!.complete();
    }
    return _initCompleter!.future;
  }

  @override
  Future<void> translate(String text) async {
    _onStatus(VLibrasStatus.translating);
    final escaped =
        text.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    await _controller.runJavaScript('vlibrasTranslate("$escaped")');
  }

  @override
  Future<void> pause() =>
      _controller.runJavaScript('if(player)player.pause()');

  @override
  Future<void> stop() =>
      _controller.runJavaScript('if(player)player.stop()');

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
  Future<void> setAvatar(VLibrasAvatar avatar) =>
      _controller.runJavaScript('vlibrasChangeAvatar("${avatar.id}")');

  @override
  Future<void> setSubtitles(bool enabled) =>
      _controller.runJavaScript('vlibrasToggleSubtitle()');

  @override
  void dispose() {
    _assetServer?.close(force: true);
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      _initCompleter!.completeError(Exception('disposed'));
    }
  }
}
