import 'package:flutter/material.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: HomePage());
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = VLibrasController();
  final _textController = TextEditingController(text: 'Olá mundo');

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _translate() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _controller.translate(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VLibras Flutter Test')),
      body: Column(
        children: [
          ValueListenableBuilder<VLibrasValue>(
            valueListenable: _controller,
            builder: (_, value, __) => Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Status: ${value.status.name}'
                '${value.hasError ? ' — ${value.error}' : ''}',
                key: const Key('status-text'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(child: VLibrasView(controller: _controller)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('translate-input'),
                    controller: _textController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Texto para traduzir',
                    ),
                    onSubmitted: (_) => _translate(),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<VLibrasValue>(
                  valueListenable: _controller,
                  builder: (_, value, __) => ElevatedButton(
                    key: const Key('translate-btn'),
                    onPressed: value.status == VLibrasStatus.ready
                        ? _translate
                        : null,
                    child: const Text('Traduzir'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
