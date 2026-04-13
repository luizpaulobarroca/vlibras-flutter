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
    return VLibrasAccessibilityWidget(
      child: MaterialApp(
        title: 'VLibras Flutter — Exemplo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005CA9)),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VLibrasAccessibilityWidget',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF005CA9),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Clique no botão flutuante à direita para abrir o avatar.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Com o avatar aberto, clique em qualquer texto desta tela para traduzi-lo para LIBRAS.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
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
        ),
      ),
    );
  }
}
