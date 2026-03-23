# Architecture Patterns

**Domain:** Plugin Flutter multiplataforma para acessibilidade em LIBRAS (VLibras)
**Researched:** 2026-03-22
**Overall confidence:** MEDIUM-HIGH (Flutter plugin patterns: HIGH; VLibras SDK internals: MEDIUM - based on training data, needs validation against actual SDK source)

## Recommended Architecture

### Decision: Simplified Federated Plugin (Single Package)

Use a **single-package plugin** with platform-specific implementations inside it, rather than a fully federated multi-package structure. The fully federated pattern (separate packages for `vlibras_flutter_platform_interface`, `vlibras_flutter_android`, `vlibras_flutter_ios`, `vlibras_flutter_web`) is designed for cases where third parties need to contribute independent platform implementations. For VLibras, a single author controls all platforms, so the overhead of 4+ packages on pub.dev is unnecessary.

However, internally follow the federated architecture's **interface discipline**: define a `VLibrasPlatform` abstract class that all platform implementations extend. This gives the option to federate later without rewriting.

### High-Level Component Diagram

```
+-----------------------------------------------+
|               App Developer Code               |
|  VLibrasController ctrl = VLibrasController();  |
|  VLibrasView(controller: ctrl)                  |
+-----------------------------------------------+
                    |
                    v
+-----------------------------------------------+
|         App-Facing Dart Layer (lib/)            |
|                                                 |
|  VLibrasController    VLibrasView               |
|  (ChangeNotifier)     (StatefulWidget)          |
|       |                    |                    |
|       v                    v                    |
|  VLibrasPlatform  <-- dispatches to -->         |
|  (abstract class, singleton pattern)            |
+-----------------------------------------------+
          |                  |               |
          v                  v               v
+---------------+  +---------------+  +----------------+
| Android Impl  |  |   iOS Impl    |  |   Web Impl     |
| (MethodChannel |  | (MethodChannel|  | (dart:js_interop|
|  + PlatformView)|  + PlatformView)|  + HtmlElement    |
|                |  |               |  |   View)        |
+-------+-------+  +-------+-------+  +-------+--------+
        |                  |                   |
        v                  v                   v
+---------------+  +---------------+  +----------------+
| VLibras SDK   |  | VLibras SDK   |  | VLibras Web    |
| Android (Java)|  | iOS (ObjC/    |  | Player (JS/    |
| Native View   |  |  Swift) Native|  |  WebGL/Unity)  |
|               |  |  View         |  |                |
+---------------+  +---------------+  +----------------+
```

### Component Boundaries

| Component | Responsibility | Communicates With | Package Location |
|-----------|---------------|-------------------|------------------|
| **VLibrasController** | Public API for developers. Holds state (loading, playing, error). Sends commands (translate, dispose). | VLibrasPlatform (downward), App widgets via ChangeNotifier (upward) | `lib/vlibras_controller.dart` |
| **VLibrasView** | StatefulWidget that renders the native/web view. Bridges Controller to visual output. | VLibrasController (receives), Platform view factories (creates) | `lib/vlibras_view.dart` |
| **VLibrasPlatform** | Abstract interface defining all platform operations. Singleton pattern with replaceable instance. | Controller calls it; platform implementations extend it | `lib/src/vlibras_platform.dart` |
| **VLibrasAndroid** | Android MethodChannel handler + PlatformViewFactory. Wraps the native VLibras Android SDK. | VLibrasPlatform (implements), Android native code via MethodChannel | `lib/src/vlibras_android.dart` + `android/` |
| **VLibrasIos** | iOS MethodChannel handler + PlatformViewFactory. Wraps the native VLibras iOS SDK. | VLibrasPlatform (implements), iOS native code via MethodChannel | `lib/src/vlibras_ios.dart` + `ios/` |
| **VLibrasWeb** | Web implementation using dart:js_interop and HtmlElementView. Embeds the VLibras web player. | VLibrasPlatform (implements), Browser DOM/JS directly | `lib/src/vlibras_web.dart` |
| **Android Native Plugin** | Kotlin/Java class registered as FlutterPlugin. Creates and manages VLibras Android SDK instance. | Dart side via MethodChannel, VLibras Android SDK directly | `android/src/main/kotlin/` |
| **iOS Native Plugin** | Swift/ObjC class registered as FlutterPlugin. Creates and manages VLibras iOS SDK instance. | Dart side via MethodChannel, VLibras iOS SDK directly | `ios/Classes/` |

### Data Flow

**Primary flow: Text to LIBRAS Avatar**

```
1. Developer calls:
   controller.translate("Ola mundo")
        |
        v
2. VLibrasController:
   - Sets state to VLibrasState.loading
   - Notifies listeners (UI updates)
   - Calls VLibrasPlatform.instance.translate(viewId, "Ola mundo")
        |
        v
3. VLibrasPlatform dispatches to active implementation:

   ANDROID PATH:                    iOS PATH:                     WEB PATH:
   MethodChannel.invokeMethod(      MethodChannel.invokeMethod(   dart:js_interop call to
     'translate',                     'translate',                 vlibrasPlayer.translate(
     {'text': 'Ola mundo',            {'text': 'Ola mundo',         'Ola mundo'
      'viewId': 1}                     'viewId': 1}               ) on the JS object
   )                                )                             embedded via
        |                                |                        HtmlElementView
        v                                v                              |
4. Native handler:               Native handler:                        v
   VLibrasPlugin.kt              VLibrasPlugin.swift             5. JS web player
   retrieves VLibras             retrieves VLibras                  receives text,
   SDK View instance             SDK View instance                  calls VLibras
   by viewId, calls              by viewId, calls                   API, Unity/WebGL
   sdk.translate(text)           sdk.translate(text)                 renders avatar
        |                                |
        v                                v
5. VLibras Android SDK           VLibras iOS SDK
   processes text                processes text
   (may call server API)         (may call server API)
   -> renders avatar             -> renders avatar
   in native View                in native View
        |                                |
        v                                v
6. Native SDK sends callback     Native SDK sends callback
   (animation started/ended)     (animation started/ended)
        |                                |
        v                                v
7. MethodChannel sends event     MethodChannel sends event       JS callback fires,
   back to Dart                  back to Dart                    Dart interop catches it
        |                                |                              |
        +--------------------------------+------------------------------+
                                    |
                                    v
8. VLibrasPlatform notifies VLibrasController
   - Sets state to VLibrasState.playing / VLibrasState.idle
   - Controller.notifyListeners()
   - VLibrasView rebuilds if needed
```

**Initialization flow:**

```
1. VLibrasController() constructor
   -> Sets initial state (uninitialized)

2. controller.initialize()
   -> VLibrasPlatform.instance.init(config)
   -> Platform creates native SDK instance
   -> Returns when SDK is ready
   -> Controller state = initialized

3. VLibrasView(controller: ctrl) builds
   -> Checks platform
   -> Android: returns AndroidView(viewType: 'com.example.vlibras/view')
   -> iOS: returns UiKitView(viewType: 'com.example.vlibras/view')
   -> Web: returns HtmlElementView(viewType: 'vlibras-player')
   -> Links created view to controller via viewId

4. Ready for translate() calls
```

## Directory Structure

```
vlibras_flutter/
+-- lib/
|   +-- vlibras_flutter.dart            # Barrel export file
|   +-- vlibras_controller.dart         # Public: VLibrasController
|   +-- vlibras_view.dart               # Public: VLibrasView widget
|   +-- src/
|       +-- vlibras_platform.dart       # Abstract platform interface
|       +-- vlibras_method_channel.dart  # Shared MethodChannel logic
|       +-- vlibras_android.dart        # Android Dart-side impl
|       +-- vlibras_ios.dart            # iOS Dart-side impl
|       +-- vlibras_web.dart            # Web Dart-side impl (conditionally imported)
|       +-- vlibras_state.dart          # State enum/classes
|       +-- vlibras_value.dart          # Value object for controller state
+-- android/
|   +-- build.gradle
|   +-- src/main/kotlin/com/example/vlibras_flutter/
|       +-- VLibrasFlutterPlugin.kt     # FlutterPlugin registration
|       +-- VLibrasViewFactory.kt       # PlatformViewFactory for AndroidView
|       +-- VLibrasNativeView.kt        # Wraps VLibras Android SDK view
+-- ios/
|   +-- vlibras_flutter.podspec
|   +-- Classes/
|       +-- VLibrasFlutterPlugin.swift  # FlutterPlugin registration
|       +-- VLibrasViewFactory.swift    # FlutterPlatformViewFactory
|       +-- VLibrasNativeView.swift     # Wraps VLibras iOS SDK view
+-- web/                                # Only if using separate web dir
|   +-- vlibras_web.dart                # Web plugin registration
+-- example/
|   +-- lib/main.dart                   # Demo app
+-- test/
|   +-- vlibras_controller_test.dart
|   +-- vlibras_platform_test.dart
+-- pubspec.yaml
```

## Patterns to Follow

### Pattern 1: Controller + Widget (a la video_player)

**What:** Separate the imperative API (Controller) from the declarative UI (Widget). Controller extends ChangeNotifier and holds a value object with current state. Widget listens to controller and rebuilds.

**When:** Always -- this is the chosen API pattern for VLibras.

**Why:** Established Flutter convention. Developers already know this from VideoPlayerController, WebViewController, GoogleMapController, etc. Provides clean separation between "what to do" (commands) and "how to show it" (rendering).

**Example:**

```dart
// vlibras_controller.dart
class VLibrasController extends ValueNotifier<VLibrasValue> {
  VLibrasController() : super(VLibrasValue.uninitialized());

  Future<void> initialize() async {
    try {
      await VLibrasPlatform.instance.init();
      value = value.copyWith(isInitialized: true);
    } catch (e) {
      value = value.copyWith(error: e.toString());
    }
  }

  Future<void> translate(String text) async {
    value = value.copyWith(isTranslating: true);
    try {
      await VLibrasPlatform.instance.translate(_viewId, text);
      // State updates come via event stream from platform
    } catch (e) {
      value = value.copyWith(isTranslating: false, error: e.toString());
    }
  }

  @override
  Future<void> dispose() async {
    await VLibrasPlatform.instance.dispose(_viewId);
    super.dispose();
  }
}

// vlibras_value.dart
class VLibrasValue {
  final bool isInitialized;
  final bool isTranslating;
  final String? error;

  VLibrasValue._({
    required this.isInitialized,
    required this.isTranslating,
    this.error,
  });

  factory VLibrasValue.uninitialized() => VLibrasValue._(
    isInitialized: false,
    isTranslating: false,
  );

  VLibrasValue copyWith({bool? isInitialized, bool? isTranslating, String? error}) {
    return VLibrasValue._(
      isInitialized: isInitialized ?? this.isInitialized,
      isTranslating: isTranslating ?? this.isTranslating,
      error: error ?? this.error,
    );
  }
}
```

### Pattern 2: Platform Interface with Singleton Instance

**What:** Abstract class that defines all platform operations. Has a static `instance` field defaulting to MethodChannel implementation. Platform-specific implementations replace it at registration time.

**When:** Always -- this is how Flutter federated plugins work internally.

**Why:** Decouples the app-facing code from platform specifics. Enables testing with mock implementations. Leaves door open for future federation.

**Example:**

```dart
// vlibras_platform.dart
abstract class VLibrasPlatform {
  static VLibrasPlatform _instance = VLibrasMethodChannel();

  static VLibrasPlatform get instance => _instance;

  static set instance(VLibrasPlatform instance) {
    _instance = instance;
  }

  Future<void> init();
  Future<void> translate(int viewId, String text);
  Future<void> dispose(int viewId);
  Stream<VLibrasEvent> get onEvent;
}

// vlibras_method_channel.dart (default implementation for Android/iOS)
class VLibrasMethodChannel extends VLibrasPlatform {
  final _channel = const MethodChannel('com.example.vlibras_flutter');
  final _eventChannel = const EventChannel('com.example.vlibras_flutter/events');

  @override
  Future<void> translate(int viewId, String text) {
    return _channel.invokeMethod('translate', {
      'viewId': viewId,
      'text': text,
    });
  }

  @override
  Stream<VLibrasEvent> get onEvent {
    return _eventChannel.receiveBroadcastStream().map(_parseEvent);
  }
  // ...
}
```

### Pattern 3: Conditional Import for Web vs Mobile

**What:** Use Dart conditional imports to swap implementations at compile time. The web implementation uses `dart:html` / `dart:js_interop` which are unavailable on mobile, and vice versa for `dart:io`.

**When:** Always for plugins supporting both mobile and web.

**Why:** Avoids runtime errors from importing platform-specific dart: libraries. The compiler tree-shakes the unused path.

**Example:**

```dart
// vlibras_flutter.dart (barrel file)
export 'vlibras_controller.dart';
export 'vlibras_view.dart';

// vlibras_platform.dart - registration
import 'vlibras_platform_stub.dart'
    if (dart.library.html) 'vlibras_web.dart'
    if (dart.library.io) 'vlibras_method_channel.dart';

// Each file exports a registerPlatform() function
// Called during plugin registration
```

### Pattern 4: PlatformView for Native View Embedding

**What:** Use `AndroidView` / `UiKitView` to embed the VLibras native SDK view directly into the Flutter widget tree. Each view gets a unique `viewId` that maps to a native view instance.

**When:** For Android and iOS where the VLibras SDK renders a native view (likely a WebView or GLSurfaceView internally).

**Why:** The VLibras SDK renders a 3D animated avatar. This cannot be replicated in Flutter Canvas -- it must use the native rendering surface provided by the SDK. PlatformView is the only way to embed native views.

**Example:**

```dart
// vlibras_view.dart
class VLibrasView extends StatelessWidget {
  final VLibrasController controller;
  const VLibrasView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VLibrasValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (!value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }
        if (value.error != null) {
          return Center(child: Text('Error: ${value.error}'));
        }
        return _buildPlatformView(context);
      },
    );
  }

  Widget _buildPlatformView(BuildContext context) {
    if (kIsWeb) {
      return HtmlElementView(
        viewType: 'vlibras-player-${controller.viewId}',
      );
    }
    final viewType = 'com.example.vlibras_flutter/view';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: viewType,
          onPlatformViewCreated: controller.onPlatformViewCreated,
          creationParams: controller.creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
      case TargetPlatform.iOS:
        return UiKitView(
          viewType: viewType,
          onPlatformViewCreated: controller.onPlatformViewCreated,
          creationParams: controller.creationParams,
          creationParamsCodec: const StandardMessageCodec(),
        );
      default:
        return const Center(child: Text('Platform not supported'));
    }
  }
}
```

### Pattern 5: Event-Driven State Updates from Native

**What:** Use an EventChannel to stream events from native code back to Dart (animation started, animation completed, error occurred). The Controller subscribes to this stream and updates its value.

**When:** For any asynchronous state changes that originate on the native side (avatar started animating, finished animating, SDK error).

**Why:** MethodChannel is request-response. But the native SDK's animation lifecycle is asynchronous and event-driven. EventChannel provides the proper pub/sub mechanism.

**Example (Kotlin side):**

```kotlin
class VLibrasFlutterPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "com.example.vlibras_flutter")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.example.vlibras_flutter/events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    // When SDK animation completes:
    private fun onAnimationComplete(viewId: Int) {
        eventSink?.success(mapOf(
            "event" to "animationComplete",
            "viewId" to viewId
        ))
    }
}
```

## Anti-Patterns to Avoid

### Anti-Pattern 1: Pigeon for This Use Case

**What:** Using the Pigeon code generator for type-safe platform channels.

**Why bad:** Pigeon excels when you have many distinct method calls with complex parameter types. VLibras has a very narrow API surface (init, translate, dispose, events). The Pigeon setup overhead (code generation, build_runner dependency, generated file management) is not justified for 3-4 methods. Additionally, PlatformViews have their own communication pattern that Pigeon does not simplify.

**Instead:** Use plain MethodChannel with a small, well-tested set of method names. The codec handles String/Map serialization automatically.

### Anti-Pattern 2: Fully Federated Multi-Package from Day 1

**What:** Publishing 4+ packages to pub.dev (vlibras_flutter, vlibras_flutter_platform_interface, vlibras_flutter_android, vlibras_flutter_ios, vlibras_flutter_web).

**Why bad:** Massive coordination overhead for a single-author plugin. Every change requires updating 2-4 pubspec.yaml files, publishing in sequence, managing version constraints. The federation benefit (third-party platform implementations) is unlikely -- VLibras is specific to Brazilian government infrastructure.

**Instead:** Single package with internal separation. Define `VLibrasPlatform` as an abstract class inside `lib/src/` but don't make it a separate package. If demand for federation appears later, extracting the interface to a separate package is straightforward because the architecture already follows the pattern.

### Anti-Pattern 3: WebView Inside PlatformView on Mobile

**What:** Using the web player (vlibras-web-player) inside a WebView on Android/iOS instead of the native SDKs.

**Why bad:** Double embedding penalty: Flutter PlatformView embeds a native WebView, which embeds a Unity/WebGL player. Performance is terrible (two composition layers, GPU context switches). Also loses native SDK features like offline capability and proper lifecycle management.

**Instead:** Use the native Android/iOS SDKs on mobile. Reserve the web player approach exclusively for Flutter Web where HtmlElementView has zero overhead (it is the native web platform).

### Anti-Pattern 4: Global Singleton Controller

**What:** Having a single global VLibras instance shared across the app.

**Why bad:** Prevents showing multiple VLibras views simultaneously (e.g., a chat app with LIBRAS translation per message). Makes testing harder. Ties lifecycle to app rather than widget.

**Instead:** Each VLibrasController manages its own view instance via a viewId. Multiple controllers can coexist. The platform layer routes commands to the correct native view by viewId.

### Anti-Pattern 5: Synchronous Initialization

**What:** Initializing the VLibras SDK in the controller constructor or synchronously.

**Why bad:** Native SDK initialization involves loading assets, potentially network calls, and GPU setup. Blocking the constructor makes it impossible to show loading states. Also, constructors cannot be async in Dart.

**Instead:** Two-phase pattern: `VLibrasController()` (instant, sets state to uninitialized) then `await controller.initialize()` (async, loads SDK, transitions to initialized state). The VLibrasView handles all states (uninitialized, loading, initialized, error) with appropriate UI.

## Platform-Specific Architecture Details

### Android Implementation

```
VLibrasFlutterPlugin (Kotlin)
  implements: FlutterPlugin, MethodCallHandler
  |
  +-- registers MethodChannel("com.example.vlibras_flutter")
  +-- registers EventChannel("com.example.vlibras_flutter/events")
  +-- registers PlatformViewFactory("com.example.vlibras_flutter/view")
        |
        +-- VLibrasViewFactory
              creates: VLibrasNativeView(context, viewId, creationParams)
                |
                +-- Instantiates VLibras Android SDK view
                +-- Holds reference by viewId
                +-- Forwards translate() calls to SDK
                +-- Listens for SDK callbacks -> sends to EventSink
```

**Key considerations:**
- The VLibras Android SDK likely provides a `View` subclass (possibly WebView-based internally). Wrap it directly in the PlatformViewFactory.
- Use `PlatformViewLink` / Hybrid Composition mode for better performance on Android (vs Virtual Display mode).
- The SDK AAR/dependency must be declared in `android/build.gradle`.

### iOS Implementation

```
VLibrasFlutterPlugin (Swift)
  implements: NSObject, FlutterPlugin
  |
  +-- registers MethodChannel
  +-- registers EventChannel
  +-- registers FlutterPlatformViewFactory
        |
        +-- VLibrasViewFactory: FlutterPlatformViewFactory
              creates: VLibrasNativeView: NSObject, FlutterPlatformView
                |
                +-- func view() -> UIView  (returns VLibras SDK view)
                +-- Holds reference by viewId
                +-- Forwards translate() calls to SDK
                +-- Listens for SDK callbacks -> sends to EventSink
```

**Key considerations:**
- The VLibras iOS SDK likely provides a `UIView` subclass. Return it from `view()`.
- Declare SDK dependency in `ios/vlibras_flutter.podspec` (pod dependency or vendored framework).
- Handle iOS-specific lifecycle (viewWillAppear/Disappear) via FlutterPlugin lifecycle delegates.

### Web Implementation

```
VLibrasWeb (Dart)
  extends: VLibrasPlatform
  |
  +-- registerWith() -> sets VLibrasPlatform.instance = VLibrasWeb()
  +-- init():
  |     +-- Injects <script src="https://vlibras.gov.br/app/vlibras-plugin.js">
  |     +-- Waits for script load
  |     +-- Creates VLibras player instance via JS interop
  |
  +-- translate(viewId, text):
  |     +-- Calls JS: vlibrasPlayer.translate(text) via dart:js_interop
  |
  +-- Widget creation:
        +-- Registers viewType 'vlibras-player-{id}' with platformViewRegistry
        +-- Creates <div> element
        +-- VLibras JS player renders into that <div>
        +-- HtmlElementView displays the <div> in Flutter widget tree
```

**Key considerations:**
- The VLibras web player is loaded via a `<script>` tag from `vlibras.gov.br`. It injects a floating widget by default. For the plugin, we need to control where it renders (inside a specific div, not floating).
- Use `dart:js_interop` (not the deprecated `dart:js`) for Dart 3.x+ compatibility.
- Use `web` package (not `dart:html` which is deprecated) for DOM manipulation.
- No MethodChannel needed for web -- communicate directly via JS interop.
- `HtmlElementView.fromTagName()` or `platformViewRegistry.registerViewFactory()` for view creation.

## Communication Protocol

### MethodChannel API Contract

| Method | Direction | Arguments | Returns | Purpose |
|--------|-----------|-----------|---------|---------|
| `init` | Dart -> Native | `Map{config}` | `void` | Initialize VLibras SDK |
| `translate` | Dart -> Native | `Map{viewId: int, text: String}` | `void` | Send text for translation |
| `dispose` | Dart -> Native | `Map{viewId: int}` | `void` | Release native resources |

### EventChannel Events

| Event | Direction | Payload | Purpose |
|-------|-----------|---------|---------|
| `onReady` | Native -> Dart | `{viewId: int}` | SDK view is ready |
| `onAnimationStart` | Native -> Dart | `{viewId: int, text: String}` | Avatar started signing |
| `onAnimationEnd` | Native -> Dart | `{viewId: int}` | Avatar finished signing |
| `onError` | Native -> Dart | `{viewId: int, code: String, message: String}` | SDK error occurred |

### Channel Names

```
Method Channel:  "com.example.vlibras_flutter"
Event Channel:   "com.example.vlibras_flutter/events"
View Type:       "com.example.vlibras_flutter/view"
```

## Scalability Considerations

| Concern | Single View | Multiple Views | Notes |
|---------|-------------|----------------|-------|
| Memory | One native SDK instance, acceptable | Each view creates SDK instance; VLibras SDK is WebGL/Unity-heavy | Limit concurrent views; provide guidance in docs |
| viewId management | Trivial | Need registry pattern in native code | Use AtomicInteger/counter for unique IDs |
| Event routing | Direct | Must filter events by viewId | EventChannel payload includes viewId |
| Web script loading | Load once | Shared script, multiple player divs | Script tag is idempotent; manage player instances |

## Build Order (Dependency Graph)

This is the recommended implementation order based on component dependencies:

```
Phase 1: Foundation (no platform dependency)
  [1] VLibrasValue / VLibrasState (pure Dart data classes)
  [2] VLibrasPlatform (abstract interface)
  [3] VLibrasController (depends on 1, 2)
  [4] VLibrasView skeleton (depends on 3, shows placeholder)
  [5] Unit tests for Controller with mock platform

Phase 2: First Platform (choose ONE to prove architecture)
  [6] Android OR Web native implementation
      - If Android: VLibrasFlutterPlugin.kt + VLibrasViewFactory.kt + VLibrasNativeView.kt
      - If Web: VLibrasWeb.dart + JS interop (faster to iterate, no device needed)
  [7] Wire VLibrasView to render actual platform view
  [8] Integration test on chosen platform

Phase 3: Second Platform
  [9] The other mobile platform (iOS)
  [10] Platform-specific adjustments

Phase 4: Third Platform + Polish
  [11] Remaining platform (Web or Android, whichever was not in Phase 2)
  [12] Cross-platform testing
  [13] API polish, documentation, example app
```

**Recommendation: Start with Web in Phase 2.** Rationale:
- Fastest iteration cycle (hot reload in browser, no emulator)
- The VLibras web player is publicly hosted and well-documented (vlibras.gov.br)
- Proves the Controller+Widget pattern without native build toolchain
- Android and iOS SDKs may require investigation into packaging (AAR/Pod distribution)

**Then Android in Phase 3, iOS in Phase 4.** Android has more accessible tooling/debugging. iOS follows the same pattern but needs CocoaPods configuration.

## Sources

- Flutter official documentation: Developing packages and plugins (https://docs.flutter.dev/packages-and-plugins/developing-packages) -- HIGH confidence
- Flutter official documentation: Platform channels (https://docs.flutter.dev/platform-integration/platform-channels) -- HIGH confidence
- Flutter video_player plugin architecture (training knowledge of the federated plugin structure) -- HIGH confidence for patterns, the video_player plugin is a canonical reference in Flutter docs
- VLibras project context from PROJECT.md -- confirmed
- VLibras SDK repositories (https://github.com/orgs/spbgovbr-vlibras/repositories) -- MEDIUM confidence, repository existence confirmed in PROJECT.md but SDK internals based on training data
- VLibras web player public URL pattern (vlibras.gov.br) -- MEDIUM confidence, needs validation

## Confidence Notes

| Area | Confidence | Notes |
|------|------------|-------|
| Flutter plugin architecture patterns | HIGH | Verified against official Flutter docs |
| Controller+Widget pattern | HIGH | Canonical Flutter pattern used by video_player, google_maps, webview |
| Platform channels / PlatformView | HIGH | Verified against official Flutter docs |
| Web implementation via HtmlElementView + JS interop | HIGH | Standard Flutter web plugin pattern |
| VLibras Android SDK API surface | MEDIUM | Based on training data; needs validation against actual SDK source |
| VLibras iOS SDK API surface | MEDIUM | Based on training data; needs validation against actual SDK source |
| VLibras web player embedding approach | MEDIUM | Public player exists at vlibras.gov.br; exact integration API needs validation |
| Build order recommendation | MEDIUM-HIGH | Based on dependency analysis and general plugin dev experience |
