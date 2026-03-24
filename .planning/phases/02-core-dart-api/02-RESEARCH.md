# Phase 2: Core Dart API - Research

**Researched:** 2026-03-24
**Domain:** Flutter plugin Dart API design — Controller/Value/Platform interface pattern, state machine, unit testing with mocks
**Confidence:** HIGH (Flutter/Dart patterns verified against official sources; decisions locked by CONTEXT.md)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**State machine — 6 states:**
- `idle` → `initializing` → `ready` → `translating` → `playing` → `error`
- `idle`: controller created but initialize() not yet called
- `initializing`: initialize() in progress
- `ready`: initialized, waiting for translate()
- `translating`: translate() accepted, waiting for player response
- `playing`: avatar animating
- `error`: failure during initialize() or translate()
- translate() while `translating` or `playing` → cancels current, starts new (v1; queue is DIFF-01 v2)
- After `error` → state resets automatically to `translating` when translate() is called
- initialize() is idempotent — repeated calls when already `ready`/`translating`/`playing` are ignored

**VLibrasValue structure:**
- Fields: `status` (enum `VLibrasStatus`) + `error` (String?) — minimum for v1
- Immutable data class (`@immutable`), NOT a sealed class
- Implements `==` and `hashCode` (avoids unnecessary notifications on ValueNotifier)
- Implements `copyWith()` for internal partial updates
- `error` is `null` when no error; descriptive String when there is one

**Notification mechanism:**
- `VLibrasController extends ChangeNotifier` and exposes `VLibrasValue value`
- Developer consumes via `ValueListenableBuilder<VLibrasValue>` or `addListener`
- Established Flutter pattern (identical to `VideoPlayerController`)

**Platform interface scope:**
- `VLibrasPlatform` is a simple **abstract class** (no `plugin_platform_interface` package — plugin is not federated)
- Public methods exposed: `initialize()`, `translate(String text)`, `pause()`, `stop()`, `resume()`, `repeat()`, `setSpeed(double speed)`, `dispose()`
- `load()`, `on()`, `off()` are **internal implementation** of the web platform (Phase 3) — do NOT appear in the interface
- Controller receives implementation via **constructor with optional parameter**: `VLibrasController({VLibrasPlatform? platform})`
- In production, Controller uses real implementation (injected by web layer in Phase 3); in tests, receives a mock

**Error model:**
- `VLibrasValue.error` is `String?` — human-readable message, null when no error
- Errors from `initialize()` and `translate()` handled the same (both go to `VLibrasValue.error`)
- Message must include context: `"Falha ao inicializar: ..."` or `"Falha ao traduzir: ..."`
- `error` clears immediately (returns to `null`) when entering `translating` state
- Controller uses `debugPrint` in debug mode to log errors internally — silent in release

### Claude's Discretion

- Exact names for enum values of `VLibrasStatus` (must cover the 6 states above)
- File and directory structure within `lib/`
- Unit test details (coverage and mock structure)

### Deferred Ideas (OUT OF SCOPE)

- Translation queue (translate() while playing → enqueue) — DIFF-01, deferred to v2
- VLibrasValue with `text` field (text being translated) — can be added without breaking change in v2
- VLibrasValue with `progress` field (0.0–1.0) — `animation:progress` event exists in Player, but exposing in v1 is not required
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| CORE-01 | Developer can instantiate a VLibrasController and associate it with a VLibrasView widget | Controller/Value/ChangeNotifier pattern documented; constructor with optional platform injection researched |
| CORE-03 | VLibrasController exposes VLibrasValue with states: idle, loading, playing, error | 6-state machine design locked; ValueNotifier/ChangeNotifier pattern verified against video_player reference |
| CORE-04 | VLibrasController has async initialize() for initialization and dispose() for resource release | initialize()/dispose() lifecycle pattern researched; ChangeNotifier.dispose() pattern confirmed |
| ERR-01 | Translation/initialization errors are exposed via VLibrasValue.error (no exceptions thrown to developer) | Error model locked; try/catch-to-value pattern researched; VLibrasValue.error as String? confirmed |
</phase_requirements>

---

## Summary

Phase 2 builds the pure Dart API layer: `VLibrasController`, `VLibrasValue`, and `VLibrasPlatform` (interface). No web platform implementation — this phase produces code that compiles and is fully unit-testable using mock platforms without any running web player.

The reference architecture is the Flutter `video_player` package (`VideoPlayerController extends ValueNotifier<VideoPlayerValue>`). The locked decisions in CONTEXT.md differ slightly: `VLibrasController extends ChangeNotifier` (not `ValueNotifier`) and exposes `VLibrasValue value` as a plain getter. This is equivalent in behavior — both are ChangeNotifier-based and observable via `ValueListenableBuilder` or `addListener`. The planner should implement exactly what CONTEXT.md specifies.

Testing uses either `mocktail` (zero codegen, simpler setup) or `mockito` (codegen, more ceremony). Since `VLibrasPlatform` is a simple abstract class with ~8 abstract methods, either works. `mocktail` is the recommendation for this phase because it requires no `build_runner` step, keeping the Wave 0 setup lightweight.

**Primary recommendation:** Follow the `VideoPlayerController`/`VideoPlayerValue` structural template exactly, adjusted for the 6-state enum machine and error-as-String model locked in CONTEXT.md. Use `mocktail` for mock platform in unit tests.

---

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter (SDK) | >=3.7.2 (Dart SDK ^3.7.2) | Framework; ChangeNotifier, @immutable, debugPrint | Already pinned by spike pubspec.yaml |
| meta | bundled with flutter | `@immutable` annotation | Part of flutter/meta; no separate dep needed |
| flutter_test | SDK bundled | Unit test framework; `test()`, `expect()`, `group()` | Flutter-standard; no pub.dev dep needed |

### Supporting (dev)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| mocktail | ^0.3.0 | Mock `VLibrasPlatform` without code generation | Recommended for this phase — zero codegen |
| mockito | ^5.6.3 | Code-gen mocks via `@GenerateNiceMocks` | Alternative if project already uses mockito elsewhere |
| build_runner | ^2.4.0 | Code generation runner (required ONLY if using mockito) | Only needed if mockito is chosen |
| flutter_lints | ^5.0.0 | Lint rules for Dart/Flutter packages | Standard for all Flutter packages created 2024+ |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| mocktail | mockito | mockito requires build_runner + code generation step; mocktail simpler for a small abstract interface |
| mocktail | manual Fake | `class FakePlatform extends Fake implements VLibrasPlatform` is valid with no deps; less expressive stubs |
| ChangeNotifier (as decided) | ValueNotifier<VLibrasValue> | VideoPlayerController uses ValueNotifier; both work; CONTEXT.md locks ChangeNotifier |
| abstract class VLibrasPlatform | plugin_platform_interface | plugin_platform_interface adds federated plugin plumbing; locked out as not needed (non-federated) |

**Installation:**
```bash
# In plugin root (not spike/):
flutter pub add dev:mocktail
flutter pub add dev:flutter_lints
```

---

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── src/
│   ├── vlibras_controller.dart   # VLibrasController (ChangeNotifier)
│   ├── vlibras_value.dart        # VLibrasValue + VLibrasStatus enum
│   └── vlibras_platform.dart     # VLibrasPlatform abstract class (interface)
└── vlibras_flutter.dart          # Public barrel export: exports the three above

test/
├── vlibras_controller_test.dart  # Unit tests for controller state machine
└── mocks/
    └── mock_vlibras_platform.dart  # MockVLibrasPlatform (mocktail or manual)
```

**Rationale:** `lib/src/` hides implementation details; the barrel file (`vlibras_flutter.dart`) is the only public surface. This is the standard Dart package layout convention.

### Pattern 1: VLibrasValue as @immutable data class with copyWith

**What:** An immutable value object holding `VLibrasStatus status` and `String? error`. All fields are `final`. Equality and hashCode are based on all fields. `copyWith()` enables internal updates without mutation.

**When to use:** Every state transition in the controller creates a new `VLibrasValue` via `copyWith()` rather than modifying fields.

**Example:**
```dart
// Source: Verified pattern from VideoPlayerValue in flutter/packages + @immutable docs
import 'package:flutter/foundation.dart';

enum VLibrasStatus { idle, initializing, ready, translating, playing, error }

@immutable
class VLibrasValue {
  const VLibrasValue({
    this.status = VLibrasStatus.idle,
    this.error,
  });

  final VLibrasStatus status;
  final String? error;

  bool get hasError => error != null;

  VLibrasValue copyWith({
    VLibrasStatus? status,
    String? error,
    bool clearError = false,
  }) {
    return VLibrasValue(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VLibrasValue &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          error == other.error;

  @override
  int get hashCode => Object.hash(status, error);

  @override
  String toString() => 'VLibrasValue(status: $status, error: $error)';
}
```

### Pattern 2: VLibrasController extends ChangeNotifier

**What:** The controller owns a mutable `_value` field and notifies listeners via `notifyListeners()` whenever state transitions occur. The public `value` getter returns the current `VLibrasValue`.

**When to use:** This is THE controller pattern for all state transitions.

**Example:**
```dart
// Source: Structural analog to VideoPlayerController in flutter/packages
// Controller receives optional platform for testability (dependency injection)
import 'package:flutter/foundation.dart';
import 'vlibras_value.dart';
import 'vlibras_platform.dart';

class VLibrasController extends ChangeNotifier {
  VLibrasController({VLibrasPlatform? platform})
      : _platform = platform ?? _defaultPlatform();

  final VLibrasPlatform _platform;
  VLibrasValue _value = const VLibrasValue();

  VLibrasValue get value => _value;

  void _setValue(VLibrasValue newValue) {
    if (_value == newValue) return;   // == operator prevents spurious notifies
    _value = newValue;
    notifyListeners();
  }

  Future<void> initialize() async {
    // Idempotent: ignore if already initialized
    if (_value.status != VLibrasStatus.idle) return;
    _setValue(_value.copyWith(status: VLibrasStatus.initializing));
    try {
      await _platform.initialize();
      _setValue(_value.copyWith(status: VLibrasStatus.ready, clearError: true));
    } catch (e) {
      debugPrint('[VLibrasController] initialize error: $e');
      _setValue(_value.copyWith(
        status: VLibrasStatus.error,
        error: 'Falha ao inicializar: $e',
      ));
    }
  }

  Future<void> translate(String text) async {
    // Cancel current translation: works from translating, playing, or error
    _setValue(_value.copyWith(
      status: VLibrasStatus.translating,
      clearError: true,
    ));
    try {
      await _platform.translate(text);
    } catch (e) {
      debugPrint('[VLibrasController] translate error: $e');
      _setValue(_value.copyWith(
        status: VLibrasStatus.error,
        error: 'Falha ao traduzir: $e',
      ));
    }
  }

  @override
  void dispose() {
    _platform.dispose();
    super.dispose();
  }
}
```

**Note:** The `playing` state transitions are driven by platform callbacks (Phase 3). In Phase 2, the platform interface defines async methods; the `playing` state will be entered when the platform reports `animation:play` via a callback mechanism (to be designed at Phase 3 boundary).

### Pattern 3: VLibrasPlatform as abstract class (interface)

**What:** A pure abstract class defining the contract between the controller and any platform implementation. No `plugin_platform_interface` package (not a federated plugin).

**When to use:** This is the seam for dependency injection — production code will have `VLibrasWebPlatform extends VLibrasPlatform`; tests use a mock.

**Example:**
```dart
// Source: Derived from CONTEXT.md locked decisions + standard Dart abstract class conventions
abstract class VLibrasPlatform {
  Future<void> initialize();
  Future<void> translate(String text);
  Future<void> pause();
  Future<void> stop();
  Future<void> resume();
  Future<void> repeat();
  Future<void> setSpeed(double speed);
  void dispose();
}
```

### Pattern 4: Mock platform for unit tests (mocktail)

**What:** A mock implementing `VLibrasPlatform` created with `mocktail` — no codegen, no `build_runner`.

**When to use:** All unit tests in `test/vlibras_controller_test.dart`.

**Example:**
```dart
// Source: mocktail docs — https://pub.dev/packages/mocktail
import 'package:mocktail/mocktail.dart';
import 'package:vlibras_flutter/src/vlibras_platform.dart';

class MockVLibrasPlatform extends Mock implements VLibrasPlatform {}

// In tests:
void main() {
  late MockVLibrasPlatform platform;
  late VLibrasController controller;

  setUp(() {
    platform = MockVLibrasPlatform();
    controller = VLibrasController(platform: platform);
    // Stub all methods that will be called
    when(() => platform.initialize()).thenAnswer((_) async {});
    when(() => platform.translate(any())).thenAnswer((_) async {});
    when(() => platform.dispose()).thenReturn(null);
  });

  test('initialize transitions idle → initializing → ready', () async {
    expect(controller.value.status, VLibrasStatus.idle);
    final future = controller.initialize();
    // After calling but before await, state may be initializing
    await future;
    expect(controller.value.status, VLibrasStatus.ready);
    expect(controller.value.error, isNull);
  });

  test('initialize error sets error state', () async {
    when(() => platform.initialize())
        .thenThrow(Exception('network unavailable'));
    await controller.initialize();
    expect(controller.value.status, VLibrasStatus.error);
    expect(controller.value.error, contains('Falha ao inicializar'));
  });
}
```

### Anti-Patterns to Avoid

- **Throwing exceptions from controller public methods:** `initialize()` and `translate()` must catch all exceptions and route them into `VLibrasValue.error`. Never let exceptions propagate to the caller (ERR-01).
- **Mutable `VLibrasValue` fields:** All fields must be `final`. The `@immutable` annotation enforces this at analyzer level.
- **Calling `notifyListeners()` when value did not change:** The `_setValue` guard (`if (_value == newValue) return`) prevents spurious rebuilds. This requires correct `==` implementation on `VLibrasValue`.
- **Putting `load()`, `on()`, `off()` in VLibrasPlatform:** These are internal web implementation details (Phase 3). The platform interface exposes only the controller-facing methods listed in CONTEXT.md.
- **Using `plugin_platform_interface` package:** Not applicable for non-federated plugins. Adds unnecessary complexity.
- **Sealed class for VLibrasValue:** CONTEXT.md locks `@immutable` data class; sealed class would require exhaustive pattern matching in consumer code which is not intended for v1.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Mock platform for tests | Manual stub class with all methods | mocktail `extends Mock implements VLibrasPlatform` | mocktail handles unimplemented method errors, verify(), when() with zero codegen |
| Equality on value objects | Manual field comparison loops | `Object.hash()` + `==` per field | `Object.hash()` is the idiomatic Dart way; VideoPlayerValue does exactly this |
| Immutability enforcement | Runtime checks | `@immutable` annotation + `final` fields | Dart analyzer lint catches violations at write time, not runtime |
| State notification | Custom event stream | `ChangeNotifier.notifyListeners()` | Integrates directly with `ValueListenableBuilder`, `AnimatedBuilder`, `ListenableBuilder` |
| Debug-only logging | Print statements everywhere | `debugPrint()` | `debugPrint` is silenced in release mode automatically; no custom guard needed |

**Key insight:** The `ChangeNotifier`/`ValueNotifier` ecosystem in Flutter is deeply integrated with the widget tree. Building a custom event bus or stream would break compatibility with standard Flutter state management patterns and `ValueListenableBuilder`.

---

## Common Pitfalls

### Pitfall 1: Spurious notifyListeners() calls

**What goes wrong:** Controller calls `notifyListeners()` on every state update, even when the value did not actually change. This causes expensive widget rebuilds for no reason.

**Why it happens:** Forgetting to implement `==` and `hashCode` on `VLibrasValue`, or not guarding `_setValue` with an equality check.

**How to avoid:** Implement `==` and `hashCode` on `VLibrasValue` (locked in CONTEXT.md). In `_setValue`, check `if (_value == newValue) return;` before assigning and notifying.

**Warning signs:** Tests that check `notifyListeners` call count show unexpected extra calls; profiler shows excessive rebuilds.

### Pitfall 2: initialize() called multiple times — race condition

**What goes wrong:** Developer calls `initialize()` twice before the first completes. Controller starts two concurrent `initializing` flows, leading to double state transitions.

**Why it happens:** No guard on the entry state.

**How to avoid:** The idempotency rule is locked: `if (_value.status != VLibrasStatus.idle) return;` at the top of `initialize()`. Any status other than `idle` is a no-op. This prevents re-entry entirely.

**Warning signs:** Tests show final state as `initializing` instead of `ready` because the second call's early return left the first call's transition hanging.

### Pitfall 3: Errors thrown instead of stored in VLibrasValue

**What goes wrong:** Platform method throws; controller propagates the exception to the caller instead of catching it.

**Why it happens:** Missing try/catch in `initialize()` or `translate()`.

**How to avoid:** Both `initialize()` and `translate()` must wrap platform calls in try/catch. On catch: set status to `VLibrasStatus.error`, set `error` to descriptive string with context prefix, call `debugPrint`.

**Warning signs:** Tests of error paths fail with unhandled exceptions rather than assertions on `controller.value.error`.

### Pitfall 4: error field not cleared on next translate() call

**What goes wrong:** After an error, `translate()` is called again. The old `error` string lingers in `VLibrasValue` even though status transitions to `translating`.

**Why it happens:** `copyWith()` call in `translate()` forgets to pass `clearError: true`.

**How to avoid:** When entering `translating` state (in `translate()`), always call `copyWith(status: VLibrasStatus.translating, clearError: true)`. This is explicit in CONTEXT.md: "error clears immediately when entering translating."

**Warning signs:** UI shows stale error message after user retries; `controller.value.error` is non-null with status `translating`.

### Pitfall 5: dispose() called on platform but ChangeNotifier.dispose() not called (or vice versa)

**What goes wrong:** Controller override of `dispose()` calls `_platform.dispose()` but forgets `super.dispose()`, leaving ChangeNotifier resources unreleased (or calls `super.dispose()` first, then tries to use the notifier).

**Why it happens:** `@override void dispose()` — easy to forget `super.dispose()`.

**How to avoid:** Always call `_platform.dispose()` first (clean up platform resources), then `super.dispose()` (releases ChangeNotifier listeners). Never call `notifyListeners()` after `super.dispose()`.

**Warning signs:** Test teardown prints "A listener was called after dispose()"; memory leak warnings in flutter_test.

### Pitfall 6: VLibrasPlatform.dispose() returns Future vs. void

**What goes wrong:** `dispose()` in the abstract interface returns `Future<void>`, but `ChangeNotifier.dispose()` is synchronous `void`. If the platform's async dispose is awaited inside the controller's synchronous `dispose()`, Dart will silently discard the Future.

**Why it happens:** Trying to make platform disposal async when the framework's dispose pattern is synchronous.

**How to avoid:** Declare `VLibrasPlatform.dispose()` as synchronous `void`. Platform implementations must handle any async cleanup internally (fire-and-forget if needed) or use a separate `close()` method. The controller's `dispose()` must remain synchronous.

**Warning signs:** `Unhandled Future` lint warnings; async cleanup that never completes.

---

## Code Examples

Verified patterns from official sources:

### ChangeNotifier subclass with value pattern
```dart
// Source: structural analog to VideoPlayerController
// https://github.com/flutter/packages/blob/main/packages/video_player/video_player/lib/video_player.dart
class VLibrasController extends ChangeNotifier {
  VLibrasValue _value = const VLibrasValue();
  VLibrasValue get value => _value;

  void _setValue(VLibrasValue newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }
}
```

### Listening with ValueListenableBuilder (consumer side — reference only)
```dart
// Source: Flutter docs — ValueListenableBuilder
// https://api.flutter.dev/flutter/widgets/ValueListenableBuilder-class.html
// Note: requires controller to implement ValueListenable<VLibrasValue>
// OR use AnimatedBuilder / ListenableBuilder with ChangeNotifier:
ListenableBuilder(
  listenable: controller,
  builder: (context, _) {
    return Text(controller.value.status.name);
  },
);
```

**Note:** `ChangeNotifier` works with `ListenableBuilder` (Flutter 3.7+) or `AnimatedBuilder`. `ValueListenableBuilder` requires `ValueNotifier` specifically. Since CONTEXT.md locks `extends ChangeNotifier`, the consumer must use `ListenableBuilder` or `addListener`. The CONTEXT.md mentions `ValueListenableBuilder<VLibrasValue>` as consumption pattern — this is achievable if the controller also `implements ValueListenable<VLibrasValue>` (add `@override VLibrasValue get value` which is already present). This is worth implementing.

### debugPrint usage
```dart
// Source: Flutter API docs — debugPrint
// https://api.flutter.dev/flutter/foundation/debugPrint.html
// debugPrint is a no-op in release mode automatically.
debugPrint('[VLibrasController] error during initialize: $e');
```

### @immutable + copyWith pattern
```dart
// Source: meta package annotation + VideoPlayerValue pattern
// https://api.flutter.dev/flutter/meta/immutable-constant.html
import 'package:flutter/foundation.dart';  // exports @immutable from meta

@immutable
class VLibrasValue {
  const VLibrasValue({this.status = VLibrasStatus.idle, this.error});
  final VLibrasStatus status;
  final String? error;

  VLibrasValue copyWith({VLibrasStatus? status, String? error, bool clearError = false}) =>
    VLibrasValue(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is VLibrasValue && status == other.status && error == other.error;

  @override
  int get hashCode => Object.hash(status, error);
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `dart:js` / `dart:html` interop | `dart:js_interop` + `package:web` | Dart 3.3 (2024), deprecated Dart 3.7 (Feb 2025) | Phase 2 is pure Dart — no web interop needed; but Phase 3 must use new APIs |
| `flutter_driver` for plugin tests | `flutter_test` unit tests + `integration_test` | Flutter 2.5+ | Phase 2 uses plain `flutter_test` unit tests; no integration layer needed |
| mockito 4.x (non-null-safe) | mockito 5.x + build_runner (null-safe) | Dart 2.12 / 2022 | mockito now requires codegen; mocktail is the zero-codegen alternative |
| Manual `toString`/`hashCode` | `Object.hash()` (Dart 2.14+) | Dart 2.14 (2021) | `Object.hash()` is now the idiomatic way to combine hash codes |
| `plugin_platform_interface` for all plugins | Only for federated plugins | Flutter 2.x | Non-federated plugins do not need this package |

**Deprecated/outdated:**
- `dart:html`: Deprecated Dart 3.7. Phase 2 has no web code, so no impact here.
- `ListenableBuilder`: Available since Flutter 3.7.0; preferred over `AnimatedBuilder` for non-animation use cases.
- `ValueListenableBuilder` with `ChangeNotifier`: Does not work directly; needs `ValueNotifier` or an explicit `implements ValueListenable<T>` on the class.

---

## Open Questions

1. **Should VLibrasController also implement ValueListenable<VLibrasValue>?**
   - What we know: CONTEXT.md says developer consumes via `ValueListenableBuilder<VLibrasValue>` or `addListener`. `ValueListenableBuilder` requires `ValueListenable<T>`.
   - What's unclear: Whether to make the controller a `ChangeNotifier` that also `implements ValueListenable<VLibrasValue>` (both `addListener` and `ValueListenableBuilder` work), or to accept that `ListenableBuilder` is the consumption pattern.
   - Recommendation: Add `implements ValueListenable<VLibrasValue>` to the class declaration alongside `extends ChangeNotifier`. This satisfies both consumption patterns mentioned in CONTEXT.md. The `value` getter already satisfies the interface.

2. **How does the controller receive platform callbacks for `playing` state transitions?**
   - What we know: `playing` state is entered when the avatar starts animating (event: `animation:play`). The platform interface as designed is request-driven (async methods). Phase 2 does not implement web platform.
   - What's unclear: Does `VLibrasPlatform` need a callback/stream mechanism so the platform can push `animation:play`/`animation:end` back to the controller? Or is this deferred to Phase 3 design?
   - Recommendation: For Phase 2, the controller's `playing` state can be left as a reachable enum value but not actively tested for transition. The platform interface may need a `Stream<VLibrasPlatformEvent>` or callback setters added in Phase 3. Document this as a Phase 3 design task.

3. **Exact pubspec.yaml structure for the plugin package root**
   - What we know: The project currently only has `spike/`; the plugin `lib/` does not exist yet. Phase 2 creates it.
   - What's unclear: The pubspec.yaml for the plugin root has not been created. Standard Flutter plugin pubspec includes `flutter.plugin.platforms` for platform declarations.
   - Recommendation: Create a minimal plugin pubspec.yaml without platform declarations for now (Phase 3 will add `web:` platform entry). The package name should be `vlibras_flutter` (matching the project core value statement).

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (Flutter SDK bundled) |
| Config file | none — `flutter test` discovers `test/` automatically |
| Quick run command | `flutter test test/vlibras_controller_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CORE-01 | VLibrasController can be instantiated with default and injected platform | unit | `flutter test test/vlibras_controller_test.dart` | No — Wave 0 |
| CORE-03 | controller.value.status transitions through all 6 states; observable via addListener | unit | `flutter test test/vlibras_controller_test.dart` | No — Wave 0 |
| CORE-04 | initialize() is async, idempotent; dispose() releases platform resources | unit | `flutter test test/vlibras_controller_test.dart` | No — Wave 0 |
| ERR-01 | Errors from initialize()/translate() land in VLibrasValue.error; no exceptions propagate | unit | `flutter test test/vlibras_controller_test.dart` | No — Wave 0 |

### Key test cases to cover (planner should include these in task acceptance criteria)
- `idle` → `initializing` → `ready` on successful initialize()
- `idle` → `initializing` → `error` when platform.initialize() throws
- `ready` → `translating` on translate() call (error cleared)
- `translating` → `error` when platform.translate() throws
- `translating` state mid-flight → new translate() call cancels and restarts (replaces)
- initialize() called a second time when already `ready` → no state change (idempotent)
- dispose() calls platform.dispose() then super.dispose()
- `VLibrasValue` equality: two values with same fields are `==`
- `VLibrasValue` equality: prevents spurious notifyListeners()

### Sampling Rate
- **Per task commit:** `flutter test test/vlibras_controller_test.dart`
- **Per wave merge:** `flutter test` (full suite)
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `pubspec.yaml` — plugin root pubspec (name: vlibras_flutter, sdk: ^3.7.2, dev: mocktail, flutter_lints)
- [ ] `analysis_options.yaml` — `include: package:flutter_lints/flutter.yaml`
- [ ] `lib/vlibras_flutter.dart` — barrel export file
- [ ] `lib/src/vlibras_value.dart` — VLibrasValue class + VLibrasStatus enum
- [ ] `lib/src/vlibras_platform.dart` — VLibrasPlatform abstract class
- [ ] `lib/src/vlibras_controller.dart` — VLibrasController class
- [ ] `test/vlibras_controller_test.dart` — unit tests
- [ ] `test/mocks/mock_vlibras_platform.dart` — MockVLibrasPlatform (mocktail)

---

## Sources

### Primary (HIGH confidence)
- [VideoPlayerController source](https://github.com/flutter/packages/blob/main/packages/video_player/video_player/lib/video_player.dart) — ChangeNotifier/ValueNotifier pattern, copyWith, errorDescription, platform injection
- [Flutter developing packages docs](https://docs.flutter.dev/packages-and-plugins/developing-packages) — package vs. plugin structure, pubspec declarations
- [Dart package layout conventions](https://dart.dev/tools/pub/package-layout) — `lib/src/` hiding, barrel exports
- [meta @immutable docs](https://api.flutter.dev/flutter/meta/immutable-constant.html) — annotation usage, all fields must be final
- [debugPrint API docs](https://api.flutter.dev/flutter/foundation/debugPrint.html) — release-mode no-op behavior confirmed
- [flutter_lints pub.dev](https://pub.dev/packages/flutter_lints) — current version, analysis_options.yaml setup

### Secondary (MEDIUM confidence)
- [mocktail pub.dev](https://pub.dev/packages/mocktail) — `extends Mock implements X`, no codegen, current version ^0.3.0
- [mockito pub.dev](https://pub.dev/packages/mockito) — version 5.6.3, `@GenerateNiceMocks`, build_runner requirement
- [Flutter mocking cookbook](https://docs.flutter.dev/cookbook/testing/unit/mocking) — Mockito setup, GenerateMocks annotation
- [Flutter testing plugins docs](https://docs.flutter.dev/testing/testing-plugins) — plugin-specific test patterns

### Tertiary (LOW confidence — verify if used)
- Phase 1 findings: `spike/lib/vlibras_js.dart` — VLibrasPlayerInstance method names confirmed as source for VLibrasPlatform interface design (resume workaround `@JS('continue')` is Phase 3 concern only)

---

## Metadata

**Confidence breakdown:**
- Standard stack (Flutter/Dart pattern): HIGH — VideoPlayerController source confirmed; @immutable, debugPrint, ChangeNotifier are core Flutter APIs
- Architecture (Controller/Value structure): HIGH — directly mirrors video_player package, verified against source
- Testing approach (mocktail): MEDIUM — mocktail is well-established but not the Flutter official recommendation (mockito is); both work
- Pitfalls: HIGH — most pitfalls are derived from direct code analysis of the locked decisions and official API contracts

**Research date:** 2026-03-24
**Valid until:** 2026-05-24 (Flutter/Dart stable APIs; mocktail versioning — verify before use)
