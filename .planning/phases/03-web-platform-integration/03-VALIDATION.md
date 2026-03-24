---
phase: 3
slug: web-platform-integration
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter SDK bundled) |
| **Config file** | none — `flutter test` discovers `test/` automatically |
| **Quick run command** | `flutter test test/vlibras_controller_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~10 seconds (quick) / ~30 seconds (full) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/vlibras_controller_test.dart`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 3-??-01 | WEB-01 | 1 | WEB-01 | widget (chrome) | `flutter test test/vlibras_view_test.dart --platform chrome` | ❌ W0 | ⬜ pending |
| 3-??-02 | WEB-02 | 1 | WEB-02 | unit (mock) | `flutter test test/vlibras_web_platform_test.dart` | ❌ W0 | ⬜ pending |
| 3-??-03 | CORE-02 | 1 | CORE-02 | unit | `flutter test test/vlibras_controller_test.dart` | ✅ exists | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/vlibras_view_test.dart` — WEB-01: widget test verifying VLibrasView renders HtmlElementView with Key('vlibras-player-view')
- [ ] `test/vlibras_web_platform_test.dart` — WEB-02: unit test with mock JS player injected via callback; verifies state machine transitions (idle -> initializing -> ready -> translating -> playing -> ready)

*Existing `test/vlibras_controller_test.dart` (29 passing tests) covers CORE-02 behaviors. New tests extend coverage for playing-state transitions pushed by platform callbacks.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| VLibras 3D avatar renders visibly in browser | WEB-01 | Requires Unity WebGL assets + browser rendering; cannot be automated in CI | Run `flutter run -d chrome` in example app, confirm avatar canvas appears |
| `translate("Ola mundo")` triggers visible LIBRAS signing | WEB-02 | Avatar animation requires real player + Unity WebGL; no headless equivalent | Call translate via example app UI, confirm avatar moves |
| State transitions observable via ValueListenableBuilder | CORE-02 | UI state rendering requires browser + real player | Observe loading indicator, playing state, idle state in example app |
| Timeout fires when animation:end does not arrive | CORE-02 | Requires simulating player failure (network block or player stall) | Block `/vlibras/target/` network requests in DevTools, trigger translate, confirm error state |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
