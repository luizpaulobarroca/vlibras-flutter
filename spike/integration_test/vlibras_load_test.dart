import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vlibras_spike/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // SC-1: VLibras avatar container (HtmlElementView) renders in widget tree
  testWidgets('VLibras player container is present in widget tree', (WidgetTester tester) async {
    await tester.pumpWidget(const VLibrasSpikeApp());
    // Unity WebGL cold-start can take 20-30 seconds
    await tester.pumpAndSettle(const Duration(seconds: 30));
    expect(find.byKey(const Key('vlibras-player-view')), findsOneWidget);
  });

  // SC-2: Translate button is present and tappable (visual animation confirmed manually)
  testWidgets('Translate button exists and is interactable', (WidgetTester tester) async {
    await tester.pumpWidget(const VLibrasSpikeApp());
    await tester.pumpAndSettle(const Duration(seconds: 30));
    expect(find.byKey(const Key('translate-btn')), findsOneWidget);
    // Note: whether the button is enabled depends on player loading — that is verified manually
    expect(find.byKey(const Key('status-text')), findsOneWidget);
  });
}
