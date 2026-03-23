import 'package:flutter/material.dart';

void main() {
  runApp(const VLibrasSpikeApp());
}

class VLibrasSpikeApp extends StatelessWidget {
  const VLibrasSpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VLibras Spike',
      home: Scaffold(
        appBar: AppBar(title: const Text('VLibras Spike')),
        body: const Center(
          // Placeholder -- replaced in Plan 02 with HtmlElementView
          child: Text('VLibras player will appear here'),
        ),
      ),
    );
  }
}
