import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';

/// Plataforma falsa que registra as chamadas e expõe a view mobile que o
/// [VLibrasView] pede fora da web.
class _FakePlatform implements VLibrasPlatform {
  _FakePlatform({this.failInitialize = false});

  final bool failInitialize;
  int initializeCalls = 0;
  final List<String> translated = [];
  final List<double> speeds = [];
  bool translateThrows = false;
  bool disposed = false;

  Widget buildView() => const SizedBox.expand();

  @override
  Future<void> initialize() async {
    initializeCalls++;
    if (failInitialize) throw Exception('falhou');
  }

  @override
  Future<void> translate(String text) async {
    if (translateThrows) throw Exception('renderer encerrado');
    translated.add(text);
  }

  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> repeat() async {}
  @override
  Future<void> setSpeed(double speed) async => speeds.add(speed);
  @override
  Future<void> setAvatar(VLibrasAvatar avatar) async {}
  @override
  Future<void> setSubtitles(bool enabled) async {}
  @override
  void dispose() => disposed = true;
}

/// Monta o widget como no README (via MaterialApp.builder) e registra cada
/// controller criado, com as preferências recebidas.
class _Harness {
  _Harness({this.failInitialize = false});

  final bool failInitialize;
  final List<_FakePlatform> platforms = [];
  final List<VLibrasController> controllers = [];
  final List<VLibrasSettings?> settingsReceived = [];

  _FakePlatform get platform => platforms.last;
  VLibrasController get controller => controllers.last;

  Widget app({required Widget home, bool preloadAvatar = false}) {
    return MaterialApp(
      // Como no app que usa o pacote: o Slider do rodapé precisa de um Overlay
      // acima dele, e o builder do MaterialApp fica acima do Navigator.
      builder:
          (context, child) => Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) => _widget(child!, preloadAvatar),
              ),
            ],
          ),
      home: home,
    );
  }

  Widget _widget(Widget child, bool preloadAvatar) {
    return VLibrasAccessibilityWidget(
      preloadAvatar: preloadAvatar,
      controllerFactory: (settings) {
        settingsReceived.add(settings);
        final platform = _FakePlatform(failInitialize: failInitialize);
        platforms.add(platform);
        final controller = VLibrasController(
          platform: platform,
          initialSettings: settings,
        );
        controllers.add(controller);
        return controller;
      },
      child: child,
    );
  }
}

// O próprio widget Semantics do botão flutuante (find.bySemanticsLabel acharia
// o nó mesclado da tela inteira).
final _openButton = find.byWidgetPredicate(
  (widget) =>
      widget is Semantics &&
      widget.properties.label ==
          'Conteudo acessivel em Libras usando o VLibras',
);

Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(_openButton);
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('só cria o avatar quando o painel é aberto', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app(home: const Scaffold()));
    await tester.pump();

    expect(harness.controllers, isEmpty);

    await _openPanel(tester);

    expect(harness.controllers, hasLength(1));
    expect(harness.platform.initializeCalls, 1);
    expect(harness.controller.value.status, VLibrasStatus.ready);
  });

  testWidgets('preloadAvatar carrega o avatar na montagem', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(
      harness.app(home: const Scaffold(), preloadAvatar: true),
    );
    await tester.pump();

    expect(harness.controllers, hasLength(1));
    expect(harness.platform.initializeCalls, 1);
  });

  testWidgets('primeiro toque traduz sem acionar; o segundo aciona', (
    tester,
  ) async {
    final harness = _Harness();
    var pressed = 0;
    await tester.pumpWidget(
      harness.app(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: ElevatedButton(
              onPressed: () => pressed++,
              child: const Text('Jogos'),
            ),
          ),
        ),
      ),
    );
    await _openPanel(tester);

    await tester.tap(find.text('Jogos'));
    await tester.pump();
    expect(harness.platform.translated, ['Jogos']);
    expect(pressed, 0);

    await tester.tap(find.text('Jogos'));
    await tester.pump();
    expect(pressed, 1);
    expect(harness.platform.translated, ['Jogos']);

    // Depois de acionar, o próximo toque volta a traduzir.
    await tester.tap(find.text('Jogos'));
    await tester.pump();
    expect(harness.platform.translated, ['Jogos', 'Jogos']);
    expect(pressed, 1);
  });

  testWidgets('a lista rola com o painel aberto e rolar desarma o toque', (
    tester,
  ) async {
    final harness = _Harness();
    final scroll = ScrollController();
    var pressed = 0;
    await tester.pumpWidget(
      harness.app(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            child: ListView.builder(
              controller: scroll,
              itemCount: 50,
              itemBuilder:
                  (context, i) => SizedBox(
                    height: 60,
                    child: TextButton(
                      onPressed: () => pressed++,
                      child: Text('Item $i'),
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
    await _openPanel(tester);

    final position = tester.getCenter(find.text('Item 1'));
    await tester.tapAt(position);
    await tester.pump();
    expect(harness.platform.translated, ['Item 1']);

    await tester.drag(find.text('Item 3'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0));

    // O conteúdo mudou de lugar: o toque no mesmo ponto conta como primeiro
    // toque (não aciona), e só o seguinte aciona.
    await tester.tapAt(position);
    await tester.pump();
    expect(pressed, 0);
    await tester.tapAt(position);
    await tester.pump();
    expect(pressed, 1);
  });

  testWidgets('sem texto sob o dedo, usa o rótulo semântico', (tester) async {
    final harness = _Harness();
    await tester.pumpWidget(
      harness.app(
        home: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: 'Slider Puzzle',
                child: Container(
                  key: const Key('banner'),
                  width: 200,
                  height: 100,
                  color: Colors.green,
                ),
              ),
              const Icon(
                Icons.home,
                key: Key('com-rotulo'),
                semanticLabel: 'Início',
              ),
              const Icon(Icons.star, key: Key('sem-rotulo')),
            ],
          ),
        ),
      ),
    );
    await _openPanel(tester);

    await tester.tap(find.byKey(const Key('banner')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('com-rotulo')));
    await tester.pump();
    // Ícone sem rótulo: o caractere da fonte de ícones não vai ao tradutor.
    await tester.tap(find.byKey(const Key('sem-rotulo')));
    await tester.pump();

    expect(harness.platform.translated, ['Slider Puzzle', 'Início']);
  });

  testWidgets(
    'em segundo plano com o painel fechado, libera o avatar e mantém as '
    'preferências',
    (tester) async {
      final harness = _Harness();
      await tester.pumpWidget(harness.app(home: const Scaffold()));
      await _openPanel(tester);
      await harness.controller.setSpeed(VLibrasSpeed.fast);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(harness.platforms.single.disposed, isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(harness.controllers, hasLength(1));

      await _openPanel(tester);
      expect(harness.controllers, hasLength(2));
      expect(harness.settingsReceived.last?.speed, VLibrasSpeed.fast);
      expect(harness.controller.value.speed, VLibrasSpeed.fast);
    },
  );

  testWidgets('com o painel aberto, segundo plano não libera o avatar', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(harness.app(home: const Scaffold()));
    await _openPanel(tester);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(harness.platforms.single.disposed, isFalse);
  });

  testWidgets('erro com o painel aberto recria o avatar uma vez', (
    tester,
  ) async {
    final harness = _Harness();
    await tester.pumpWidget(
      harness.app(
        home: const Scaffold(
          body: Align(alignment: Alignment.topLeft, child: Text('Olá')),
        ),
      ),
    );
    await _openPanel(tester);

    harness.platform.translateThrows = true;
    await tester.tap(find.text('Olá'));
    await tester.pump(); // erro
    await tester.pump(); // recriação no pós-frame
    await tester.pump();

    expect(harness.controllers, hasLength(2));
    expect(harness.platforms.first.disposed, isTrue);
    expect(harness.platform.initializeCalls, 1);
    expect(harness.controller.value.status, VLibrasStatus.ready);
  });

  testWidgets('se recriar não resolve, mostra o erro com tentar novamente', (
    tester,
  ) async {
    final harness = _Harness(failInitialize: true);
    await tester.pumpWidget(harness.app(home: const Scaffold()));
    await _openPanel(tester);
    await tester.pump();
    await tester.pump();

    // A primeira falha recria uma vez; a segunda fica no painel.
    expect(harness.controllers, hasLength(2));
    expect(find.text('Tentar novamente'), findsOneWidget);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pump();
    expect(harness.controllers, hasLength(3));
  });
}
