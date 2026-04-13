---
phase: 04-publication-readiness
plan: "06"
subsystem: infra
tags: [flutter, pubspec, flutter_tools, pana, publish, web-plugin]

# Dependency graph
requires:
  - phase: 04-publication-readiness
    provides: "flutter: plugin: platforms: web: {} declaration (plan 04-05)"
provides:
  - "pubspec.yaml with valid web plugin declaration: pluginClass + fileName"
  - "lib/vlibras_flutter_web_plugin.dart — stub registrar satisfying flutter_tools WebPlugin.fromYaml"
  - "flutter test VM suite restored: 40/40 tests passing"
  - "flutter pub publish --dry-run: 0 warnings"
affects: [pub.dev publish, flutter test, pana score]

# Tech tracking
tech-stack:
  added:
    - "flutter_web_plugins (sdk: flutter) — required by the stub registrar"
  patterns:
    - "flutter.plugin.platforms.web with pluginClass + fileName for non-federated conditional-import web plugins"
    - "Stub VLibrasFlutterWebPlugin.registerWith() as no-op — web support via conditional imports, not channel registrar"

key-files:
  created:
    - lib/vlibras_flutter_web_plugin.dart
  modified:
    - pubspec.yaml
    - pubspec.lock

key-decisions:
  - "dartPluginClass: null is NOT supported by WebPlugin.fromYaml in Flutter 3.29.x — the class requires pluginClass: String and fileName: String; null fails the `is! String` check"
  - "Solution: create stub VLibrasFlutterWebPlugin with no-op registerWith(); declare pluginClass + fileName in pubspec.yaml"
  - "flutter_web_plugins added to dependencies (sdk: flutter) so the stub file compiles on web builds"
  - "VM tests never import the stub class — generateMainDartWithPluginRegistrant uses selectDartPluginsOnly: true, excluding WebPlugin from the VM test registrant"

patterns-established:
  - "Flutter 3.29.x WebPlugin.fromYaml pattern: always provide pluginClass: String and fileName: String — dartPluginClass: null is not valid for WebPlugin (only for AndroidPlugin/IOSPlugin/etc.)"

requirements-completed: [PUB-04]

# Metrics
duration: 15min
completed: 2026-03-29
---

# Phase 4 Plan 06: Publication Readiness Gap-Closure Summary

**Stub web plugin registrar created — all 40 VM tests restored and dry-run clean after diagnosing that WebPlugin.fromYaml in Flutter 3.29.x accepts only pluginClass: String, not dartPluginClass: null**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-03-29T21:10:00Z
- **Completed:** 2026-03-29T21:25:00Z
- **Tasks:** 2
- **Files modified:** 3 (pubspec.yaml, pubspec.lock, + 1 created)

## Accomplishments

- Diagnosed root cause: `WebPlugin.fromYaml` in Flutter 3.29.x checks `yaml['pluginClass'] is! String` — `null` fails this check, making `dartPluginClass: null` ineffective (that sentinel only works in `AndroidPlugin`/`IOSPlugin`, not `WebPlugin`)
- Created `lib/vlibras_flutter_web_plugin.dart` — minimal stub registrar with no-op `registerWith()`, satisfying flutter_tools parsing without altering web functionality (which uses conditional imports)
- Updated `pubspec.yaml`: `web: {}` → `web: { pluginClass: VLibrasFlutterWebPlugin, fileName: lib/vlibras_flutter_web_plugin.dart }`
- Added `flutter_web_plugins: sdk: flutter` to dependencies
- `flutter test` exits 0 with all 40 tests passing
- `flutter pub publish --dry-run` shows "Package has 0 warnings"

## Task Commits

1. **Task 1 + Task 2: Create web plugin registrar, update pubspec, verify and commit** - `08d36c1` (fix)

## Files Created/Modified

- `lib/vlibras_flutter_web_plugin.dart` — Stub web plugin registrar (`VLibrasFlutterWebPlugin` with no-op `registerWith(Registrar)`)
- `pubspec.yaml` — Added `flutter_web_plugins: sdk: flutter` dep; updated platforms block with `pluginClass` + `fileName`
- `pubspec.lock` — Updated dependency resolution after adding `flutter_web_plugins`

## Decisions Made

- **dart`PluginClass: null` does not work for `WebPlugin`** — after reading the flutter_tools source at `/c/Users/Luiz/dev/flutter/packages/flutter_tools/lib/src/platform_plugins.dart`, confirmed that `WebPlugin.fromYaml` checks `yaml['pluginClass'] is! String` (not `yaml['dartPluginClass']`). The `dartPluginClass` sentinel is handled by `AndroidPlugin`, `IOSPlugin`, `MacOSPlugin`, etc. — not `WebPlugin`. `WebPlugin` is a web-only registrar-based API.
- **Stub registrar is correct architecture** — since `vlibras_flutter` provides web support via `dart.library.js_interop` conditional imports (not a plugin channel), `registerWith` is intentionally empty. The stub exists only to satisfy `WebPlugin.fromYaml` parsing and pana platform scoring.
- **VM tests unaffected by stub** — `generateMainDartWithPluginRegistrant` passes `selectDartPluginsOnly: true`, which excludes `WebPlugin` entries from the generated VM test registrant. The stub file is never compiled into VM test binaries.

## Deviations from Plan

### Auto-fixed Issues

**1. [Incorrect fix assumption] Plan specified `dartPluginClass: null` but WebPlugin.fromYaml rejects it**
- **Found during:** Task 1 (after applying `dartPluginClass: null`, tests still failed)
- **Issue:** Plan's proposed fix (`dartPluginClass: null`) does not satisfy `WebPlugin.fromYaml` in Flutter 3.29.x — the class only validates `pluginClass: String`, not `dartPluginClass`
- **Fix:** Read flutter_tools source (`platform_plugins.dart`) to understand the actual constraint, then created a stub registrar class and updated pubspec.yaml with valid `pluginClass` + `fileName`
- **Files modified:** `pubspec.yaml`, new `lib/vlibras_flutter_web_plugin.dart`
- **Verification:** `flutter test` exits 0, 40/40 pass; dry-run 0 warnings
- **Committed in:** `08d36c1`

---

**Total deviations:** 1 auto-fixed (incorrect fix → correct fix after source inspection)
**Impact on plan:** Fix required deeper investigation than planned but outcome satisfies all success criteria.

## Issues Encountered

- **`dartPluginClass: null` rejected by `WebPlugin.fromYaml`** — Applied the plan's proposed fix, ran `flutter test`, error persisted. Read flutter_tools source code to understand the actual validation: `WebPlugin` has no `dartPluginClass` handling. Pivoted to creating a proper stub registrar. No wasted builds beyond the first failed attempt.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 4 is now fully resolved:
- All automated gates green: `flutter test` (40/40), `flutter pub publish --dry-run` (0 warnings), `dart doc` (0 undocumented warnings)
- Pana platform scoring: `platforms: web:` block present with valid `pluginClass` declaration
- Published package size: 111 KB compressed
- Working tree clean — no dirty-tree publish warnings
- Ready for `flutter pub publish` when the user decides to publish

---
*Phase: 04-publication-readiness*
*Completed: 2026-03-29*

## Self-Check: PASSED

- `flutter test`: exits 0, output "All tests passed!", test count = 40
- `flutter pub publish --dry-run`: "Package has 0 warnings."
- `grep -A 3 "platforms:" pubspec.yaml`: shows `web:` with `pluginClass: VLibrasFlutterWebPlugin` and `fileName: lib/vlibras_flutter_web_plugin.dart`
- `lib/vlibras_flutter_web_plugin.dart`: created, contains `VLibrasFlutterWebPlugin` with `registerWith(Registrar)`
- Commit `08d36c1`: in git log
- No other files modified (except pubspec.lock — updated automatically by pub)
