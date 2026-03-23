import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'vlibras_js.dart';

void main() {
  runApp(const VLibrasSpikeApp());
}

class VLibrasSpikeApp extends StatelessWidget {
  const VLibrasSpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'VLibras Spike',
      home: VLibrasSpikeHome(),
    );
  }
}

class VLibrasSpikeHome extends StatefulWidget {
  const VLibrasSpikeHome({super.key});

  @override
  State<VLibrasSpikeHome> createState() => _VLibrasSpikeHomeState();
}

class _VLibrasSpikeHomeState extends State<VLibrasSpikeHome> {
  VLibrasPlayerInstance? _player;
  bool _playerReady = false;
  String _status = 'Initializing...';

  void _onPlayerContainerCreated(Object element) {
    final div = element as web.HTMLDivElement;
    div.id = 'vlibras-player';
    div.style.width = '100%';
    div.style.height = '100%';

    // Delay player init to allow vlibras-plugin.js to fully parse.
    // VLibras script is loaded synchronously via index.html <script> tag,
    // but Unity WebGL initialization is async after parse.
    //
    // WebGL conflict investigation:
    // Flutter CanvasKit uses WebGL2 on the Flutter canvas element.
    // VLibras Unity player also uses WebGL2 on its own canvas inside this div.
    // These are separate canvas elements in separate DOM subtrees, so context
    // isolation should prevent conflicts. Browser console should be checked for:
    //   - "WebGL: INVALID_OPERATION: bindTexture: object does not belong to this context"
    //   - Black/blank avatar area with no Unity loader visible
    //   - Flutter layout corruption or rendering artifacts
    // Result will be documented in the SUMMARY.md after manual verification.
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        final player = createVLibrasPlayer();
        player.on('load', () {
          setState(() {
            _playerReady = true;
            _status = 'Player ready';
          });
        }.toJS);
        player.on('error', (JSAny? err) {
          setState(() {
            _status = 'Error: ${err?.toString() ?? "unknown"}';
          });
        }.toJS);
        player.on('animation:play', () {
          setState(() => _status = 'Animating...');
        }.toJS);
        player.on('animation:end', () {
          setState(() => _status = 'Animation complete');
        }.toJS);
        player.load(div as JSObject);
        setState(() {
          _player = player;
          _status = 'Loading Unity WebGL...';
        });
      } catch (e) {
        setState(() => _status = 'Init error: $e');
      }
    });
  }

  void _translate() {
    final player = _player;
    if (player == null || !_playerReady) {
      setState(() => _status = 'Player not ready yet');
      return;
    }
    player.translate('Ola mundo');
    setState(() => _status = 'Translating: Ola mundo');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VLibras Spike')),
      body: Column(
        children: [
          // Status banner — visible in browser for manual verification
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Text(_status, key: const Key('status-text')),
          ),
          // VLibras player container — 320x480 is a reasonable avatar size
          SizedBox(
            width: 320,
            height: 480,
            child: HtmlElementView.fromTagName(
              key: const Key('vlibras-player-view'),
              tagName: 'div',
              onElementCreated: _onPlayerContainerCreated,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('translate-btn'),
            onPressed: _playerReady ? _translate : null,
            child: const Text('Translate: Ola mundo'),
          ),
        ],
      ),
    );
  }
}
