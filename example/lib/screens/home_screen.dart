import 'package:flutter/material.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';
import '../widgets/draggable_avatar.dart';

/// Main screen of the VLibras Flutter example app.
///
/// Displays a polished landing page with:
/// - A floating, draggable avatar that snaps to screen corners
/// - A [TextField] for typing text to translate
/// - A Traduzir button that calls [VLibrasController.translate]
/// - A status indicator showing the current [VLibrasValue.status]
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final VLibrasController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  String _statusText(VLibrasValue value) {
    return switch (value.status) {
      VLibrasStatus.idle        => 'Aguardando inicialização',
      VLibrasStatus.initializing => 'Inicializando...',
      VLibrasStatus.ready       => 'Pronto',
      VLibrasStatus.translating => 'Traduzindo...',
      VLibrasStatus.playing     => 'Reproduzindo',
      VLibrasStatus.error       => 'Erro: ${value.error ?? "desconhecido"}',
    };
  }

  Color _statusColor(VLibrasStatus status) {
    return switch (status) {
      VLibrasStatus.error       => Colors.red.shade700,
      VLibrasStatus.ready       => Colors.green.shade700,
      VLibrasStatus.playing     => Colors.blue.shade700,
      _                         => Colors.grey.shade600,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  // Header
                  Text(
                    'vlibras_flutter',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF005CA9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plugin Flutter para tradução de texto em LIBRAS via avatar 3D VLibras.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  // Status indicator
                  ValueListenableBuilder<VLibrasValue>(
                    valueListenable: widget.controller,
                    builder: (context, value, _) {
                      return Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: _statusColor(value.status),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _statusText(value),
                            style: TextStyle(
                              color: _statusColor(value.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Translation input
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'Texto para traduzir',
                      hintText: 'Ex: Olá, como vai você?',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        widget.controller.translate(text.trim());
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ValueListenableBuilder<VLibrasValue>(
                    valueListenable: widget.controller,
                    builder: (context, value, _) {
                      final canTranslate = value.status == VLibrasStatus.ready ||
                          value.status == VLibrasStatus.playing ||
                          value.status == VLibrasStatus.error;
                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: canTranslate
                              ? () {
                                  final text = _textController.text.trim();
                                  if (text.isNotEmpty) {
                                    widget.controller.translate(text);
                                  }
                                }
                              : null,
                          icon: const Icon(Icons.translate),
                          label: const Text('Traduzir'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  // Usage hint
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Como usar',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '• O avatar flutua sobre o conteúdo\n'
                            '• Arraste-o para qualquer posição\n'
                            '• Ao soltar, ele se encaixa na quina mais próxima\n'
                            '• O tamanho padrão é 200×200px (parametrizável)',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Floating draggable avatar — size passed explicitly so snap
          // calculations use Stack bounds, not the MediaQuery screen size.
          DraggableAvatar(
            controller: widget.controller,
            availableSize: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        ],
        ),
      ),
    );
  }
}
