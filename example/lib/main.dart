import 'package:flutter/material.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VLibrasExampleApp());
}

class VLibrasExampleApp extends StatefulWidget {
  const VLibrasExampleApp({super.key});

  @override
  State<VLibrasExampleApp> createState() => _VLibrasExampleAppState();
}

class _VLibrasExampleAppState extends State<VLibrasExampleApp> {
  late final VLibrasController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VLibrasController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VLibras Flutter — Exemplo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF005CA9)),
        useMaterial3: true,
      ),
      home: HomeScreen(controller: _controller),
    );
  }
}
