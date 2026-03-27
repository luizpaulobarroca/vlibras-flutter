---
phase: 4
slug: publication-readiness
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-03-27
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (bundled with Flutter SDK >=3.7.2) |
| **Config file** | None — `flutter test` discovers test/ automatically |
| **Quick run command** | `flutter test test/vlibras_controller_test.dart test/vlibras_web_platform_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/vlibras_controller_test.dart test/vlibras_web_platform_test.dart`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green + `flutter pub publish --dry-run` must pass
- **Max feedback latency:** ~10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | PUB-04 | unit | `flutter test test/vlibras_web_platform_test.dart` | ✅ (appended to existing) | ⬜ pending |
| 4-01-02 | 01 | 1 | PUB-04 | widget | `flutter test test/vlibras_view_vm_test.dart` | ✅ (created in plan) | ⬜ pending |
| 4-01-03 | 01 | 1 | PUB-04 | widget (browser) | `flutter test --platform chrome test/vlibras_view_test.dart` | ✅ (created/expanded in plan) | ⬜ pending |
| 4-02-01 | 02 | 1 | PUB-03 | smoke | `flutter pub publish --dry-run` | ✅ (command exists) | ⬜ pending |
| 4-02-02 | 02 | 1 | PUB-03 | smoke | `flutter pub publish --dry-run \| grep readme` | ✅ (README created in task) | ⬜ pending |
| 4-02-03 | 02 | 1 | PUB-02 | static | `dart doc . 2>&1 \| grep "warning"` | ✅ | ⬜ pending |
| 4-03-01 | 03 | 2 | PUB-01 | manual/smoke | `flutter run -d chrome` in example/ | ✅ (scaffolded in plan) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

All Wave 0 requirements are resolved inline in Plans 01-03. No separate Wave 0 plan is needed:

- [x] `test/vlibras_view_vm_test.dart` — stubs for PUB-04 VLibrasView non-web branch (FakeMobilePlatform) — covered by Plan 01 Task 2
- [x] `test/vlibras_web_platform_test.dart` — add `initialize() idempotent` test stub — covered by Plan 01 Task 1
- [x] `test/vlibras_view_test.dart` — browser test for onElementCreated div configuration — covered by Plan 01 Task 3
- [x] `example/` directory — basic app structure (covers PUB-01 smoke test) — covered by Plan 03
- [x] `LICENSE` — hard blocker for `flutter pub publish --dry-run` — covered by Plan 02 Task 1
- [x] `README.md` — hard blocker for `flutter pub publish --dry-run` — covered by Plan 02 Task 2
- [x] `CHANGELOG.md` — required for pub.dev scoring — covered by Plan 02 Task 1
- [x] `.pubignore` — prevents spike/ and web/vlibras/target/ from being published — covered by Plan 02 Task 1

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Example app runs on Flutter Web with VLibras avatar visible | PUB-01 | Requires browser + VLibras server | `cd example && flutter run -d chrome` — verify avatar renders and translates text |
| VLibrasView snap-to-corner animation | PUB-01 | Visual/interaction verification | Drag avatar across screen, release — verify it snaps to nearest corner with animation |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (resolved inline in plans)
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending execution
