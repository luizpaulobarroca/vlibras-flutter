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
      builder: (context, child) => VLibrasAccessibilityWidget(
        child: child!,
        translateUrl: 'https://traducao2.vlibras.gov.br/translate',
      ),
      home: const _DemoPage(),
    );
  }
}

class _DemoPage extends StatelessWidget {
  const _DemoPage();

  void _notify(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VLibras — Acessibilidade')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Instruções ────────────────────────────────────────────────
              Text(
                'Como usar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF005CA9),
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Abra o avatar tocando no botão flutuante à direita.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 6),
              const Text(
                '2. Toque em um texto para traduzi-lo para LIBRAS.',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 6),
              const Text(
                '3. Toque em um botão ou link — aparecerá o tooltip "Acessar link". '
                'Toque novamente no mesmo local para ativá-lo.',
                style: TextStyle(fontSize: 15),
              ),

              const Divider(height: 40),

              // ── Textos para tradução ──────────────────────────────────────
              Text(
                'Textos para tradução',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const Text('Olá, como vai você?', style: TextStyle(fontSize: 17)),
              const SizedBox(height: 8),
              const Text('Bom dia!', style: TextStyle(fontSize: 17)),
              const SizedBox(height: 8),
              const Text('Obrigado pela atenção.', style: TextStyle(fontSize: 17)),
              const SizedBox(height: 8),
              const Text('Acessibilidade para todos.', style: TextStyle(fontSize: 17)),

              const Divider(height: 40),

              // ── Botões interativos (validar "Acessar link") ───────────────
              Text(
                'Botões e links (duplo toque)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // ElevatedButton
              ElevatedButton.icon(
                onPressed: () => _notify(context, 'ElevatedButton ativado!'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Cadastrar Serviço'),
              ),
              const SizedBox(height: 12),

              // TextButton (link style)
              TextButton(
                onPressed: () => _notify(context, 'TextButton ativado!'),
                child: const Text(
                  'Acessar portal gov.br',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
              const SizedBox(height: 12),

              // InkWell (link inline)
              InkWell(
                onTap: () => _notify(context, 'Link inline ativado!'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    'Concurso Público Nacional Unificado (CPNU)',
                    style: TextStyle(
                      color: Color(0xFF005CA9),
                      fontSize: 15,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // OutlinedButton
              OutlinedButton.icon(
                onPressed: () => _notify(context, 'OutlinedButton ativado!'),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Ver regulamento'),
              ),
              const SizedBox(height: 12),

              // ListTile interativo
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Meio Ambiente e Clima'),
                  subtitle: const Text('Cadastrar Cães e Gatos (SinPatinhas)'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _notify(context, 'ListTile ativado!'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
