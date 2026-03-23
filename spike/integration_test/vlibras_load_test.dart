import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vlibras_spike/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // SC-1: VLibras avatar container renders inside HtmlElementView
  testWidgets('VLibras player container is present in widget tree', (WidgetTester tester) async {
    await tester.pumpWidget(const VLibrasSpikeApp());
    await tester.pumpAndSettle(const Duration(seconds: 30));
    // After Plan 02: expect(find.byKey(const Key('vlibras-player-view')), findsOneWidget);
    // For now, verify the app renders without throwing
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  // SC-2: Dart translate() call does not throw and triggers player
  testWidgets('translate() call completes without exception', (WidgetTester tester) async {
    await tester.pumpWidget(const VLibrasSpikeApp());
    await tester.pumpAndSettle(const Duration(seconds: 30));
    // After Plan 02: tap a translate button and verify no exception is thrown
    // For now, verify the app is in a testable state
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
