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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                'Status: ${value.status.name}',
                key: const Key('status-text'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(child: VLibrasView(controller: _controller)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: ElevatedButton(
              key: const Key('translate-btn'),
              onPressed: () => _controller.translate('Ola mundo'),
              child: const Text('Traduzir: Ola mundo'),
            ),
          ),
        ],
      ),
    );
  }
}
