import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';

/// A fake platform for non-web environments.
///
/// Implements [VLibrasPlatform] and exposes a [buildView] method used by
/// [VLibrasController.buildMobileView] via dynamic dispatch.
class FakeMobilePlatform implements VLibrasPlatform {
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

  Widget buildView() => const SizedBox.shrink(key: Key('vlibras-mobile-view'));
}

void main() {
  testWidgets(
      'VLibrasView renders the mobile-branch widget when kIsWeb is false',
      (tester) async {
    final controller = VLibrasController(platform: FakeMobilePlatform());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: VLibrasView(controller: controller)),
      ),
    );

    expect(find.byKey(const Key('vlibras-mobile-view')), findsOneWidget);
    controller.dispose();
  });
}
