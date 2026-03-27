# Phase 4: Publication Readiness - Research

**Researched:** 2026-03-27
**Domain:** Flutter plugin publication (pub.dev), dartdoc, example app, draggable floating widget, test expansion
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Example app:**
- UI polida com branding VLibras, conteúdo informativo sobre o plugin e demonstração interativa
- Avatar flutuante com snap para quinas: o VLibrasView se comporta como uma janela flutuante que o usuário pode arrastar livremente; ao soltar, anima automaticamente para a quina mais próxima das 4 (top-left, top-right, bottom-left, bottom-right)
- Sempre visível — avatar não pode ser ocultado; flutua sobre todo o conteúdo da página
- Tamanho fixo mas parametrizável — tamanho padrão definido (ex: 200×200), mas o exemplo deixa clara a possibilidade de customizar
- Conteúdo principal: TextField para digitar texto livre + botão "Traduzir" que aciona `controller.translate()`
- Indicadores de estado visíveis: texto simples mostrando o `VLibrasValue.status` atual ("Inicializando...", "Traduzindo...", "Erro: ...") — educa o developer sobre como consumir o controller

**README:**
- Idioma: Português (público-alvo principal são desenvolvedores brasileiros)
- Nível: Essencial — o que é o plugin, instalação, uso básico com snippet de código, plataformas suportadas, setup dos assets VLibras (`target/` e script no `index.html`)
- Sem screenshots no MVP

**CHANGELOG:**
- Formato Keep a Changelog — `## [0.1.0] - YYYY-MM-DD` com seções `Added` listando as capacidades entregues
- Entrada única para v0.1.0 (primeiro release)

**pubspec metadata:**
- Licença: MIT — arquivo `LICENSE` na raiz com texto MIT padrão
- Versão: `0.1.0`
- Homepage: Claude escolhe URL adequada (repositório atual ou placeholder descritivo)
- topics: `accessibility`, `libras`, `sign-language`, `vlibras`
- description: melhorar para ser descritiva e clara (~100–180 chars)
- plugin.platforms: declarar `web: {}` explicitamente
- .pubignore: excluir `build/`, `spike/`, `web/vlibras/target/`

**Cobertura de testes:**
- VLibrasView — expandir: adicionar testes para `buildMobileView` em non-web, `onElementCreated` configura id/style no div, widget usa o controller fornecido
- VLibrasWebPlatform — ampliar com casos de erro: timeout sem `animation:end` → emite error, `translate()` durante playing → cancel-and-restart, `initialize()` idempotente
- Garantir que todos os testes existentes passam com `flutter test`

### Claude's Discretion
- Implementação interna do snap animation (AnimationController, physics, curve de animação)
- Estrutura de arquivos interna do /example
- Exato texto das seções do README
- URL do repositório no homepage
- Qual teste de View é VM-compilável vs browser-only

### Deferred Ideas (OUT OF SCOPE)
- Screenshots no README
- Versão bilingue do README (EN + PT-BR)
- Avatar redimensionável por gesto (DIFF-04, v2)
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PUB-01 | Plugin inclui app /example funcional demonstrando uso básico do Controller+View | Example app structure, path dependency, draggable snap widget pattern |
| PUB-02 | Toda API pública possui comentários dartdoc (classes, métodos, propriedades) | Dartdoc `///` format, Effective Dart conventions, pub.dev scoring |
| PUB-03 | README documenta instalação, uso básico e plataformas suportadas | pub.dev README requirements, Keep a Changelog format, pubspec metadata |
| PUB-04 | Plugin inclui testes unitários e/ou widget cobrindo o comportamento do controller | Existing test infrastructure, VM-runnable test patterns, FakePlayer injection |
</phase_requirements>

---

## Summary

Phase 4 transforms the working plugin into a publishable pub.dev package. The four deliverables are: (1) an `/example` app with a polished UI and draggable snap-to-corner VLibrasView, (2) complete `///` dartdoc on every public symbol, (3) pubspec/README/CHANGELOG/LICENSE metadata, and (4) expanded test coverage. The codebase is already well-structured — Phases 1–3 produced documented code, test infrastructure with `MockVLibrasPlatform` and `FakePlayer`, and a working Web platform. Phase 4 is primarily assembly and polish, not architecture.

The most technically novel piece is the draggable snap-to-corner widget. Flutter's standard `Stack + Positioned + GestureDetector` pattern handles free drag. On `onPanEnd`, compute the nearest corner from the released position, then use `AnimationController.animateWith(SpringSimulation(...))` or `AnimatedPositioned` with a `CurvedAnimation` to animate to that corner. The `AnimatedPositioned` approach (implicit animation, no explicit controller needed) is simpler to implement and sufficient for this use case.

`flutter pub publish --dry-run` has two confirmed blockers in the current project: missing `LICENSE` file (explicit pub requirement) and missing `README.md`. Additional blockers from pubspec: `platforms: {}` (empty map) does not register the plugin as web-supported for pana scoring — it must be `platforms: web: {}`. The `spike/` and `build/` directories, and the Unity `web/vlibras/target/` assets, must be excluded via `.pubignore` to keep package size under the 100 MB compressed limit.

**Primary recommendation:** Build the /example app and draggable widget first (most visible), then complete metadata (LICENSE, README, CHANGELOG, pubspec), then expand tests, then run `--dry-run` gate.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter (sdk) | >=3.7.2 | Example app framework | Already constrained in pubspec |
| flutter_test (sdk) | >=3.7.2 | Widget and unit testing | Built-in; no separate install |
| mocktail | ^0.3.0 | Mock injection for controller tests | Already in dev_dependencies |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| dart:async | sdk | Completer/Timer in platform tests | Already used in web platform tests |
| AnimatedPositioned | flutter widget | Implicit snap animation | Simpler than explicit AnimationController for this use case |
| SpringSimulation / AnimationController | flutter animation | Physics-based snap | When velocity-aware snap feel is required (Claude's discretion) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| AnimatedPositioned (implicit) | AnimationController + SpringSimulation (explicit) | Spring feels more natural but requires TickerProviderStateMixin and is more code |
| Stack + Positioned for drag | Overlay + OverlayEntry | Overlay is needed only if widget must float above Navigator; Stack is simpler and sufficient for example app |
| Manual .pubignore | .gitignore only | .pubignore overrides .gitignore per-directory; needed because spike/ and build/ may not be gitignored |

**Installation (example app):**
```bash
# No additional packages needed — example/pubspec.yaml uses path dependency:
# vlibras_flutter:
#   path: ../
```

---

## Architecture Patterns

### Recommended Project Structure
```
example/
├── lib/
│   ├── main.dart              # App entry: VLibrasController init, MaterialApp
│   ├── widgets/
│   │   └── draggable_avatar.dart  # DraggableAvatar: snap-to-corner logic
│   └── screens/
│       └── home_screen.dart   # TextField + Translate button + status indicator
├── web/
│   └── index.html             # Must include vlibras.js script tag
├── pubspec.yaml               # publish_to: none, depends on vlibras_flutter: path: ../
└── README.md                  # (optional, example-internal)

# Root plugin files to add/modify:
LICENSE                        # MIT license text — BLOCKING without this
README.md                      # Portuguese, installation + usage + platforms
CHANGELOG.md                   # Keep a Changelog, ## [0.1.0] - date
.pubignore                     # spike/, build/, web/vlibras/target/
pubspec.yaml                   # version, description, topics, platforms
```

### Pattern 1: Snap-to-Corner Floating Widget
**What:** A StatefulWidget wrapping VLibrasView in a `Stack + Positioned`. `GestureDetector.onPanUpdate` moves the widget. `onPanEnd` computes the nearest corner and animates to it using `AnimatedPositioned`.

**When to use:** When the floating widget must always remain on screen and snap to one of four corners after drag release.

**Example:**
```dart
// Source: Flutter docs - Animate a widget using a physics simulation
// https://docs.flutter.dev/cookbook/animation/physics-simulation
// Pattern: Stack + Positioned + GestureDetector + AnimatedPositioned

class DraggableAvatar extends StatefulWidget {
  const DraggableAvatar({super.key, required this.controller, this.size = 200});
  final VLibrasController controller;
  final double size;

  @override
  State<DraggableAvatar> createState() => _DraggableAvatarState();
}

class _DraggableAvatarState extends State<DraggableAvatar> {
  Offset _position = const Offset(16, 16); // top-left initial
  bool _animating = false;

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      _position += d.delta;
      _animating = false;
    });
  }

  void _onPanEnd(DragEndDetails d, Size screen) {
    final cx = _position.dx < screen.width / 2 ? 16.0 : screen.width - widget.size - 16;
    final cy = _position.dy < screen.height / 2 ? 16.0 : screen.height - widget.size - 16;
    setState(() {
      _position = Offset(cx, cy);
      _animating = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: (d) => _onPanEnd(d, screen),
      child: AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        left: _position.dx,
        top: _position.dy,
        width: widget.size,
        height: widget.size,
        child: VLibrasView(controller: widget.controller),
      ),
    );
  }
}
```

**Note:** `AnimatedPositioned` requires being a direct child of a `Stack`. The parent `Stack` must be positioned inside a full-screen widget (e.g., `Scaffold` body or full-screen `SizedBox`).

### Pattern 2: Example App Entry Point
**What:** `main.dart` creates and initializes `VLibrasController`, wraps the app in `MaterialApp`, and uses `ValueListenableBuilder` to display status.

**Example:**
```dart
// Standard Flutter plugin example pattern
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VLibrasExampleApp());
}

class VLibrasExampleApp extends StatefulWidget { ... }

class _VLibrasExampleAppState extends State<VLibrasExampleApp> {
  late final VLibrasController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VLibrasController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Pattern 3: VM-runnable VLibrasView Test (non-web)
**What:** Testing `buildMobileView` path (non-web) in VM via mock injection. `kIsWeb` is always false in VM tests, so `VLibrasView.build` calls `controller.buildMobileView()`. The mock platform must implement `buildView()` via dynamic dispatch.

**Key constraint:** `kIsWeb` cannot be overridden at runtime (it is a compile-time constant). VM tests automatically exercise the `!kIsWeb` branch — no override needed. The current `vlibras_view_test.dart` is `@TestOn('browser')` because it tests the web branch; new VM tests for `buildMobileView` must NOT have `@TestOn('browser')`.

```dart
// VM-runnable test: VLibrasView calls buildMobileView() on non-web
// No @TestOn annotation needed — runs in VM where kIsWeb == false
testWidgets('VLibrasView calls buildMobileView on non-web', (tester) async {
  final platform = MockVLibrasPlatform();
  // buildMobileView() uses dynamic dispatch: (_platform as dynamic).buildView()
  // MockVLibrasPlatform (via mocktail) does not have buildView() by default.
  // Solution: use a custom fake platform that returns a placeholder widget.
});
```

**Pitfall:** `MockVLibrasPlatform` (from `mocktail`) does not automatically expose `buildView()` since it is not in `VLibrasPlatform`. A `FakeMobilePlatform` stub (implements `VLibrasPlatform` + adds `buildView()`) is required for this test.

### Pattern 4: pub.dev pubspec.yaml for Web-Only Plugin
**What:** Correct declaration so pana registers this as a web-supported Flutter plugin.

```yaml
# pubspec.yaml (root, the plugin package)
name: vlibras_flutter
description: >-
  Plugin Flutter para exibir traduções de texto para LIBRAS usando o avatar
  3D VLibras. Suporta Flutter Web via HtmlElementView. (≈140 chars)
version: 0.1.0
homepage: https://github.com/example/vlibras_flutter

topics:
  - accessibility
  - libras
  - sign-language
  - vlibras

environment:
  sdk: '>=3.7.2 <4.0.0'
  flutter: '>=3.7.2'

dependencies:
  flutter:
    sdk: flutter
  web: ^1.0.0
  webview_flutter: ^4.10.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  mocktail: ^0.3.0

flutter:
  plugin:
    platforms:
      web:
        fileName: src/platform/web_platform.dart
  assets:
    - assets/vlibras.js
```

**Note on `web:` platform declaration:** The current `platforms: {}` (empty map) tells pana the plugin has NO platform support. Changing to `platforms: web: {}` or `platforms: web: fileName: ...` registers web support. For a non-federated Dart-only implementation, `fileName` pointing to the conditional-import entry is acceptable; however, since there is no `WebPlugin` class per se (just `createDefaultPlatform`), using an empty `web: {}` is the minimal correct form. Verify by running `flutter pub publish --dry-run` after the change.

### Pattern 5: Keep a Changelog Format
```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-27

### Added
- `VLibrasController` com ciclo de vida completo: `initialize()`, `translate()`, `dispose()`
- `VLibrasView` widget que renderiza o avatar VLibras em Flutter Web via `HtmlElementView`
- `VLibrasValue` e `VLibrasStatus` (6 estados: idle, initializing, ready, translating, playing, error)
- Suporte inicial exclusivo a Flutter Web
- App de exemplo com avatar flutuante snap-para-quinas e demonstração interativa
```

### Pattern 6: dartdoc Comment Style
**What:** `///` triple-slash comments on every public symbol. Per Effective Dart, the first sentence is a user-centric summary ending in a period. Parameter names are referenced in `[brackets]`.

**Source:** https://dart.dev/effective-dart/documentation

```dart
/// Returns a copy of this value with the given fields replaced.
///
/// Pass [clearError] as `true` to explicitly set [error] to `null`.
VLibrasValue copyWith({...})

/// Requests translation of [text] into LIBRAS.
///
/// Transitions: any state -> translating -> (ready | error)
Future<void> translate(String text) async { ... }
```

**Coverage required for pub.dev full score:** At least 20% of public API members. Best practice is 100% of exported public symbols. The current codebase already has substantial dartdoc on `VLibrasController`, `VLibrasValue`, `VLibrasStatus`, `VLibrasPlatform`, and `VLibrasView`. Review needed for completeness.

### Anti-Patterns to Avoid

- **`platforms: {}`** in pubspec: Tells pana the plugin supports no platforms. Must be `platforms: web: {}` at minimum.
- **Missing `LICENSE` file:** Hard blocker for `pub publish --dry-run`. Must exist with valid OSI-approved license text.
- **`Stack` without fixed-size child constraint for `AnimatedPositioned`:** `AnimatedPositioned` requires explicit `width`/`height` or both `left+right`/`top+bottom` pairs. Omitting these causes layout errors.
- **`@TestOn('browser')` on VM-targeted tests:** New tests for `buildMobileView` must NOT carry this annotation.
- **Path dependency in root pubspec:** The root `pubspec.yaml` (the plugin itself) cannot have path dependencies when published. Only `example/pubspec.yaml` uses `path: ../`.
- **Publishing `web/vlibras/target/` (Unity WebGL assets):** These can be hundreds of MB. Must be in `.pubignore`. VLibras licensing for redistribution is UNCLEAR (noted in STATE.md) — the `.pubignore` exclusion sidesteps the issue by not including them in the package.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Snap animation interpolation | Custom lerp/tween logic | `AnimatedPositioned` + `Curves.easeOutBack` | Built-in implicit animation handles frame scheduling, dispose safety |
| Mock platform for tests | Custom stub class per test | `MockVLibrasPlatform` (mocktail, already exists) | Already covers `VLibrasPlatform` interface |
| Fake player for web platform tests | New fake class | `FakePlayer` in `test/vlibras_web_platform_test.dart` (already exists) | Captures callbacks, fire() API, reusable |
| Keep a Changelog parsing | Script or tool | Manual CHANGELOG.md | Single entry v0.1.0 — no tooling needed |
| dartdoc generation locally | Custom script | `dart doc .` | Built into Dart SDK |

**Key insight:** This phase is predominantly wiring and polish. The test infrastructure (`FakePlayer`, `MockVLibrasPlatform`) is already production-quality. The animation system (`AnimatedPositioned`) is entirely within Flutter's standard library. Do not introduce new dependencies.

---

## Common Pitfalls

### Pitfall 1: `platforms: {}` gives zero platform credit on pana
**What goes wrong:** pana (pub.dev's analysis tool) does not detect web support; the package shows no supported platforms; pub points in the "Platform Support" category are lost.
**Why it happens:** Empty map `{}` means "no platforms declared." pana's auto-detection from imports may partially work, but explicit declaration is required for full score.
**How to avoid:** Change to `platforms: web: {}` (or add `fileName:` pointing to the conditional-import bridge file).
**Warning signs:** `flutter pub publish --dry-run` completes without error but pana score shows 0 in platform support.

### Pitfall 2: Missing LICENSE is a hard blocker
**What goes wrong:** `flutter pub publish --dry-run` and actual publish both fail with "No LICENSE file found."
**Why it happens:** pub.dev requires a LICENSE file in the package root.
**How to avoid:** Create `LICENSE` at project root with full MIT license text (name, year, standard MIT body).
**Warning signs:** `--dry-run` output includes "Error: No LICENSE file found."

### Pitfall 3: `web/vlibras/target/` blows package size limit
**What goes wrong:** If the Unity WebGL assets (~100 MB+ uncompressed) are included in the published package, `pub publish` will fail with a size error (100 MB gzip limit).
**Why it happens:** `dart pub publish` includes all files not excluded by `.gitignore` or `.pubignore`.
**How to avoid:** Add `web/vlibras/target/` to `.pubignore`. Also add `build/` and `spike/`.
**Warning signs:** `--dry-run` lists hundreds of files under `web/vlibras/target/`.

### Pitfall 4: `AnimatedPositioned` outside `Stack` throws
**What goes wrong:** `AnimatedPositioned` widgets must be direct children of `Stack`. Wrapping with an extra widget causes a `FlutterError` at runtime.
**Why it happens:** `AnimatedPositioned` relies on `Stack`'s layout protocol.
**How to avoid:** Structure as `Stack > AnimatedPositioned > GestureDetector > SizedBox > VLibrasView`.

### Pitfall 5: `kIsWeb` cannot be overridden for unit tests
**What goes wrong:** Attempting to test the `!kIsWeb` branch (non-web) from a browser context, or vice versa, fails silently.
**Why it happens:** `kIsWeb` is a compile-time constant (`const bool kIsWeb = identical(0, 0.0)`). VM tests always have `kIsWeb = false`.
**How to avoid:** New `buildMobileView` tests go in a VM-only file (no `@TestOn` annotation). The `vlibras_view_test.dart` with `@TestOn('browser')` remains for the web branch.

### Pitfall 6: `FakeMobilePlatform` needed for `buildMobileView` widget test
**What goes wrong:** `MockVLibrasPlatform` does not expose `buildView()` (it only implements `VLibrasPlatform`). `controller.buildMobileView()` uses `(_platform as dynamic).buildView()` — a dynamic call that fails if the mock doesn't have the method.
**Why it happens:** `mocktail` Mock only stubs declared interface methods.
**How to avoid:** Create a `FakeMobilePlatform` that `implements VLibrasPlatform` AND has a real `Widget buildView()` returning a `SizedBox` or `Placeholder`.

### Pitfall 7: `description` length outside 60–180 chars penalizes pub score
**What goes wrong:** Too short (<60 chars) or too long (>180 chars) descriptions reduce pub.dev scoring.
**Why it happens:** pana validates description length.
**How to avoid:** Current description "A Flutter plugin for displaying VLibras LIBRAS translations." is ~59 chars — one char short of the safe range. Must be expanded to ≥60 chars.

---

## Code Examples

Verified patterns from official sources:

### pubspec.yaml topics constraint (5 max, 2–32 chars, lowercase alphanumeric/hyphens)
```yaml
# Source: https://dart.dev/tools/pub/pubspec
# Max 5 topics. Each: 2-32 chars, lowercase, starts with a-z, ends alphanumeric.
topics:
  - accessibility      # 13 chars ✓
  - libras             # 6 chars ✓
  - sign-language      # 13 chars ✓
  - vlibras            # 7 chars ✓
# 4 topics — within limit
```

### example/pubspec.yaml structure
```yaml
# Source: Flutter docs - path dependency pattern
name: vlibras_flutter_example
description: Example app for vlibras_flutter plugin.
publish_to: none       # REQUIRED — prevents accidentally publishing the example

environment:
  sdk: '>=3.7.2 <4.0.0'
  flutter: '>=3.7.2'

dependencies:
  flutter:
    sdk: flutter
  vlibras_flutter:
    path: ../           # Path dependency to parent plugin
```

### MIT LICENSE template
```
MIT License

Copyright (c) 2026 [Author Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### .pubignore
```
# Source: https://dart.dev/tools/pub/publishing (.pubignore format = .gitignore format)
build/
spike/
web/vlibras/target/
.planning/
```

### New test: VLibrasView buildMobileView (VM-runnable)
```dart
// No @TestOn annotation — runs in VM where kIsWeb == false
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';

class FakeMobilePlatform implements VLibrasPlatform {
  // Implement all VLibrasPlatform methods as no-ops...
  Widget buildView() => const SizedBox.shrink(key: Key('vlibras-mobile-view'));
  @override Future<void> initialize() async {}
  @override Future<void> translate(String text) async {}
  // ... other methods
  @override void dispose() {}
}

testWidgets('VLibrasView renders mobile view on non-web', (tester) async {
  final controller = VLibrasController(platform: FakeMobilePlatform());
  await tester.pumpWidget(VLibrasView(controller: controller));
  expect(find.byKey(const Key('vlibras-mobile-view')), findsOneWidget);
  controller.dispose();
});
```

### New test: VLibrasWebPlatform initialize() idempotent
```dart
// Existing FakePlayer infrastructure in vlibras_web_platform_test.dart
test('initialize() is idempotent — second call returns same future', () async {
  final fp = FakePlayer();
  final p = VLibrasWebPlatform(onStatus: (_) {}, playerFactory: () => fp);
  p.attachToElement(null);

  final f1 = p.initialize();
  final f2 = p.initialize(); // second call
  fp.fire('load');

  await f1;
  await f2;
  // Both should complete without error (idempotent)
  p.dispose();
});
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `dart:html` for JS interop | `package:web` + `dart:js_interop` | Dart 3.x | Already applied in this project (web_platform.dart) |
| `/**/ ` block comments for dartdoc | `///` triple-slash | Dart style guide, current | Already applied; verify coverage |
| `.gitignore` only for publish exclusion | `.pubignore` supported | Dart 2.x+ | Must create `.pubignore` for spike/ and build/ dirs |
| `flutter: plugin: platforms: {}` | `flutter: plugin: platforms: web: {}` | Flutter plugin spec | Current pubspec has empty map — must fix |

**Deprecated/outdated in this project:**
- `platforms: {}` (empty): Does not register any platform support; pana penalizes this.
- `version: 0.0.1`: Semantically means "pre-alpha, unstable API." Must change to `0.1.0` for a first real release.
- `description: "A Flutter plugin for displaying VLibras LIBRAS translations."`: ~59 chars, just below the 60-char minimum for full pana score.

---

## Open Questions

1. **Exact `web:` platform declaration format for non-federated plugin**
   - What we know: `platforms: web: {}` registers web support. For federated plugins, `fileName:` points to the Dart implementation file.
   - What's unclear: For a non-federated plugin using conditional imports (not a web-specific class), whether `fileName:` is needed or whether `web: {}` alone satisfies pana.
   - Recommendation: Start with `web: {}` (minimal). If `--dry-run` warns about missing `fileName`, add `fileName: src/platform/web_platform.dart`.

2. **VLibras asset licensing for redistribution**
   - What we know: STATE.md flags "VLibras licensing for third-party redistribution via pub.dev is UNCLEAR." The `.pubignore` exclusion of `web/vlibras/target/` avoids including the Unity assets in the package.
   - What's unclear: Whether `assets/vlibras.js` (the JavaScript bridge) has redistribution restrictions.
   - Recommendation: Keep `vlibras.js` as a package asset (it is the integration bridge). The Unity WebGL target assets remain excluded. Flag for legal review before public publication.

3. **`FakeMobilePlatform` test compilation on web**
   - What we know: The new VM test for `buildMobileView` must not run in browser.
   - What's unclear: Whether having this test in the same file as browser-targeted tests causes issues.
   - Recommendation: Put `buildMobileView` tests in a dedicated `vlibras_view_vm_test.dart` with no `@TestOn` annotation, separate from the existing `@TestOn('browser')` file.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (bundled with Flutter SDK >=3.7.2) |
| Config file | None — flutter test discovers test/ automatically |
| Quick run command | `flutter test test/vlibras_controller_test.dart test/vlibras_web_platform_test.dart` |
| Full suite command | `flutter test` (excludes `@TestOn('browser')` files in VM) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PUB-01 | Example app runs on Flutter Web | manual/smoke | `flutter run -d chrome` in example/ | ❌ Wave 0 |
| PUB-02 | Zero undocumented public API warnings | static | `dart doc . 2>&1 \| grep "warning"` | ✅ (dart doc runs on existing files) |
| PUB-03 | --dry-run no blocking errors | smoke | `flutter pub publish --dry-run` | ✅ (command exists, currently fails) |
| PUB-04 | VLibrasWebPlatform timeout → emits error | unit | `flutter test test/vlibras_web_platform_test.dart` | ✅ (test already exists for timeout) |
| PUB-04 | VLibrasWebPlatform cancel-and-restart | unit | `flutter test test/vlibras_web_platform_test.dart` | ✅ (test already exists) |
| PUB-04 | VLibrasWebPlatform initialize() idempotent | unit | `flutter test test/vlibras_web_platform_test.dart` | ❌ Wave 0 |
| PUB-04 | VLibrasView buildMobileView renders mobile widget | widget | `flutter test test/vlibras_view_vm_test.dart` | ❌ Wave 0 |
| PUB-04 | VLibrasView onElementCreated sets id/style | widget | `flutter test --platform chrome test/vlibras_view_test.dart` | ❌ Wave 0 (browser) |

### Sampling Rate
- **Per task commit:** `flutter test test/vlibras_controller_test.dart test/vlibras_web_platform_test.dart`
- **Per wave merge:** `flutter test` (VM suite)
- **Phase gate:** `flutter pub publish --dry-run` + `flutter test` both green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/vlibras_view_vm_test.dart` — covers PUB-04 VLibrasView non-web branch with FakeMobilePlatform
- [ ] `test/vlibras_web_platform_test.dart` — add `initialize() idempotent` test (covers PUB-04)
- [ ] `example/` directory — does not exist yet (Wave 0 of PUB-01)
- [ ] `LICENSE` — does not exist (hard blocker for PUB-03)
- [ ] `README.md` — does not exist (hard blocker for PUB-03)
- [ ] `CHANGELOG.md` — does not exist (required for pub points)
- [ ] `.pubignore` — does not exist (risk of publishing spike/ and target/ assets)

---

## Sources

### Primary (HIGH confidence)
- https://dart.dev/tools/pub/pubspec — topics constraints (max 5, 2–32 chars), description length (60–180 chars), homepage field
- https://dart.dev/tools/pub/publishing — LICENSE requirement, README/CHANGELOG requirements, .pubignore format
- https://pub.dev/help/scoring — Six scoring categories including documentation (≥20% public API), platform support, static analysis
- https://dart.dev/effective-dart/documentation — `///` format, first-sentence conventions, parameter brackets
- https://docs.flutter.dev/packages-and-plugins/developing-packages — example app structure, web plugin pubspec format
- https://docs.flutter.dev/cookbook/animation/physics-simulation — SpringSimulation + AnimationController pattern
- Codebase read: `test/vlibras_web_platform_test.dart` — FakePlayer infrastructure confirmed reusable
- Codebase read: `lib/src/vlibras_controller.dart`, `vlibras_view.dart`, `vlibras_value.dart` — current dartdoc coverage assessed

### Secondary (MEDIUM confidence)
- https://api.flutter.dev/flutter/widgets/AnimatedPositioned-class.html — AnimatedPositioned for implicit position animation (confirmed via Flutter widget library)
- WebSearch: "Keep a Changelog" format — `## [version] - date` with `Added/Changed/Fixed` sections; confirmed by multiple pub.dev package changelogs

### Tertiary (LOW confidence)
- WebSearch result: `platforms: {}` empty map vs `web: {}` — exact pana scoring behavior for non-federated web plugin not officially documented; inferred from plugin documentation patterns. Needs verification with `--dry-run`.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; all libraries already in pubspec
- Architecture: HIGH — draggable snap pattern uses only standard Flutter widgets; pub.dev requirements from official docs
- Pitfalls: HIGH for pub.dev blockers (LICENSE, platforms declaration, package size); MEDIUM for AnimatedPositioned layout constraints (standard Flutter behavior)
- Test expansion: HIGH — existing FakePlayer/MockVLibrasPlatform infrastructure confirmed; VM vs browser split is well-understood

**Research date:** 2026-03-27
**Valid until:** 2026-06-27 (pub.dev requirements are stable; Flutter widget APIs are stable)
