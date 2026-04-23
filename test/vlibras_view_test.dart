@TestOn('browser')
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web/web.dart' as web;
import 'mocks/mock_vlibras_platform.dart';

/// A fake web platform that also exposes [attachToElement], called via dynamic
/// dispatch from [VLibrasController.attachElement] on web.
class _FakeWebPlatform implements VLibrasPlatform {
  @override
  Future<void> initialize() async {}
  @override
  Future<void> translate(String text) async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> repeat() async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> setAvatar(VLibrasAvatar avatar) async {}
  @override
  Future<void> setSubtitles(bool enabled) async {}
  @override
  void dispose() {}
  // ignore: avoid_dynamic_calls
  void attachToElement(Object? element) {}
}

void main() {
  testWidgets('VLibrasView has Key vlibras-player-view', (tester) async {
    final platform = MockVLibrasPlatform();
    when(() => platform.initialize()).thenAnswer((_) async {});
    final controller = VLibrasController(platform: platform);

    await tester.pumpWidget(VLibrasView(controller: controller));

    expect(find.byKey(const Key('vlibras-player-view')), findsOneWidget);

    controller.dispose();
  });

  testWidgets(
      'VLibrasView.onElementCreated configures div id and style',
      (tester) async {
    final controller = VLibrasController(platform: _FakeWebPlatform());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 300,
            child: VLibrasView(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final element = web.document.getElementById('vlibras-player');
    expect(element, isNotNull,
        reason: 'div#vlibras-player must be in the DOM after onElementCreated');
    expect(element!.id, equals('vlibras-player'));

    final htmlElement = element as web.HTMLElement;
    expect(htmlElement.style.width, isNotEmpty,
        reason: 'onElementCreated must set non-empty style.width');
    expect(htmlElement.style.height, isNotEmpty,
        reason: 'onElementCreated must set non-empty style.height');

    controller.dispose();
  });
}
