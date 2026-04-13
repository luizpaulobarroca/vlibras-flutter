---
phase: 001-accessibility-widget-floating-avatar-tex
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/src/vlibras_accessibility_widget.dart
  - lib/vlibras_flutter.dart
autonomous: true
requirements: []

must_haves:
  truths:
    - "A floating button appears fixed on the right side of the screen, vertically centered, when VLibrasAccessibilityWidget wraps any app content"
    - "Tapping the floating button expands the view to show the VLibras avatar window"
    - "The avatar window has an X button that collapses it back to the floating button"
    - "While the avatar window is open, tapping any text widget in the app content sends that text to controller.translate()"
    - "The widget owns the VLibrasController lifecycle: initialize() on mount, dispose() on unmount"
    - "VLibrasAccessibilityWidget is exported from lib/vlibras_flutter.dart"
  artifacts:
    - path: "lib/src/vlibras_accessibility_widget.dart"
      provides: "VLibrasAccessibilityWidget StatefulWidget with Overlay-based floating button and avatar window"
      exports: ["VLibrasAccessibilityWidget"]
    - path: "lib/vlibras_flutter.dart"
      provides: "Barrel export including VLibrasAccessibilityWidget"
      contains: "export 'src/vlibras_accessibility_widget.dart'"
  key_links:
    - from: "VLibrasAccessibilityWidget._initController"
      to: "VLibrasController.initialize()"
      via: "initState -> WidgetsBinding.addPostFrameCallback"
      pattern: "controller\\.initialize"
    - from: "VLibrasAccessibilityWidget._overlayEntry"
      to: "VLibrasView(controller: _controller)"
      via: "Overlay.of(context).insert"
      pattern: "VLibrasView"
    - from: "GestureDetector wrapping child"
      to: "VLibrasController.translate()"
      via: "onTapUp -> _extractTextAndTranslate"
      pattern: "controller\\.translate"
---

<objective>
Create VLibrasAccessibilityWidget: a self-contained accessibility overlay widget that any Flutter developer can drop into their app to get a floating VLibras translation button.

Purpose: Provides a ready-to-use accessibility component without requiring the developer to manage controller lifecycle, overlay insertion, or text capture plumbing.

Output: lib/src/vlibras_accessibility_widget.dart + barrel export update.
</objective>

<execution_context>
@C:/Users/Luiz/.claude/get-shit-done/workflows/execute-plan.md
@C:/Users/Luiz/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@lib/src/vlibras_controller.dart
@lib/src/vlibras_view.dart
@lib/src/vlibras_value.dart
@lib/vlibras_flutter.dart

<interfaces>
<!-- Key contracts the executor must use. Extracted from codebase. -->

From lib/src/vlibras_controller.dart:
```dart
class VLibrasController extends ChangeNotifier implements ValueListenable<VLibrasValue> {
  VLibrasController({VLibrasPlatform? platform});
  VLibrasValue get value;
  Future<void> initialize();      // idle -> initializing -> ready|error
  Future<void> translate(String text);  // any state -> translating -> error
  void attachElement(Object element);   // called by VLibrasView on web
  Widget buildMobileView();             // called by VLibrasView on non-web
  void dispose();                       // synchronous, call super.dispose() after _platform.dispose()
}
```

From lib/src/vlibras_value.dart:
```dart
enum VLibrasStatus { idle, initializing, ready, translating, playing, error }

@immutable
class VLibrasValue {
  final VLibrasStatus status;
  final String? error;
  bool get hasError;
}
```

From lib/src/vlibras_view.dart:
```dart
class VLibrasView extends StatefulWidget {
  const VLibrasView({super.key, required this.controller});
  final VLibrasController controller;
  // Renders HtmlElementView.fromTagName('div') on web, buildMobileView() otherwise
}
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create VLibrasAccessibilityWidget</name>
  <files>lib/src/vlibras_accessibility_widget.dart</files>
  <action>
Create a StatefulWidget `VLibrasAccessibilityWidget` in `lib/src/vlibras_accessibility_widget.dart`.

**Widget signature:**
```dart
class VLibrasAccessibilityWidget extends StatefulWidget {
  const VLibrasAccessibilityWidget({
    super.key,
    required this.child,
    this.avatarWidth = 280.0,
    this.avatarHeight = 320.0,
    this.buttonSize = 56.0,
  });

  /// The app content to wrap. Text taps on this subtree trigger translation.
  final Widget child;

  /// Width of the expanded avatar window. Defaults to 280.
  final double avatarWidth;

  /// Height of the expanded avatar window. Defaults to 320.
  final double avatarHeight;

  /// Size of the collapsed floating button. Defaults to 56.
  final double buttonSize;
}
```

**State fields:**
```dart
late final VLibrasController _controller;
OverlayEntry? _overlayEntry;
bool _isExpanded = false;
```

**Lifecycle — initState:**
- Create `_controller = VLibrasController()`
- Schedule `_controller.initialize()` via `WidgetsBinding.instance.addPostFrameCallback((_) => _controller.initialize())`

**Lifecycle — dispose:**
- Call `_overlayEntry?.remove()` then `_overlayEntry = null`
- Call `_controller.dispose()`
- Call `super.dispose()`

**build method:**
Wrap `widget.child` in a `GestureDetector` that captures text taps:
```dart
@override
Widget build(BuildContext context) {
  return GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTapUp: _isExpanded ? _onContentTap : null,
    child: widget.child,
  );
}
```

**_onContentTap:**
```dart
void _onContentTap(TapUpDetails details) {
  // Perform a hit test at the tap position and walk the element tree
  // looking for a RenderParagraph to extract its text content.
  final renderObj = context.findRenderObject();
  if (renderObj == null) return;

  final result = BoxHitTestResult();
  renderObj.hitTest(result, position: details.localPosition);

  for (final entry in result.path) {
    final target = entry.target;
    if (target is RenderParagraph) {
      final text = target.text.toPlainText(includeSemanticsLabels: false).trim();
      if (text.isNotEmpty) {
        _controller.translate(text);
        return;
      }
    }
  }
}
```

**Overlay management — _showOverlay / _hideOverlay:**

`_showOverlay(BuildContext context)` inserts an `OverlayEntry` that renders a `Positioned` widget fixed to the right side, vertically centered:
- Use `ValueListenableBuilder<VLibrasValue>` on `_controller` inside the overlay so the avatar window reacts to controller state changes.
- The overlay contains two mutually exclusive subtrees controlled by `_isExpanded`:
  - **Collapsed (button):** A `FloatingActionButton`-style `InkWell`/`Material` circle (size = `widget.buttonSize`) pinned to `right: 16`, vertically centered via `Align(alignment: Alignment.centerRight)` inside a `Positioned.fill`. Show a hand/accessibility icon (`Icons.accessibility_new`). On tap: call `setState(() => _isExpanded = true)` then `_overlayEntry!.markNeedsBuild()`.
  - **Expanded (avatar window):** A `Positioned` widget with `right: 0`, `top` calculated to center the window vertically (use `MediaQuery.of(context).size.height / 2 - widget.avatarHeight / 2`). The window is a `Material` with `elevation: 8`, `borderRadius: BorderRadius.circular(16)`, `clipBehavior: Clip.hardEdge`, sized to `widget.avatarWidth × widget.avatarHeight`. Stack inside:
    - `VLibrasView(controller: _controller)` filling the whole area
    - Top-right close button: `Positioned(top: 8, right: 8, child: IconButton(icon: Icon(Icons.close), onPressed: _hideOverlay))`

`_hideOverlay()`:
```dart
void _hideOverlay() {
  setState(() => _isExpanded = false);
  _overlayEntry?.markNeedsBuild();
}
```

**Important implementation notes:**
- The `OverlayEntry` builder captures `_isExpanded` via closure — calling `markNeedsBuild()` after changing `_isExpanded` forces the overlay to rebuild with the new state.
- Use `setState` to update `_isExpanded` so the `GestureDetector` in `build()` also re-evaluates `onTapUp`.
- Insert the overlay in `didChangeDependencies` (first call only, guard with `_overlayEntry == null`) so `Overlay.of(context)` is available:
  ```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: _buildOverlay);
      Overlay.of(context).insert(_overlayEntry!);
    }
  }
  ```
- `_buildOverlay(BuildContext context)` is a separate private method returning the overlay widget tree described above.
- Do NOT import `package:web` or `dart:html` — keep this file VM-compilable.
- Import only: `package:flutter/material.dart`, `package:flutter/rendering.dart` (for RenderParagraph/BoxHitTestResult), `vlibras_controller.dart`, `vlibras_view.dart`, `vlibras_value.dart`.
  </action>
  <verify>
    <automated>cd /c/Users/Luiz/Projetos/vlibras && flutter analyze lib/src/vlibras_accessibility_widget.dart --no-fatal-infos</automated>
  </verify>
  <done>
    - File exists at lib/src/vlibras_accessibility_widget.dart
    - `flutter analyze` reports zero errors on that file
    - Widget has constructor with child, avatarWidth, avatarHeight, buttonSize params
    - VLibrasController is created and disposed entirely inside the widget state
    - Overlay is inserted in didChangeDependencies, removed in dispose
  </done>
</task>

<task type="auto">
  <name>Task 2: Export from barrel and verify compile</name>
  <files>lib/vlibras_flutter.dart</files>
  <action>
Add the new export to `lib/vlibras_flutter.dart`. Current content ends after:
```dart
export 'src/vlibras_view.dart';
```

Append:
```dart
export 'src/vlibras_accessibility_widget.dart';
```

Also update the doc comment at the top of the file to mention `VLibrasAccessibilityWidget`:
```dart
/// VLibras Flutter plugin — exibe traduções de texto para LIBRAS com avatar 3D.
///
/// Ponto de entrada público do pacote. Importar este arquivo expõe:
/// - [VLibrasController] — controla o ciclo de vida da tradução
/// - [VLibrasView] — widget que renderiza o avatar VLibras
/// - [VLibrasAccessibilityWidget] — widget de acessibilidade com botão flutuante e captura de texto
/// - [VLibrasValue] e [VLibrasStatus] — estado imutável do controller
/// - [VLibrasPlatform] — interface para injeção de plataforma customizada
```

Then verify the entire package compiles without errors by running `flutter analyze` on lib/ and verifying `flutter test` (VM suite) still passes.
  </action>
  <verify>
    <automated>cd /c/Users/Luiz/Projetos/vlibras && flutter analyze lib/ --no-fatal-infos && flutter test</automated>
  </verify>
  <done>
    - `lib/vlibras_flutter.dart` exports `src/vlibras_accessibility_widget.dart`
    - `flutter analyze lib/` exits 0
    - `flutter test` exits 0 (existing VM tests still green)
    - `import 'package:vlibras_flutter/vlibras_flutter.dart'; VLibrasAccessibilityWidget` resolves without error
  </done>
</task>

</tasks>

<verification>
After both tasks complete:

1. `flutter analyze lib/` — zero errors, zero warnings (infos allowed)
2. `flutter test` — all existing tests pass
3. Manual inspection: `lib/src/vlibras_accessibility_widget.dart` exists and is non-empty
4. Manual inspection: `lib/vlibras_flutter.dart` contains the new export line
5. Spot-check: VLibrasController is instantiated inside `_VLibrasAccessibilityWidgetState.initState` and disposed in `dispose()` — no controller is accepted as a constructor parameter
</verification>

<success_criteria>
- VLibrasAccessibilityWidget is a drop-in widget: `VLibrasAccessibilityWidget(child: myApp)` works with zero additional setup
- Floating button is fixed to the right side, vertically centered, collapsed by default
- Tapping the button expands to show the VLibras avatar in a windowed panel
- The X button in the panel collapses it back to the floating button
- While expanded, tapping any text widget in `child` sends that text to `controller.translate()`
- The widget manages its own VLibrasController (create + initialize + dispose)
- `flutter test` passes with no regressions
</success_criteria>

<output>
After completion, create `.planning/quick/001-accessibility-widget-floating-avatar-tex/001-SUMMARY.md`
</output>
