# Roadmap: vlibras_flutter

## Overview

This roadmap delivers a Flutter Web plugin that translates Portuguese text to LIBRAS via the VLibras web player. The journey starts with an SDK investigation spike to retire the biggest risk (can we embed the VLibras web player in Flutter at all?), then builds the Dart-side API architecture (Controller, Value, platform interface), integrates the real web player, and finishes with pub.dev publication readiness. Android and iOS are deferred to v2.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: SDK Investigation Spike** - Verify VLibras web player can be embedded in Flutter Web and document its JS API
- [x] **Phase 2: Core Dart API** - Build the Controller+Value+PlatformInterface architecture with full state machine, testable with mocks (completed 2026-03-24)
- [ ] **Phase 3: Web Platform Integration** - Embed VLibras web player via HtmlElementView and deliver end-to-end translate flow
- [ ] **Phase 4: Publication Readiness** - Example app, dartdoc, README, tests, and pana score for pub.dev publication

## Phase Details

### Phase 1: SDK Investigation Spike
**Goal**: Retire the critical risk: confirm the VLibras web player can be loaded and controlled inside a Flutter Web HtmlElementView, and document the exact JS API surface needed for translate/state callbacks
**Depends on**: Nothing (first phase)
**Requirements**: (none -- risk mitigation, not feature delivery)
**Success Criteria** (what must be TRUE):
  1. A minimal Flutter Web app displays the VLibras 3D avatar inside a HtmlElementView (not in a separate browser tab/iframe)
  2. Calling a JS function from Dart triggers a visible LIBRAS translation animation on the avatar
  3. A written document lists the exact JS API calls needed (init, translate, state events), the CDN/script URLs, and any CSP/CORS requirements discovered
**Plans**: 3 plans

Plans:
- [x] 01-01-PLAN.md — Create spike Flutter Web scaffold, integration test stubs, and research directory
- [x] 01-02-PLAN.md — Implement VLibras player embedding (HtmlElementView + dart:js_interop) and translate UI
- [x] 01-03-PLAN.md — Write phase-01-findings.md from spike results and human-verify avatar animation

**Phase 1 outcome:** SC-1 FAIL / SC-2 FAIL — window.VLibras.Player not in CDN bundle. vlibras-plugin.js exports only VLibras.Widget. Phase 1 successfully identified the correct HtmlElementView architecture and documented the correct JS API (from vlibras-player-webjs source). Phase 3 path decision required: Widget (CDN) vs. self-hosted standalone Player. See: .planning/research/phase-01-findings.md

### Phase 2: Core Dart API
**Goal**: Developers can instantiate a VLibrasController, observe its state through VLibrasValue, and the entire Dart API compiles and is testable against a mock platform -- without requiring a running web player
**Depends on**: Phase 1 (JS API findings inform platform interface design)
**Requirements**: CORE-01, CORE-03, CORE-04, ERR-01
**Success Criteria** (what must be TRUE):
  1. Developer can create a VLibrasController and call initialize()/dispose() with proper lifecycle management
  2. VLibrasController exposes a VLibrasValue with states: idle, loading, playing, error -- and transitions are observable via ValueNotifier/ChangeNotifier
  3. Errors during initialization or translation are surfaced through VLibrasValue.error, never thrown as unhandled exceptions
  4. Unit tests pass using a mock VLibrasPlatform, proving the Dart API works without any real platform underneath
**Plans**: 2 plans

Plans:
- [x] 02-01-PLAN.md — Create plugin scaffold, data types (VLibrasValue + VLibrasStatus), VLibrasPlatform interface, and test stubs
- [x] 02-02-PLAN.md — Implement VLibrasController state machine and activate full test suite

### Phase 3: Web Platform Integration
**Goal**: A Flutter Web app can display the VLibras avatar and translate text to LIBRAS end-to-end -- the core value proposition works for real
**Depends on**: Phase 2 (Dart API), Phase 1 (JS API knowledge)
**Requirements**: WEB-01, WEB-02, CORE-02
**Success Criteria** (what must be TRUE):
  1. VLibrasView renders the VLibras 3D avatar in a Flutter Web app using HtmlElementView
  2. Calling controller.translate("Ola mundo") causes the avatar to animate the LIBRAS signs visibly on screen
  3. Controller state transitions from idle -> loading -> playing -> idle are observable during a translate call
  4. If the web player fails to load or translate, VLibrasValue.error contains a meaningful error description
**Plans**: 3 plans

Plans:
- [ ] 03-01-PLAN.md — Create vlibras_js.dart bindings, VLibrasWebPlatform (Completer/Timer bridge), platform factory stubs, and unit tests
- [ ] 03-02-PLAN.md — Implement VLibrasView (HtmlElementView widget), wire VLibrasController conditional import and attachElement(), update barrel export
- [ ] 03-03-PLAN.md — Commit vlibras.js asset to web/vlibras/ and human-verify end-to-end avatar rendering and translation

### Phase 4: Publication Readiness
**Goal**: The plugin meets all pub.dev publication requirements and a new developer can install, understand, and use the plugin from its pub.dev listing alone
**Depends on**: Phase 3 (working plugin to document and demonstrate)
**Requirements**: PUB-01, PUB-02, PUB-03, PUB-04
**Success Criteria** (what must be TRUE):
  1. The /example app runs on Flutter Web and demonstrates VLibrasController + VLibrasView translating text to LIBRAS
  2. Every public class, method, and property in the API has dartdoc comments (zero undocumented public API warnings)
  3. README contains installation instructions, a minimal usage code snippet, and a list of supported platforms
  4. Unit and/or widget tests exist for VLibrasController behavior (state transitions, error handling, lifecycle)
  5. `flutter pub publish --dry-run` completes with no blocking errors
**Plans**: 4 plans

Plans:
- [ ] 04-01-PLAN.md — Expand test coverage: VLibrasWebPlatform error cases and VLibrasView non-web branch (VM-runnable)
- [ ] 04-02-PLAN.md — Publication metadata (LICENSE, README, CHANGELOG, .pubignore, pubspec) and complete dartdoc
- [ ] 04-03-PLAN.md — Create /example app with draggable snap-to-corner VLibrasView and polished UI
- [ ] 04-04-PLAN.md — Run automated gates (flutter test, publish dry-run, dart doc) and human-verify example app

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. SDK Investigation Spike | 3/3 | Complete | 2026-03-24 |
| 2. Core Dart API | 2/2 | Complete   | 2026-03-24 |
| 3. Web Platform Integration | 2/3 | In Progress|  |
| 4. Publication Readiness | 0/4 | Not started | - |
