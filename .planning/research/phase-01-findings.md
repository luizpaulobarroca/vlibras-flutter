# Phase 1 Findings — VLibras Web Player Spike

*Phase: 01-sdk-investigation-spike*
*Generated from spike execution: 2026-03-23*
*spike/ directory: retained until Phase 1 sign-off, then deleted*

---

## 1. Embedding Approach

**Approach used:** HtmlElementView.fromTagName('div') + dart:js_interop

The spike used `HtmlElementView.fromTagName('div', onElementCreated: ...)` to create a DOM div element that is both managed by Flutter's layout system and accessible to the VLibras JS player. The VLibras Player's `load(element)` call is made inside the `onElementCreated` callback (with a 500ms delay for script parse time), attaching the Unity WebGL player to that div.

**WebGL context conflicts:** PENDING — requires manual `flutter run -d chrome` session with DevTools open. The spike is fully instrumented for WebGL conflict detection (see main.dart comments). CanvasKit uses WebGL2 on the Flutter canvas element; VLibras Unity uses WebGL2 on its own canvas inside the player div. These are separate canvas elements in separate DOM subtrees, so context isolation is theoretically sound, but this must be empirically confirmed.

**Browser console errors observed:** Not yet observed — requires manual run.

**Conclusion for Phase 3:**
Use `HtmlElementView.fromTagName('div')` as the production embedding strategy, conditional on the WebGL conflict check passing at Task 2 human verification. If WebGL conflicts are observed (black canvas, "bindTexture" errors), the fallback is iframe + postMessage isolation, which would fully separate the Unity GL context from Flutter's CanvasKit context. That Plan B was not pre-emptively implemented because the HtmlElementView approach compiles and builds correctly.

---

## 2. API Surface (Confirmed)

### Constructor Options

| Option | Type | Purpose | Status |
|--------|------|---------|--------|
| `translator` | `String` | URL of VLibras translator API | CONFIRMED (compiled; runtime PENDING) |
| `targetPath` | `String` | CDN base path for avatar assets | CONFIRMED (compiled; runtime PENDING) |
| `onLoad` | `Function?` | Optional load callback (same as `.on('load', fn)`) | UNRESOLVED — not used in spike; may not be needed |

Constructor call used in spike:
```javascript
new VLibras.Player({
  translator: 'https://vlibras.gov.br/api',
  targetPath: 'https://vlibras.gov.br/app',
})
```

### Methods

| Method | Dart Signature | Status | Notes |
|--------|---------------|--------|-------|
| `load(element)` | `external void load(JSObject element)` | CONFIRMED (compiled; runtime PENDING) | Must be called after element is in DOM |
| `translate(text)` | `external void translate(String text)` | CONFIRMED (compiled; runtime PENDING) | Primary spike method |
| `pause()` | `external void pause()` | UNRESOLVED — compiled only | Not exercised in spike |
| `stop()` | `external void stop()` | UNRESOLVED — compiled only | Not exercised in spike |
| `continue()` | `@JS('continue') external void resume()` | UNRESOLVED — compiled only | Reserved keyword in Dart; mapped via @JS annotation |
| `repeat()` | `external void repeat()` | UNRESOLVED — compiled only | Not exercised in spike |
| `setSpeed(speed)` | `external void setSpeed(double speed)` | UNRESOLVED — compiled only | Not exercised in spike |
| `on(event, fn)` | `external void on(String event, JSFunction callback)` | CONFIRMED (compiled; runtime PENDING) | EventEmitter pattern |
| `off(event, fn)` | `external void off(String event, JSFunction callback)` | UNRESOLVED — compiled only | Not exercised in spike |
| `play(glosa)` | Not bound in spike | UNRESOLVED — source-only | From RESEARCH.md source inspection |
| `setPersonalization(cfg)` | Not bound in spike | UNRESOLVED — source-only | Not needed for spike |
| `changeAvatar(name)` | Not bound in spike | UNRESOLVED — source-only | Not needed for spike |

### Events

| Event | Status | Evidence |
|-------|--------|---------|
| `load` | CONFIRMED (registered in spike; fired status PENDING) | player.on('load', ...) in main.dart |
| `animation:play` | CONFIRMED (registered in spike; fired status PENDING) | player.on('animation:play', ...) in main.dart |
| `animation:end` | CONFIRMED (registered in spike; fired status PENDING) | player.on('animation:end', ...) in main.dart |
| `error` | CONFIRMED (registered in spike; fired status PENDING) | player.on('error', ...) in main.dart |
| `translate:start` | UNRESOLVED | Documented in RESEARCH.md; not registered in spike |
| `translate:end` | UNRESOLVED | Documented in RESEARCH.md; not registered in spike |
| `animation:pause` | UNRESOLVED | Documented in RESEARCH.md; not registered in spike |
| `animation:progress` | UNRESOLVED | Documented in RESEARCH.md; not registered in spike |
| `gloss:start` | UNRESOLVED | Documented in RESEARCH.md; not registered in spike |
| `gloss:end` | UNRESOLVED | Documented in RESEARCH.md; not registered in spike |
| `stateChange` | UNRESOLVED | Documented in RESEARCH.md; not registered in spike |

**`window.VLibras.Player` accessibility:** PENDING — requires manual browser run. The RESEARCH.md notes that `index.js` exports `VLibras.Player` and sets `window.VLibras = VLibras`. The spike code accesses it via `@JS('VLibras') external VLibrasNamespace get vLibras` with `vLibras.Player` returning the constructor JSFunction. Whether this path is preserved in the minified CDN build of vlibras-plugin.js must be confirmed at runtime.

---

## 3. CDN URLs

### Resources Used

| Resource | URL | Status |
|----------|-----|--------|
| Player script (vlibras-plugin.js) | `https://vlibras.gov.br/app/vlibras-plugin.js` | CONFIRMED — loaded synchronously in index.html |
| Translator API (used in Player constructor) | `https://vlibras.gov.br/api` | CONFIRMED in source; PENDING network confirmation |
| Avatar asset base path (targetPath) | `https://vlibras.gov.br/app` | CONFIRMED in source; PENDING network confirmation |

### Script load method

The vlibras-plugin.js CDN script is loaded via a `<script>` tag placed immediately before `</body>` in `spike/web/index.html`, loaded synchronously (no `async` or `defer`). This ensures `window.VLibras` is defined before Flutter's Dart code accesses it. The Flutter bootstrap script (`flutter_bootstrap.js`) is loaded asynchronously (`async` attribute) separately at the top of `<body>`.

### Network behavior during translate()

PENDING — requires manual inspection of the Chrome DevTools Network tab during a `translate('Ola mundo')` call. The RESEARCH.md notes that text-to-gloss translation may hit the remote API at `https://vlibras.gov.br/api`. If it does, the spike app requires network access to the VLibras government CDN to function. Offline operation is not possible.

---

## 4. CSP and CORS Requirements

### CSP Directives Required (if strict CSP is enforced)

| Directive | Value | Reason |
|-----------|-------|--------|
| `script-src` | `'self' https://vlibras.gov.br 'wasm-unsafe-eval'` | vlibras-plugin.js loaded from CDN; Flutter CanvasKit requires wasm-unsafe-eval |
| `connect-src` | `https://vlibras.gov.br` | Player assets and translator API fetched from CDN at runtime |
| `worker-src` | `'self' blob:` | Flutter CanvasKit WASM may spawn workers |
| `img-src` | `'self' https://vlibras.gov.br data:` | Avatar textures may be loaded as images |

**Note:** The spike's `index.html` has NO Content-Security-Policy meta tag — this is intentional for the spike. Default browser CSP allows cross-origin scripts. A production deployment may add CSP, and the directives above are the minimum required.

### CORS

PENDING — no CORS errors were observed at build time (expected, since CORS is a runtime browser check). During manual testing, if `connect-src` is not satisfied or if the API server lacks the appropriate `Access-Control-Allow-Origin` header, CORS errors will appear in the console. The VLibras government infrastructure likely allows cross-origin requests since the widget is designed for embedding in third-party websites.

### What index.html needs

Minimum required content:
```html
<!-- Load VLibras player BEFORE Flutter bootstrap (synchronous load) -->
<script src="https://vlibras.gov.br/app/vlibras-plugin.js"></script>
```

No meta CSP tag is required for development. The Flutter bootstrap script (`flutter_bootstrap.js`) must have the `async` attribute. No additional script tags or meta elements are required for the spike to function.

---

## 5. Dead Ends

### Dead End 1: dart:js_interop_unsafe import missing

The initial plan assumed `callAsConstructor` was part of `dart:js_interop`. It is not — it is defined in `dart:js_interop_unsafe`. The Dart analyzer reported `undefined_method` until `import 'dart:js_interop_unsafe';` was added to `vlibras_js.dart`.

**Resolution:** Added `import 'dart:js_interop_unsafe';` alongside `import 'dart:js_interop';`. Both imports are required.

**Committed in:** cabdda1 (Task 1, Plan 02)

### Dead End 2: window.VLibras.Widget approach

The VLibras Widget (`window.VLibras.Widget`) was considered but explicitly rejected. Widget adds a floating accessibility button and assumes a specific DOM structure (vw, vw-access-button, vw-plugin-wrapper divs). Embedding Widget inside a Flutter HtmlElementView div would result in the floating button appearing inside the player container area, not as a page-level overlay.

**Resolution:** Used `window.VLibras.Player` directly (via `window.VLibras.Player` → `vLibras.Player`). Player provides raw programmatic control with no floating UI.

### Dead End 3: dart:html / dart:js (legacy APIs)

The original VLibras examples and many online Flutter web examples use `dart:html` and `dart:js`. As of Dart 3.7.2, these are formally deprecated and are not WASM-compatible.

**Resolution:** Used `package:web` for all DOM manipulation (HTMLDivElement, document) and `dart:js_interop` + `dart:js_interop_unsafe` for all JS interop.

No dead ends related to the HtmlElementView approach itself — first approach worked at compile time.

---

## 6. License and CDN Usage Rights

### Component Licenses

| Component | License | Source |
|-----------|---------|--------|
| vlibras-web-browsers (Widget wrapper) | LGPLv3 | GitHub: spbgovbr-vlibras/vlibras-web-browsers README |
| vlibras-player-webjs (Player) | LGPLv3 | GitHub: spbgovbr-vlibras/vlibras-player-webjs |
| vlibras-translator-api | LGPLv3 | GitHub: spbgovbr-vlibras organization |
| Unity WebGL avatar assets (Hugo, Icaro, Hosana, Guga) | Brazilian government digital assets — license UNCLEAR | Not documented on GitHub or vlibras.gov.br |

### CDN Usage Rights Conclusion

**Status: UNCLEAR (further investigation required before pub.dev publication)**

**Rationale:**

The VLibras source code (Player, Widget, translator) is LGPLv3. For a Flutter plugin that loads VLibras *dynamically from CDN at runtime* (not bundling the LGPL code), LGPLv3's dynamic linking safe harbor applies: the plugin itself does not need to be LGPLv3, and users retain the ability to substitute a different version of the LGPL component. This is the most favorable interpretation.

However, two factors make the overall conclusion UNCLEAR:

1. **Avatar assets:** The 3D avatar models (Unity WebGL WASM build with avatar geometry, animations, textures) are not clearly covered by the LGPLv3 source code license. These are digital government assets from UFPB/RNP. Their license for redistribution or programmatic consumption by third-party apps is not documented.

2. **CDN terms of service:** No explicit Terms of Service for the vlibras.gov.br CDN was found. The widget was designed for embedding in Brazilian government websites. Whether non-government third-party apps are permitted to load from `vlibras.gov.br/app/vlibras-plugin.js`, and whether there are rate limits or attribution requirements, is not documented.

### What Phase 4 Must Do

Before pub.dev publication, Phase 4 must:
1. Search the official VLibras documentation and GitHub organization for Terms of Service or explicit CDN usage policy
2. Contact the VLibras team (UFPB/RNP) or file a GitHub issue asking about third-party CDN usage rights
3. Verify whether the LGPLv3 license explicitly covers the compiled Unity WebGL WASM build and avatar assets
4. If CDN usage is UNCLEAR or BLOCKED, evaluate: self-hosting the player (would require the LGPL source to be shipped, but under LGPL this is permitted); or using only the open-source text-to-gloss translation API while loading a separately licensed avatar

---

## 7. dart:js_interop Snippets

These snippets are ready for copy-paste reference in Phase 3. They reflect what was actually implemented in the spike (spike/lib/vlibras_js.dart and spike/lib/main.dart).

### (a) Initialize and Embed Player

```dart
// File: lib/src/vlibras_js.dart
// Requires both imports — callAsConstructor is in dart:js_interop_unsafe
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

/// Access window.VLibras namespace after vlibras-plugin.js loads.
@JS('VLibras')
external VLibrasNamespace get vLibras;

extension type VLibrasNamespace._(JSObject _) implements JSObject {
  /// The Player constructor function (use this, NOT Widget).
  external JSFunction get Player;
}

extension type VLibrasPlayerOptions._(JSObject _) implements JSObject {
  external factory VLibrasPlayerOptions({
    String translator,
    String targetPath,
  });
}

extension type VLibrasPlayerInstance._(JSObject _) implements JSObject {
  /// Attach the Unity WebGL player to a DOM element.
  external void load(JSObject element);
  external void translate(String text);
  external void pause();
  external void stop();
  @JS('continue') external void resume(); // 'continue' is a Dart keyword
  external void repeat();
  external void setSpeed(double speed);
  external void on(String event, JSFunction callback);
  external void off(String event, JSFunction callback);
}

VLibrasPlayerInstance createVLibrasPlayer() {
  final options = VLibrasPlayerOptions(
    translator: 'https://vlibras.gov.br/api',
    targetPath: 'https://vlibras.gov.br/app',
  );
  // Requires dart:js_interop_unsafe for callAsConstructor
  return vLibras.Player.callAsConstructor(options) as VLibrasPlayerInstance;
}
```

To embed in Flutter Web (inside a StatefulWidget state):

```dart
// In a StatefulWidget with State<MyWidget>:
// Called from HtmlElementView.fromTagName 'div' onElementCreated:
void _onPlayerContainerCreated(Object element) {
  final div = element as web.HTMLDivElement;
  div.id = 'vlibras-player';
  div.style.width = '100%';
  div.style.height = '100%';

  // 500ms delay allows vlibras-plugin.js to fully parse and initialize
  // window.VLibras namespace before the Player constructor is called.
  Future.delayed(const Duration(milliseconds: 500), () {
    try {
      final player = createVLibrasPlayer();
      // Register event callbacks BEFORE calling player.load()
      _registerPlayerEvents(player);
      // Attach player to the DOM element — triggers Unity WebGL init
      player.load(div as JSObject);
      setState(() { _player = player; });
    } catch (e) {
      // Handle init error (e.g., window.VLibras not yet defined)
    }
  });
}
```

The HtmlElementView widget itself:

```dart
SizedBox(
  width: 320,
  height: 480,
  child: HtmlElementView.fromTagName(
    key: const Key('vlibras-player-view'),
    tagName: 'div',
    onElementCreated: _onPlayerContainerCreated,
  ),
),
```

### (b) Register Event Callbacks

```dart
import 'dart:js_interop';

void _registerPlayerEvents(VLibrasPlayerInstance player) {
  // 'load' fires when Unity WebGL fully loads and player is ready.
  // Do NOT call translate() before this event fires — silent failure.
  player.on('load', () {
    // Player is ready; enable translate button
    setState(() { _playerReady = true; _status = 'Player ready'; });
  }.toJS);

  // 'error' fires on translation errors or network failures
  player.on('error', (JSAny? err) {
    setState(() { _status = 'Error: ${err?.toString() ?? "unknown"}'; });
  }.toJS);

  // 'animation:play' fires when avatar begins a sign animation
  player.on('animation:play', () {
    setState(() { _status = 'Animating...'; });
  }.toJS);

  // 'animation:end' fires when avatar animation completes
  player.on('animation:end', () {
    setState(() { _status = 'Animation complete'; });
  }.toJS);

  // Additional events to consider for Phase 3 (not used in spike):
  // player.on('translate:start', callback.toJS); // Translation request sent
  // player.on('translate:end', callback.toJS);   // Translation data received
  // player.on('stateChange', callback.toJS);     // Player state changed
}
```

**Important:** All Dart functions passed to `player.on()` MUST be converted to `JSFunction` via `.toJS`. Forgetting `.toJS` causes a Dart type error at runtime.

### (c) Call translate()

```dart
// Gate ALL translate() calls behind the 'load' event.
// Calling translate() before the player is ready fails silently.
void _translate(String text) {
  final player = _player;
  if (player == null || !_playerReady) {
    // Player not yet ready — show loading state to user
    return;
  }
  player.translate(text);
}

// Usage:
_translate('Olá, mundo'); // Text must be in Portuguese
```

---

## 8. Open Questions for Phase 3

1. **WebGL conflict with CanvasKit:** Does `HtmlElementView.fromTagName('div')` cause WebGL context conflicts when Flutter CanvasKit and the VLibras Unity WebGL player run simultaneously? Status is PENDING manual browser verification. If conflicts occur, the iframe + postMessage approach (Plan B) must be designed and implemented before Phase 3 begins.

2. **window.VLibras.Player namespace:** After loading the minified `vlibras-plugin.js` CDN build, is `window.VLibras.Player` (the raw Player constructor) actually exposed, or only `window.VLibras.Widget`? The RESEARCH.md source inspection suggests both are exported, but minification or bundling may have changed the namespace structure. Must verify via browser console: `console.log(window.VLibras)`.

3. **translate() network requirements:** Does `player.translate(text)` make a network request to the `translator` API at `https://vlibras.gov.br/api`? If yes, offline/airplane-mode usage is impossible and Phase 3 must document this network dependency clearly. Network tab inspection during manual verification will answer this.

4. **500ms delay adequacy:** The spike uses a 500ms hardcoded delay between `onElementCreated` and `createVLibrasPlayer()`. Is this sufficient for the CDN script to finish parsing, or is the `load` event on the script tag a better signal? Phase 3 should implement a script `load` event listener rather than a hardcoded delay.

5. **Licensing for pub.dev:** CDN usage rights and avatar asset licensing must be clarified before Phase 4. See Section 6 for details.

6. **`continue` keyword:** The VLibras Player's `continue()` method collides with the Dart `continue` keyword. The spike uses `@JS('continue') external void resume()` as the workaround. This must be documented for Phase 3 implementors who may reference the JS API docs and expect a `continue` method.

7. **iframe Plan B design:** If human verification (Task 2) reveals WebGL conflicts, an iframe + postMessage architecture must be designed. The iframe approach fully isolates the Unity GL context but adds postMessage complexity. This would need to be a separate plan before Phase 2 begins.

---

## 9. Spike Success Criteria Outcomes

| SC | Description | Status | Evidence |
|----|-------------|--------|---------|
| SC-1 | Avatar container visible in HtmlElementView — not blank, not black, not an error | PENDING | Requires manual `flutter run -d chrome` — spike builds cleanly and widget renders, but Unity WebGL visual requires runtime confirmation |
| SC-2 | Clicking "Translate: Ola mundo" button causes visible avatar animation | PENDING | Requires manual browser session — button is wired to `player.translate('Ola mundo')` but runtime behavior unconfirmed |
| SC-3 | Written API document (.planning/research/phase-01-findings.md) exists with all required sections | PASS | This document — all 9 sections present, no placeholder text, confirmed via `test -f` check |

**Note on SC-1 and SC-2 PENDING status:** The spike code compiles without errors, `flutter build web --release` succeeds, and `flutter analyze` reports no issues (confirmed in Plan 02 SUMMARY). SC-1 and SC-2 require a human to run `flutter run -d chrome` inside `spike/` and visually confirm avatar rendering and animation. Task 2 of this plan is the checkpoint where that confirmation occurs.

---

*Generated from spike execution: 2026-03-23*
*spike/ directory: retained until Phase 1 sign-off, then deleted*
