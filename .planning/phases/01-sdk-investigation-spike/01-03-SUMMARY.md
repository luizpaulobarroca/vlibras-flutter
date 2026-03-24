---
phase: 01-sdk-investigation-spike
plan: 03
subsystem: research
tags: [vlibras, dart-js-interop, flutter-web, cdn, api-surface]

# Dependency graph
requires:
  - phase: 01-sdk-investigation-spike/01-02
    provides: "Compiled spike app with HtmlElementView + dart:js_interop bindings"
provides:
  - "Definitive Phase 1 findings document with empirical SC-1/SC-2 results and root cause analysis"
  - "Confirmed VLibras CDN API surface: window.VLibras.Widget only, no Player in CDN"
  - "Two forward paths for Phase 3: Widget (CDN) vs. self-hosted standalone Player"
  - "Corrected dart:js_interop snippets for both approaches"
affects: [02-state-machine-design, 03-production-implementation, phase-3-planning]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "CDN source inspection via curl + Python to validate API surface assumptions before runtime testing"
    - "Two-product model: vlibras-plugin.js (Widget CDN) vs. vlibras-player-webjs (standalone Player, no CDN)"

key-files:
  created: []
  modified:
    - ".planning/research/phase-01-findings.md"

key-decisions:
  - "SC-1 FAIL: window.VLibras.Player does not exist in CDN bundle — vlibras-plugin.js exports only VLibras.Widget"
  - "SC-2 FAIL: translate button never enabled, Unity WebGL never loaded, no animation occurred"
  - "SC-3 PASS: phase-01-findings.md complete with empirical truth and CDN source inspection evidence"
  - "Phase 3 path decision required: VLibras.Widget (CDN, limited programmatic control) vs. self-hosted vlibras-player-webjs (full translate() control, requires serving Unity WebGL assets ~100MB+)"
  - "HtmlElementView.fromTagName embedding architecture is still correct — the container approach works, only the JS API target was wrong"

patterns-established:
  - "Validate CDN API surface via source inspection before writing bindings — do not assume source repo exports match CDN bundle exports"

requirements-completed: []

# Metrics
duration: 45min
completed: 2026-03-24
---

# Phase 1 Plan 3: Findings Document and Runtime Verification Summary

**SC-1 FAIL / SC-2 FAIL: window.VLibras.Player not in CDN bundle — vlibras-plugin.js exports Widget only; Phase 1 spike identified correct HtmlElementView architecture but targeted wrong JS API**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-03-24T02:00:00Z
- **Completed:** 2026-03-24T02:45:00Z
- **Tasks:** 2 (Task 1: write findings from spike results — completed in prior session; Task 2: investigate runtime failure, update findings — completed in this session)
- **Files modified:** 1

## Accomplishments

- Identified root cause of runtime TypeError: `window.VLibras.Player` is `null` because the CDN bundle does not export it
- Confirmed via CDN source inspection that `vlibras-plugin.js` only exports `window.VLibras.Widget`; `window.VLibras.Player` exists only in the standalone `vlibras-player-webjs` product (no public CDN)
- Updated phase-01-findings.md with empirical SC-1/SC-2 FAIL status, full root cause analysis, and two forward paths for Phase 3
- Documented the two-product model (portal widget vs. standalone player) that was the false assumption underlying the spike

## Task Commits

1. **Task 1: Write phase-01-findings.md from spike results** - `5975809` (docs)
2. **Task 2: Update findings with runtime failure analysis** - `f7f574e` (docs)

## Files Created/Modified

- `.planning/research/phase-01-findings.md` — Updated with empirical SC outcomes, CDN source analysis, root cause, two forward paths, revised dart:js_interop snippets for both Widget and standalone Player approaches

## Decisions Made

- `window.VLibras.Player` is REFUTED as a CDN-accessible API. The RESEARCH.md assumption was based on `vlibras-player-webjs/src/index.js` which is a separate product. The portal CDN bundle (`vlibras-plugin.js`) exports only `VLibras.Widget`.
- Phase 3 must decide between Widget (CDN-compatible, requires `[vw]` DOM structure, no direct translate()) and self-hosted standalone Player (full programmatic translate() control, requires hosting ~100MB+ Unity WebGL assets).
- HtmlElementView.fromTagName embedding architecture remains the correct strategy — the HtmlElementView approach itself was not the failure point.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Runtime failure investigation required CDN source inspection**
- **Found during:** Task 2 (Human visual verification of avatar animation)
- **Issue:** User reported "Init error: TypeError: null: type 'Null' is not a subtype of type 'JavaScriptFunction'" — the `vLibras.Player` property was null at runtime
- **Fix:** Investigated CDN bundle source via `curl`, confirmed `window.VLibras.Player` is not exported by `vlibras-plugin.js`. Also confirmed `vlibras-player-webjs` standalone build has no public CDN. Updated findings document with empirical truth — SC-1 FAIL, SC-2 FAIL with root cause evidence.
- **Files modified:** `.planning/research/phase-01-findings.md`
- **Verification:** CDN source last line: `window.VLibras=r` where `r = {Widget: <fn>}` — no Player key. `vlibras-player-webjs/build/` returns 404 on GitHub API.
- **Committed in:** f7f574e

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug investigation and documentation)
**Impact on plan:** The plan's checkpoint asked for SC-1/SC-2 verification — the failure mode itself IS the empirical result that needed documenting. No scope creep; documentation updated to reflect reality.

## Issues Encountered

- The RESEARCH.md (Phase 1 Plan 1) contained a false assumption: that `vlibras-player-webjs/src/index.js` exporting `VLibras.Player` meant the CDN `vlibras-plugin.js` also exported it. These are two separate products. The portal bundle (vlibras-plugin.js) bundles a Widget-centric experience and does not expose the raw Player constructor.
- There is no public CDN build of the standalone `vlibras-player-webjs`. The `build/` directory is not committed to the repo. Using the Player API requires either building from source or finding an alternative distribution method.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

**Phase 2 (state machine design) is ready to begin** — the findings document provides the empirical API surface for state machine design. The state machine design can proceed for the standalone Player path (which has the correct EventEmitter API confirmed in source: `load`, `animation:play`, `animation:end`, `animation:pause`, `translate:start`).

**Phase 3 (production implementation) requires a path decision first:**

1. **Widget path:** Use `VLibras.Widget` from CDN. Requires understanding Widget lifecycle, DOM structure requirements (`[vw]` elements), and whether programmatic translate() is possible after widget initialization via `window.plugin.player`. Advantage: no self-hosting. Disadvantage: complex DOM requirements, indirect translate() access.

2. **Self-hosted Player path:** Build `vlibras-player-webjs`, serve the compiled `vlibras.js` and `target/` Unity WebGL assets from the Flutter app's web assets. Advantage: full programmatic control, clean API. Disadvantage: ~100MB+ asset hosting burden, build process complexity, license implications for asset redistribution.

**Recommended:** Resolve the path decision as the first task of Phase 3 planning (before implementing anything). The Phase 2 state machine design should be path-agnostic where possible.

**Blockers:**
- Window.VLibras.Player CDN path is closed — must use Widget or self-host
- Unity WebGL avatar asset licensing is UNCLEAR — must be resolved before pub.dev publication

---

## Reference

Full empirical findings: `.planning/research/phase-01-findings.md`

---
*Phase: 01-sdk-investigation-spike*
*Completed: 2026-03-24*
