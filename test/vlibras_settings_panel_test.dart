import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';

import 'mocks/mock_vlibras_platform.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(VLibrasAvatar.icaro);
  });

  late MockVLibrasPlatform platform;
  late VLibrasController controller;

  setUp(() async {
    platform = MockVLibrasPlatform();
    when(() => platform.initialize()).thenAnswer((_) async {});
    when(() => platform.dispose()).thenReturn(null);
    when(() => platform.setSpeed(any())).thenAnswer((_) async {});
    when(() => platform.setAvatar(any())).thenAnswer((_) async {});
    when(() => platform.setSubtitles(any())).thenAnswer((_) async {});
    controller = VLibrasController(platform: platform);
    await controller.initialize();
  });

  tearDown(() {
    controller.dispose();
  });

  Future<void> pumpPanel(
    WidgetTester tester, {
    VoidCallback? onClose,
    VLibrasSettingsLabels? labels,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: VLibrasSettingsPanel(
          controller: controller,
          onClose: onClose,
          labels: labels ?? const VLibrasSettingsLabels(),
        ),
      ),
    ));
  }

  group('VLibrasSettingsPanel', () {
    testWidgets('renders the three section titles in PT by default',
        (tester) async {
      await pumpPanel(tester);
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Velocidade'), findsOneWidget);
      expect(find.text('Avatar'), findsOneWidget);
      expect(find.text('Legendas'), findsOneWidget);
    });

    testWidgets('tapping "Rápido" calls setSpeed(fast)', (tester) async {
      await pumpPanel(tester);
      await tester.tap(find.text('Rápido'));
      await tester.pump();
      verify(() => platform.setSpeed(1.5)).called(1);
    });

    testWidgets('tapping "Hosana" calls setAvatar(hosana)', (tester) async {
      await pumpPanel(tester);
      await tester.tap(find.text('Hosana'));
      await tester.pump();
      verify(() => platform.setAvatar(VLibrasAvatar.hosana)).called(1);
    });

    testWidgets('toggling subtitle switch calls setSubtitles(false)',
        (tester) async {
      await pumpPanel(tester);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      verify(() => platform.setSubtitles(false)).called(1);
    });

    testWidgets('close button hidden when onClose is null', (tester) async {
      await pumpPanel(tester);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('close button shown and invoked when onClose is non-null',
        (tester) async {
      var closed = false;
      await pumpPanel(tester, onClose: () => closed = true);
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);
    });

    testWidgets('custom labels replace defaults', (tester) async {
      await pumpPanel(
        tester,
        labels: const VLibrasSettingsLabels(
          title: 'Settings',
          speed: 'Speed',
          speedSlow: 'Slow',
          speedNormal: 'Normal',
          speedFast: 'Fast',
          avatar: 'Character',
          subtitles: 'Captions',
        ),
      );
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('Captions'), findsOneWidget);
      expect(find.text('Configurações'), findsNothing);
    });
  });
}
