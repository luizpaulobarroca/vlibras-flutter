import 'package:flutter/material.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VLibrasExampleApp());
}

class VLibrasExampleApp extends StatelessWidget {
  const VLibrasExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VLibras Flutter — Exemplo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005CA9)),
        useMaterial3: true,
      ),
      // VLibrasAccessibilityWidget deve ser inserido via builder para ter
      // acesso a Directionality, MediaQuery e Theme do MaterialApp.
      builder: (context, child) =>
          VLibrasAccessibilityWidget(child: child!),
      home: const _DemoPage(),
    );
  }
}

class _DemoPage extends StatelessWidget {
  const _DemoPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VLibras — Acessibilidade')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Como usar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF005CA9),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '1. Toque no botão flutuante à direita para abrir o avatar.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                '2. Com o avatar aberto, toque em qualquer texto abaixo para traduzi-lo para LIBRAS.',
                style: TextStyle(fontSize: 16),
              ),
              const Divider(height: 40),
              const Text('Olá, como vai você?', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              const Text('Bom dia!', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              const Text('Obrigado pela atenção.', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              const Text('Acessibilidade para todos.', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
