---
phase: 1
slug: sdk-investigation-spike
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-23
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | integration_test (Flutter SDK bundled) |
| **Config file** | none — driven by `flutter drive` CLI |
| **Quick run command** | `flutter run -d chrome` |
| **Full suite command** | `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/vlibras_load_test.dart -d chrome` |
| **Estimated runtime** | ~60 seconds (Unity WebGL cold-load is slow) |

---

## Sampling Rate

- **After every task commit:** Run `flutter run -d chrome` — manually verify avatar appears
- **After every plan wave:** Run `flutter drive --driver=test_driver/integration_test.dart --target=integration_test/vlibras_load_test.dart -d chrome`
- **Before `/gsd:verify-work`:** Full integration suite must be green + findings document written
- **Max feedback latency:** ~60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 0 | SC-1 | integration | `flutter drive ... -d chrome` | ❌ W0 | ⬜ pending |
| 1-01-02 | 01 | 0 | SC-2 | integration | `flutter drive ... -d chrome` | ❌ W0 | ⬜ pending |
| 1-01-03 | 01 | 1 | SC-1 | integration (visual) | `flutter drive ... -d chrome` | ❌ W0 | ⬜ pending |
| 1-01-04 | 01 | 1 | SC-2 | integration (visual) | `flutter drive ... -d chrome` | ❌ W0 | ⬜ pending |
| 1-01-05 | 01 | 2 | SC-3 | manual | N/A — document check | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `spike/` — create with `flutter create --platforms web spike`
- [ ] `spike/integration_test/vlibras_load_test.dart` — stubs for SC-1 (avatar renders) and SC-2 (translate triggers animation)
- [ ] `spike/test_driver/integration_test.dart` — minimal driver: `integrationDriver()`
- [ ] `spike/pubspec.yaml` — add `web: ^1.0.0` under dependencies
- [ ] `.planning/research/` directory — for phase-01-findings.md

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| VLibras 3D avatar visually animating in LIBRAS | SC-2 | Automated assertions cannot verify Unity WebGL animation correctness | Open `flutter run -d chrome`, call translate("olá"), observe avatar signing |
| Findings document completeness | SC-3 | Document review cannot be automated | Open `.planning/research/phase-01-findings.md`, verify all required sections: API surface, CDN URLs, CSP/CORS, dead ends, license |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
