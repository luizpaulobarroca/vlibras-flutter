# VLibras Player Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expor pause/stop/resume/repeat, setSpeed, setAvatar e setSubtitles no `VLibrasController`, adicionar `VLibrasSettingsPanel` reutilizável e integrar painel inline no `VLibrasAccessibilityWidget`, com persistência opt-in via callbacks.

**Architecture:** Três camadas tocadas — `VLibrasPlatform` ganha `setAvatar`/`setSubtitles`; `VLibrasController` expõe API imperativa, mantém estado em `VLibrasValue` estendido e dispara `onSettingsChanged`; camada de widgets adiciona `VLibrasSettingsPanel` público e integra overlay no widget de acessibilidade.

**Tech Stack:** Dart + Flutter 3.7+, `flutter_test`, `mocktail` para mocks, `webview_flutter` no mobile, `web` + `dart:js_interop` no Flutter Web. Sem dependências novas.

**Reference spec:** `docs/superpowers/specs/2026-04-17-vlibras-player-controls-design.md`

---

## File Structure

**Created:**
- `lib/src/vlibras_settings.dart` — `VLibrasSettings` (immutable + toJson/fromJson).
- `lib/src/vlibras_settings_labels.dart` — `VLibrasSettingsLabels` (i18n).
- `lib/src/vlibras_settings_panel.dart` — `VLibrasSettingsPanel` widget.
- `test/vlibras_settings_test.dart` — testes do `VLibrasSettings`.
- `test/vlibras_settings_panel_test.dart` — testes do widget.

**Modified:**
- `lib/src/vlibras_value.dart` — adiciona enums `VLibrasSpeed`/`VLibrasAvatar` e estende `VLibrasValue`.
- `lib/src/vlibras_platform.dart` — adiciona `setAvatar` e `setSubtitles`.
- `lib/src/vlibras_js.dart` — expõe `changeAvatar`/`toggleSubtitle` no extension type.
- `lib/src/vlibras_web_platform.dart` — implementa novos métodos na `VLibrasPlayerAdapter` e no platform.
- `lib/src/platform/web_platform.dart` — `_WebPlayerAdapter` delega os novos métodos.
- `lib/src/platform/mobile_platform.dart` — HTML template + métodos `setAvatar`/`setSubtitles`.
- `lib/src/vlibras_controller.dart` — novos métodos, parâmetros de construtor, fila pré-init.
- `lib/src/vlibras_accessibility_widget.dart` — aceita `controller` opcional, adiciona botão ⚙️ e overlay.
- `lib/vlibras_flutter.dart` — exporta tipos novos.
- `test/vlibras_controller_test.dart` — testes para todos os novos métodos.
- `README.md` — seção "Persisting user preferences".

---

## Task 1: Add `VLibrasSpeed` enum

**Files:**
- Modify: `lib/src/vlibras_value.dart`
- Test: `test/vlibras_controller_test.dart`

- [ ] **Step 1: Write the failing test**

Add this group at the end of the top-level `group` block (before the final `}`) in `test/vlibras_controller_test.dart`:

```dart
  // -------------------------------------------------------------------------
  // VLibrasSpeed
  // -------------------------------------------------------------------------
  group('VLibrasSpeed', () {
    test('has exactly 3 values', () {
      expect(VLibrasSpeed.values, hasLength(3));
    });

    test('exposes multiplier 0.5 / 1.0 / 1.5', () {
      expect(VLibrasSpeed.slow.multiplier, 0.5);
      expect(VLibrasSpeed.normal.multiplier, 1.0);
      expect(VLibrasSpeed.fast.multiplier, 1.5);
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "VLibrasSpeed"`
Expected: compilation error — `VLibrasSpeed` not defined.

- [ ] **Step 3: Implement `VLibrasSpeed` enum**

Add to the top of `lib/src/vlibras_value.dart` (after the `import` line):

```dart
/// Playback speed presets accepted by the VLibras Unity player.
///
/// Values map to Unity's speed multiplier: 0.5x (slow), 1.0x (normal), 1.5x (fast).
enum VLibrasSpeed {
  slow(0.5),
  normal(1.0),
  fast(1.5);

  const VLibrasSpeed(this.multiplier);

  /// The raw speed multiplier passed to the Unity player.
  final double multiplier;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "VLibrasSpeed"`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/vlibras_value.dart test/vlibras_controller_test.dart
git commit -m "feat(value): add VLibrasSpeed enum with slow/normal/fast presets"
```

---

## Task 2: Add `VLibrasAvatar` enum

**Files:**
- Modify: `lib/src/vlibras_value.dart`
- Test: `test/vlibras_controller_test.dart`

- [ ] **Step 1: Write the failing test**

Add this group immediately after the `VLibrasSpeed` group in `test/vlibras_controller_test.dart`:

```dart
  // -------------------------------------------------------------------------
  // VLibrasAvatar
  // -------------------------------------------------------------------------
  group('VLibrasAvatar', () {
    test('has exactly 3 values', () {
      expect(VLibrasAvatar.values, hasLength(3));
    });

    test('exposes Unity ids icaro / hosana / guga', () {
      expect(VLibrasAvatar.icaro.id, 'icaro');
      expect(VLibrasAvatar.hosana.id, 'hosana');
      expect(VLibrasAvatar.guga.id, 'guga');
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "VLibrasAvatar"`
Expected: compilation error — `VLibrasAvatar` not defined.

- [ ] **Step 3: Implement `VLibrasAvatar` enum**

Add to `lib/src/vlibras_value.dart` right after the `VLibrasSpeed` enum:

```dart
/// The avatar personas supported by the VLibras Unity player.
///
/// The [id] is the exact string expected by `player.changeAvatar(name)`.
enum VLibrasAvatar {
  icaro('icaro'),
  hosana('hosana'),
  guga('guga');

  const VLibrasAvatar(this.id);

  /// The string accepted by the Unity player's `changeAvatar` message.
  final String id;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "VLibrasAvatar"`
Expected: PASS (2 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/vlibras_value.dart test/vlibras_controller_test.dart
git commit -m "feat(value): add VLibrasAvatar enum (icaro/hosana/guga)"
```

---

## Task 3: Extend `VLibrasValue` with speed, avatar, subtitlesEnabled

**Files:**
- Modify: `lib/src/vlibras_value.dart`
- Test: `test/vlibras_controller_test.dart`

- [ ] **Step 1: Write the failing test**

Inside the existing `group('VLibrasValue', …)` block in `test/vlibras_controller_test.dart`, add these tests **before** the inner `copyWith` sub-group:

```dart
    test('default speed is normal', () {
      const value = VLibrasValue();
      expect(value.speed, VLibrasSpeed.normal);
    });

    test('default avatar is icaro', () {
      const value = VLibrasValue();
      expect(value.avatar, VLibrasAvatar.icaro);
    });

    test('subtitles enabled by default', () {
      const value = VLibrasValue();
      expect(value.subtitlesEnabled, isTrue);
    });

    test('two instances with same speed/avatar/subtitles are equal', () {
      const a = VLibrasValue(
        speed: VLibrasSpeed.fast,
        avatar: VLibrasAvatar.hosana,
        subtitlesEnabled: false,
      );
      const b = VLibrasValue(
        speed: VLibrasSpeed.fast,
        avatar: VLibrasAvatar.hosana,
        subtitlesEnabled: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('instances with different speed are not equal', () {
      const a = VLibrasValue(speed: VLibrasSpeed.slow);
      const b = VLibrasValue(speed: VLibrasSpeed.fast);
      expect(a, isNot(equals(b)));
    });
```

Inside the inner `group('copyWith', …)` block, add these tests:

```dart
      test('changes speed while preserving other fields', () {
        const original = VLibrasValue(
          status: VLibrasStatus.ready,
          avatar: VLibrasAvatar.guga,
          subtitlesEnabled: false,
        );
        final copy = original.copyWith(speed: VLibrasSpeed.fast);
        expect(copy.speed, VLibrasSpeed.fast);
        expect(copy.status, VLibrasStatus.ready);
        expect(copy.avatar, VLibrasAvatar.guga);
        expect(copy.subtitlesEnabled, isFalse);
      });

      test('changes avatar while preserving other fields', () {
        const original = VLibrasValue(speed: VLibrasSpeed.slow);
        final copy = original.copyWith(avatar: VLibrasAvatar.hosana);
        expect(copy.avatar, VLibrasAvatar.hosana);
        expect(copy.speed, VLibrasSpeed.slow);
      });

      test('changes subtitlesEnabled while preserving other fields', () {
        const original = VLibrasValue(avatar: VLibrasAvatar.guga);
        final copy = original.copyWith(subtitlesEnabled: false);
        expect(copy.subtitlesEnabled, isFalse);
        expect(copy.avatar, VLibrasAvatar.guga);
      });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "VLibrasValue"`
Expected: compilation error — `speed`, `avatar`, `subtitlesEnabled` not defined on `VLibrasValue`.

- [ ] **Step 3: Extend `VLibrasValue`**

Replace the entire `VLibrasValue` class in `lib/src/vlibras_value.dart` with:

```dart
/// Immutable value object representing the current state of [VLibrasController].
///
/// Consumers use [VLibrasController.value] to read the current state, and
/// subscribe via [ChangeNotifier.addListener] or [ValueListenableBuilder].
@immutable
class VLibrasValue {
  /// The current lifecycle status.
  final VLibrasStatus status;

  /// A human-readable error message when [status] is [VLibrasStatus.error],
  /// or `null` otherwise.
  final String? error;

  /// The current playback speed preset. Defaults to [VLibrasSpeed.normal].
  final VLibrasSpeed speed;

  /// The currently selected avatar persona. Defaults to [VLibrasAvatar.icaro].
  final VLibrasAvatar avatar;

  /// Whether subtitles are currently visible on the avatar view. Defaults to `true`.
  final bool subtitlesEnabled;

  /// Creates a [VLibrasValue].
  const VLibrasValue({
    this.status = VLibrasStatus.idle,
    this.error,
    this.speed = VLibrasSpeed.normal,
    this.avatar = VLibrasAvatar.icaro,
    this.subtitlesEnabled = true,
  });

  /// Whether this value contains an error message.
  bool get hasError => error != null;

  /// Returns a copy of this value with the given fields replaced.
  ///
  /// Pass [clearError] as `true` to explicitly set [error] to `null`.
  VLibrasValue copyWith({
    VLibrasStatus? status,
    String? error,
    bool clearError = false,
    VLibrasSpeed? speed,
    VLibrasAvatar? avatar,
    bool? subtitlesEnabled,
  }) {
    return VLibrasValue(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      speed: speed ?? this.speed,
      avatar: avatar ?? this.avatar,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VLibrasValue &&
        other.status == status &&
        other.error == error &&
        other.speed == speed &&
        other.avatar == avatar &&
        other.subtitlesEnabled == subtitlesEnabled;
  }

  @override
  int get hashCode =>
      Object.hash(status, error, speed, avatar, subtitlesEnabled);

  @override
  String toString() => 'VLibrasValue('
      'status: $status, '
      'error: $error, '
      'speed: $speed, '
      'avatar: $avatar, '
      'subtitlesEnabled: $subtitlesEnabled)';
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "VLibrasValue"`
Expected: PASS (all VLibrasValue tests including new ones).

- [ ] **Step 5: Commit**

```bash
git add lib/src/vlibras_value.dart test/vlibras_controller_test.dart
git commit -m "feat(value): extend VLibrasValue with speed, avatar, subtitlesEnabled"
```

---

## Task 4: Create `VLibrasSettings`

**Files:**
- Create: `lib/src/vlibras_settings.dart`
- Create: `test/vlibras_settings_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/vlibras_settings_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';

void main() {
  group('VLibrasSettings', () {
    test('defaults match VLibrasValue defaults', () {
      const s = VLibrasSettings();
      expect(s.speed, VLibrasSpeed.normal);
      expect(s.avatar, VLibrasAvatar.icaro);
      expect(s.subtitlesEnabled, isTrue);
    });

    test('equal instances have same hashCode', () {
      const a = VLibrasSettings(
        speed: VLibrasSpeed.fast,
        avatar: VLibrasAvatar.hosana,
        subtitlesEnabled: false,
      );
      const b = VLibrasSettings(
        speed: VLibrasSpeed.fast,
        avatar: VLibrasAvatar.hosana,
        subtitlesEnabled: false,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('toJson emits string keys for enums and bool for subtitlesEnabled', () {
      const s = VLibrasSettings(
        speed: VLibrasSpeed.slow,
        avatar: VLibrasAvatar.guga,
        subtitlesEnabled: false,
      );
      expect(s.toJson(), {
        'speed': 'slow',
        'avatar': 'guga',
        'subtitlesEnabled': false,
      });
    });

    test('fromJson parses a well-formed map', () {
      final s = VLibrasSettings.fromJson(const {
        'speed': 'fast',
        'avatar': 'hosana',
        'subtitlesEnabled': true,
      });
      expect(s.speed, VLibrasSpeed.fast);
      expect(s.avatar, VLibrasAvatar.hosana);
      expect(s.subtitlesEnabled, isTrue);
    });

    test('fromJson falls back to defaults for missing/unknown keys', () {
      final s = VLibrasSettings.fromJson(const {'speed': 'invalid'});
      expect(s.speed, VLibrasSpeed.normal);
      expect(s.avatar, VLibrasAvatar.icaro);
      expect(s.subtitlesEnabled, isTrue);
    });

    test('toJson -> fromJson round-trips', () {
      const original = VLibrasSettings(
        speed: VLibrasSpeed.slow,
        avatar: VLibrasAvatar.guga,
        subtitlesEnabled: false,
      );
      final roundTrip = VLibrasSettings.fromJson(original.toJson());
      expect(roundTrip, equals(original));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/vlibras_settings_test.dart`
Expected: compilation error — `VLibrasSettings` not defined.

- [ ] **Step 3: Implement `VLibrasSettings`**

Create `lib/src/vlibras_settings.dart`:

```dart
import 'package:flutter/foundation.dart';

import 'vlibras_value.dart';

/// Immutable, serialisable payload carrying the user-facing VLibras settings.
///
/// Distinct from [VLibrasValue] — this object only contains preferences
/// (speed, avatar, subtitles), not status or error. Meant to be handed to
/// `VLibrasController(onSettingsChanged: ...)` callbacks for persistence.
@immutable
class VLibrasSettings {
  /// Creates a [VLibrasSettings].
  const VLibrasSettings({
    this.speed = VLibrasSpeed.normal,
    this.avatar = VLibrasAvatar.icaro,
    this.subtitlesEnabled = true,
  });

  /// The current playback speed preset.
  final VLibrasSpeed speed;

  /// The selected avatar persona.
  final VLibrasAvatar avatar;

  /// Whether subtitles are currently enabled on the avatar view.
  final bool subtitlesEnabled;

  /// Returns a copy with the given fields replaced.
  VLibrasSettings copyWith({
    VLibrasSpeed? speed,
    VLibrasAvatar? avatar,
    bool? subtitlesEnabled,
  }) {
    return VLibrasSettings(
      speed: speed ?? this.speed,
      avatar: avatar ?? this.avatar,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
    );
  }

  /// Serialises this settings payload to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'speed': speed.name,
        'avatar': avatar.name,
        'subtitlesEnabled': subtitlesEnabled,
      };

  /// Parses a [VLibrasSettings] from a JSON map. Falls back to defaults for
  /// any missing or unrecognised fields — never throws.
  factory VLibrasSettings.fromJson(Map<String, dynamic> json) {
    return VLibrasSettings(
      speed: _enumFromName(VLibrasSpeed.values, json['speed']) ??
          VLibrasSpeed.normal,
      avatar: _enumFromName(VLibrasAvatar.values, json['avatar']) ??
          VLibrasAvatar.icaro,
      subtitlesEnabled: json['subtitlesEnabled'] is bool
          ? json['subtitlesEnabled'] as bool
          : true,
    );
  }

  static T? _enumFromName<T extends Enum>(List<T> values, Object? raw) {
    if (raw is! String) return null;
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VLibrasSettings &&
        other.speed == speed &&
        other.avatar == avatar &&
        other.subtitlesEnabled == subtitlesEnabled;
  }

  @override
  int get hashCode => Object.hash(speed, avatar, subtitlesEnabled);

  @override
  String toString() =>
      'VLibrasSettings(speed: $speed, avatar: $avatar, subtitlesEnabled: $subtitlesEnabled)';
}
```

- [ ] **Step 4: Export from barrel**

Modify `lib/vlibras_flutter.dart` — add this line in the `export` block:

```dart
export 'src/vlibras_settings.dart';
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/vlibras_settings_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 6: Commit**

```bash
git add lib/src/vlibras_settings.dart lib/vlibras_flutter.dart test/vlibras_settings_test.dart
git commit -m "feat(settings): add VLibrasSettings with toJson/fromJson"
```

---

## Task 5: Add `setAvatar`/`setSubtitles` to `VLibrasPlatform`

**Files:**
- Modify: `lib/src/vlibras_platform.dart`
- Modify: `test/vlibras_controller_test.dart` (setUp)

- [ ] **Step 1: Extend `VLibrasPlatform` interface**

Append these two methods inside the `abstract class VLibrasPlatform { … }` in `lib/src/vlibras_platform.dart`, immediately before `void dispose();`:

```dart
  /// Sets the active avatar persona.
  Future<void> setAvatar(VLibrasAvatar avatar);

  /// Applies the desired subtitles state.
  ///
  /// Implementations that can only toggle should assume the caller already
  /// verified the desired state differs from the current one.
  Future<void> setSubtitles(bool enabled);
```

Add this import at the top of the file:

```dart
import 'vlibras_value.dart';
```

- [ ] **Step 2: Stub the new methods in existing test setUp**

In `test/vlibras_controller_test.dart`, update the `setUp()` block to add stubs for the new methods (immediately after the existing `when(() => platform.dispose()).thenReturn(null);`):

```dart
    when(() => platform.pause()).thenAnswer((_) async {});
    when(() => platform.stop()).thenAnswer((_) async {});
    when(() => platform.resume()).thenAnswer((_) async {});
    when(() => platform.repeat()).thenAnswer((_) async {});
    when(() => platform.setSpeed(any())).thenAnswer((_) async {});
    when(() => platform.setAvatar(any())).thenAnswer((_) async {});
    when(() => platform.setSubtitles(any())).thenAnswer((_) async {});
```

Add `registerFallbackValue` calls at the very top of `main()` (before `late final`):

```dart
  setUpAll(() {
    registerFallbackValue(VLibrasAvatar.icaro);
  });
```

- [ ] **Step 3: Run existing tests to confirm they still pass**

Run: `flutter test test/vlibras_controller_test.dart`
Expected: PASS (all existing tests + new ones from previous tasks). No new failures.

- [ ] **Step 4: Commit**

```bash
git add lib/src/vlibras_platform.dart test/vlibras_controller_test.dart
git commit -m "feat(platform): add setAvatar and setSubtitles to VLibrasPlatform interface"
```

---

## Task 6: Implement web platform `setAvatar`/`setSubtitles`

**Files:**
- Modify: `lib/src/vlibras_js.dart`
- Modify: `lib/src/vlibras_web_platform.dart`
- Modify: `lib/src/platform/web_platform.dart`

- [ ] **Step 1: Expose JS methods on extension type**

Modify `lib/src/vlibras_js.dart` — inside the `extension type VLibrasPlayerInstance …` block, add after the `setSpeed` line:

```dart
  external void changeAvatar(String avatarName);
  external void toggleSubtitle();
```

- [ ] **Step 2: Extend `VLibrasPlayerAdapter`**

In `lib/src/vlibras_web_platform.dart`, inside the `abstract class VLibrasPlayerAdapter { … }` block, add after the `setSpeed` declaration:

```dart
  /// Changes the active avatar to [avatarName].
  void changeAvatar(String avatarName);

  /// Toggles subtitles on/off on the Unity player (no explicit setter exists).
  void toggleSubtitle();
```

- [ ] **Step 3: Implement new methods on `VLibrasWebPlatform`**

In the same file (`lib/src/vlibras_web_platform.dart`), add these methods to `VLibrasWebPlatform` right after `setSpeed`:

```dart
  @override
  Future<void> setAvatar(VLibrasAvatar avatar) async =>
      _player?.changeAvatar(avatar.id);

  @override
  Future<void> setSubtitles(bool enabled) async => _player?.toggleSubtitle();
```

- [ ] **Step 4: Delegate in `_WebPlayerAdapter`**

In `lib/src/platform/web_platform.dart`, add to `_WebPlayerAdapter` after `setSpeed`:

```dart
  @override
  void changeAvatar(String avatarName) => _instance.changeAvatar(avatarName);

  @override
  void toggleSubtitle() => _instance.toggleSubtitle();
```

- [ ] **Step 5: Run web platform test suite**

Run: `flutter test test/vlibras_web_platform_test.dart`
Expected: PASS. If it fails because the fake adapter in that file doesn't implement the new methods, add the two methods as empty stubs on the fake inside the test file (look for `class _FakeAdapter` or similar; add `void changeAvatar(String _) {}` and `void toggleSubtitle() {}`). Re-run.

- [ ] **Step 6: Commit**

```bash
git add lib/src/vlibras_js.dart lib/src/vlibras_web_platform.dart lib/src/platform/web_platform.dart test/vlibras_web_platform_test.dart
git commit -m "feat(web): implement setAvatar and setSubtitles on web platform"
```

---

## Task 7: Implement mobile platform `setAvatar`/`setSubtitles`

**Files:**
- Modify: `lib/src/platform/mobile_platform.dart`

- [ ] **Step 1: Add JS helper functions to HTML template**

In `lib/src/platform/mobile_platform.dart`, find the `_buildHtml` string (inside the `<script>` block at the bottom). Add these two helper functions immediately after the existing `function vlibrasTranslate(t) { … }` line:

```javascript
    function vlibrasChangeAvatar(name) { if (player) player.changeAvatar(name); }
    function vlibrasToggleSubtitle() { if (player) player.toggleSubtitle(); }
```

- [ ] **Step 2: Implement `setAvatar`/`setSubtitles` on the Dart side**

In the same file, add these two overrides after the existing `setSpeed` method:

```dart
  @override
  Future<void> setAvatar(VLibrasAvatar avatar) =>
      _controller.runJavaScript('vlibrasChangeAvatar("${avatar.id}")');

  @override
  Future<void> setSubtitles(bool enabled) =>
      _controller.runJavaScript('vlibrasToggleSubtitle()');
```

- [ ] **Step 3: Verify analyzer is happy**

Run: `flutter analyze lib/src/platform/mobile_platform.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/src/platform/mobile_platform.dart
git commit -m "feat(mobile): implement setAvatar and setSubtitles via runJavaScript"
```

---

## Task 8: Controller — `pause`/`stop`/`resume`/`repeat`

**Files:**
- Modify: `lib/src/vlibras_controller.dart`
- Test: `test/vlibras_controller_test.dart`

- [ ] **Step 1: Write the failing tests**

Append this group at the end of `test/vlibras_controller_test.dart` (inside `main()`):

```dart
  // -------------------------------------------------------------------------
  // Playback controls
  // -------------------------------------------------------------------------
  group('playback controls', () {
    setUp(() async {
      await controller.initialize();
    });

    test('pause() delegates to platform', () async {
      await controller.pause();
      verify(() => platform.pause()).called(1);
    });

    test('stop() delegates to platform', () async {
      await controller.stop();
      verify(() => platform.stop()).called(1);
    });

    test('resume() delegates to platform', () async {
      await controller.resume();
      verify(() => platform.resume()).called(1);
    });

    test('repeat() delegates to platform', () async {
      await controller.repeat();
      verify(() => platform.repeat()).called(1);
    });

    test('platform error in pause() is captured in value.error', () async {
      when(() => platform.pause()).thenThrow(Exception('boom'));
      await controller.pause();
      expect(controller.value.status, VLibrasStatus.error);
      expect(controller.value.error, contains('boom'));
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "playback controls"`
Expected: compilation error — `pause`, `stop`, `resume`, `repeat` are not defined on `VLibrasController`.

- [ ] **Step 3: Implement the methods**

In `lib/src/vlibras_controller.dart`, **replace** the comment line `// Phase 3 will add pause(), stop(), resume(), repeat(), setSpeed() by …` (and the following line) with these methods:

```dart
  /// Pauses the current animation. Errors are captured in [VLibrasValue.error].
  Future<void> pause() => _guardedCall(_platform.pause, 'pause');

  /// Stops the current animation and resets player state.
  Future<void> stop() => _guardedCall(_platform.stop, 'stop');

  /// Resumes a paused animation.
  Future<void> resume() => _guardedCall(_platform.resume, 'resume');

  /// Repeats the last translation from the beginning.
  Future<void> repeat() => _guardedCall(_platform.repeat, 'repeat');

  /// Runs [action] and captures any thrown error into [VLibrasValue.error].
  Future<void> _guardedCall(
    Future<void> Function() action,
    String label,
  ) async {
    try {
      await action();
    } catch (e) {
      debugPrint('[VLibrasController] $label error: $e');
      _setValue(_value.copyWith(
        status: VLibrasStatus.error,
        error: 'Falha em $label: $e',
      ));
    }
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "playback controls"`
Expected: PASS (5 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/vlibras_controller.dart test/vlibras_controller_test.dart
git commit -m "feat(controller): expose pause/stop/resume/repeat"
```

---

## Task 9: Controller — `setSpeed`

**Files:**
- Modify: `lib/src/vlibras_controller.dart`
- Test: `test/vlibras_controller_test.dart`

- [ ] **Step 1: Write the failing tests**

Append this group in `test/vlibras_controller_test.dart`:

```dart
  // -------------------------------------------------------------------------
  // setSpeed
  // -------------------------------------------------------------------------
  group('setSpeed', () {
    setUp(() async {
      await controller.initialize();
    });

    test('delegates to platform with the multiplier', () async {
      await controller.setSpeed(VLibrasSpeed.fast);
      verify(() => platform.setSpeed(1.5)).called(1);
    });

    test('updates value.speed', () async {
      await controller.setSpeed(VLibrasSpeed.slow);
      expect(controller.value.speed, VLibrasSpeed.slow);
    });

    test('platform error is captured in value.error', () async {
      when(() => platform.setSpeed(any())).thenThrow(Exception('no go'));
      await controller.setSpeed(VLibrasSpeed.fast);
      expect(controller.value.status, VLibrasStatus.error);
      expect(controller.value.speed, VLibrasSpeed.normal);
    });
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "setSpeed"`
Expected: compilation error — `setSpeed` not defined.

- [ ] **Step 3: Implement `setSpeed` with pre-ready guard**

In `lib/src/vlibras_controller.dart`, add inside the class (after `repeat`). Note the guard at the top — before the player is ready, calls only update `_value`, deferring the platform call to initialize()'s sync phase (added in Task 13):

```dart
  /// Sets the avatar animation speed preset.
  ///
  /// Called before [initialize()] completes: updates [value.speed] only —
  /// the platform is synced at the end of [initialize()].
  Future<void> setSpeed(VLibrasSpeed speed) async {
    if (!_isReadyForPlatform) {
      _setValue(_value.copyWith(speed: speed));
      return;
    }
    try {
      await _platform.setSpeed(speed.multiplier);
      _setValue(_value.copyWith(speed: speed, clearError: true));
    } catch (e) {
      debugPrint('[VLibrasController] setSpeed error: $e');
      _setValue(_value.copyWith(
        status: VLibrasStatus.error,
        error: 'Falha em setSpeed: $e',
      ));
    }
  }

  bool get _isReadyForPlatform =>
      _value.status == VLibrasStatus.ready ||
      _value.status == VLibrasStatus.translating ||
      _value.status == VLibrasStatus.playing;
```

- [ ] **Step 4: Run to verify passing**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "setSpeed"`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/vlibras_controller.dart test/vlibras_controller_test.dart
git commit -m "feat(controller): expose setSpeed(VLibrasSpeed)"
```

---

## Task 10: Controller — `setAvatar`

**Files:**
- Modify: `lib/src/vlibras_controller.dart`
- Test: `test/vlibras_controller_test.dart`

- [ ] **Step 1: Write the failing tests**

Append this group:

```dart
  // -------------------------------------------------------------------------
  // setAvatar
  // -------------------------------------------------------------------------
  group('setAvatar', () {
    setUp(() async {
      await controller.initialize();
    });

    test('delegates to platform with selected avatar', () async {
      await controller.setAvatar(VLibrasAvatar.hosana);
      verify(() => platform.setAvatar(VLibrasAvatar.hosana)).called(1);
    });

    test('updates value.avatar', () async {
      await controller.setAvatar(VLibrasAvatar.guga);
      expect(controller.value.avatar, VLibrasAvatar.guga);
    });

    test('platform error is captured in value.error', () async {
      when(() => platform.setAvatar(any())).thenThrow(Exception('fail'));
      await controller.setAvatar(VLibrasAvatar.hosana);
      expect(controller.value.status, VLibrasStatus.error);
      expect(controller.value.avatar, VLibrasAvatar.icaro);
    });
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "setAvatar"`
Expected: compilation error.

- [ ] **Step 3: Implement `setAvatar` with pre-ready guard**

In `lib/src/vlibras_controller.dart`, after `setSpeed`:

```dart
  /// Switches the active avatar persona.
  Future<void> setAvatar(VLibrasAvatar avatar) async {
    if (!_isReadyForPlatform) {
      _setValue(_value.copyWith(avatar: avatar));
      return;
    }
    try {
      await _platform.setAvatar(avatar);
      _setValue(_value.copyWith(avatar: avatar, clearError: true));
    } catch (e) {
      debugPrint('[VLibrasController] setAvatar error: $e');
      _setValue(_value.copyWith(
        status: VLibrasStatus.error,
        error: 'Falha em setAvatar: $e',
      ));
    }
  }
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "setAvatar"`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/vlibras_controller.dart test/vlibras_controller_test.dart
git commit -m "feat(controller): expose setAvatar(VLibrasAvatar)"
```

---

## Task 11: Controller — `setSubtitles` with state diff

**Files:**
- Modify: `lib/src/vlibras_controller.dart`
- Test: `test/vlibras_controller_test.dart`

- [ ] **Step 1: Write the failing tests**

Append this group:

```dart
  // -------------------------------------------------------------------------
  // setSubtitles
  // -------------------------------------------------------------------------
  group('setSubtitles', () {
    setUp(() async {
      await controller.initialize();
    });

    test('no-op when desired state equals current', () async {
      // default subtitlesEnabled is true; calling with true should not toggle.
      await controller.setSubtitles(true);
      verifyNever(() => platform.setSubtitles(any()));
    });

    test('delegates to platform when state differs', () async {
      await controller.setSubtitles(false);
      verify(() => platform.setSubtitles(false)).called(1);
    });

    test('updates value.subtitlesEnabled', () async {
      await controller.setSubtitles(false);
      expect(controller.value.subtitlesEnabled, isFalse);
    });

    test('platform error is captured in value.error', () async {
      when(() => platform.setSubtitles(any())).thenThrow(Exception('nope'));
      await controller.setSubtitles(false);
      expect(controller.value.status, VLibrasStatus.error);
      expect(controller.value.subtitlesEnabled, isTrue);
    });
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "setSubtitles"`
Expected: compilation error.

- [ ] **Step 3: Implement `setSubtitles` with diff + pre-ready guard**

In `lib/src/vlibras_controller.dart`, after `setAvatar`:

```dart
  /// Enables or disables subtitles. No-op when already in the desired state.
  Future<void> setSubtitles(bool enabled) async {
    if (_value.subtitlesEnabled == enabled) return;
    if (!_isReadyForPlatform) {
      _setValue(_value.copyWith(subtitlesEnabled: enabled));
      return;
    }
    try {
      await _platform.setSubtitles(enabled);
      _setValue(_value.copyWith(subtitlesEnabled: enabled, clearError: true));
    } catch (e) {
      debugPrint('[VLibrasController] setSubtitles error: $e');
      _setValue(_value.copyWith(
        status: VLibrasStatus.error,
        error: 'Falha em setSubtitles: $e',
      ));
    }
  }
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "setSubtitles"`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/src/vlibras_controller.dart test/vlibras_controller_test.dart
git commit -m "feat(controller): expose setSubtitles with state-diff optimization"
```

---

## Task 12: Controller — `onSettingsChanged` callback

**Files:**
- Modify: `lib/src/vlibras_controller.dart`
- Test: `test/vlibras_controller_test.dart`

- [ ] **Step 1: Write the failing tests**

Append this group:

```dart
  // -------------------------------------------------------------------------
  // onSettingsChanged
  // -------------------------------------------------------------------------
  group('onSettingsChanged', () {
    test('is invoked after setSpeed succeeds', () async {
      final captured = <VLibrasSettings>[];
      final c = VLibrasController(
        platform: platform,
        onSettingsChanged: captured.add,
      );
      await c.initialize();
      await c.setSpeed(VLibrasSpeed.fast);
      expect(captured, hasLength(1));
      expect(captured.last.speed, VLibrasSpeed.fast);
      c.dispose();
    });

    test('is NOT invoked when platform throws', () async {
      when(() => platform.setAvatar(any())).thenThrow(Exception('fail'));
      final captured = <VLibrasSettings>[];
      final c = VLibrasController(
        platform: platform,
        onSettingsChanged: captured.add,
      );
      await c.initialize();
      await c.setAvatar(VLibrasAvatar.hosana);
      expect(captured, isEmpty);
      c.dispose();
    });

    test('is NOT invoked by setSubtitles when state is unchanged', () async {
      final captured = <VLibrasSettings>[];
      final c = VLibrasController(
        platform: platform,
        onSettingsChanged: captured.add,
      );
      await c.initialize();
      await c.setSubtitles(true); // default is true
      expect(captured, isEmpty);
      c.dispose();
    });
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "onSettingsChanged"`
Expected: compilation error — `onSettingsChanged` not a known parameter.

- [ ] **Step 3: Add `onSettingsChanged` and `initialSettings` to constructor**

In `lib/src/vlibras_controller.dart`, update the constructor to accept the new parameters. `initialSettings` seeds `_value` so the single source of truth is `_value` (Task 13 then syncs it to the platform during initialize):

```dart
  VLibrasController({
    VLibrasPlatform? platform,
    String targetPath = '/vlibras/target',
    VLibrasSettings? initialSettings,
    void Function(VLibrasSettings)? onSettingsChanged,
  })  : _onSettingsChanged = onSettingsChanged {
    if (initialSettings != null) {
      _value = _value.copyWith(
        speed: initialSettings.speed,
        avatar: initialSettings.avatar,
        subtitlesEnabled: initialSettings.subtitlesEnabled,
      );
    }
    _platform =
        platform ?? createDefaultPlatform(_onPlatformStatus, targetPath);
  }

  final void Function(VLibrasSettings)? _onSettingsChanged;
  bool _applyingInitial = false;
```

Add a helper that emits current settings (just before `dispose`):

```dart
  void _emitSettingsChanged() {
    if (_applyingInitial) return;
    final cb = _onSettingsChanged;
    if (cb == null) return;
    cb(VLibrasSettings(
      speed: _value.speed,
      avatar: _value.avatar,
      subtitlesEnabled: _value.subtitlesEnabled,
    ));
  }
```

Also add this import at the top of the file:

```dart
import 'vlibras_settings.dart';
```

Replace the bodies of `setSpeed`, `setAvatar` and `setSubtitles` with the following. Each path — pre-ready and ready — fires `_emitSettingsChanged()` on success (so persistence callbacks receive the user's intent even if made before initialize).

```dart
  Future<void> setSpeed(VLibrasSpeed speed) async {
    if (!_isReadyForPlatform) {
      _setValue(_value.copyWith(speed: speed));
      _emitSettingsChanged();
      return;
    }
    try {
      await _platform.setSpeed(speed.multiplier);
      _setValue(_value.copyWith(speed: speed, clearError: true));
      _emitSettingsChanged();
    } catch (e) {
      debugPrint('[VLibrasController] setSpeed error: $e');
      _setValue(_value.copyWith(
        status: VLibrasStatus.error,
        error: 'Falha em setSpeed: $e',
      ));
    }
  }

  Future<void> setAvatar(VLibrasAvatar avatar) async {
    if (!_isReadyForPlatform) {
      _setValue(_value.copyWith(avatar: avatar));
      _emitSettingsChanged();
      return;
    }
    try {
      await _platform.setAvatar(avatar);
      _setValue(_value.copyWith(avatar: avatar, clearError: true));
      _emitSettingsChanged();
    } catch (e) {
      debugPrint('[VLibrasController] setAvatar error: $e');
      _setValue(_value.copyWith(
        status: VLibrasStatus.error,
        error: 'Falha em setAvatar: $e',
      ));
    }
  }

  Future<void> setSubtitles(bool enabled) async {
    if (_value.subtitlesEnabled == enabled) return;
    if (!_isReadyForPlatform) {
      _setValue(_value.copyWith(subtitlesEnabled: enabled));
      _emitSettingsChanged();
      return;
    }
    try {
      await _platform.setSubtitles(enabled);
      _setValue(_value.copyWith(subtitlesEnabled: enabled, clearError: true));
      _emitSettingsChanged();
    } catch (e) {
      debugPrint('[VLibrasController] setSubtitles error: $e');
      _setValue(_value.copyWith(
        status: VLibrasStatus.error,
        error: 'Falha em setSubtitles: $e',
      ));
    }
  }
```

- [ ] **Step 4: Run all tests**

Run: `flutter test test/vlibras_controller_test.dart`
Expected: PASS including the three new tests.

- [ ] **Step 5: Commit**

```bash
git add lib/src/vlibras_controller.dart test/vlibras_controller_test.dart
git commit -m "feat(controller): invoke onSettingsChanged after successful settings updates"
```

---

## Task 13: Controller — apply `initialSettings` during `initialize`

**Files:**
- Modify: `lib/src/vlibras_controller.dart`
- Test: `test/vlibras_controller_test.dart`

- [ ] **Step 1: Write the failing tests**

Append this group:

```dart
  // -------------------------------------------------------------------------
  // initialSettings
  // -------------------------------------------------------------------------
  group('initialSettings', () {
    test('is applied before transitioning to ready', () async {
      final states = <VLibrasStatus>[];
      final applyOrder = <String>[];
      when(() => platform.setSpeed(any())).thenAnswer((inv) async {
        applyOrder.add('speed');
      });
      when(() => platform.setAvatar(any())).thenAnswer((inv) async {
        applyOrder.add('avatar');
      });
      when(() => platform.setSubtitles(any())).thenAnswer((inv) async {
        applyOrder.add('subtitles');
      });

      final c = VLibrasController(
        platform: platform,
        initialSettings: const VLibrasSettings(
          speed: VLibrasSpeed.fast,
          avatar: VLibrasAvatar.hosana,
          subtitlesEnabled: false,
        ),
      );
      c.addListener(() => states.add(c.value.status));
      await c.initialize();

      expect(states.last, VLibrasStatus.ready);
      expect(c.value.speed, VLibrasSpeed.fast);
      expect(c.value.avatar, VLibrasAvatar.hosana);
      expect(c.value.subtitlesEnabled, isFalse);
      expect(applyOrder, ['speed', 'avatar', 'subtitles']);
      c.dispose();
    });

    test('does NOT invoke onSettingsChanged during initial application',
        () async {
      final captured = <VLibrasSettings>[];
      final c = VLibrasController(
        platform: platform,
        initialSettings: const VLibrasSettings(speed: VLibrasSpeed.slow),
        onSettingsChanged: captured.add,
      );
      await c.initialize();
      expect(captured, isEmpty);
      c.dispose();
    });

    test('errors during initial application are logged but do not fail init',
        () async {
      when(() => platform.setSpeed(any())).thenThrow(Exception('oops'));
      final c = VLibrasController(
        platform: platform,
        initialSettings: const VLibrasSettings(speed: VLibrasSpeed.fast),
      );
      await c.initialize();
      expect(c.value.status, VLibrasStatus.ready);
      c.dispose();
    });
  });
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "initialSettings"`
Expected: failures — initialSettings has no effect yet.

- [ ] **Step 3: Sync `_value` to platform in `initialize()`**

The constructor (already updated in Task 12) seeds `_value` from `initialSettings`, and pre-ready `setX` calls also mutate `_value` directly. So `initialize()` just needs a single sync step after the platform reports ready, pushing the consolidated state out.

Replace the body of `initialize()` with a version that syncs `_value` — covering both `initialSettings` AND any direct `setX` calls made before `initialize()`:

```dart
  Future<void> initialize() async {
    if (_value.status != VLibrasStatus.idle) return;
    _setValue(_value.copyWith(status: VLibrasStatus.initializing));
    try {
      await _platform.initialize();
      await _syncValueToPlatform();
      _setValue(_value.copyWith(
        status: VLibrasStatus.ready,
        clearError: true,
      ));
    } catch (e) {
      debugPrint('[VLibrasController] initialize error: $e');
      _setValue(_value.copyWith(
        status: VLibrasStatus.error,
        error: 'Falha ao inicializar: $e',
      ));
    }
  }

  /// Pushes the current speed/avatar/subtitles from [_value] to the platform.
  ///
  /// Called once during [initialize()] after the platform reports it is up.
  /// Errors are logged but swallowed — a lost default is better than a broken
  /// init. [onSettingsChanged] is NOT invoked during the sync.
  Future<void> _syncValueToPlatform() async {
    _applyingInitial = true;
    try {
      try {
        await _platform.setSpeed(_value.speed.multiplier);
      } catch (e) {
        debugPrint('[VLibrasController] sync setSpeed error: $e');
      }
      try {
        await _platform.setAvatar(_value.avatar);
      } catch (e) {
        debugPrint('[VLibrasController] sync setAvatar error: $e');
      }
      // subtitles default is `true` on a fresh player — only toggle if we want false
      if (!_value.subtitlesEnabled) {
        try {
          await _platform.setSubtitles(false);
        } catch (e) {
          debugPrint('[VLibrasController] sync setSubtitles error: $e');
        }
      }
    } finally {
      _applyingInitial = false;
    }
  }
```

- [ ] **Step 4: Run tests**

Run: `flutter test test/vlibras_controller_test.dart --plain-name "initialSettings"`
Expected: PASS (3 tests).

- [ ] **Step 5: Full regression**

Run: `flutter test test/vlibras_controller_test.dart`
Expected: PASS (all tests).

- [ ] **Step 6: Commit**

```bash
git add lib/src/vlibras_controller.dart test/vlibras_controller_test.dart
git commit -m "feat(controller): apply initialSettings before reaching ready"
```

---

## Task 14: `VLibrasSettingsLabels`

**Files:**
- Create: `lib/src/vlibras_settings_labels.dart`
- Modify: `lib/vlibras_flutter.dart`

- [ ] **Step 1: Create the class**

Create `lib/src/vlibras_settings_labels.dart`:

```dart
import 'package:flutter/foundation.dart';

/// User-facing strings used by [VLibrasSettingsPanel].
///
/// Defaults are in Portuguese. Pass a custom instance to localise the panel
/// without pulling in a full i18n framework.
@immutable
class VLibrasSettingsLabels {
  const VLibrasSettingsLabels({
    this.title = 'Configurações',
    this.speed = 'Velocidade',
    this.speedSlow = 'Devagar',
    this.speedNormal = 'Normal',
    this.speedFast = 'Rápido',
    this.avatar = 'Avatar',
    this.avatarIcaro = 'Ícaro',
    this.avatarHosana = 'Hosana',
    this.avatarGuga = 'Guga',
    this.subtitles = 'Legendas',
    this.close = 'Fechar',
  });

  final String title;
  final String speed;
  final String speedSlow;
  final String speedNormal;
  final String speedFast;
  final String avatar;
  final String avatarIcaro;
  final String avatarHosana;
  final String avatarGuga;
  final String subtitles;
  final String close;
}
```

- [ ] **Step 2: Export from barrel**

In `lib/vlibras_flutter.dart`, add:

```dart
export 'src/vlibras_settings_labels.dart';
```

- [ ] **Step 3: Verify compilation**

Run: `flutter analyze lib/src/vlibras_settings_labels.dart lib/vlibras_flutter.dart`
Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/src/vlibras_settings_labels.dart lib/vlibras_flutter.dart
git commit -m "feat(panel): add VLibrasSettingsLabels for panel i18n"
```

---

## Task 15: `VLibrasSettingsPanel` widget

**Files:**
- Create: `lib/src/vlibras_settings_panel.dart`
- Create: `test/vlibras_settings_panel_test.dart`
- Modify: `lib/vlibras_flutter.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/vlibras_settings_panel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';

import 'mocks/mock_vlibras_platform.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(VLibrasAvatar.icaro);
  });

  late MockVLibrasPlatform platform;
  late VLibrasController controller;

  setUp(() async {
    platform = MockVLibrasPlatform();
    when(() => platform.initialize()).thenAnswer((_) async {});
    when(() => platform.dispose()).thenReturn(null);
    when(() => platform.setSpeed(any())).thenAnswer((_) async {});
    when(() => platform.setAvatar(any())).thenAnswer((_) async {});
    when(() => platform.setSubtitles(any())).thenAnswer((_) async {});
    controller = VLibrasController(platform: platform);
    await controller.initialize();
  });

  tearDown(() {
    controller.dispose();
  });

  Future<void> pumpPanel(
    WidgetTester tester, {
    VoidCallback? onClose,
    VLibrasSettingsLabels? labels,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: VLibrasSettingsPanel(
          controller: controller,
          onClose: onClose,
          labels: labels ?? const VLibrasSettingsLabels(),
        ),
      ),
    ));
  }

  group('VLibrasSettingsPanel', () {
    testWidgets('renders the three section titles in PT by default',
        (tester) async {
      await pumpPanel(tester);
      expect(find.text('Configurações'), findsOneWidget);
      expect(find.text('Velocidade'), findsOneWidget);
      expect(find.text('Avatar'), findsOneWidget);
      expect(find.text('Legendas'), findsOneWidget);
    });

    testWidgets('tapping "Rápido" calls setSpeed(fast)', (tester) async {
      await pumpPanel(tester);
      await tester.tap(find.text('Rápido'));
      await tester.pump();
      verify(() => platform.setSpeed(1.5)).called(1);
    });

    testWidgets('tapping "Hosana" calls setAvatar(hosana)', (tester) async {
      await pumpPanel(tester);
      await tester.tap(find.text('Hosana'));
      await tester.pump();
      verify(() => platform.setAvatar(VLibrasAvatar.hosana)).called(1);
    });

    testWidgets('toggling subtitle switch calls setSubtitles(false)',
        (tester) async {
      await pumpPanel(tester);
      await tester.tap(find.byType(Switch));
      await tester.pump();
      verify(() => platform.setSubtitles(false)).called(1);
    });

    testWidgets('close button hidden when onClose is null', (tester) async {
      await pumpPanel(tester);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('close button shown and invoked when onClose is non-null',
        (tester) async {
      var closed = false;
      await pumpPanel(tester, onClose: () => closed = true);
      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(closed, isTrue);
    });

    testWidgets('custom labels replace defaults', (tester) async {
      await pumpPanel(
        tester,
        labels: const VLibrasSettingsLabels(
          title: 'Settings',
          speed: 'Speed',
          speedSlow: 'Slow',
          speedNormal: 'Normal',
          speedFast: 'Fast',
          avatar: 'Character',
          subtitles: 'Captions',
        ),
      );
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Speed'), findsOneWidget);
      expect(find.text('Captions'), findsOneWidget);
      expect(find.text('Configurações'), findsNothing);
    });
  });
}
```

- [ ] **Step 2: Run to verify failure**

Run: `flutter test test/vlibras_settings_panel_test.dart`
Expected: compilation error — `VLibrasSettingsPanel` not defined.

- [ ] **Step 3: Implement the panel**

Create `lib/src/vlibras_settings_panel.dart`:

```dart
import 'package:flutter/material.dart';

import 'vlibras_controller.dart';
import 'vlibras_settings_labels.dart';
import 'vlibras_value.dart';

/// A pre-built settings panel for the VLibras player.
///
/// Renders three sections — speed, avatar, subtitles — each wired to the given
/// [controller]. Re-renders automatically when [VLibrasController.value] changes.
///
/// Place this widget inside a [Dialog], [BottomSheet], [Drawer] or your own
/// [Overlay]. It has an intrinsic width of ~320dp and vertical size driven
/// by content.
class VLibrasSettingsPanel extends StatelessWidget {
  const VLibrasSettingsPanel({
    super.key,
    required this.controller,
    this.onClose,
    this.labels = const VLibrasSettingsLabels(),
  });

  /// The controller whose settings this panel displays and mutates.
  final VLibrasController controller;

  /// Invoked when the close button is tapped. Close button is hidden when null.
  final VoidCallback? onClose;

  /// User-facing strings. Defaults are in Portuguese.
  final VLibrasSettingsLabels labels;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final value = controller.value;
        return SizedBox(
          width: 320,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildSpeedSection(value),
                const SizedBox(height: 16),
                _buildAvatarSection(value),
                const SizedBox(height: 16),
                _buildSubtitlesSection(value),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return Row(
      children: [
        Expanded(child: Text(labels.title, style: titleStyle)),
        if (onClose != null)
          IconButton(
            tooltip: labels.close,
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
      ],
    );
  }

  Widget _buildSpeedSection(VLibrasValue value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(labels.speed),
        const SizedBox(height: 8),
        SegmentedButton<VLibrasSpeed>(
          segments: [
            ButtonSegment(
              value: VLibrasSpeed.slow,
              label: Text(labels.speedSlow),
            ),
            ButtonSegment(
              value: VLibrasSpeed.normal,
              label: Text(labels.speedNormal),
            ),
            ButtonSegment(
              value: VLibrasSpeed.fast,
              label: Text(labels.speedFast),
            ),
          ],
          selected: {value.speed},
          onSelectionChanged: (s) => controller.setSpeed(s.first),
        ),
      ],
    );
  }

  Widget _buildAvatarSection(VLibrasValue value) {
    Widget radio(VLibrasAvatar a, String label) => Expanded(
          child: RadioListTile<VLibrasAvatar>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(label),
            value: a,
            groupValue: value.avatar,
            onChanged: (next) {
              if (next != null) controller.setAvatar(next);
            },
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(labels.avatar),
        const SizedBox(height: 8),
        Row(children: [
          radio(VLibrasAvatar.icaro, labels.avatarIcaro),
          radio(VLibrasAvatar.hosana, labels.avatarHosana),
          radio(VLibrasAvatar.guga, labels.avatarGuga),
        ]),
      ],
    );
  }

  Widget _buildSubtitlesSection(VLibrasValue value) {
    return Row(
      children: [
        Expanded(child: Text(labels.subtitles)),
        Switch(
          value: value.subtitlesEnabled,
          onChanged: controller.setSubtitles,
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Export from barrel**

In `lib/vlibras_flutter.dart`, add:

```dart
export 'src/vlibras_settings_panel.dart';
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/vlibras_settings_panel_test.dart`
Expected: PASS (7 widget tests).

- [ ] **Step 6: Commit**

```bash
git add lib/src/vlibras_settings_panel.dart lib/vlibras_flutter.dart test/vlibras_settings_panel_test.dart
git commit -m "feat(panel): add VLibrasSettingsPanel public widget"
```

---

## Task 16: Integrate panel in `VLibrasAccessibilityWidget`

**Files:**
- Modify: `lib/src/vlibras_accessibility_widget.dart`

- [ ] **Step 1: Add `showSettingsButton` parameter and settings state**

In `lib/src/vlibras_accessibility_widget.dart`, update the constructor and fields:

```dart
  const VLibrasAccessibilityWidget({
    super.key,
    required this.child,
    this.avatarWidth = 280.0,
    this.avatarHeight = 320.0,
    this.buttonSize = 56.0,
    this.showSettingsButton = true,
    this.settingsLabels = const VLibrasSettingsLabels(),
  });

  final Widget child;
  final double avatarWidth;
  final double avatarHeight;
  final double buttonSize;

  /// When `true` (default), a secondary ⚙️ button is rendered alongside the
  /// close button while the avatar panel is open. Tapping it reveals a
  /// [VLibrasSettingsPanel] overlay inline with the avatar.
  final bool showSettingsButton;

  /// Labels passed to the internal [VLibrasSettingsPanel]. Override for i18n.
  final VLibrasSettingsLabels settingsLabels;
```

Add the import at the top (next to the existing imports):

```dart
import 'vlibras_settings_labels.dart';
import 'vlibras_settings_panel.dart';
```

- [ ] **Step 2: Add `_isSettingsOpen` state**

In `_VLibrasAccessibilityWidgetState`, add alongside `_isExpanded`:

```dart
  bool _isSettingsOpen = false;
```

- [ ] **Step 3: Extend `_buildAvatarPanel` with the ⚙️ button and overlay**

Replace the existing `_buildAvatarPanel` method with:

```dart
  Widget _buildAvatarPanel(BuildContext context, VLibrasValue value) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topOffset = (screenHeight - widget.avatarHeight) / 2;
    final isLoading = value.status == VLibrasStatus.initializing ||
        value.status == VLibrasStatus.idle;

    return Positioned(
      right: 0,
      top: topOffset,
      width: widget.avatarWidth,
      height: widget.avatarHeight,
      child: Material(
        elevation: 8,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomLeft: Radius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            VLibrasView(controller: _controller),
            if (isLoading)
              const ColoredBox(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Carregando avatar...',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            if (value.status == VLibrasStatus.error)
              ColoredBox(
                color: Colors.black87,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      value.error ?? 'Erro ao carregar',
                      style:
                          const TextStyle(color: Colors.redAccent, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            // Top-right action buttons
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.showSettingsButton)
                    IconButton(
                      tooltip: widget.settingsLabels.title,
                      icon: const Icon(Icons.settings, color: Colors.white),
                      onPressed: () => setState(
                          () => _isSettingsOpen = !_isSettingsOpen),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() {
                      _isExpanded = false;
                      _isSettingsOpen = false;
                    }),
                  ),
                ],
              ),
            ),
            // Settings panel overlay
            if (_isSettingsOpen)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  child: VLibrasSettingsPanel(
                    controller: _controller,
                    labels: widget.settingsLabels,
                    onClose: () => setState(() => _isSettingsOpen = false),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 4: Run analyzer and all tests**

Run: `flutter analyze lib/src/vlibras_accessibility_widget.dart`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/src/vlibras_accessibility_widget.dart
git commit -m "feat(accessibility-widget): inline settings panel with ⚙️ toggle"
```

---

## Task 17: README — persistence recipe

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Append persistence section**

Append this section at the end of `README.md`:

````markdown
## Persisting user preferences

`VLibrasController` does not bundle a persistence backend. To save the user's
speed, avatar and subtitle choices across app launches, wire two optional
constructor parameters and plug in a package of your choice (for example
`shared_preferences`):

```dart
Future<VLibrasSettings> _loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('vlibras_settings');
  if (raw == null) return const VLibrasSettings();
  return VLibrasSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

Future<void> _saveSettings(VLibrasSettings settings) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('vlibras_settings', jsonEncode(settings.toJson()));
}

final controller = VLibrasController(
  initialSettings: await _loadSettings(),
  onSettingsChanged: _saveSettings,
);
await controller.initialize();
```

`onSettingsChanged` is invoked only after the underlying player accepts a
change, so callbacks never persist an intermediate or rejected state.
`initialSettings` is applied before the controller first reports `ready`,
so the first observed state already reflects the user's preferences.
````

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs(readme): add persistence recipe using shared_preferences"
```

---

## Task 18: Manual verification

**Files:**
- None (manual).

- [ ] **Step 1: Run analyzer across the whole package**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: Run the full test suite**

Run: `flutter test`
Expected: all tests pass; no skipped-with-error.

- [ ] **Step 3: Launch example app (web)**

Run: `cd example && flutter run -d chrome`

Verify in browser:
- Avatar loads and translates text on tap (regression).
- ⚙️ button appears when panel is open.
- Tapping ⚙️ opens the settings overlay inside the avatar panel.
- Changing speed to "Devagar" visibly slows the next translation.
- Changing avatar reloads the player persona (may blink; observe that the visual changes).
- Toggling legendas hides/shows the subtitle line in the Unity view.
- Closing (✕) and reopening the avatar preserves the chosen settings in-session.

- [ ] **Step 4: Launch example app (Android)**

Run: `cd example && flutter run -d <android-device-or-emulator-id>`

Verify: same checks as Step 3, noting that Unity WebGL in WebView has visibly different framing; the panel must still render readable text and interactive controls.

- [ ] **Step 5: Smoke-test persistence**

Temporarily add the persistence snippet from the README to `example/lib/main.dart`, run twice, and confirm that a non-default choice made in run 1 is restored in run 2. Revert the edit to `example/lib/main.dart` before committing (`git checkout example/lib/main.dart`).

- [ ] **Step 6: No commit**

Manual verification produces no code changes. Leave working tree clean.
