---
phase: 4
slug: publication-readiness
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| 4-01-01 | 01 | 1 | PUB-04 | unit | `flutter test test/vlibras_web_platform_test.dart` | ❌ Wave 0 | ⬜ pending |
| 4-01-02 | 01 | 1 | PUB-04 | widget | `flutter test test/vlibras_view_vm_test.dart` | ❌ Wave 0 | ⬜ pending |
| 4-01-03 | 01 | 1 | PUB-04 | widget (browser) | `flutter test --platform chrome test/vlibras_view_test.dart` | ❌ Wave 0 | ⬜ pending |
| 4-02-01 | 02 | 1 | PUB-03 | smoke | `flutter pub publish --dry-run` | ✅ (command exists) | ⬜ pending |
| 4-02-02 | 02 | 1 | PUB-02 | static | `dart doc . 2>&1 \| grep "warning"` | ✅ | ⬜ pending |
| 4-03-01 | 03 | 2 | PUB-01 | manual/smoke | `flutter run -d chrome` in example/ | ❌ Wave 0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/vlibras_view_vm_test.dart` — stubs for PUB-04 VLibrasView non-web branch (FakeMobilePlatform)
- [ ] `test/vlibras_web_platform_test.dart` — add `initialize() idempotent` test stub
- [ ] `example/` directory — basic app structure (covers PUB-01 smoke test)
- [ ] `LICENSE` — hard blocker for `flutter pub publish --dry-run`
- [ ] `README.md` — hard blocker for `flutter pub publish --dry-run`
- [ ] `CHANGELOG.md` — required for pub.dev scoring
- [ ] `.pubignore` — prevents spike/ and web/vlibras/target/ from being published

*Wave 0 must be complete before any further waves execute.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Example app runs on Flutter Web with VLibras avatar visible | PUB-01 | Requires browser + VLibras server | `cd example && flutter run -d chrome` — verify avatar renders and translates text |
| VLibrasView snap-to-corner animation | PUB-01 | Visual/interaction verification | Drag avatar across screen, release — verify it snaps to nearest corner with animation |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
