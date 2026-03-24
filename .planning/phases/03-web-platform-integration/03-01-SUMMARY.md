---
phase: 03-web-platform-integration
plan: "01"
subsystem: platform
tags: [dart, flutter-web, js-interop, dart:js_interop, web, completer, timer, tdd]

# Dependency graph
requires:
  - phase: 02-core-dart-api
    provides: VLibrasPlatform interface, VLibrasStatus enum, VLibrasController scaffold

provides:
  - VLibrasWebPlatform: Completer/Timer JS bridge implementing VLibrasPlatform
  - vlibras_js.dart: dart:js_interop bindings for VLibrasPlayerInstance
  - VLibrasPlayerAdapter: internal interface enabling unit-testable player injection
  - platform/web_platform.dart: createDefaultPlatform() factory (web branch)
  - platform/unsupported_platform.dart: createDefaultPlatform() factory (non-web branch)
  - 7 unit tests proving all state machine behaviors without a real browser

affects:
  - 03-02 (VLibrasView widget will call attachToElement() on VLibrasWebPlatform)
  - 03-03 (VLibrasController will use conditional import to pick createDefaultPlatform())

# Tech tracking
tech-stack:
  added:
    - web: ^1.0.0 (package:web, WASM-compatible DOM bindings)
  patterns:
    - Completer/Timer bridge: JS event callbacks become awaitable Dart Futures
    - cancel-and-restart: second translate() completes in-flight Completer with error before creating new one
    - VLibrasPlayerAdapter: abstract Dart interface decouples implementation from JS extension type for testability
    - playerFactory injection: constructor parameter overrides player creation for unit tests

key-files:
  created:
    - lib/src/vlibras_js.dart
    - lib/src/vlibras_web_platform.dart
    - lib/src/platform/web_platform.dart
    - lib/src/platform/unsupported_platform.dart
    - test/vlibras_web_platform_test.dart
  modified:
    - pubspec.yaml (added web: ^1.0.0)

key-decisions:
  - "VLibrasPlayerAdapter abstract class decouples VLibrasWebPlatform from dart:js_interop extension type — unit tests inject FakePlayer without needing a browser or JS runtime"
  - "playerFactory: VLibrasPlayerAdapter Function()? constructor parameter chosen (Option B) over subclass override — simpler injection point for tests"
  - "attachToElement(Object? element) is a separate method from initialize() — VLibrasView calls it when DOM element is ready; initialize() only sets up the Completer"
  - "_RealPlayerAdapter.create() throws UnsupportedError at runtime to prevent accidental use outside Flutter Web — explicit error message guides developer"

patterns-established:
  - "Completer/Timer: use _completeTranslate(error) helper to pop+complete in one call, guards isCompleted"
  - "cancel-and-restart: always call _completeTranslate(Exception('cancelled')) at top of translate() before creating new Completer"

requirements-completed: [WEB-02]

# Metrics
duration: 4min
completed: 2026-03-24
---

# Phase 3 Plan 01: JS Interop Layer and VLibrasWebPlatform Summary

**VLibrasWebPlatform bridges vlibras-player-webjs JS events to Dart Futures via Completer/Timer, with VLibrasPlayerAdapter enabling fully VM-runnable unit tests for all 7 state machine behaviors**

## Performance

- **Duration:** 4 min
- **Started:** 2026-03-24T23:00:58Z
- **Completed:** 2026-03-24T23:04:58Z
- **Tasks:** 1 (TDD: RED commit + GREEN commit)
- **Files modified:** 6

## Accomplishments

- Created `vlibras_js.dart` with complete dart:js_interop bindings for VLibrasPlayerInstance including `@JS('continue')` workaround for Dart keyword collision
- Implemented `VLibrasWebPlatform` with Completer/Timer bridge: translate() awaits animation:end, times out after 30s, cancel-and-restart pattern, dispose() cleans up all in-flight state
- Introduced `VLibrasPlayerAdapter` abstract interface so unit tests run on the Dart VM without any browser dependency — all 7 behaviors verified
- Created conditional-import factory stubs (`web_platform.dart` / `unsupported_platform.dart`) ready for Phase 3 Plan 3 wiring
- No regressions: all 29 existing controller tests still pass

## Task Commits

Each task was committed atomically:

1. **RED — failing tests** - `5ba5554` (test)
2. **GREEN — implementation** - `7fd88c6` (feat)

_Note: TDD task had two commits: test (RED) then feat (GREEN). No refactor commit needed._

## Files Created/Modified

- `pubspec.yaml` - Added `web: ^1.0.0` dependency
- `lib/src/vlibras_js.dart` - dart:js_interop + dart:js_interop_unsafe bindings for VLibrasNamespace, VLibrasPlayerOptions, VLibrasPlayerInstance, createVLibrasPlayer()
- `lib/src/vlibras_web_platform.dart` - VLibrasWebPlatform class + VLibrasPlayerAdapter interface
- `lib/src/platform/web_platform.dart` - createDefaultPlatform() factory returning VLibrasWebPlatform (web branch)
- `lib/src/platform/unsupported_platform.dart` - createDefaultPlatform() factory throwing UnsupportedError (non-web branch)
- `test/vlibras_web_platform_test.dart` - 7 unit tests via FakePlayer injection

## Decisions Made

- **VLibrasPlayerAdapter** (not raw VLibrasPlayerInstance) as the internal type: dart:js_interop extension types cannot be implemented by plain Dart classes, so a separate Dart interface was required to allow FakePlayer in tests. This decision keeps all JS interop isolated to `vlibras_js.dart` and `_RealPlayerAdapter`.
- **Option B (playerFactory parameter)** over Option A (subclass override): simpler, no need to expose a protected method, factory is nullably optional.
- **attachToElement separate from initialize()**: matches the natural Flutter lifecycle — the controller calls `initialize()` first (sets up Completer), then the View calls `attachToElement()` when its DOM element is created (wires player). These are two distinct events in the Flutter widget tree.

## Deviations from Plan

None — plan executed exactly as written. The only adaptation was technical: `FakePlayer implements VLibrasPlayerAdapter` was added to the test file (the plan said "inject a fake player via factory" — `VLibrasPlayerAdapter` is the mechanism that makes this possible without conditional imports).

## Issues Encountered

One type mismatch: `FakePlayer.load(Object element)` vs `VLibrasPlayerAdapter.load(Object? element)` — required making the parameter nullable. Fixed immediately (Rule 1 auto-fix, ~30 seconds).

## User Setup Required

None — no external service configuration required. Developer-facing setup (copying Unity WebGL assets to `web/vlibras/target/` and adding `<script>` tag) is documented in CONTEXT.md and deferred to the end of Phase 3.

## Next Phase Readiness

- `VLibrasWebPlatform` is fully implemented and tested; ready for `VLibrasView` to call `attachToElement()`
- Platform factory stubs exist; `VLibrasController` conditional import wiring is next (Plan 03)
- `web: ^1.0.0` is in pubspec; no further dependency changes expected in Phase 3

## Self-Check: PASSED

- FOUND: lib/src/vlibras_js.dart
- FOUND: lib/src/vlibras_web_platform.dart
- FOUND: lib/src/platform/web_platform.dart
- FOUND: lib/src/platform/unsupported_platform.dart
- FOUND: test/vlibras_web_platform_test.dart
- FOUND: .planning/phases/03-web-platform-integration/03-01-SUMMARY.md
- FOUND: commit 5ba5554 (test RED)
- FOUND: commit 7fd88c6 (feat GREEN)

---
*Phase: 03-web-platform-integration*
*Completed: 2026-03-24*
