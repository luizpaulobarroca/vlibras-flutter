---
phase: 2
slug: core-dart-api
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-24
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter SDK bundled) |
| **Config file** | none — `flutter test` discovers `test/` automatically |
| **Quick run command** | `flutter test test/vlibras_controller_test.dart` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/vlibras_controller_test.dart`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 0 | CORE-01 | unit | `flutter test test/vlibras_controller_test.dart` | ❌ W0 | ⬜ pending |
| 02-01-02 | 01 | 0 | CORE-03 | unit | `flutter test test/vlibras_controller_test.dart` | ❌ W0 | ⬜ pending |
| 02-01-03 | 01 | 0 | CORE-04 | unit | `flutter test test/vlibras_controller_test.dart` | ❌ W0 | ⬜ pending |
| 02-01-04 | 01 | 0 | ERR-01 | unit | `flutter test test/vlibras_controller_test.dart` | ❌ W0 | ⬜ pending |
| 02-02-01 | 02 | 1 | CORE-01 | unit | `flutter test test/vlibras_controller_test.dart` | ❌ W0 | ⬜ pending |
| 02-02-02 | 02 | 1 | CORE-03 | unit | `flutter test test/vlibras_controller_test.dart` | ❌ W0 | ⬜ pending |
| 02-02-03 | 02 | 1 | CORE-04 | unit | `flutter test test/vlibras_controller_test.dart` | ❌ W0 | ⬜ pending |
| 02-02-04 | 02 | 1 | ERR-01 | unit | `flutter test test/vlibras_controller_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `pubspec.yaml` — plugin root pubspec (name: vlibras_flutter, sdk: ^3.7.2, dev: mocktail, flutter_lints)
- [ ] `analysis_options.yaml` — `include: package:flutter_lints/flutter.yaml`
- [ ] `lib/vlibras_flutter.dart` — barrel export file
- [ ] `lib/src/vlibras_value.dart` — VLibrasValue class + VLibrasStatus enum
- [ ] `lib/src/vlibras_platform.dart` — VLibrasPlatform abstract class
- [ ] `lib/src/vlibras_controller.dart` — VLibrasController class
- [ ] `test/vlibras_controller_test.dart` — unit tests (stubs first, filled during wave 1)
- [ ] `test/mocks/mock_vlibras_platform.dart` — MockVLibrasPlatform (mocktail)

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
