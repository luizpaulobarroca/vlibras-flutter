import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vlibras_spike/main.dart';

void main() {
  testWidgets('VLibras spike app renders placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(const VLibrasSpikeApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('VLibras player will appear here'), findsOneWidget);
  });
}
