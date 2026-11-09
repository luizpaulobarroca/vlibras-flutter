import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../vlibras_platform.dart';
import '../vlibras_value.dart';
import 'render_process_guard.dart';

VLibrasPlatform createDefaultPlatform(
  void Function(VLibrasStatus) onStatus,
  String targetPath, [
  String? translateUrl,
]) {
  return VLibrasMobilePlatform(
    onStatus: onStatus,
    targetPath: targetPath,
    translateUrl: translateUrl,
  );
}

class VLibrasMobilePlatform implements VLibrasPlatform {
  VLibrasMobilePlatform({
    required void Function(VLibrasStatus) onStatus,
    String targetPath = '',
    String? translateUrl,
  })  : _onStatus = onStatus,
        _requestedTargetPath = targetPath,
        _translateUrl = translateUrl;

  final void Function(VLibrasStatus) _onStatus;

  /// Raw targetPath as provided by the caller. If empty or relative (doesn't
  /// start with http:// or https://), local bundled assets are served via a
  /// loopback HTTP server — no CDN required, no CORS or ORB issues.
  final String _requestedTargetPath;

  /// Custom translation API endpoint. When null the built-in VLibras URL is used.
  final String? _translateUrl;

  // Criado sob demanda: o WebView com o player Unity ocupa centenas de MB no
  // processo do renderer, então nada é instanciado nem carregado até alguém
  // pedir a view ou chamar initialize().
  WebViewController? _webView;
  WebViewController get _controller => _webView ??= _buildController();
  bool _disposed = false;
  // O renderer do WebView caiu: este WebView não pode mais ser usado.
  bool _renderGone = false;
  int? _guardId;
  Completer<void>? _initCompleter;
  String? _pendingText;
  HttpServer? _assetServer;

  bool get _useLocalAssets =>
      !_requestedTargetPath.startsWith('http://') &&
      !_requestedTargetPath.startsWith('https://');

  Widget buildView() => WebViewWidget(controller: _controller);

  WebViewController _buildController() {
    final controller = WebViewController()
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
    _watchRenderProcess(controller);
    return controller;
  }

  Future<void> _watchRenderProcess(WebViewController controller) async {
    final id = await RenderProcessGuard.watch(controller, _onRenderProcessGone);
    if (id == null) return;
    if (_disposed) {
      RenderProcessGuard.unwatch(id);
    } else {
      _guardId = id;
    }
  }

  void _onRenderProcessGone() {
    if (_disposed) return;
    _renderGone = true;
    final completer = _initCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.completeError(
        StateError('O processo de renderização do WebView foi encerrado'),
      );
    }
    _onStatus(VLibrasStatus.error);
  }

  /// Roda [script] no player, a não ser que o WebView já tenha sido
  /// descartado ou perdido o renderer.
  Future<void> _run(String script) async {
    if (_disposed || _renderGone) return;
    await _controller.runJavaScript(script);
  }

  // Fixed loopback port for the local asset server.
  //
  // Using a stable port keeps the page origin (http://127.0.0.1:_kAssetPort)
  // constant across hot-restarts and full restarts. The VLibras dictionary
  // and translator servers cache CORS preflight responses keyed by origin, so
  // a changing random port causes stale-cache CORS failures on subsequent runs.
  // `shared: true` lets a new instance bind immediately even if the previous
  // Dart isolate hasn't fully released the port yet.
  static const int _kAssetPort = 44100;

  static Future<HttpServer> _bindAssetServer() async {
    try {
      return await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        _kAssetPort,
        shared: true,
      );
    } on SocketException {
      // Extremely unlikely fallback: if the fixed port is blocked by something
      // outside our control, use an ephemeral port.
      return HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    }
  }

  Future<void> _initialize() async {
    final vlibrasJs = await rootBundle
        .loadString('packages/vlibras_flutter/assets/vlibras.js');
    final unityLoaderJs = await rootBundle
        .loadString('packages/vlibras_flutter/assets/unity_loader.js');
    if (_disposed) return;

    final String targetPath;
    final String baseUrl;
    String? proxyBase;

    if (_useLocalAssets) {
      _assetServer = await _bindAssetServer();
      if (_disposed) {
        await _assetServer?.close(force: true);
        return;
      }
      final port = _assetServer!.port;
      _serveAssets(_assetServer!);
      targetPath =
          'http://127.0.0.1:$port/packages/vlibras_flutter/assets/vlibras/target';
      baseUrl = 'http://127.0.0.1:$port/';
      // All requests to *.vlibras.gov.br are routed through the local proxy so
      // they are same-origin — eliminating CORS preflight caching issues entirely.
      proxyBase = 'http://127.0.0.1:$port/vlibras-proxy';
    } else {
      targetPath = _requestedTargetPath;
      baseUrl = 'https://vlibras.gov.br/';
    }

    // Clear stale CORS preflight entries that the WebView may have cached from
    // previous sessions with a different port.
    await _controller.clearCache();
    if (_disposed) return;

    await _controller.loadHtmlString(
      _buildHtml(vlibrasJs, unityLoaderJs, targetPath, _translateUrl, proxyBase),
      baseUrl: baseUrl,
    );
  }

  /// Serves flutter assets from the loopback HTTP server.
  /// Also handles `/vlibras-proxy/<host>/<path>` to forward requests to
  /// VLibras external APIs with proper `Access-Control-Allow-Origin: *` headers,
  /// bypassing server-side CORS preflight caching issues.
  static void _serveAssets(HttpServer server) {
    server.listen((HttpRequest req) async {
      if (req.uri.path.startsWith('/vlibras-proxy/')) {
        await _proxyRequest(req);
        return;
      }

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

  /// Proxies requests to VLibras external APIs through the local server,
  /// adding `Access-Control-Allow-Origin: *` so the WebView never sees a CORS
  /// error regardless of what the upstream CDN has cached.
  ///
  /// Request path format: `/vlibras-proxy/<hostname>/<original-path>`
  static Future<void> _proxyRequest(HttpRequest req) async {
    // Respond to CORS preflight immediately.
    if (req.method == 'OPTIONS') {
      req.response
        ..statusCode = HttpStatus.ok
        ..headers.set('Access-Control-Allow-Origin', '*')
        ..headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        ..headers.set('Access-Control-Allow-Headers', '*');
      await req.response.close();
      return;
    }

    try {
      final rest = req.uri.path.substring('/vlibras-proxy/'.length);
      final slash = rest.indexOf('/');
      final host = slash >= 0 ? rest.substring(0, slash) : rest;
      final path = slash >= 0 ? rest.substring(slash) : '/';
      final target = Uri(
        scheme: 'https',
        host: host,
        path: path,
        query: req.uri.query.isNotEmpty ? req.uri.query : null,
      );

      final client = HttpClient();
      final proxyReq = await client.openUrl(req.method, target);

      // Forward headers — drop host/origin/referer so the upstream server
      // receives a clean request (not 127.0.0.1 as origin).
      req.headers.forEach((name, values) {
        final n = name.toLowerCase();
        if (const {'host', 'origin', 'referer'}.contains(n) ||
            n.startsWith('access-control')) { return; }
        for (final v in values) {
          try {
            proxyReq.headers.add(name, v);
          } catch (_) {}
        }
      });

      // Forward request body (required for POST /translate).
      final body =
          await req.fold<List<int>>([], (buf, chunk) => buf..addAll(chunk));
      if (body.isNotEmpty) {
        proxyReq.contentLength = body.length;
        proxyReq.add(body);
      }

      final proxyResp = await proxyReq.close();

      req.response.statusCode = proxyResp.statusCode;
      req.response.headers
        ..set('Access-Control-Allow-Origin', '*')
        ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        ..set('Access-Control-Allow-Headers', '*');
      if (proxyResp.headers.contentType != null) {
        req.response.headers.contentType = proxyResp.headers.contentType;
      }
      await proxyResp.pipe(req.response);
      client.close();
    } catch (e) {
      debugPrint('[VLibras proxy] error forwarding ${req.uri}: $e');
      req.response.statusCode = HttpStatus.badGateway;
      await req.response.close();
    }
  }

  static String _buildHtml(
    String vlibrasJs,
    String unityLoaderJs,
    String targetPath, [
    String? translateUrl,
    String? proxyBase,
  ]) =>
      '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; overflow: hidden; background: #DCE8F5; }
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
  ${proxyBase != null ? '''
  <script>
  // Intercept all XHR requests to *.vlibras.gov.br and redirect them through
  // the local proxy server. This eliminates CORS errors caused by server-side
  // CDN caching of preflight responses with stale origins.
  (function() {
    var PROXY = '$proxyBase';
    var HOSTS = [
      'dicionario2.vlibras.gov.br',
      'dicionario.vlibras.gov.br',
      'traducao2.vlibras.gov.br',
      'vlibras.gov.br'
    ];
    var _origOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function(method, url, async, user, pass) {
      for (var i = 0; i < HOSTS.length; i++) {
        if (url.indexOf('https://' + HOSTS[i]) === 0) {
          url = PROXY + '/' + HOSTS[i] + url.substring(('https://' + HOSTS[i]).length);
          break;
        }
      }
      return _origOpen.call(this, method, url,
        async !== undefined ? async : true, user, pass);
    };
  })();
  </script>
  ''' : '<!-- CDN mode: no proxy needed -->'}
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
        var playerOpts = { targetPath: '$targetPath' };
        ${translateUrl != null ? "playerOpts.translator = '$translateUrl';" : '// using default translator URL'}
        player = new VLibras.Player(playerOpts);
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
    if (_disposed || _renderGone) return;
    final message = msg.message;
    if (message.startsWith('debug:') ||
        message.startsWith('js_error:') ||
        message.startsWith('player_error:')) {
      debugPrint('[VLibras JS] $message');
      return;
    }
    switch (message) {
      case 'load':
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

  /// Começa a carregar o player (só na primeira chamada) e conclui quando o
  /// Unity avisar que carregou.
  @override
  Future<void> initialize() {
    final existing = _initCompleter;
    if (existing != null) return existing.future;
    final completer = _initCompleter = Completer<void>();
    _initialize().catchError((Object error, StackTrace stack) {
      if (!completer.isCompleted) completer.completeError(error, stack);
    });
    return completer.future;
  }

  @override
  Future<void> translate(String text) async {
    _onStatus(VLibrasStatus.translating);
    // jsonEncode yields a fully-escaped, quoted string literal (handles ", \,
    // newlines, tabs, control chars). A JSON string is a valid JS string, so
    // it can be dropped straight into the call. U+2028/U+2029 are valid in
    // JSON but were illegal in JS string literals before ES2019, so escape
    // them explicitly to stay safe across WebView engines.
    final encoded = jsonEncode(text)
        .replaceAll(' ', '\\u2028')
        .replaceAll(' ', '\\u2029');
    await _run('vlibrasTranslate($encoded)');
  }

  @override
  Future<void> pause() => _run('if(player)player.pause()');

  @override
  Future<void> stop() => _run('if(player)player.stop()');

  @override
  Future<void> resume() => _run('if(player)player.continue()');

  @override
  Future<void> repeat() => _run('if(player)player.repeat()');

  @override
  Future<void> setSpeed(double speed) =>
      _run('if(player)player.setSpeed($speed)');

  @override
  Future<void> setAvatar(VLibrasAvatar avatar) =>
      _run('vlibrasChangeAvatar("${avatar.id}")');

  @override
  Future<void> setSubtitles(bool enabled) => _run('vlibrasToggleSubtitle()');

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final guardId = _guardId;
    if (guardId != null) RenderProcessGuard.unwatch(guardId);
    _assetServer?.close(force: true);
    final webView = _webView;
    if (webView != null && !_renderGone) {
      // Descarrega a página na hora: o WebView nativo só é destruído quando o
      // Dart coleta o controller, e até lá o Unity seguiria ocupando memória.
      webView
          .loadRequest(Uri.parse('about:blank'))
          .catchError((Object _) {});
    }
    if (_initCompleter != null && !_initCompleter!.isCompleted) {
      _initCompleter!.completeError(Exception('disposed'));
    }
  }
}
