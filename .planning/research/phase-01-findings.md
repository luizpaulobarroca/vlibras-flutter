# Phase 1 Findings — VLibras Web Player Spike

*Phase: 01-sdk-investigation-spike*
*Generated from spike execution: 2026-03-23, updated with runtime results: 2026-03-24*
*spike/ directory: retained until Phase 1 sign-off, then deleted*

---

## 1. Embedding Approach

**Approach attempted:** HtmlElementView.fromTagName('div') + dart:js_interop

The spike used `HtmlElementView.fromTagName('div', onElementCreated: ...)` to create a DOM div element managed by Flutter's layout system, with the intention of attaching the VLibras Player to it. The architecture was sound and compiled cleanly. However, the spike failed at runtime before reaching the WebGL embedding stage, because `window.VLibras.Player` does not exist in the CDN build (see Section 2 and Section 5).

**WebGL context conflicts:** NOT TESTABLE — the VLibras Player constructor call threw a TypeError before any Unity WebGL content was loaded. No canvas element was ever created, so WebGL conflict testing between Flutter CanvasKit and VLibras Unity was not possible.

**Browser console errors observed:**
```
Init error: TypeError: null: type 'Null' is not a subtype of type 'JavaScriptFunction'
```
This error originates in `createVLibrasPlayer()` in `vlibras_js.dart`. The call `vLibras.Player.callAsConstructor(options)` fails because `vLibras.Player` resolves to `null` — the CDN bundle does not export a `Player` property on `window.VLibras`.

**Conclusion for Phase 3:**
The `HtmlElementView.fromTagName('div')` approach remains the correct strategy for embedding an HTML/WebGL player inside Flutter Web. The approach itself is not at fault. However, Phase 3 cannot proceed until the correct VLibras API surface is identified and a working initialization path is confirmed. The CDN does not provide `VLibras.Player` directly. Phase 3 must either use `VLibras.Widget` (with DOM embedding trade-offs) or self-host the `vlibras-player-webjs` standalone build.

---

## 2. API Surface (Confirmed)

### Root cause of runtime failure

The spike assumed `window.VLibras.Player` would be accessible after loading `vlibras-plugin.js` from the CDN. This assumption was refuted by inspection of the actual CDN bundle.

**The CDN bundle (`vlibras.gov.br/app/vlibras-plugin.js`, redirects to `cdn.jsdelivr.net/gh/spbgovbr-vlibras/vlibras-portal@dev/app/vlibras-plugin.js`) exports only:**
```javascript
window.VLibras = { Widget: <WidgetConstructor> }
```

`window.VLibras.Player` is **not exported**. It is `undefined` (Dart sees it as `null`), which causes the TypeError when `callAsConstructor` is invoked.

**`window.VLibras.Plugin`** is also not exported at load time. It is set lazily — only when a user clicks the Widget access button, triggering a dynamic import of chunk 7. It is never accessible programmatically before user interaction.

**What `window.VLibras.Plugin` is:** The `Plugin` class (dynamically loaded) wraps a `Player` instance. After the Widget button click, `window.plugin.player` (note: lowercase, not `VLibras.Player`) holds the actual Player instance. There is no way to access the Player constructor directly from the CDN bundle.

### window.VLibras.Player accessibility

**Status: REFUTED** — `window.VLibras.Player` is NOT exposed by the CDN `vlibras-plugin.js` bundle. The RESEARCH.md assumption was based on `vlibras-player-webjs/src/index.js` which exports `VLibras.Player` in a separate standalone build. The portal bundle (`vlibras-plugin.js`) is a different product with a Widget-centric API.

### Two separate products

| Product | Repo | CDN | Exports |
|---------|------|-----|---------|
| vlibras-plugin.js (portal widget) | spbgovbr-vlibras/vlibras-portal | `vlibras.gov.br/app/vlibras-plugin.js` | `window.VLibras.Widget` only |
| vlibras.js (standalone player) | spbgovbr-vlibras/vlibras-player-webjs | No public CDN — build output not committed | `window.VLibras.Player` |

### Constructor Options (vlibras-player-webjs Player)

Sourced from `vlibras-player-webjs/src/Player.js` and `config.js`:

| Option | Type | Purpose | Status |
|--------|------|---------|--------|
| `translator` | `String` | URL of VLibras translator API | CONFIRMED (source inspection) — defaults to `https://vlibras.gov.br/api` |
| `targetPath` | `String` | Local/CDN path for Unity WebGL assets | CONFIRMED (source inspection) — defaults to `"target"` (relative path) |
| `onLoad` | `Function?` | Optional load callback | CONFIRMED (source inspection) |

### Methods (vlibras-player-webjs Player)

All statuses are SOURCE-CONFIRMED only — no runtime confirmation was achieved.

| Method | Status | Notes |
|--------|--------|-------|
| `load(element)` | SOURCE-CONFIRMED | Attaches Unity WebGL to DOM element |
| `translate(text)` | SOURCE-CONFIRMED | Calls translator API then plays gloss animation |
| `pause()` | SOURCE-CONFIRMED | Pauses animation |
| `stop()` | SOURCE-CONFIRMED | Stops animation |
| `continue()` | SOURCE-CONFIRMED | Resumes (Dart: @JS('continue') external void resume()) |
| `repeat()` | SOURCE-CONFIRMED | Replays last animation |
| `setSpeed(speed)` | SOURCE-CONFIRMED | Adjusts speed (1.0 = normal) |
| `on(event, fn)` | SOURCE-CONFIRMED | EventEmitter pattern |
| `off(event, fn)` | SOURCE-CONFIRMED | Remove listener |

### Events (vlibras-player-webjs Player)

| Event | Status | Evidence |
|-------|--------|---------|
| `load` | SOURCE-CONFIRMED | `this.emit("load")` after Unity loads |
| `animation:play` | SOURCE-CONFIRMED | `this.emit("animation:play")` on stateChange |
| `animation:end` | SOURCE-CONFIRMED | `this.emit("animation:end")` on stateChange |
| `animation:pause` | SOURCE-CONFIRMED | `this.emit("animation:pause")` on stateChange |
| `animation:progress` | SOURCE-CONFIRMED | `this.emit("animation:progress", progress)` |
| `translate:start` | SOURCE-CONFIRMED | `this.emit("translate:start")` in translate() |
| `response:glosa` | SOURCE-CONFIRMED | `this.emit("response:glosa", counter, glosaLenght)` |
| `stop:welcome` | SOURCE-CONFIRMED | `this.emit("stop:welcome", bool)` |
| `GetAvatar` | SOURCE-CONFIRMED | `this.emit("GetAvatar", avatar)` |
| `error` | UNRESOLVED | Not in Player.js source; may be emitted by GlosaTranslator |

---

## 3. CDN URLs

### Resources Confirmed

| Resource | URL | Status |
|----------|-----|--------|
| Portal widget script | `https://vlibras.gov.br/app/vlibras-plugin.js` | CONFIRMED — 302 redirects to jsdelivr |
| Portal widget actual source | `https://cdn.jsdelivr.net/gh/spbgovbr-vlibras/vlibras-portal@dev/app/vlibras-plugin.js` | CONFIRMED — inspected |
| Translator API | `https://vlibras.gov.br/api` | SOURCE-CONFIRMED — appears in config.js defaults |
| Avatar assets (Unity WebGL) | NOT available on public CDN | CONFIRMED ABSENT — `vlibras-player-webjs/build/` directory does not exist in the repo; assets are only in `src/target/` (developer-only) |

### Script load method

The spike loaded `vlibras-plugin.js` synchronously in `index.html`. This is correct for the Widget approach but irrelevant for the Player approach since the Player bundle is not on any CDN.

### Network behavior during translate()

NOT TESTED — translate() was never reached. From source inspection: `GlosaTranslator.translate()` makes an HTTP POST to the translator API URL. Network access to `vlibras.gov.br/api` is required at runtime; offline operation is not possible.

---

## 4. CSP and CORS Requirements

### CDN CORS policy (confirmed)

The CDN response includes:
```
access-control-allow-origin: *
access-control-allow-methods: GET,HEAD,OPTIONS
```
CORS is not a blocker for script loading from `vlibras.gov.br`.

### CSP Directives Required

| Directive | Value | Reason |
|-----------|-------|--------|
| `script-src` | `'self' https://vlibras.gov.br https://cdn.jsdelivr.net 'wasm-unsafe-eval'` | vlibras-plugin.js redirects to jsdelivr; Flutter CanvasKit requires wasm-unsafe-eval |
| `connect-src` | `https://vlibras.gov.br` | Translator API and avatar asset requests |
| `worker-src` | `'self' blob:` | Flutter CanvasKit WASM may spawn workers |

### What index.html needs

For Widget approach:
```html
<script src="https://vlibras.gov.br/app/vlibras-plugin.js"></script>
<div vw class="enabled">
  <div vw-access-button class="active"></div>
  <div vw-plugin-wrapper>
    <div vp></div>
  </div>
</div>
```

For standalone Player approach (requires self-hosting): serve `vlibras.js` and the `target/` Unity WebGL assets from same origin.

---

## 5. Dead Ends

### Dead End 1: dart:js_interop_unsafe import missing

The initial plan assumed `callAsConstructor` was part of `dart:js_interop`. It is not — it is defined in `dart:js_interop_unsafe`. The Dart analyzer reported `undefined_method` until `import 'dart:js_interop_unsafe';` was added.

**Resolution:** Added `import 'dart:js_interop_unsafe';` alongside `import 'dart:js_interop';`.
**Committed in:** cabdda1

### Dead End 2: window.VLibras.Player does not exist in the CDN bundle

The RESEARCH.md assumed that `window.VLibras.Player` was exposed by `vlibras-plugin.js` based on source inspection of `vlibras-player-webjs/src/index.js`. This was WRONG. The portal bundle (`vlibras-plugin.js`) exports only `window.VLibras.Widget`. The `Player` constructor is in a separate product (`vlibras-player-webjs`) that has no public CDN build.

**Runtime error:** `TypeError: null: type 'Null' is not a subtype of type 'JavaScriptFunction'`
**Root cause:** `vLibras.Player` is `null`/`undefined` because `window.VLibras` has no `Player` property.
**CDN bundle source confirmed:** `window.VLibras=r` where `r = {Widget: <fn>}` — no `Player` key.
**Resolution:** NOT RESOLVED in Phase 1. Two paths forward for Phase 3: (a) use `VLibras.Widget` with DOM injection, or (b) self-host the `vlibras-player-webjs` standalone build and its Unity WebGL assets.

### Dead End 3: dart:html / dart:js (legacy APIs)

Deprecated as of Dart 3.7.2. Not WASM-compatible.
**Resolution:** Used `package:web` for DOM and `dart:js_interop` + `dart:js_interop_unsafe` for all interop.

### Dead End 4: window.VLibras.Widget approach considered but deferred

`VLibras.Widget` is the only publicly available API in the CDN. Widget manages its own DOM structure (floating button + plugin wrapper div with specific `[vw]`, `[vw-access-button]`, `[vw-plugin-wrapper]`, `[vp]` elements). The Widget constructor calls `player.load()` internally after button click, but exposes no `translate()` method directly.

**Status:** Not attempted in Phase 1. The Widget API may be usable in Phase 3 if the DOM structure requirements are compatible with HtmlElementView embedding — requires separate investigation.

---

## 6. License and CDN Usage Rights

### Component Licenses

| Component | License | Source |
|-----------|---------|--------|
| vlibras-portal (Widget) | LGPLv3 | GitHub: spbgovbr-vlibras/vlibras-portal |
| vlibras-player-webjs (Player) | LGPLv3 | GitHub: spbgovbr-vlibras/vlibras-player-webjs LICENSE |
| vlibras-translator-api | LGPLv3 | GitHub: spbgovbr-vlibras organization |
| Unity WebGL avatar assets (Hugo, Icaro, Hosana, Guga) | Brazilian government digital assets — license UNCLEAR | Not documented on GitHub or vlibras.gov.br |

### CDN Usage Rights Conclusion

**Status: UNCLEAR (further investigation required before pub.dev publication)**

**Rationale:** The VLibras source code is LGPLv3. Dynamic CDN loading (not bundling) benefits from LGPLv3's dynamic linking safe harbor. However, the avatar assets license is undocumented, and CDN Terms of Service are not published. CORS headers (`Access-Control-Allow-Origin: *`) indicate the CDN is designed for cross-origin embedding, which is a positive signal.

### What Phase 4 Must Do

Before pub.dev publication:
1. Contact the VLibras team (UFPB/RNP via GitHub) asking about third-party CDN usage rights
2. Verify whether the LGPLv3 license explicitly covers the compiled Unity WebGL WASM build and avatar assets
3. If CDN usage is BLOCKED, evaluate self-hosting the player under LGPL
4. Review whether Widget (rather than Player) approach changes the licensing calculus

---

## 7. dart:js_interop Snippets

**IMPORTANT:** The snippets below are updated based on Phase 1 findings. The `window.VLibras.Player` path does NOT work with the CDN. Two alternative approaches are documented.

### Approach A: VLibras.Widget (CDN-compatible, DOM-dependent)

This uses the only API actually exported by the CDN. The Widget manages its own DOM structure and requires specific HTML elements to exist in the page.

```dart
// File: lib/src/vlibras_js.dart
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

/// Access window.VLibras namespace after vlibras-plugin.js loads.
@JS('VLibras')
external VLibrasNamespace get vLibras;

extension type VLibrasNamespace._(JSObject _) implements JSObject {
  /// The Widget constructor — the ONLY public API in the CDN bundle.
  external JSFunction get Widget;
  // NOTE: Player is NOT exported. Plugin is set lazily after button click only.
}

extension type VLibrasWidgetOptions._(JSObject _) implements JSObject {
  external factory VLibrasWidgetOptions({
    String rootPath,
    String position,    // 'TL','T','TR','L','R','BL','B','BR'
    String avatar,      // 'icaro','hosana','guga','random'
  });
}

VLibrasNamespace createVLibrasWidget(VLibrasWidgetOptions options) {
  // Requires dart:js_interop_unsafe for callAsConstructor
  return vLibras.Widget.callAsConstructor(options) as VLibrasNamespace;
}
```

Widget requires specific DOM structure in `index.html`:
```html
<div vw class="enabled">
  <div vw-access-button class="active"></div>
  <div vw-plugin-wrapper>
    <div vp></div>
  </div>
</div>
<script src="https://vlibras.gov.br/app/vlibras-plugin.js"></script>
```

**Limitation:** Widget shows a floating UI button and requires the DOM structure above. The Plugin (player) loads only after button click — no programmatic translate() possible before that. This approach requires a different interaction model than originally planned.

### Approach B: Standalone Player (self-hosted, programmatic control)

This uses `vlibras-player-webjs` built and self-hosted. Gives full programmatic access.

```dart
// Bindings remain the same as originally designed — these ARE correct
// for the standalone player bundle, just not for the CDN portal bundle.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('VLibras')
external VLibrasNamespace get vLibras;

extension type VLibrasNamespace._(JSObject _) implements JSObject {
  /// Available in standalone vlibras-player-webjs build, NOT in CDN portal.
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
  @JS('continue') external void resume();
  external void repeat();
  external void setSpeed(double speed);
  external void on(String event, JSFunction callback);
  external void off(String event, JSFunction callback);
}

VLibrasPlayerInstance createVLibrasPlayer() {
  final options = VLibrasPlayerOptions(
    translator: 'https://vlibras.gov.br/api',
    targetPath: '/assets/vlibras/target',  // self-hosted Unity WebGL assets
  );
  return vLibras.Player.callAsConstructor(options) as VLibrasPlayerInstance;
}
```

**Requirement:** Build `vlibras-player-webjs` and serve `vlibras.js` + `target/` Unity WebGL assets. The Unity WebGL assets are large (50-200 MB estimated). This is the only path to full programmatic `translate()` control.

### (b) Register Event Callbacks (Approach B — Player)

```dart
import 'dart:js_interop';

void _registerPlayerEvents(VLibrasPlayerInstance player) {
  player.on('load', () {
    // Player is ready — enable translate button
    setState(() { _playerReady = true; });
  }.toJS);

  player.on('animation:play', () {
    setState(() { _status = 'Animating...'; });
  }.toJS);

  player.on('animation:end', () {
    setState(() { _status = 'Animation complete'; });
  }.toJS);

  // NOTE: 'error' event may not exist — check GlosaTranslator source
  // player.on('error', (JSAny? err) { ... }.toJS);
}
```

**IMPORTANT:** All Dart functions passed to `player.on()` MUST use `.toJS`. Missing `.toJS` causes a Dart type error at runtime.

### (c) Call translate() (Approach B — Player)

```dart
void _translate(String text) {
  final player = _player;
  if (player == null || !_playerReady) return;
  player.translate(text);  // Requires network: POST to vlibras.gov.br/api
}
```

---

## 8. Open Questions for Phase 3

1. **Which API path to use:** The CDN provides only `VLibras.Widget` (no programmatic translate()). The standalone `VLibras.Player` requires self-hosting Unity WebGL assets (~100MB+). Phase 3 planning must decide: (a) use Widget with its interaction model, (b) self-host the player, or (c) investigate if there is another CDN or API endpoint that provides programmatic translation.

2. **VLibras.Widget programmatic control:** After the Widget is initialized and the user has clicked the button (triggering `window.VLibras.Plugin` load and `window.plugin` creation), is `window.plugin.player.translate()` accessible? This could allow programmatic translate() after the initial Widget initialization flow. Requires testing.

3. **Translator API without Player:** The RESEARCH.md mentions `https://vlibras.gov.br/api` as the translator endpoint. Is the translator API independently accessible? If text→gloss translation is possible via a REST API call, a custom Unity WebGL player (or iframe with the CDN Widget) could be driven independently.

4. **Widget in HtmlElementView:** Can `VLibras.Widget` be initialized with its required DOM structure (`[vw]`, `[vw-plugin-wrapper]` etc.) inside a Flutter HtmlElementView div? The Widget uses `window.onload` which fires after the full page loads — this may conflict with Flutter's SPA rendering model.

5. **500ms delay adequacy:** The spike delay was for Player constructor timing. If Widget approach is used, the `window.onload` lifecycle must be understood instead.

6. **Licensing for pub.dev:** Unchanged from original — requires investigation before pub.dev publication.

7. **`continue` keyword:** The Player's `continue()` method collides with Dart's `continue` keyword. Use `@JS('continue') external void resume()` workaround.

8. **Self-hosting legal implications:** Self-hosting Unity WebGL avatar assets requires understanding the asset license (currently UNCLEAR). Self-hosting the `vlibras.js` player bundle is permitted under LGPLv3 (source must be included or made available).

---

## 9. Spike Success Criteria Outcomes

| SC | Description | Status | Evidence |
|----|-------------|--------|---------|
| SC-1 | Avatar container visible in HtmlElementView — not blank, not black, not an error | FAIL | App displayed: "Init error: TypeError: null: type 'Null' is not a subtype of type 'JavaScriptFunction'" — no avatar container rendered. Root cause: `window.VLibras.Player` does not exist in CDN bundle. |
| SC-2 | Clicking "Translate: Ola mundo" button causes visible avatar animation | FAIL | Button was never enabled (player never reached ready state). No animation occurred. |
| SC-3 | Written API document (.planning/research/phase-01-findings.md) exists with all required sections | PASS | This document — all 9 sections present with empirical truth. Updated 2026-03-24 with runtime failure analysis and CDN source inspection. |

**Summary of Phase 1 outcome:** The spike successfully identified the correct HtmlElementView embedding architecture and dart:js_interop binding patterns. It also identified and documented a critical false assumption: `window.VLibras.Player` is not in the CDN bundle. The spike cannot be considered a "success" in the original sense (avatar animating), but it IS a success in its actual purpose — producing a validated findings document that retires risk and gives Phase 3 accurate information to build on.

**Revised Phase 3 entry conditions:**
- The HtmlElementView approach is still correct — the embedding container architecture works
- The dart:js_interop binding pattern is correct — needs to target the right API
- Phase 3 must first resolve "which VLibras API path" before implementing the production widget
- Two viable paths: Widget (CDN, limited programmatic control) vs. self-hosted Player (full control, asset hosting required)

---

*Generated from spike execution: 2026-03-23*
*Updated with runtime results and CDN source inspection: 2026-03-24*
*spike/ directory: retained until Phase 1 sign-off, then deleted*
