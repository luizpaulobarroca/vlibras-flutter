---
phase: 01-sdk-investigation-spike
plan: 02
subsystem: ui
tags: [flutter, dart-js-interop, vlibras, htmlelementview, webgl, web]

# Dependency graph
requires:
  - phase: 01-sdk-investigation-spike
    provides: spike Flutter Web project scaffold with pubspec.yaml, integration test stubs, and index.html placeholder comments

provides:
  - dart:js_interop extension types for VLibras Player API (VLibrasNamespace, VLibrasPlayerOptions, VLibrasPlayerInstance)
  - HtmlElementView.fromTagName('div') embedding of VLibras player container
  - Translate button wired to player.translate() via UI
  - Integration tests updated with Key-based assertions for SC-1 and SC-2
  - VLibras CDN script tag in index.html (synchronous load)
  - WebGL conflict investigation framework (comments + runtime status banner)

affects:
  - 02-flutter-plugin-core
  - Any phase implementing vlibras_controller or vlibras_widget

# Tech tracking
tech-stack:
  added:
    - dart:js_interop (extension types for JS interop, Dart 3.7)
    - dart:js_interop_unsafe (callAsConstructor for new VLibras.Player())
    - package:web (HTMLDivElement, replaces dart:html)
  patterns:
    - extension type pattern for JS bindings (VLibrasPlayerInstance._(JSObject _))
    - HtmlElementView.fromTagName('div') for DOM element embedding in Flutter Web
    - 500ms Future.delayed for script-parse-to-init timing

key-files:
  created:
    - spike/lib/vlibras_js.dart
  modified:
    - spike/lib/main.dart
    - spike/web/index.html
    - spike/integration_test/vlibras_load_test.dart

key-decisions:
  - "dart:js_interop_unsafe required for callAsConstructor — not available in dart:js_interop itself; discovered during Task 1 analysis"
  - "HtmlElementView.fromTagName('div') chosen as primary embedding approach; Plan B (iframe+postMessage) not needed at compile time — WebGL conflict determination deferred to manual browser run"
  - "Synchronous CDN script load via index.html <script> tag; avoids async race conditions during spike"
  - "500ms delayed init after element creation allows vlibras-plugin.js parse time before VLibras.Player constructor is called"

patterns-established:
  - "JS interop binding pattern: extension type Foo._(JSObject _) implements JSObject with external methods"
  - "HtmlElementView.fromTagName pattern for DOM embedding in Flutter Web"
  - "Player event registration via player.on(eventName, dartFn.toJS)"

requirements-completed: []

# Metrics
duration: 6min
completed: 2026-03-23
---

# Phase 1 Plan 02: VLibras Player Embedding and JS Interop Bindings Summary

**dart:js_interop extension types for VLibras Player API plus HtmlElementView.fromTagName embedding wired to a Translate button, building for web with no errors**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-23T23:42:41Z
- **Completed:** 2026-03-23T23:48:38Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- Created `spike/lib/vlibras_js.dart` with complete dart:js_interop extension types mirroring the VLibras Player API (load, translate, on, off, pause, stop, repeat, setSpeed, resume)
- Replaced placeholder main.dart with a working StatefulWidget that embeds VLibras player via HtmlElementView.fromTagName and wires a Translate button to player.translate()
- Updated integration tests from permissive MaterialApp/Scaffold assertions to Key-based assertions (Key('vlibras-player-view'), Key('translate-btn'), Key('status-text'))
- `flutter build web --release` completes without errors; `flutter analyze` reports no issues

## Task Commits

Each task was committed atomically:

1. **Task 1: Add CDN script tag and create dart:js_interop bindings** - `cabdda1` (feat)
2. **Task 2: Implement HtmlElementView embedding and translate UI** - `ba53165` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `spike/lib/vlibras_js.dart` - dart:js_interop bindings: VLibrasNamespace, VLibrasPlayerOptions, VLibrasPlayerInstance, createVLibrasPlayer()
- `spike/lib/main.dart` - Flutter app with HtmlElementView.fromTagName embedding, event handlers, Translate button, status banner
- `spike/web/index.html` - Added vlibras-plugin.js CDN script tag (synchronous, before </body>)
- `spike/integration_test/vlibras_load_test.dart` - Updated SC-1 and SC-2 assertions to use Key-based finders

## Decisions Made

- **dart:js_interop_unsafe required:** `callAsConstructor` is in `dart:js_interop_unsafe`, not `dart:js_interop`. Must import both packages to construct `new VLibras.Player(options)`.
- **HtmlElementView as primary approach:** Proceeded with HtmlElementView.fromTagName('div'); Plan B (iframe+postMessage) is not pre-emptively implemented. WebGL conflict determination requires a live browser run with DevTools open — that is manual verification outside this plan's automation scope.
- **Synchronous CDN load:** Script tag in index.html loaded synchronously. Avoids timing issues; acceptable for spike. Production SDK would use async load with readiness callback.
- **500ms delayed init:** Small delay between element creation callback and VLibras.Player constructor call allows vlibras-plugin.js parse phase to complete. May need tuning empirically.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added dart:js_interop_unsafe import for callAsConstructor**
- **Found during:** Task 1 (dart:js_interop bindings)
- **Issue:** Plan code used `vLibras.Player.callAsConstructor(options)` but `callAsConstructor` is defined on `JSFunction` extension in `dart:js_interop_unsafe`, not `dart:js_interop`. flutter analyze reported `undefined_method`.
- **Fix:** Added `import 'dart:js_interop_unsafe';` to vlibras_js.dart
- **Files modified:** spike/lib/vlibras_js.dart
- **Verification:** `flutter analyze lib/vlibras_js.dart` reported no issues after fix
- **Committed in:** cabdda1 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking import)
**Impact on plan:** Single import addition required for correct constructor invocation. No scope creep.

## Issues Encountered

- `callAsConstructor` not available in `dart:js_interop` in Dart 3.7.2 — it lives in `dart:js_interop_unsafe`. Confirmed by inspecting dart-sdk source at `lib/js_interop_unsafe/js_interop_unsafe.dart`. Fixed by adding the import.

## WebGL Conflict Investigation

The spike is now instrumented for WebGL conflict detection:

- **Browser console check items:** "WebGL: INVALID_OPERATION: bindTexture: object does not belong to this context", black/blank avatar area, Flutter layout corruption
- **Status banner** (Key('status-text')) shows real-time player state in the running app
- **Result:** PENDING — requires manual `flutter run -d chrome` and DevTools inspection. CanvasKit and Unity WebGL are in separate DOM subtrees (separate canvas elements), so conflicts are theoretically unlikely but must be empirically confirmed.
- **Plan B (iframe+postMessage):** Not yet needed. If WebGL conflicts appear during manual verification, Plan B should be implemented as a follow-up task.

## VLibras API Validation Status

| Method | Confidence | Status |
|--------|-----------|--------|
| `new VLibras.Player(options)` | Medium | Compiled; runtime unconfirmed |
| `player.load(element)` | Medium | Compiled; runtime unconfirmed |
| `player.translate(text)` | Medium | Compiled; runtime unconfirmed |
| `player.on(event, fn)` | Medium | Compiled; runtime unconfirmed |
| `player.off(event, fn)` | Low | Compiled; runtime unconfirmed |
| `VLibras.Player` constructor path | Medium | Requires window.VLibras.Player accessible after CDN load |

All bindings compile. Runtime validation requires `flutter run -d chrome` manual session.

## User Setup Required

None — no external service configuration required for the spike build. Manual browser verification (`flutter run -d chrome` inside `spike/`) is needed to confirm runtime behavior.

## Next Phase Readiness

- Spike compiles and builds for web; ready for manual browser run to confirm HtmlElementView embedding and VLibras player initialization
- After manual confirmation: SC-1 (container visible) and SC-2 (translate button triggers animation) will be empirically verified
- If WebGL conflicts found: Plan B (iframe+postMessage) implementation needed before proceeding to Phase 2
- If no conflicts found: Phase 2 (Flutter Plugin Core) can proceed with HtmlElementView as the confirmed embedding strategy

---
*Phase: 01-sdk-investigation-spike*
*Completed: 2026-03-23*
