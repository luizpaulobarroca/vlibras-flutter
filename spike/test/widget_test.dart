import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vlibras_spike/main.dart';

void main() {
  testWidgets('VLibras spike app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
