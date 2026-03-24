@TestOn('browser')
library;

import 'package:flutter/widgets.dart' show Key;
import 'package:flutter_test/flutter_test.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'mocks/mock_vlibras_platform.dart';

void main() {
  testWidgets('VLibrasView has Key vlibras-player-view', (tester) async {
    final platform = MockVLibrasPlatform();
    when(() => platform.initialize()).thenAnswer((_) async {});
    final controller = VLibrasController(platform: platform);

    await tester.pumpWidget(VLibrasView(controller: controller));

    expect(find.byKey(const Key('vlibras-player-view')), findsOneWidget);

    controller.dispose();
  });
}
