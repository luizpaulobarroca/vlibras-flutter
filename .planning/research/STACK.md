# Technology Stack

**Project:** vlibras_flutter
**Researched:** 2026-03-22
**Research mode:** Ecosystem (Stack dimension)

## Recommended Stack

### Core Framework

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Flutter SDK | >=3.22.0 | Framework principal | Versao estavel atual com suporte maduro a plugins web, Android e iOS. Constraint `>=3.22.0` garante APIs recentes de platform views e web interop | MEDIUM -- versao exata precisa validacao no dia da criacao |
| Dart SDK | >=3.5.0 | Linguagem e toolchain | Alinhado com Flutter 3.22+. Suporte completo a `dart:js_interop` (substituto do deprecated `dart:js`) e null safety pleno | MEDIUM |
| Kotlin | 1.9+ | Implementacao Android nativa | Linguagem padrao para plugins Flutter Android desde 2023. Template oficial do Flutter usa Kotlin por default (`flutter create -a kotlin`) | HIGH |
| Swift | 5.9+ | Implementacao iOS nativa | Linguagem padrao para plugins Flutter iOS. Template oficial usa Swift por default | HIGH |

### Platform Channels e Code Generation

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| Pigeon | ^22.0.0 | Geracao type-safe de platform channels | Elimina strings magicas em MethodChannel manual. Gera codigo Kotlin/Swift/Dart automaticamente. Recomendado oficialmente pela documentacao Flutter. Suporta classes aninhadas e comunicacao bidirecional | HIGH -- confirmado na doc oficial |
| MethodChannel (manual) | built-in | Fallback para casos simples | Usar APENAS se Pigeon for overkill para a API (ex: 1-2 metodos). Para VLibras com translate/dispose/configure, Pigeon e a escolha certa | HIGH |

**Por que Pigeon e nao MethodChannel manual:** A API do VLibras vai ter pelo menos `translate(text)`, `dispose()`, `setLanguage()`, `onReady` callback. Com MethodChannel manual, cada metodo requer string matching nos 3 lados (Dart, Kotlin, Swift) -- propenso a erro. Pigeon gera tudo type-safe de um arquivo `.dart` de definicao.

### Web Platform

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| `dart:js_interop` | built-in (Dart 3.x) | Interop JavaScript type-safe | Substitui `dart:js` e `package:js` (ambos deprecated). API oficial para chamar JS do Dart no Flutter Web | HIGH -- confirmado na doc oficial |
| `package:web` | ^1.0.0 | Acesso tipado a APIs DOM/browser | Substitui `dart:html` (deprecated). Necessario para manipular DOM, criar elementos, registrar scripts | HIGH |
| `HtmlElementView` | built-in (Flutter) | Embeddar elemento HTML nativo no widget tree | Unica forma de embeddar o player WebGL/Unity do VLibras dentro de um Widget Flutter Web. NAO precisa de webview_flutter para web | HIGH |

**Por que NAO usar `webview_flutter` para Web:** O `webview_flutter` nao tem implementacao web oficial -- ele e para embeddar webviews dentro de apps mobile nativos. Para Flutter Web, voce ja ESTA no browser; use `HtmlElementView` para embeddar um `<div>` ou `<iframe>` com o player VLibras diretamente no DOM.

### SDKs VLibras (Dependencias Nativas)

| Technology | Integracao | Purpose | Confidence |
|------------|-----------|---------|------------|
| vlibras-mobile-android | AAR via Gradle (repositorio Maven local ou remoto) | SDK nativo Android do VLibras -- fornece View com avatar 3D | LOW -- nao foi possivel acessar o repo para confirmar formato de distribuicao; precisa investigacao na Phase 1 |
| vlibras-mobile-ios | CocoaPods ou XCFramework | SDK nativo iOS do VLibras -- fornece UIView com avatar 3D | LOW -- mesma situacao; verificar se distribui via CocoaPods, SPM ou XCFramework manual |
| vlibras-web-player | Script JS (CDN ou bundled) | Player web do VLibras -- WebGL/Unity, carrega via `<script>` tag | LOW -- verificar URL do CDN e API JavaScript exposta |

**FLAG CRITICO:** A forma exata de distribuicao dos SDKs VLibras (Maven coordinates, CocoaPods spec name, CDN URL do web player) precisa ser investigada no inicio da implementacao. Os repositorios estao em `github.com/spbgovbr-vlibras/` mas o acesso detalhado nao foi possivel durante esta pesquisa.

### Tooling de Desenvolvimento

| Technology | Version | Purpose | Why | Confidence |
|------------|---------|---------|-----|------------|
| flutter_lints | ^5.0.0 | Linting padrao pub.dev | Pacote de lints recomendado para publicacao. Inclui regras de API publica, documentacao, null safety | HIGH |
| very_good_analysis | ^6.0.0 | Alternativa a flutter_lints | Mais rigoroso. Recomendado se quiser qualidade maxima para pub.dev. Escolher UM dos dois, nao ambos | MEDIUM |
| build_runner | ^2.4.0 | Executa code generators (Pigeon) | Necessario para rodar `dart run pigeon` ou como parte do build | HIGH |
| mockito | ^5.4.0 | Mocks para testes unitarios | Padrao da comunidade Flutter para mock de platform channels em testes | HIGH |
| plugin_platform_interface | ^2.1.0 | Base class para platform interface | Pacote oficial Flutter para criar a camada de abstracao entre API publica e implementacoes de plataforma | HIGH -- confirmado na doc oficial |

### Publicacao

| Technology | Purpose | Why | Confidence |
|------------|---------|-----|------------|
| `flutter pub publish` | Publicar no pub.dev | Comando oficial. Rodar `--dry-run` primeiro | HIGH |
| pana | Analise estatica pre-publicacao | Verifica score antes de publicar. pub.dev usa pana internamente | HIGH |
| dart doc | Gerar documentacao da API | pub.dev auto-gera docs, mas rodar local garante que tudo esta documentado | HIGH |

## Estrutura de Plugin Recomendada

### Decisao: Plugin Simples (nao Federated)

**Recomendacao:** Usar plugin simples (single-package) e NAO federated plugin.

**Racional:**
1. O VLibras tem apenas 3 plataformas (Android, iOS, Web) -- todas mantidas pelo mesmo autor
2. Federated plugins existem para permitir que OUTROS desenvolvedores contribuam implementacoes de plataformas que o autor nao suporta (ex: Windows, Linux)
3. A complexidade de 3+ pacotes separados (app-facing, platform_interface, android, ios, web) nao se justifica para um plugin mantido por uma pessoa
4. Se no futuro desktop for adicionado, pode-se migrar para federated nesse momento
5. Plugins populares como `url_launcher` sao federated porque o time do Flutter tem contribuidores especializados por plataforma -- nao e o caso aqui

**Excecao:** Se o autor planeja que a comunidade contribua implementacoes (ex: alguem adicionar macOS), entao federated faz sentido. Mas baseado no PROJECT.md, desktop esta explicitamente out of scope.

### Estrutura de Diretorios

```
vlibras_flutter/
├── lib/
│   ├── vlibras_flutter.dart              # Barrel export (API publica)
│   ├── src/
│   │   ├── vlibras_controller.dart       # VLibrasController (logica)
│   │   ├── vlibras_view.dart             # VLibrasView widget
│   │   ├── vlibras_platform_interface.dart  # Abstract class (contrato)
│   │   ├── vlibras_method_channel.dart   # Impl via MethodChannel/Pigeon
│   │   └── vlibras_web.dart              # Impl web (HtmlElementView)
│   └── src/generated/
│       └── pigeon.g.dart                 # Codigo gerado pelo Pigeon
├── android/
│   ├── src/main/kotlin/com/example/vlibras_flutter/
│   │   └── VlibrasFlutterPlugin.kt       # Plugin Android (Kotlin)
│   ├── build.gradle                       # Dependencia do SDK VLibras Android
│   └── src/main/AndroidManifest.xml
├── ios/
│   ├── Classes/
│   │   └── VlibrasFlutterPlugin.swift    # Plugin iOS (Swift)
│   └── vlibras_flutter.podspec           # Dependencia do SDK VLibras iOS
├── web/                                   # (opcional -- pode ficar em lib/src/)
├── pigeons/
│   └── messages.dart                      # Definicao Pigeon da API
├── example/
│   ├── lib/main.dart                      # App exemplo minimo
│   ├── android/
│   ├── ios/
│   └── web/
├── test/
│   ├── vlibras_controller_test.dart
│   ├── vlibras_method_channel_test.dart
│   └── vlibras_web_test.dart
├── pubspec.yaml
├── analysis_options.yaml
├── README.md
├── CHANGELOG.md
├── LICENSE
└── CONTRIBUTING.md
```

### pubspec.yaml Recomendado

```yaml
name: vlibras_flutter
description: >
  Plugin Flutter para VLibras - traduz texto para LIBRAS com avatar 3D.
  Suporta Android, iOS e Web.
version: 0.1.0
homepage: https://github.com/[author]/vlibras_flutter
repository: https://github.com/[author]/vlibras_flutter
issue_tracker: https://github.com/[author]/vlibras_flutter/issues
topics:
  - accessibility
  - libras
  - vlibras
  - sign-language

environment:
  sdk: ">=3.5.0 <4.0.0"
  flutter: ">=3.22.0"

dependencies:
  flutter:
    sdk: flutter
  plugin_platform_interface: ^2.1.0
  web: ^1.0.0  # Para implementacao web (substitui dart:html)

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  pigeon: ^22.0.0
  mockito: ^5.4.0
  build_runner: ^2.4.0

flutter:
  plugin:
    platforms:
      android:
        package: com.example.vlibras_flutter
        pluginClass: VlibrasFlutterPlugin
      ios:
        pluginClass: VlibrasFlutterPlugin
      web:
        pluginClass: VlibrasFlutterWeb
        fileName: src/vlibras_web.dart
```

## Alternativas Consideradas

| Categoria | Recomendado | Alternativa | Por que NAO a alternativa |
|-----------|-------------|-------------|---------------------------|
| Plugin structure | Plugin simples (single-package) | Federated plugin (multi-package) | Over-engineering para 1 mantedor com 3 plataformas. Federated adiciona 3+ pacotes, releases coordenados, e overhead sem beneficio real aqui |
| Platform channels | Pigeon (code-gen) | MethodChannel manual | Strings magicas em 3 plataformas = bugs. Pigeon elimina classe inteira de erros |
| Web approach | HtmlElementView + JS interop | webview_flutter | webview_flutter nao tem suporte web. No browser, embeddar HTML nativo via HtmlElementView e o caminho correto |
| JS interop | `dart:js_interop` + `package:web` | `dart:js` + `dart:html` | `dart:js` e `dart:html` estao deprecated desde Dart 3.x. Novos projetos DEVEM usar `dart:js_interop` e `package:web` |
| Linguagem Android | Kotlin | Java | Template Flutter default e Kotlin desde 2023. Menos boilerplate, null safety, coroutines. Java so se SDK VLibras exigir |
| Linguagem iOS | Swift | Objective-C | Template Flutter default e Swift. Interop moderno, mais seguro. ObjC so se SDK VLibras exigir |
| Linting | flutter_lints | very_good_analysis | flutter_lints e suficiente e padrao. very_good_analysis e mais opinionated -- bom se quiser max score no pub.dev, mas nao essencial |
| State management (controller) | ChangeNotifier nativo | Riverpod/Bloc | O Controller do plugin nao deve depender de pacotes de state management. Usar ChangeNotifier puro (como VideoPlayerController faz) permite que o USUARIO do plugin escolha seu SM |

## O que NAO Usar

| Tecnologia | Por que evitar |
|------------|----------------|
| `dart:js` | **Deprecated.** Substituido por `dart:js_interop` no Dart 3.x. Codigo usando `dart:js` nao compila com wasm |
| `dart:html` | **Deprecated.** Substituido por `package:web`. Mesmo motivo |
| `package:js` | **Deprecated.** Substituido por `dart:js_interop` |
| `webview_flutter` para web | Nao tem implementacao web. E para embeddar webview em apps NATIVOS. No Flutter Web, use HtmlElementView |
| `flutter_inappwebview` | Overkill e dependency pesada. Para mobile o SDK nativo VLibras ja fornece a view; para web, HtmlElementView basta |
| Federated plugin structure | Over-engineering para este projeto. Ver racional acima |
| `dart:ffi` | FFI e para chamar C/C++ direto. SDKs VLibras sao Java/Kotlin (Android) e Swift/ObjC (iOS), entao platform channels e o mecanismo correto |
| Riverpod/Bloc/GetX no plugin | Plugin nao deve impor state management ao usuario. Expor ChangeNotifier e deixar o usuario wrappear como quiser |

## Padroes de API Recomendados

### Controller + Widget Pattern

Seguir o padrao estabelecido por `video_player` e `webview_flutter`:

```dart
// API publica do plugin
class VLibrasController extends ChangeNotifier {
  VLibrasController();

  Future<void> translate(String text) async { ... }
  Future<void> dispose() async { ... }

  // Estado observavel
  bool get isReady => _isReady;
  bool get isTranslating => _isTranslating;
}

class VLibrasView extends StatelessWidget {
  final VLibrasController controller;
  const VLibrasView({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    // Retorna AndroidView, UiKitView, ou HtmlElementView
    // dependendo da plataforma
  }
}
```

### Platform Interface Pattern

Mesmo em plugin simples, usar o padrao de platform interface para testabilidade:

```dart
abstract class VLibrasPlatform extends PlatformInterface {
  static VLibrasPlatform _instance = VLibrasMethodChannel();
  static VLibrasPlatform get instance => _instance;
  static set instance(VLibrasPlatform instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  Future<void> translate(int viewId, String text);
  Future<void> dispose(int viewId);
}
```

## Comandos de Setup

```bash
# Criar o plugin (se partindo do zero)
flutter create --org br.com.vlibras \
  --template=plugin \
  --platforms=android,ios,web \
  -a kotlin \
  vlibras_flutter

# Instalar dependencias
cd vlibras_flutter
flutter pub get

# Rodar Pigeon para gerar platform channel code
dart run pigeon --input pigeons/messages.dart

# Rodar testes
flutter test

# Verificar score antes de publicar
flutter pub publish --dry-run

# Publicar (irreversivel!)
flutter pub publish
```

## Versoes Minimas das Plataformas Alvo

| Plataforma | Versao Minima Sugerida | Racional | Confidence |
|------------|------------------------|----------|------------|
| Android | minSdkVersion 21 (Android 5.0) | Padrao de plugins Flutter populares. Verificar se SDK VLibras exige maior | MEDIUM |
| iOS | 13.0 | Flutter 3.22 suporta iOS 13+. Verificar requisito do SDK VLibras | MEDIUM |
| Web | Browsers modernos (Chrome 90+, Safari 15+, Firefox 90+) | Requisito do Flutter Web + WebGL necessario pelo player VLibras (Unity) | MEDIUM |

## Sources

- Flutter official docs: Developing Packages and Plugins -- https://docs.flutter.dev/packages-and-plugins/developing-packages (fetched 2026-03-22, HIGH confidence)
- Flutter official docs: Platform Channels -- https://docs.flutter.dev/platform-integration/platform-channels (fetched 2026-03-22, HIGH confidence)
- Pigeon package: https://pub.dev/packages/pigeon (not fetched -- version number LOW confidence, verify at implementation time)
- plugin_platform_interface: https://pub.dev/packages/plugin_platform_interface (referenced in official docs, HIGH confidence on pattern)
- VLibras repos: https://github.com/orgs/spbgovbr-vlibras/repositories (not accessed -- LOW confidence on SDK details)

## Gaps e Acoes para Phase 1

1. **CRITICO: Investigar SDKs VLibras** -- Verificar formato de distribuicao (AAR/Maven vs source, CocoaPods vs XCFramework, CDN URL do web player), API exposta (classes, metodos), versoes minimas exigidas, e licenca
2. **Verificar versoes exatas** -- `pigeon`, `plugin_platform_interface`, `web`, `flutter_lints` no pub.dev antes de fixar no pubspec.yaml
3. **Testar HtmlElementView com Unity WebGL** -- O player VLibras web usa Unity WebGL; confirmar que funciona embedado via HtmlElementView (possivel issue com canvas/WebGL context)
4. **Confirmar AndroidView vs TextureLayer** -- Para embeddar a View nativa do SDK VLibras no Android, verificar se `AndroidView` (hybrid composition) ou `TextureLayer` e mais adequado para conteudo WebGL/3D
