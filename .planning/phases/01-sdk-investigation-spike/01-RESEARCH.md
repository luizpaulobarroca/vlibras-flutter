# Phase 1: SDK Investigation Spike - Research

**Researched:** 2026-03-23
**Domain:** VLibras Web Player JS API + Flutter Web HtmlElementView + WebGL/CanvasKit conflict investigation
**Confidence:** MEDIUM (VLibras API partially reverse-engineered from source; Flutter/Dart patterns HIGH)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Spike artifacts:**
- Code is disposable — proof of concept, not the base for Phase 3
- Lives in `spike/` at repo root, separate from plugin code
- Deleted after Phase 1 completes (findings remain in the document)
- Created with standard `flutter create` with Web support enabled
- Includes minimal README with run commands (`flutter run -d chrome`)
- Includes basic integration tests running only in interactive Chrome (not headless)

**Findings documentation:**
- Primary document: `.planning/research/phase-01-findings.md`
- Includes Dart snippets using `dart:js_interop` showing how to call each discovered JS function
- Records dead ends (what was tried and didn't work + reason)
- Includes a dedicated VLibras licensing section for redistribution via pub.dev
- Document structure: API surface (init/translate/events), URLs/CDN, CSP/CORS, dead ends, license

**Embedding approach:**
- **First approach**: HtmlElementView + dart:html — create `<div>` via dart:html, inject VLibras script, register as HtmlElementView
- **Plan B** (if HtmlElementView fails): iframe + postMessage for Dart-to-player communication
- Player loaded via public CDN first (official vlibras.gov.br URLs)
- Test only the most recent version available on the CDN
- Use **dart:js_interop** (Dart 3+), NOT classic dart:js

**Investigation scope:**
- Map the explicit init flow (whether `VLibras.init()` exists or it auto-loads)
- Map all available state callbacks/events: onStarted, onCompleted, onError and similar
- Investigate Unity WebGL player vs Flutter Web CanvasKit implications (potential WebGL context conflict)
- Verify CSP and CORS requirements needed in Flutter Web's `index.html`
- Prototype basic `@JS` annotation structure for discovered functions

### Claude's Discretion

- Internal structure of the spike README
- Which specific integration tests to implement (beyond basic loading verification)
- Details of `@JS` struct in the spike (can be simple, it's disposable)

### Deferred Ideas (OUT OF SCOPE)

- None — discussion stayed within phase scope
</user_constraints>

---

## Summary

This phase is a pure technical spike — no production code, only validated knowledge. The three unknowns that block production work are: (1) whether the VLibras web player can be embedded inside Flutter's HtmlElementView at all, (2) exactly what JS API surface is needed to drive the player programmatically, and (3) what the VLibras license means for pub.dev redistribution.

The VLibras web player is a Unity WebGL application served from vlibras.gov.br's CDN. The widget layer (`vlibras-plugin.js`) wraps the player and exposes a `window.VLibras.Widget` constructor, while the underlying `vlibras-player-webjs` library exposes a `Player` class with EventEmitter-based callbacks. The critical risk is that Flutter Web CanvasKit uses WebGL for its own rendering, and Unity WebGL also needs a WebGL context — browsers limit active WebGL contexts (typically 8-16), and context switching between two competing WebGL users is a documented source of rendering artifacts. This must be empirically confirmed or refuted.

The modern Dart approach (Dart 3+) for web interop is `dart:js_interop` + `package:web`, replacing the deprecated `dart:html` / `dart:js`. Integration tests for web use the `integration_test` package with `flutter drive --driver ... -d chrome` (not headless for this spike, per locked decisions).

**Primary recommendation:** Build the spike using `HtmlElementView.fromTagName('div', onElementCreated: ...)`, inject the VLibras script via `package:web`'s `HTMLScriptElement`, and call `window.VLibras.Player` directly (not Widget) to avoid the floating-button UI. If WebGL conflicts appear, fall back to the iframe + postMessage plan B.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter Web | current stable | Platform; HtmlElementView is web-only | Required |
| dart:js_interop | Dart 3.3+ (SDK bundled) | Type-safe JS interop for Dart 3 + WASM | Official replacement for dart:js |
| package:web | ^1.x | Dart bindings for browser DOM APIs | Official replacement for dart:html |
| integration_test | SDK bundled | Flutter integration tests on Chrome | Official Flutter test framework |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| chromedriver | match Chrome version | Drives Chrome for integration tests | Required for `flutter drive -d chrome` |
| VLibras CDN (vlibras-plugin.js) | latest at vlibras.gov.br/app | Delivers the player | Load from CDN in spike; avoid local build |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| HtmlElementView.fromTagName | platformViewRegistry.registerViewFactory | registerViewFactory offers more control but fromTagName is simpler for spike |
| dart:js_interop + package:web | dart:html + dart:js (legacy) | Legacy APIs are deprecated as of Dart 3.7 (Feb 2025); not WASM-compatible |
| Direct Player API (vlibras-player-webjs) | Widget API (window.VLibras.Widget) | Widget adds floating-button UI not wanted; Player gives raw control |

**Installation:**
```bash
# In spike/ directory after flutter create:
flutter pub add web

# pubspec.yaml dev_dependencies (already present from flutter create):
# integration_test:
#   sdk: flutter
# flutter_test:
#   sdk: flutter
```

---

## Architecture Patterns

### Recommended Spike Project Structure
```
spike/
├── lib/
│   └── main.dart              # Flutter app entry + HtmlElementView scaffold
├── web/
│   └── index.html             # CSP headers + optional VLibras CDN script tag
├── integration_test/
│   └── vlibras_load_test.dart # Verifies avatar loads and translate fires
├── test_driver/
│   └── integration_test.dart  # Minimal driver: integrationDriver()
└── README.md                  # flutter run -d chrome, flutter drive commands
```

### Pattern 1: Script Injection via package:web (Dart 3+)

**What:** Inject the VLibras CDN script into document.head programmatically from Dart when the HtmlElementView element is created.

**When to use:** When you cannot or do not want to hard-code the script tag in index.html (lazy loading, or keeping spike index.html clean).

**Example:**
```dart
// Source: https://dart.dev/interop/js-interop/package-web
import 'package:web/web.dart' as web;
import 'dart:js_interop';

void injectVLibrasScript({required void Function() onLoad}) {
  final script = web.HTMLScriptElement()
    ..src = 'https://vlibras.gov.br/app/vlibras-plugin.js';
  script.addEventListener(
    'load',
    (web.Event _) {
      onLoad();
    }.toJS,
  );
  web.document.head?.append(script);
}
```

**Simpler alternative for spike:** Add script tag directly to `web/index.html` before `</body>`, avoiding async injection complexity.

### Pattern 2: HtmlElementView.fromTagName for Custom Container

**What:** Create a `<div>` as the container for VLibras player, then initialize the player inside it.

**When to use:** When you need Flutter's layout system to reserve space for the player.

**Example:**
```dart
// Source: https://api.flutter.dev/flutter/widgets/HtmlElementView-class.html
import 'package:web/web.dart' as web;

Widget buildPlayerView() {
  return SizedBox(
    width: 320,
    height: 480,
    child: HtmlElementView.fromTagName(
      tagName: 'div',
      onElementCreated: (Object element) {
        final div = element as web.HTMLDivElement;
        div.id = 'vlibras-container';
        div.style.width = '100%';
        div.style.height = '100%';
        // VLibras Player init happens here or after script loads
        _initVLibrasPlayer(div);
      },
    ),
  );
}
```

### Pattern 3: dart:js_interop @JS Bindings for VLibras Player API

**What:** Declare Dart extension types that mirror the VLibras JS API surface.

**When to use:** To call JS methods from Dart with type safety.

**Example (sketch — exact method signatures to be confirmed empirically during spike):**
```dart
// Source: https://dart.dev/interop/js-interop/usage
import 'dart:js_interop';

// Access VLibras.Player from the global window namespace
// (window.VLibras is set when vlibras-plugin.js loads)
@JS('VLibras.Player')
external JSFunction get vLibrasPlayerConstructor;

extension type VLibrasPlayerInstance._(JSObject _) implements JSObject {
  external void load(JSObject element);
  external void translate(String text);
  external void play(String glosa);
  external void pause();
  external void stop();
  external void setSpeed(double speed);
  // EventEmitter: player.on('load', callback)
  external void on(String event, JSFunction callback);
}
```

NOTE: These signatures are derived from source inspection and must be validated empirically during the spike.

### Pattern 4: Integration Test on Chrome (non-headless)

**What:** Verify VLibras player loads and translate fires using the `integration_test` package.

**When to use:** As the formal verification artifact for Phase 1 success criteria.

**test_driver/integration_test.dart:**
```dart
import 'package:integration_test/integration_test_driver.dart';
Future<void> main() => integrationDriver();
```

**integration_test/vlibras_load_test.dart:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('VLibras player container renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    // Wait for async player load (Unity WebGL can take several seconds)
    await tester.pumpAndSettle(const Duration(seconds: 20));
    expect(find.byKey(const Key('vlibras-player-view')), findsOneWidget);
  });
}
```

**Run command:**
```bash
# Start ChromeDriver first (match your installed Chrome version):
chromedriver --port=4444

# Then in a second terminal:
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/vlibras_load_test.dart \
  -d chrome
```

### Anti-Patterns to Avoid

- **Using `dart:js` or `dart:html` directly:** These are deprecated as of Dart 3.7. Use `dart:js_interop` + `package:web`.
- **Using `window.VLibras.Widget` for the spike:** The Widget adds a floating button UI and auto-triggers UI flows. Use `window.VLibras.Player` directly for programmatic control.
- **Ignoring onElementCreated timing:** The VLibras Player's `load()` call must happen after the container div is in the DOM. Do not call `load()` before the element is attached.
- **Assuming the HTML renderer is available:** As of Flutter 3.24+, CanvasKit is the default and the HTML renderer is being deprecated. The spike must work on CanvasKit.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Browser DOM manipulation | Custom JS interop layer | package:web | Already typed; WASM-compatible; official Dart solution |
| JS function bindings | Manual string-based interop | dart:js_interop @JS extension types | Type-safe; works with WASM compilation |
| Integration test runner | Custom Selenium/Playwright setup | integration_test + flutter drive | Native Flutter; same test API as widget tests |
| VLibras 3D avatar rendering | DIY LIBRAS animation | VLibras CDN player (Unity WebGL) | Avatar assets are proprietary; this is the whole point |

**Key insight:** The VLibras player is a Unity WebGL build — it manages its own WebGL context, shaders, and animation. There is no way to re-implement it. The spike's job is only to discover whether Flutter's host page can coexist with Unity's WebGL without context conflicts.

---

## Common Pitfalls

### Pitfall 1: WebGL Context Exhaustion (The Critical Risk)

**What goes wrong:** Flutter Web CanvasKit creates its own WebGL context to render the Flutter UI. Unity WebGL (VLibras player) creates another WebGL context for the 3D avatar. Browsers cap active WebGL contexts at 8-16. When both are active simultaneously, errors like "bindTexture: object does not belong to this context" appear and rendering fails.

**Why it happens:** Each HtmlElementView in CanvasKit mode causes Flutter to create an additional canvas overlay. With a Unity WebGL player embedded, both Flutter and Unity compete for GL context slots and may inadvertently conflict on texture operations.

**How to avoid:** During the spike, explicitly check browser console for WebGL errors. If HtmlElementView causes conflicts, Plan B (iframe + postMessage) isolates Unity's GL context in a separate browsing context where it cannot interfere with CanvasKit.

**Warning signs:** Console errors containing "WebGL", "context", "bindTexture", blank or black avatar area, or Flutter UI corruption when the player initializes.

### Pitfall 2: VLibras Script Loads Asynchronously

**What goes wrong:** The VLibras script (`vlibras-plugin.js`) fetches the Unity WebGL build from the CDN. There is a multi-step async load: JS parses, Unity build downloads, then player initializes. Calling `player.translate()` before the `'load'` event fires returns silently with no animation.

**Why it happens:** Unity WebGL loads are large (multiple megabytes of WASM and JS). The `Player` constructor is synchronous but the player is not usable until the `load` event fires.

**How to avoid:** Always gate `translate()` calls behind the `load` event listener on the Player. In the spike, add a visible loading indicator until the player emits `load`.

**Warning signs:** `translate()` called but no animation; no error thrown (silent failure).

### Pitfall 3: CSP Blocks VLibras CDN

**What goes wrong:** Flutter Web's generated `index.html` has no CSP by default. If a strict CSP is added (common in enterprise hosting), it must allow:
- `script-src 'self' https://vlibras.gov.br 'wasm-unsafe-eval'` (for CanvasKit's WASM; `'wasm-unsafe-eval'` is the safer alternative to `'unsafe-eval'` for WASM-only scenarios)
- `connect-src https://vlibras.gov.br` (for player CDN asset fetches)
- Unity WebGL may internally require broader script execution permissions

**Why it happens:** Flutter CanvasKit itself requires `'wasm-unsafe-eval'` (or the broader `'unsafe-eval'`). VLibras player loads additional assets cross-origin. Most deployments have no CSP, but the spike should document requirements explicitly.

**How to avoid:** For the spike, leave `index.html` without a strict CSP. Document what would be needed in the findings document.

**Warning signs:** Console errors: "Refused to execute script", "Content Security Policy", execution restrictions.

### Pitfall 4: VLibras DOM Structure Requirements

**What goes wrong:** The default `window.VLibras.Widget` expects a specific DOM structure with `vw`, `vw-access-button`, and `vw-plugin-wrapper` divs. If those are missing when Widget is initialized, the player may silently fail to render.

**Why it happens:** The Widget was designed for full-page injection on gov.br websites, not for embedding in a custom container.

**How to avoid:** Use the underlying `VLibras.Player` directly (from `vlibras-player-webjs`) rather than Widget, which skips the floating-button DOM requirement. Load player.js directly OR reverse-engineer the minimal DOM structure.

**Warning signs:** Widget initializes but avatar never appears; console shows DOM-related errors.

### Pitfall 5: dart:html vs package:web Confusion

**What goes wrong:** Many Flutter web examples online use `dart:html` (deprecated). Mixing `dart:html` and `package:web` types causes type errors at runtime.

**Why it happens:** Dart 3.3+ introduced `package:web` to replace `dart:html`. As of Dart 3.7 (Feb 2025), old JS interop is formally deprecated.

**How to avoid:** Use only `package:web` and `dart:js_interop`. Never import `dart:html` in the spike.

**Warning signs:** Compile warnings about deprecated APIs; type cast failures on DOM elements.

---

## Code Examples

Verified patterns from official sources:

### Script Element Injection (package:web)
```dart
// Source: https://dart.dev/interop/js-interop/package-web
import 'package:web/web.dart' as web;
import 'dart:js_interop';

void injectScript(String src, void Function() onLoaded) {
  final script = web.HTMLScriptElement()
    ..src = src;
  script.addEventListener(
    'load',
    ((web.Event _) => onLoaded()).toJS,
  );
  web.document.head!.append(script);
}
```

### HtmlElementView.fromTagName
```dart
// Source: https://api.flutter.dev/flutter/widgets/HtmlElementView-class.html
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

Widget buildPlayerView() {
  return SizedBox(
    width: 320,
    height: 480,
    child: HtmlElementView.fromTagName(
      tagName: 'div',
      onElementCreated: (Object element) {
        final div = element as web.HTMLDivElement;
        div.id = 'vlibras-player';
        div.style.width = '100%';
        div.style.height = '100%';
        // Initialize player after element is in DOM
      },
    ),
  );
}
```

### dart:js_interop Extension Type (Dart 3+ pattern)
```dart
// Source: https://dart.dev/interop/js-interop/usage
import 'dart:js_interop';

// EventEmitter-style on() method (used by VLibras Player)
extension type VLibrasEventEmitter._(JSObject _) implements JSObject {
  external void on(String event, JSFunction handler);
  external void off(String event, JSFunction handler);
}

// Usage: register load callback
void whenPlayerReady(VLibrasEventEmitter player, void Function() onReady) {
  player.on('load', onReady.toJS);
}
```

### package:web: DOM Attribute Setting
```dart
// Source: https://dart.dev/interop/js-interop/package-web
// Key difference from dart:html: use .toJS for string args to setAttribute
element.setAttribute('data-custom', '123');
// package:web uses the original WebIDL names (no Dart renames)
```

---

## VLibras JS API Surface (Discovered)

This section is the primary reference for writing `@JS` bindings during the spike.

### CDN URLs
| Resource | URL |
|----------|-----|
| Widget script (primary entry point) | `https://vlibras.gov.br/app/vlibras-plugin.js` |
| App base path (rootPath) | `https://vlibras.gov.br/app` |
| Personalization config | `https://vlibras.gov.br/config/configs.json` |

### Global Namespace After Script Load
```
window.VLibras = {
  Player: <PlayerClass>,   // From vlibras-player-webjs (raw control)
  Widget: <WidgetClass>    // Wraps Player + floating UI (NOT recommended for spike)
}
```

### Player Constructor (from src/Player.js)
```javascript
const player = new VLibras.Player({
  translator: 'https://vlibras.gov.br/api',
  targetPath: 'target',
  onLoad: callbackFn   // optional; same as player.on('load', fn)
})

// Attach to a DOM container element:
player.load(domElement)
```

### Player Public Methods (confirmed via source inspection — validate empirically)
| Method | Signature | Purpose |
|--------|-----------|---------|
| `load` | `load(element)` | Attach player to DOM element; triggers Unity WebGL init |
| `translate` | `translate(text, options?)` | Send text for sign language translation |
| `play` | `play(glosa, options?)` | Play pre-fetched gloss data |
| `pause` | `pause()` | Pause playback |
| `stop` | `stop()` | Stop playback |
| `continue` | `continue()` | Resume paused playback |
| `repeat` | `repeat()` | Replay current animation |
| `setSpeed` | `setSpeed(speed)` | Adjust speed (1.0 = normal) |
| `setPersonalization` | `setPersonalization(config)` | Avatar customization |
| `changeAvatar` | `changeAvatar(name)` | Switch avatar: "icaro", "hosana", "guga" |
| `toggleSubtitle` | `toggleSubtitle()` | Show/hide subtitles |
| `setRegion` | `setRegion(code)` | Regional dictionary (e.g., "BR") |
| `playWellcome` | `playWellcome()` | Trigger welcome animation |

### Player Events (EventEmitter — use `player.on(event, callback)`)
| Event | When Fired |
|-------|-----------|
| `load` | Player ready (Unity WebGL fully loaded) |
| `translate:start` | Translation request sent |
| `translate:end` | Translation data received |
| `animation:play` | Animation begins |
| `animation:pause` | Animation paused |
| `animation:end` | Animation completes |
| `animation:progress` | Progress update during playback |
| `gloss:start` | Sign animation starts |
| `gloss:end` | Sign animation ends |
| `error` | Translation or network error |
| `stateChange` | Player state changed (playing/paused/loading) |

**CONFIDENCE:** MEDIUM — derived from source file inspection via GitHub, not official API docs. Must be validated empirically during spike execution.

### Widget Constructor (reference only — NOT recommended for spike)
```javascript
new window.VLibras.Widget({
  rootPath: 'https://vlibras.gov.br/app',
  avatar: 'icaro',       // 'icaro' | 'hosana' | 'guga' | 'random'
  position: 'R',         // TL | T | TR | R | BR | B | BL | L
  opacity: 1,            // 0 to 1
  personalization: null  // URL to JSON config
})
```

---

## VLibras License Analysis (pub.dev Blocker)

| Component | License |
|-----------|---------|
| vlibras-web-browsers (Widget) | LGPLv3 |
| vlibras-player-webjs | LGPLv3 |
| vlibras-translator-api | LGPLv3 |

**LGPLv3 implications for a Flutter plugin that loads VLibras from CDN (not bundled):**

The plugin would NOT bundle the LGPLv3 code — it loads from vlibras.gov.br's CDN at runtime. Under LGPLv3, loading a library via dynamic linking (runtime loading via URL) is the permissive safe harbor: the plugin itself does not need to be LGPLv3, and users can substitute a different version of the LGPL component.

**However:** The 3D avatar assets (Unity WebGL build) served from the CDN may have separate licensing beyond LGPLv3 — they are Brazilian government digital assets. This is the true unknown. The findings document must explicitly investigate and document whether third-party applications are permitted to call the vlibras.gov.br CDN from their own apps.

**CONFIDENCE:** LOW — this is standard LGPLv3 interpretation applied to the known facts, but has not been verified against official VLibras terms of service. The spike findings document must address this explicitly.

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `dart:html` for DOM manipulation | `package:web` | Dart 3.3 (Q1 2024) | Must use new API; dart:html deprecated |
| `dart:js` / classic `@JS()` | `dart:js_interop` extension types | Dart 3.3 (Q1 2024), formally deprecated Dart 3.7 Feb 2025 | WASM-compatible; old path deprecated |
| HTML renderer (Flutter Web) | CanvasKit (default) | Flutter 3.24+ 2024 | HTML renderer deprecated; CanvasKit is the only target |
| `flutter_driver` for integration tests | `integration_test` + `flutter drive` | Flutter 2.5+ | flutter_driver still works; integration_test is canonical |

**Deprecated/outdated:**
- `dart:html`: Deprecated Dart 3.7 (Feb 2025). Replaced by `package:web`.
- `dart:js` (classic): Deprecated. Replaced by `dart:js_interop`.
- Flutter HTML renderer (`--web-renderer html`): Deprecated in Flutter 3.24 stable; removal pending.

---

## Open Questions

1. **Does VLibras Player WebGL actually conflict with CanvasKit in practice?**
   - What we know: Both use WebGL; browsers limit contexts; historical Flutter issues are documented
   - What's unclear: Whether current 2025 versions have mitigated this; whether the Unity canvas gets its own element inside the HtmlElementView div or competes with Flutter's canvas
   - Recommendation: This is exactly what the spike must answer empirically. Check browser console for WebGL errors on first render.

2. **Is `VLibras.Player` accessible directly at `window.VLibras.Player` after loading vlibras-plugin.js?**
   - What we know: index.js exports `VLibras.Player` and sets `window.VLibras = VLibras`
   - What's unclear: Whether the built/minified vlibras-plugin.js exposes the same namespace, or only Widget
   - Recommendation: Open browser console after loading vlibras-plugin.js and inspect `window.VLibras`. Document findings.

3. **Does `translate()` hit a network API or work offline?**
   - What we know: Player config includes a `translator` URL; PlayerManagerAdapter uses SendMessage to Unity
   - What's unclear: Whether text-to-gloss translation happens in the Unity WASM or on a remote API at vlibras.gov.br
   - Recommendation: Monitor Network tab during translate() call; document the endpoint if one is called.

4. **Are third-party apps permitted to use the vlibras.gov.br CDN?**
   - What we know: Code is LGPLv3; CDN is publicly accessible; no visible terms of service checked
   - What's unclear: Whether CDN usage from third-party apps is permitted, rate-limited, or requires attribution
   - Recommendation: Check vlibras.gov.br for terms of service; search for official guidance or contact the VLibras team.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | integration_test (Flutter SDK bundled) |
| Config file | none — driven by `flutter drive` CLI |
| Quick run command | `flutter run -d chrome` (manual visual check) |
| Full suite command | `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/vlibras_load_test.dart -d chrome` |

### Phase Requirements -> Test Map

This phase has no formal requirement IDs (it is a risk-mitigation spike). The success criteria from the phase description map as follows:

| Success Criterion | Behavior | Test Type | Automated Command | File Exists? |
|-------------------|----------|-----------|-------------------|-------------|
| SC-1: Avatar visible in HtmlElementView | HtmlElementView renders VLibras 3D avatar (no blank/black canvas) | integration (visual) | `flutter drive ... -d chrome` | No — Wave 0 |
| SC-2: Dart translate() triggers animation | Calling translate from Dart produces visible LIBRAS animation | integration (visual) | `flutter drive ... -d chrome` | No — Wave 0 |
| SC-3: Written API document exists | `.planning/research/phase-01-findings.md` created with all required sections | manual | N/A — document check | No — Wave 0 |

**Note:** SC-1 and SC-2 require human visual confirmation — automated assertions cannot verify "avatar is animating correctly." The integration test verifies the container widget is present and no exceptions are thrown; visual confirmation is manual and must be noted in findings.

### Sampling Rate
- **Per task commit:** `flutter run -d chrome` — manually verify avatar appears
- **Per wave merge:** `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/vlibras_load_test.dart -d chrome`
- **Phase gate:** Full integration test green + SC-3 findings document written

### Wave 0 Gaps
- [ ] `spike/` directory — create with `flutter create --platforms web spike`
- [ ] `spike/integration_test/vlibras_load_test.dart` — covers SC-1, SC-2
- [ ] `spike/test_driver/integration_test.dart` — driver file for `flutter drive`
- [ ] `spike/pubspec.yaml` — add `web: ^1.0.0` under dependencies
- [ ] `.planning/research/` directory — for phase-01-findings.md

---

## Sources

### Primary (HIGH confidence)
- [Flutter HtmlElementView API](https://api.flutter.dev/flutter/widgets/HtmlElementView-class.html) — constructors, onElementCreated, platformViewRegistry
- [Embedding web content in Flutter](https://docs.flutter.dev/platform-integration/web/web-content-in-flutter) — HtmlElementView patterns
- [dart:js_interop usage](https://dart.dev/interop/js-interop/usage) — @JS extension types, external members
- [Migrate to package:web](https://dart.dev/interop/js-interop/package-web) — createElement, script injection, event listeners
- [Flutter integration tests](https://docs.flutter.dev/testing/integration-tests) — integration_test setup, flutter drive

### Secondary (MEDIUM confidence)
- [vlibras-player-webjs Player.js](https://github.com/spbgovbr-vlibras/vlibras-player-webjs/blob/master/src/Player.js) — public methods via source inspection
- [vlibras-player-webjs PlayerManagerAdapter.js](https://github.com/spbgovbr-vlibras/vlibras-player-webjs/blob/master/src/PlayerManagerAdapter.js) — events, Unity SendMessage bridge
- [vlibras-player-webjs index.js](https://github.com/spbgovbr-vlibras/vlibras-player-webjs/blob/master/src/index.js) — window.VLibras.Player namespace
- [vlibras-web-browsers README](https://github.com/spbgovbr-vlibras/vlibras-web-browsers/blob/dev/README.md) — Widget config options, CDN URL, LGPLv3 license confirmation
- [VLibras widget integration docs](https://vlibras.gov.br/doc/widget/installation/webpageintegration.html) — CDN URL confirmed

### Tertiary (LOW confidence)
- [Flutter WebGL context issues #50719](https://github.com/flutter/flutter/issues/50719) — WebGL context limit; not Unity-specific
- [Flutter HtmlElementView WebGL errors #49947](https://github.com/flutter/flutter/issues/49947) — CanvasKit + embedded WebGL conflict; fixed in PR but class of problem persists
- LGPLv3 dynamic linking safe harbor interpretation — standard legal analysis, not verified for VLibras CDN specifically

---

## Metadata

**Confidence breakdown:**
- VLibras JS API surface: MEDIUM — derived from source code inspection, not official API docs; must be validated empirically
- Flutter HtmlElementView patterns: HIGH — verified against official Flutter docs
- dart:js_interop / package:web patterns: HIGH — verified against official Dart docs
- WebGL conflict risk: MEDIUM — Flutter issues confirm the class of problem exists; VLibras-specific outcome is empirically unknown
- License analysis: LOW — standard LGPLv3 interpretation, not legally reviewed, VLibras CDN terms unverified

**Research date:** 2026-03-23
**Valid until:** 2026-04-23 (stable APIs); VLibras CDN URL/API may change without notice (verify before Phase 3)
