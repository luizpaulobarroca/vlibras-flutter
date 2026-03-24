# Phase 3: Web Platform Integration - Research

**Researched:** 2026-03-24
**Domain:** Flutter Web plugin integration — dart:js_interop, HtmlElementView, vlibras-player-webjs, conditional imports, Completer-based async event bridging
**Confidence:** HIGH (all critical patterns verified against official Dart/Flutter docs and project spike findings)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **Self-hosted Player** (vlibras-player-webjs) — only option with programmatic translate()
- `vlibras.js` pre-compiled and committed to `web/` of the plugin (no build step at app-build time)
- Unity WebGL assets (`target/`) go in `web/` of the Flutter app — developer adds them manually
- `targetPath` fixed at `/vlibras/target` by convention (not a configurable parameter in v1)
- Translator API fixed at `https://vlibras.gov.br/api` (not configurable in v1)
- `index.html` of the app only needs `<script src="/vlibras/vlibras.js"></script>`; no additional HTML structure required
- Widget fills parent constraints (developer uses `SizedBox`, `Expanded`, etc. — Flutter standard)
- No built-in loading UI: during `initializing`, the area is blank/black; developer uses `VLibrasController.value` for their own indicator
- No built-in error overlay: developer uses `ValueListenableBuilder<VLibrasValue>` to build error UI
- Background transparency is the goal; if Unity WebGL doesn't support it, fallback is black (document as limitation)
- `VLibrasWebPlatform` receives a `void Function(VLibrasStatus)` callback in its constructor for state transitions
- `animation:play` callback -> `VLibrasStatus.playing`
- `animation:end` callback -> `VLibrasStatus.ready`
- `translate()` on the controller resolves (Future completes) when `animation:end` fires
- Timeout configurable in `VLibrasWebPlatform` (default ~30s); if `animation:end` doesn't arrive, emit error via callback
- Conditional import in `VLibrasController`: `if (dart.library.io) platform/unsupported_platform.dart` / web uses `platform/web_platform.dart`
- `VLibrasController()` without arguments works automatically in Flutter Web
- On unsupported platforms: throws `UnsupportedError` with message "vlibras_flutter suporta apenas Flutter Web em v1"
- `VLibrasWebPlatform` is an internal implementation detail — not exported in public API

### Claude's Discretion

- File structure of `VLibrasWebPlatform` and `VLibrasJs` inside `lib/src/`
- Names of internal JS interop variables
- How cancel-and-restart is implemented mechanically when `translate()` is called during playing (Phase 2 decided behavior; Phase 3 decides the mechanics)
- Exact value of default timeout (around 30s)

### Deferred Ideas (OUT OF SCOPE)

- Translation queue (translate() while playing -> enqueue) — DIFF-01, v2
- Configurable `targetPath` and `translatorUrl` via controller/view — v2 if demanded
- Android/iOS support (vlibras-mobile-android/ios SDKs via platform channels) — v2 (MOB-01, MOB-02)
- VLibras license investigation for pub.dev — explicitly reserved for Phase 4
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| WEB-01 | Plugin renders the VLibras avatar in Flutter Web using HtmlElementView | HtmlElementView.fromTagName confirmed; onElementCreated callback pattern established in spike |
| WEB-02 | translate() sends text to the web player VLibras and triggers avatar animation in the embedded view | vlibras-player-webjs exports `window.VLibras.Player` with `translate(text)` method (source confirmed); Completer pattern bridges animation:end event to Future resolution |
| CORE-02 | Developer can call translate(String text) on the controller to trigger LIBRAS animation | VLibrasController.translate() exists from Phase 2; Phase 3 wires the platform callback so translating -> playing -> ready transitions complete the Future |
</phase_requirements>

---

## Summary

Phase 3 connects the completed VLibrasController (Phase 2) to the real vlibras-player-webjs JavaScript player running inside a Flutter Web app. The core work is three files: `VLibrasView` (HtmlElementView widget), `VLibrasWebPlatform` (VLibrasPlatform implementation using dart:js_interop), and `VLibrasJs` (JS interop bindings). A conditional import in `VLibrasController._defaultPlatform()` replaces the current `UnimplementedError` stub with `VLibrasWebPlatform` on web and `UnsupportedError` on other platforms.

The critical technical decision (self-hosted Player vs CDN Widget) was resolved in context: only the standalone `vlibras-player-webjs` build provides a programmatic `translate()` API. The compiled `vlibras.js` (output of `npm run build` in vlibras-player-webjs) must be committed to `web/` of the plugin, and the Unity WebGL assets (`target/`) must be placed by the app developer at `web/vlibras/target/`. The `index.html` only needs one script tag.

The state callback bridge is the most nuanced pattern: `VLibrasWebPlatform.translate()` uses a `Completer<void>` that is completed by the `animation:end` JS event listener, with a `Timer` as a safety timeout. Cancel-and-restart (calling translate() during playing) is implemented by cancelling the in-flight `Completer` and `Timer` before starting a new one.

**Primary recommendation:** Implement `VLibrasView` + `VLibrasWebPlatform` + `VLibrasJs` as three separate files in `lib/src/`, wire the conditional import in `VLibrasController`, commit `vlibras.js` to `web/`, update the barrel export with `VLibrasView`.

---

## Standard Stack

### Core (all already in pubspec.yaml or built-in)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `dart:js_interop` | built-in (Dart 3.7+) | Type-safe JS interop — `@JS()`, extension types, `.toJS` | Official replacement for deprecated `dart:js`; WASM-compatible; confirmed in spike |
| `dart:js_interop_unsafe` | built-in (Dart 3.7+) | `callAsConstructor` for `new VLibras.Player(opts)` | Required for constructor calls not coverable with `dart:js_interop` alone; confirmed in spike |
| `package:web` | ^1.0.0 (already in spike pubspec) | Typed DOM access — `web.HTMLDivElement`, `web.HTMLScriptElement` | Official replacement for deprecated `dart:html`; WASM-compatible |
| `flutter` widgets | SDK | `HtmlElementView.fromTagName`, `ChangeNotifier` | Built-in; no additions needed |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `dart:async` | built-in | `Completer<void>`, `Timer` | Bridging JS event callbacks to Dart Futures; timeout implementation |
| `mocktail` | ^0.3.0 (already in dev_deps) | Mock `VLibrasPlatform` in tests | Unit tests for `VLibrasWebPlatform` callbacks (inject mock instead of real JS) |

### pubspec.yaml Changes Needed

```yaml
# ADD to dependencies (not yet present in main pubspec):
dependencies:
  flutter:
    sdk: flutter
  web: ^1.0.0   # <-- ADD THIS

# No new dev_dependencies needed
```

The `web: ^1.0.0` dependency is the only pubspec addition. Everything else is built-in.

---

## Architecture Patterns

### Recommended File Structure

```
lib/
├── vlibras_flutter.dart              # barrel — ADD VLibrasView export
└── src/
    ├── vlibras_value.dart            # DONE (Phase 2)
    ├── vlibras_platform.dart         # DONE (Phase 2)
    ├── vlibras_controller.dart       # MODIFY: replace _defaultPlatform() with conditional import
    ├── platform/
    │   ├── web_platform.dart         # NEW: VLibrasWebPlatform implements VLibrasPlatform
    │   └── unsupported_platform.dart # NEW: throws UnsupportedError
    ├── vlibras_js.dart               # NEW: dart:js_interop bindings (migrated from spike)
    └── vlibras_view.dart             # NEW: VLibrasView widget (HtmlElementView)

web/
└── vlibras/
    └── vlibras.js                    # NEW: pre-compiled vlibras-player-webjs bundle (committed)
    # target/ — NOT committed; app developer copies Unity WebGL assets here manually
```

### Pattern 1: Conditional Import for Platform Selection

**What:** Replace `VLibrasController._defaultPlatform()` static method with a conditional import that imports either `web_platform.dart` or `unsupported_platform.dart` at compile time.

**When to use:** Any time Dart code references `dart:js_interop` or `package:web`, it must be conditionally imported to avoid compile errors on mobile.

**Correct guard (Dart 3.x / WASM-compatible):** Use `dart.library.js_interop`, NOT `dart.library.html`. The `dart.library.html` guard is deprecated alongside `dart:html`.

```dart
// lib/src/vlibras_controller.dart — modified section
import 'platform/unsupported_platform.dart'
    if (dart.library.js_interop) 'platform/web_platform.dart';

// ...inside VLibrasController:
static VLibrasPlatform _defaultPlatform(void Function(VLibrasStatus) onStatus) {
  return createDefaultPlatform(onStatus);
}
```

```dart
// lib/src/platform/unsupported_platform.dart
import '../vlibras_platform.dart';
import '../vlibras_value.dart';

VLibrasPlatform createDefaultPlatform(void Function(VLibrasStatus) onStatus) {
  throw UnsupportedError(
    'vlibras_flutter suporta apenas Flutter Web em v1',
  );
}
```

```dart
// lib/src/platform/web_platform.dart
import '../vlibras_platform.dart';
import '../vlibras_value.dart';
import '../vlibras_web_platform.dart'; // the actual class

VLibrasPlatform createDefaultPlatform(void Function(VLibrasStatus) onStatus) {
  return VLibrasWebPlatform(onStatus: onStatus);
}
```

**Source:** Dart official docs — https://dart.dev/interop/js-interop/package-web

**Confidence:** HIGH — verified against official Dart migration guide.

### Pattern 2: VLibrasWebPlatform with Callback-to-Future Bridge

**What:** `VLibrasWebPlatform` implements `VLibrasPlatform`. It holds a `VLibrasPlayerInstance?` and a `Completer<void>?` for the in-flight translate. The `translate()` method: (1) cancels any in-flight completer (cancel-and-restart), (2) calls `_player!.translate(text)`, (3) creates a new `Completer<void>` and a `Timer` timeout, (4) returns the completer's future.

**When the events fire:**
- `animation:play` -> call `onStatus(VLibrasStatus.playing)`
- `animation:end` -> call `onStatus(VLibrasStatus.ready)`, then complete the completer
- Timeout fires before `animation:end` -> complete completer with error, call `onStatus` with error details

```dart
// Source: phase-01-findings.md §7 + spike/lib/vlibras_js.dart patterns
import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';

import '../vlibras_js.dart';
import '../vlibras_platform.dart';
import '../vlibras_value.dart';

class VLibrasWebPlatform implements VLibrasPlatform {
  VLibrasWebPlatform({
    required this.onStatus,
    this.timeout = const Duration(seconds: 30),
  });

  final void Function(VLibrasStatus) onStatus;
  final Duration timeout;

  VLibrasPlayerInstance? _player;
  Completer<void>? _translateCompleter;
  Timer? _timeoutTimer;

  // Called by VLibrasView.onElementCreated once the div is in the DOM tree
  void attachToElement(web.HTMLDivElement div) {
    final player = createVLibrasPlayer();
    _registerEvents(player);
    player.load(div as JSObject);
    _player = player;
  }

  void _registerEvents(VLibrasPlayerInstance player) {
    player.on('load', _onLoad.toJS);
    player.on('animation:play', _onPlay.toJS);
    player.on('animation:end', _onEnd.toJS);
    // NOTE: 'error' event is NOT confirmed in Player.js source.
    // If GlosaTranslator emits it, we can add it later (Phase 3 discretion).
  }

  void _onLoad() {
    // Player is ready — initialize() Future can complete
    // (see initialize() below)
  }

  void _onPlay() {
    onStatus(VLibrasStatus.playing);
  }

  void _onEnd() {
    onStatus(VLibrasStatus.ready);
    _completeTranslate(null);
  }

  void _completeTranslate(Object? error) {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    final c = _translateCompleter;
    _translateCompleter = null;
    if (c != null && !c.isCompleted) {
      if (error != null) {
        c.completeError(error);
      } else {
        c.complete();
      }
    }
  }

  @override
  Future<void> initialize() async {
    // initialize() resolves when 'load' event fires
    // Implementation note: use a Completer here too (similar pattern)
  }

  @override
  Future<void> translate(String text) async {
    // Cancel any in-flight translation (cancel-and-restart)
    _completeTranslate(Exception('cancelled'));
    final c = Completer<void>();
    _translateCompleter = c;
    _timeoutTimer = Timer(timeout, () {
      _completeTranslate(
        TimeoutException('animation:end not received', timeout),
      );
    });
    _player!.translate(text);
    return c.future;
  }

  @override
  void dispose() {
    _completeTranslate(Exception('disposed'));
    _player = null;
  }

  // pause, stop, resume, repeat, setSpeed delegate directly to _player
}
```

**Source:** Spike findings section 7 + dart:async Completer pattern.

**Confidence:** HIGH — Completer/Timer pattern is standard Dart; player events confirmed in phase-01-findings.md §2.

### Pattern 3: VLibrasView with HtmlElementView.fromTagName

**What:** `VLibrasView` is a `StatefulWidget` that creates an `HtmlElementView.fromTagName('div')` and wires the `onElementCreated` callback to `VLibrasWebPlatform.attachToElement()`.

**Key insight:** `VLibrasView` must initialize the controller on `initState` and pass the element reference to the platform. The controller's `initialize()` is called from `initState`.

```dart
// Source: spike/lib/main.dart onElementCreated pattern + official Flutter docs
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'vlibras_controller.dart';

class VLibrasView extends StatefulWidget {
  const VLibrasView({super.key, required this.controller});
  final VLibrasController controller;

  @override
  State<VLibrasView> createState() => _VLibrasViewState();
}

class _VLibrasViewState extends State<VLibrasView> {
  void _onElementCreated(Object element) {
    final div = element as web.HTMLDivElement;
    div.id = 'vlibras-player';
    div.style.width = '100%';
    div.style.height = '100%';
    // Attach player to the DOM element (this wires up the JS player)
    widget.controller.attachElement(div);
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      key: const Key('vlibras-player-view'),
      tagName: 'div',
      onElementCreated: _onElementCreated,
    );
  }
}
```

**Source:** Official Flutter docs — https://docs.flutter.dev/platform-integration/web/web-content-in-flutter; spike/lib/main.dart.

**Confidence:** HIGH — confirmed against official API and spike prototype.

### Pattern 4: VLibrasJs Bindings (migrated from spike)

**What:** The JS interop bindings in `lib/src/vlibras_js.dart` are a direct migration of `spike/lib/vlibras_js.dart` with the constructor options updated to use the locked `targetPath` and `translator` values.

```dart
// Source: spike/lib/vlibras_js.dart (confirmed correct for standalone player)
// Source: phase-01-findings.md §7 Approach B
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('VLibras')
external VLibrasNamespace get vLibras;

extension type VLibrasNamespace._(JSObject _) implements JSObject {
  // Player is exported by vlibras-player-webjs standalone build.
  // NOT available in CDN vlibras-plugin.js (confirmed dead end — Phase 1).
  external JSFunction get Player;
}

extension type VLibrasPlayerOptions._(JSObject _) implements JSObject {
  external factory VLibrasPlayerOptions({
    String translator,
    String targetPath,
  });
}

extension type VLibrasPlayerInstance._(JSObject _) implements JSObject {
  external void load(JSObject element);
  external void translate(String text);
  external void pause();
  external void stop();
  @JS('continue') external void resume();  // 'continue' is a Dart keyword
  external void repeat();
  external void setSpeed(double speed);
  external void on(String event, JSFunction callback);
  external void off(String event, JSFunction callback);
}

VLibrasPlayerInstance createVLibrasPlayer() {
  final options = VLibrasPlayerOptions(
    translator: 'https://vlibras.gov.br/api',
    targetPath: '/vlibras/target',  // locked convention from CONTEXT.md
  );
  return vLibras.Player.callAsConstructor(options) as VLibrasPlayerInstance;
}
```

**Confidence:** HIGH — bindings sourced from spike and confirmed against phase-01-findings.md §2 (Player methods/events all SOURCE-CONFIRMED).

### Anti-Patterns to Avoid

- **Using `dart.library.html` as conditional import guard:** Deprecated; not WASM-compatible. Use `dart.library.js_interop` instead.
- **Using `dart:html` or `dart:js`:** Deprecated since Dart 3.x. Must use `package:web` and `dart:js_interop`.
- **Calling `.toJS` on anything other than Dart closures/primitives:** Only Dart functions need `.toJS`. JS objects received from JS are already JS types.
- **Omitting `.toJS` on any Dart function passed to `player.on()`:** Causes runtime TypeError. Every callback to `player.on(event, fn)` MUST use `.toJS` — confirmed dead end from spike.
- **Exporting `VLibrasWebPlatform` from the barrel file:** It is an internal implementation detail. Only `VLibrasView`, `VLibrasController`, `VLibrasValue`, `VLibrasStatus` are public API.
- **Using `HtmlElementView` (old factory with `viewType`) instead of `HtmlElementView.fromTagName`:** The `fromTagName` factory is the modern, recommended approach for directly creating HTML elements.
- **Trying to use `window.VLibras.Player` from the CDN bundle (`vlibras-plugin.js`):** This is a confirmed dead end. The CDN only exports `VLibras.Widget`. Only the standalone `vlibras-player-webjs` build exports `VLibras.Player`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Callback-to-Future bridge | Custom wrapper class | `dart:async` `Completer<void>` | Standard Dart pattern; handles cancellation, error propagation, and timeout cleanly |
| Timeout on async JS events | Manual polling / `Future.delayed` | `Timer` + `Completer` | Timer is cancellable; no polling overhead |
| JS constructor invocation | Custom JS eval string | `JSFunction.callAsConstructor()` from `dart:js_interop_unsafe` | Already discovered in Phase 1; no alternative |
| DOM element type access | Custom JS interop wrappers | `package:web` typed DOM classes (`HTMLDivElement`, etc.) | Official typed DOM access; maintained by Dart team |

**Key insight:** The most dangerous hand-roll temptation is the event-to-Future bridge. Using `Completer` keeps cancel-and-restart clean — a new `translate()` call just abandons the old completer and starts fresh.

---

## Common Pitfalls

### Pitfall 1: `dart.library.html` vs `dart.library.js_interop` in Conditional Imports

**What goes wrong:** Using `if (dart.library.html) 'web_platform.dart'` compiles but fails for WASM targets and will eventually break as `dart:html` is phased out.

**Why it happens:** Historical pattern from pre-Dart-3.x days when `dart:html` was the standard.

**How to avoid:** Always use `if (dart.library.js_interop) 'web_platform.dart'` for the web branch. Verified against Dart's official migration guide (2025).

**Warning signs:** Compile warnings about `dart:html` availability; WASM build failures.

### Pitfall 2: Missing `.toJS` on Dart callbacks to `player.on()`

**What goes wrong:** Runtime TypeError at the JS boundary. The JS EventEmitter expects a JS function, but receives a Dart object.

**Why it happens:** Easy to forget `.toJS` when writing what looks like a regular Dart closure.

**How to avoid:** Every single argument to `player.on(event, ...)` is a `JSFunction`. Always write `player.on('load', _handler.toJS)` — the `.toJS` is never optional.

**Warning signs:** `TypeError` in browser console at the line calling `player.on()`.

### Pitfall 3: `callAsConstructor` Requires `dart:js_interop_unsafe`

**What goes wrong:** `undefined_method` analyzer error on `callAsConstructor`.

**Why it happens:** `callAsConstructor` is defined in `dart:js_interop_unsafe`, not `dart:js_interop`. Both imports are needed.

**How to avoid:** Always import both: `import 'dart:js_interop'; import 'dart:js_interop_unsafe';` in `vlibras_js.dart`.

**Warning signs:** Analyzer reports `undefined_method` on `callAsConstructor`.

### Pitfall 4: `player.load(div)` Must Be Called After `onElementCreated`

**What goes wrong:** Calling `player.load(element)` before the div is attached to the DOM. Unity WebGL may fail silently or display a blank canvas.

**Why it happens:** `onElementCreated` fires before the element is attached to the DOM. The player needs the element in the document flow.

**How to avoid:** The `onElementCreated` callback is fine for setup (setting id, styles), and calling `player.load(div)` from there should work because Unity bootstraps asynchronously after the element is attached. However, if issues arise, use a `Future.microtask` to defer `player.load()` until after the current frame.

**Warning signs:** Black/blank area where avatar should appear; no Unity WebGL loader visible.

### Pitfall 5: `Completer` Leak if `translate()` Never Gets `animation:end`

**What goes wrong:** If the VLibras player fails silently (network error, translation API down, gloss not found), `animation:end` may never fire, leaving a `Completer` open and the controller stuck in `translating` state.

**Why it happens:** The JS player's error handling is unclear — the `error` event is NOT confirmed to exist in Player.js source (only in GlosaTranslator, which may be different).

**How to avoid:** Always pair every `translate()` `Completer` with a `Timer` timeout (the ~30s default from CONTEXT.md). The `Timer` callback calls `_completeTranslate(TimeoutException(...))`, which propagates an error via the controller's catch block.

**Warning signs:** Controller stuck in `translating` state; user-visible UI freeze.

### Pitfall 6: `@JS('continue')` Workaround for `resume()`

**What goes wrong:** `external void continue()` fails to compile because `continue` is a Dart keyword.

**Why it happens:** The VLibras Player JS API has a method literally named `continue`.

**How to avoid:** Use `@JS('continue') external void resume();` — the `@JS` annotation renames the Dart method. Confirmed working in spike.

### Pitfall 7: `web/vlibras/vlibras.js` Path Convention

**What goes wrong:** Developer puts `vlibras.js` at `web/vlibras.js` (not in subdirectory), then the index.html script tag and `targetPath` constructor option become inconsistent.

**How to avoid:** Enforce the convention: plugin commits `web/vlibras/vlibras.js`. Developer's `index.html` uses `<script src="/vlibras/vlibras.js"></script>`. `targetPath` is fixed at `/vlibras/target`. All three are consistent under the `/vlibras/` prefix.

---

## Code Examples

Verified patterns from official sources and spike:

### VLibrasJs — `@JS('continue')` workaround

```dart
// Source: phase-01-findings.md §7 Dead End 7 + spike/lib/vlibras_js.dart line 36-37
extension type VLibrasPlayerInstance._(JSObject _) implements JSObject {
  @JS('continue')
  external void resume();  // 'continue' is a reserved Dart keyword
}
```

### Conditional Import — Dart 3.x WASM-safe guard

```dart
// Source: https://dart.dev/interop/js-interop/package-web
// Correct guard for web branch in Dart 3.x
import 'platform/unsupported_platform.dart'
    if (dart.library.js_interop) 'platform/web_platform.dart';
```

### HtmlElementView.fromTagName — official signature

```dart
// Source: https://api.flutter.dev/flutter/widgets/HtmlElementView/HtmlElementView.fromTagName.html
HtmlElementView.fromTagName(
  key: const Key('vlibras-player-view'),
  tagName: 'div',
  onElementCreated: (Object element) {
    final div = element as web.HTMLDivElement;
    div.style.width = '100%';
    div.style.height = '100%';
    // attach VLibras player here
  },
)
```

### Completer + Timer — translate() Future bridge

```dart
// Source: dart:async standard pattern
Future<void> translate(String text) async {
  // Cancel any in-flight translation first (cancel-and-restart)
  _cancelInFlight();

  final c = Completer<void>();
  _translateCompleter = c;
  _timeoutTimer = Timer(timeout, () {
    _completeWithError(TimeoutException('VLibras animation:end timeout', timeout));
  });

  _player!.translate(text);
  return c.future;
}

void _onAnimationEnd() {
  onStatus(VLibrasStatus.ready);
  _completeSuccess();
}
```

### index.html — minimal required script tag

```html
<!-- Source: CONTEXT.md locked decision + vlibras-player-webjs webpack build output -->
<!-- Place in web/index.html of the Flutter app (not the plugin) -->
<script src="/vlibras/vlibras.js"></script>
```

### JS interop — `callAsConstructor` with Player options

```dart
// Source: spike/lib/vlibras_js.dart + dart:js_interop_unsafe docs
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

VLibrasPlayerInstance createVLibrasPlayer() {
  final options = VLibrasPlayerOptions(
    translator: 'https://vlibras.gov.br/api',
    targetPath: '/vlibras/target',
  );
  return vLibras.Player.callAsConstructor(options) as VLibrasPlayerInstance;
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `dart:js` | `dart:js_interop` + `dart:js_interop_unsafe` | Dart 3.0 (2023) | Old API not WASM-compatible; new API is type-safe with extension types |
| `dart:html` | `package:web` | Dart 3.x (2023-2024) | `dart:html` deprecated; `package:web` is WASM-compatible |
| `if (dart.library.html)` conditional guard | `if (dart.library.js_interop)` | Dart 3.x migration (2024) | Old guard tied to deprecated `dart:html` |
| `HtmlElementView(viewType: '...')` + `platformViewRegistry.registerViewFactory` | `HtmlElementView.fromTagName(tagName: '...')` | Flutter ~3.10+ | `fromTagName` avoids viewType registry boilerplate for simple element creation |
| `package:js` annotations (`@JS`, `@anonymous`) | `dart:js_interop` extension types | Dart 3.0 (2023) | `package:js` deprecated; extension types are more ergonomic and type-safe |

**Deprecated/outdated patterns this project must NOT use:**
- `dart:html` / `import 'dart:html'` — compiler error on WASM targets
- `dart:js` / `package:js` — deprecated
- `if (dart.library.html)` conditional import guard — tied to deprecated library
- CDN `vlibras-plugin.js` for `VLibras.Player` — confirmed absent (Phase 1 spike)

---

## vlibras-player-webjs Build Facts

| Fact | Detail | Confidence |
|------|--------|------------|
| Build tool | webpack (`npm run build`) | HIGH — webpack.config.js confirmed in repo |
| Output file | `vlibras.js` in `./build/` | HIGH — webpack.config.js output filename confirmed |
| Entry point | `./src/index.js` | HIGH — webpack.config.js |
| Global export | `window.VLibras = VLibras; module.exports = VLibras;` | HIGH — src/index.js inspected |
| VLibras.Player export | `VLibras.Player` references imported Player class | HIGH — src/index.js inspected |
| Unity WebGL assets | Copied from `src/target/` to `target/` in build output | HIGH — copy-webpack-plugin in config |
| License | LGPLv3 | HIGH — GitHub repo LICENSE file |
| Avatar asset license | UNCLEAR | LOW — not documented; Phase 4 issue |

**What the plugin must commit:** `web/vlibras/vlibras.js` (the webpack output). The `target/` directory (~100MB+ Unity WebGL assets) is NOT committed to the plugin — the developer copies it to `web/vlibras/target/` in their own app.

---

## Open Questions

1. **`error` event in GlosaTranslator**
   - What we know: Player.js source does not emit an `error` event directly; GlosaTranslator (separate class) is the network call layer.
   - What's unclear: Does GlosaTranslator forward an error event up to the Player's EventEmitter?
   - Recommendation: Do NOT register an `error` event listener in Phase 3. Rely on the timeout mechanism to handle silent failures. Document in code with a TODO to investigate GlosaTranslator source.

2. **Unity WebGL transparent background**
   - What we know: Unity WebGL supports transparent canvas via the `backgroundColor: 0x00000000` config. Whether vlibras-player-webjs enables this option is not confirmed.
   - What's unclear: Is the Player constructor or config file setting this option?
   - Recommendation: Implement with default (black background). If transparent is desired, inspect the Unity WebGL build configuration during Phase 3 implementation. CONTEXT.md locked decision: "if Unity WebGL doesn't support it, fallback is black — document as limitation."

3. **`initialize()` completion event**
   - What we know: The `load` event fires when Unity WebGL finishes loading.
   - What's unclear: Does `load` fire before or after the Unity player is fully interactive?
   - Recommendation: Use `load` event to complete the `initialize()` Completer. If the player turns out to need additional time, add a brief `Future.delayed` before completing.

4. **`player.load(element)` timing relative to `onElementCreated`**
   - What we know: `onElementCreated` fires after the div is created but before it is attached to the DOM. `player.load(element)` needs to render WebGL into the element.
   - What's unclear: Does Unity WebGL require the element to already be in the document (attached to DOM) before `load()` is called, or does it handle deferred attachment?
   - Recommendation: Call `player.load(div)` directly in `onElementCreated`. If the Unity player displays blank, wrap in `Future.microtask(() => player.load(div))` to defer until after DOM attachment.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (Flutter SDK bundled) |
| Config file | none — `flutter test` discovers `test/` automatically |
| Quick run command | `flutter test test/vlibras_controller_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| WEB-01 | VLibrasView renders HtmlElementView with Key('vlibras-player-view') | widget (web only) | `flutter test test/vlibras_view_test.dart --platform chrome` | ❌ Wave 0 |
| WEB-02 | translate() sends text to web player; state transitions translating -> playing -> ready | unit (mock platform) | `flutter test test/vlibras_controller_test.dart` | ✅ exists (needs new tests) |
| CORE-02 | controller.translate('text') completes when animation:end fires | unit (mock platform) | `flutter test test/vlibras_controller_test.dart` | ✅ exists (needs new tests) |
| CORE-02 | controller state transitions idle -> initializing -> ready on initialize() | unit | `flutter test test/vlibras_controller_test.dart` | ✅ (29 passing tests cover this) |
| CORE-02 | translate() while playing re-enters translating (cancel-and-restart) | unit | `flutter test test/vlibras_controller_test.dart` | ✅ (covered in Phase 2) |

**Note on WEB-01:** `HtmlElementView.fromTagName` is only available in Flutter Web. Widget tests for VLibrasView must run with `--platform chrome`. Unit tests for `VLibrasWebPlatform` can use mock injection and do NOT require a browser. The existing `vlibras_controller_test.dart` tests remain platform-agnostic because they inject `MockVLibrasPlatform`.

### Sampling Rate

- **Per task commit:** `flutter test test/vlibras_controller_test.dart`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/vlibras_view_test.dart` — WEB-01 widget test (HtmlElementView renders with correct key)
- [ ] `test/vlibras_web_platform_test.dart` — WEB-02 unit test with mock JS player (state machine transitions via callback injection)

*(Existing `test/vlibras_controller_test.dart` with 29 tests covers CORE-02 behaviors. New tests extend coverage for playing state transitions pushed by platform callbacks.)*

---

## Sources

### Primary (HIGH confidence)

- `spike/lib/vlibras_js.dart` — JS interop bindings confirmed for vlibras-player-webjs Player
- `.planning/research/phase-01-findings.md` — empirical spike findings: Player methods/events (SOURCE-CONFIRMED), CDN dead ends, confirmed patterns
- https://api.flutter.dev/flutter/widgets/HtmlElementView/HtmlElementView.fromTagName.html — official API signature for `fromTagName` + `onElementCreated`
- https://docs.flutter.dev/platform-integration/web/web-content-in-flutter — embedding web content patterns
- https://dart.dev/interop/js-interop/package-web — `dart.library.js_interop` conditional import guard (WASM-safe)
- `dart:async` `Completer` + `Timer` — standard Dart library, no external source needed
- https://github.com/spbgovbr-vlibras/vlibras-player-webjs webpack.config.js — output file `vlibras.js`, copy-webpack-plugin for `target/` assets

### Secondary (MEDIUM confidence)

- https://github.com/spbgovbr-vlibras/vlibras-player-webjs src/index.js — `window.VLibras = VLibras` global export pattern; `VLibras.Player` property confirmed
- https://dart.dev/language/libraries — conditional import syntax confirmation

### Tertiary (LOW confidence)

- Unity WebGL transparent background support — inferred from Unity docs, not confirmed against vlibras-player-webjs build config
- `error` event from GlosaTranslator — unresolved from Phase 1; not in Player.js directly

---

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all libraries are built-in (dart:js_interop, dart:js_interop_unsafe, package:web) or already in pubspec; confirmed in spike
- Architecture: HIGH — conditional import pattern verified against official Dart docs; HtmlElementView.fromTagName verified against official Flutter API; Completer/Timer is standard Dart
- JS bindings: HIGH — migrated directly from spike code that was compiled and ran (errors were about CDN content, not binding correctness)
- Pitfalls: HIGH — all major pitfalls were discovered empirically in Phase 1 spike or verified against official docs
- Open questions: LOW confidence items are explicitly flagged and have fallback strategies documented

**Research date:** 2026-03-24
**Valid until:** 2026-06-24 (stable APIs — dart:js_interop, package:web, HtmlElementView are stable; 90-day validity)
