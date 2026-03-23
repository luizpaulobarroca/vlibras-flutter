# Domain Pitfalls

**Domain:** Flutter plugin multiplataforma wrapping SDKs nativos (Android AAR + iOS CocoaPods) com WebView para Web
**Project:** vlibras_flutter
**Researched:** 2026-03-22
**Note:** Based on training data knowledge of Flutter plugin architecture. Web search unavailable during research -- confidence levels adjusted accordingly. Core Flutter plugin patterns are stable and well-documented, so structural pitfalls carry HIGH confidence.

---

## Critical Pitfalls

Mistakes that cause rewrites, broken releases, or weeks of debugging.

---

### Pitfall 1: Platform Channel Lifecycle Mismatch (Controller vs. Native View)

**What goes wrong:** The Dart `VLibrasController` and the native platform view (Android `PlatformView` / iOS `FlutterPlatformView`) have independent lifecycles. The controller may send method calls before the native view is attached, or the native view may be destroyed (e.g., on navigation) while the controller still holds a reference. This causes `MissingPluginException` on Android or silent failures on iOS.

**Why it happens:** Flutter's `PlatformViewFactory` creates the native view when the widget enters the tree, but developers often create the controller in `initState` or even in a provider/bloc -- before the view exists. On disposal, the reverse problem occurs: the widget is removed but the controller tries to call `translate()` from a lingering animation or timer.

**Consequences:**
- Crashes on navigation (pop a route with VLibras, come back, crash)
- Race conditions where `translate()` is called before the native SDK is initialized
- Memory leaks from native views not being properly disposed

**Warning signs:**
- `MissingPluginException` in debug logs
- Avatar renders as black/blank screen after navigating away and back
- Memory usage climbs when repeatedly entering/leaving VLibras screens

**Prevention:**
1. Use a `ready` completer/stream in the controller. The native side sends a `"onReady"` event through an EventChannel when the SDK is fully initialized. The controller exposes `Future<void> get ready` or `Stream<VLibrasState>`.
2. Guard all method channel calls behind the ready state. `translate()` should queue or throw if not ready.
3. On the native side, implement `dispose()` explicitly in both Android (`PlatformView.dispose()`) and iOS (`FlutterPlatformView` dealloc) to release the VLibras SDK resources.
4. In the Dart widget, tie controller lifecycle to widget lifecycle using `dispose()` in State.

**Phase to address:** Phase 1 (core architecture). Getting this wrong means rewriting the entire channel/controller layer later.

**Confidence:** HIGH -- this is the single most common Flutter plugin pitfall, extensively documented in Flutter's own PlatformView docs.

---

### Pitfall 2: Android AAR Dependency Hell (Gradle Version Conflicts)

**What goes wrong:** The VLibras Android SDK is distributed as an AAR. When the plugin's `build.gradle` declares this dependency, it may conflict with the host app's Gradle version, Android Gradle Plugin (AGP) version, `minSdkVersion`, `compileSdkVersion`, or transitive dependencies (e.g., both the host app and VLibras SDK depend on different versions of `androidx.core` or `okhttp`).

**Why it happens:** AAR dependencies carry their own transitive dependency tree. The VLibras Android SDK likely uses Unity-based rendering (for the 3D avatar), which brings heavy native dependencies. Flutter plugin consumers have no control over what the plugin's AAR brings in.

**Consequences:**
- Build failures on consumer side: `Duplicate class found` errors
- `minSdkVersion` mismatch: VLibras SDK may require API 21+ or even 24+ (for Unity)
- The plugin becomes impossible to use alongside other plugins that also embed Unity or heavy native libraries
- Gradle resolution failures that produce cryptic multi-page error messages

**Warning signs:**
- Plugin example app builds, but a real app with other plugins does not
- Build errors mentioning `DuplicateClassException` or version conflicts in `AndroidManifest.xml` merge
- Users report issues only when combining with specific other plugins

**Prevention:**
1. In the plugin's `android/build.gradle`, declare the AAR dependency with `implementation` (not `api`) to minimize transitive leakage.
2. Set `minSdkVersion` and `compileSdkVersion` to the minimum the VLibras SDK actually requires. Document this prominently in README.
3. Test the plugin in a "real-world" example app that includes common plugins (camera, webview, maps) to catch conflicts early.
4. If the VLibras AAR is not published to Maven Central/Google's Maven, you may need to bundle it as a local AAR or use a custom Maven repo. Document the approach clearly.
5. Use `resolutionStrategy` in the plugin's Gradle to force-align critical transitive dependencies if needed.
6. Check if the VLibras SDK uses `ndk` filters -- if it only supports `armeabi-v7a` and `arm64-v8a`, document that `x86`/`x86_64` (emulator) may not work.

**Phase to address:** Phase 1 (Android integration). Must be validated before any feature work.

**Confidence:** HIGH -- Gradle dependency conflicts are the most reported issue category for Flutter Android plugins.

---

### Pitfall 3: iOS CocoaPods Linking and Architecture Mismatches

**What goes wrong:** The VLibras iOS SDK (CocoaPods) may be distributed as a pre-compiled binary (`.framework` or `.xcframework`). If it contains only `arm64` slices, it won't work on the iOS Simulator (which needs `x86_64` or `arm64` simulator slices). If it's a static library, it may cause duplicate symbol errors with Flutter's own static linking.

**Why it happens:** iOS SDK vendors often distribute release-only binaries. Unity-based iOS builds are notoriously large and architecture-specific. Flutter plugins on iOS use CocoaPods, which has its own set of linking rules that interact with Xcode's build settings.

**Consequences:**
- Plugin cannot be tested on iOS Simulator at all (blocks development)
- `ld: symbol(s) not found for architecture x86_64` or similar
- App Store rejection due to unsupported architectures or missing bitcode (less relevant post-Xcode 14, but still possible with older SDKs)
- Binary size explosion if the SDK includes unstripped Unity libraries

**Warning signs:**
- Build succeeds on device but fails on simulator
- Linker errors mentioning architectures
- IPA size jumps by 50-100+ MB after adding the plugin
- `pod install` warnings about deployment targets

**Prevention:**
1. Immediately test on both Simulator and real device. If Simulator doesn't work, document it and provide guidance (use real device only).
2. In the plugin's `.podspec`, set `s.platform` and `s.ios.deployment_target` to match the VLibras SDK's requirements.
3. If the SDK is an `.xcframework`, it likely already handles architectures. If it's a plain `.framework`, check architectures with `lipo -info`.
4. Use `s.vendored_frameworks` in the podspec if bundling the framework directly.
5. Set `s.static_framework = true` if the VLibras SDK requires static linking.
6. Test `pod lib lint` and `pod spec lint` locally before publishing to catch spec issues.
7. Document expected IPA size impact.

**Phase to address:** Phase 1 (iOS integration). This is a go/no-go gate -- if the SDK doesn't link, nothing else matters.

**Confidence:** HIGH -- iOS architecture/linking issues are the second most reported Flutter plugin issue category.

---

### Pitfall 4: PlatformView Performance with 3D/WebGL Content

**What goes wrong:** Flutter's `AndroidView`/`UiKitView` (mobile) and `HtmlElementView` (web) each have different performance characteristics when embedding native views that do heavy rendering (3D avatar, WebGL). On Android specifically, there are two rendering modes: Virtual Display (default, older) and Hybrid Composition. Virtual Display has known issues with rendering heavy OpenGL/Vulkan content -- the native view may flicker, show a black frame on first render, or have incorrect touch event routing. On iOS, `UiKitView` works better but still has compositing overhead. On Web, `HtmlElementView` creates an actual DOM element outside Flutter's canvas, causing z-ordering issues.

**Why it happens:** Flutter paints its own UI via Skia/Impeller on a single GPU surface. Embedding a native view that also uses the GPU (Unity 3D avatar, WebGL canvas) requires complex compositing. Each platform handles this differently, and all have trade-offs.

**Consequences:**
- Black flicker on Android when the VLibras view appears (1-2 frames of black before content)
- Touch events not reaching the native view (user can't interact with avatar)
- On Web, Flutter widgets cannot be rendered on top of the HtmlElementView (z-order is always DOM-order based)
- Scrolling jank when VLibras view is inside a ScrollView
- On older Android devices, Virtual Display mode may not render the 3D content at all

**Warning signs:**
- Black frame flash when navigating to the VLibras screen
- Touch/gesture events don't work on the avatar
- Flutter widgets (like an overlay loading indicator) appear behind the native view on Web
- Significant frame drops when the VLibras view is visible

**Prevention:**
1. On Android, use Hybrid Composition mode explicitly: set `PlatformViewsService.initSurfaceAndroidView` instead of `initAndroidView`. In Flutter 3.x+, this is controlled via `AndroidView`'s `creationParams` and `viewType`.
2. On Android, handle the "first frame black" issue by showing a placeholder widget until the native view signals it has rendered its first frame.
3. On iOS, `UiKitView` generally works well with OpenGL/Metal content. No special mode needed.
4. On Web, accept that `HtmlElementView` has z-ordering limitations. Design the UI so that no Flutter widgets need to overlay the VLibras player. Use pointer interceptors (`pointer_interceptor` package) if you need clickable Flutter widgets near the embedded view.
5. Avoid putting the VLibras view inside a `ListView` or `ScrollView` -- if needed, use `SliverToBoxAdapter` and fixed heights.
6. Document minimum Android API level and GPU requirements.

**Phase to address:** Phase 1-2 (platform view integration). Must be validated per-platform before building features on top.

**Confidence:** HIGH -- PlatformView rendering issues are extensively documented in Flutter's GitHub issues and official docs.

---

### Pitfall 5: Web Platform -- HtmlElementView Isolation and CSP Issues

**What goes wrong:** The VLibras web player loads external JavaScript (from vlibras.gov.br or bundled), creates a WebGL canvas, and may load remote assets (3D models, animations). When embedded via `HtmlElementView` in Flutter Web, multiple issues arise: Content Security Policy (CSP) blocks on the hosting domain, CORS failures loading remote assets, and the JS player's global state conflicting with Flutter's own JS.

**Why it happens:** Flutter Web runs as a single-page application. The VLibras web player was designed to be embedded in regular HTML pages, not inside Flutter's shadow DOM-like rendering. CSP headers on the deployment domain may block inline scripts or connections to `vlibras.gov.br` subdomains.

**Consequences:**
- VLibras player fails silently in production (works in `flutter run` debug but not deployed)
- WebGL context creation fails due to CSP `script-src` restrictions
- 3D model assets fail to load due to CORS (avatar appears but animations don't play)
- Multiple VLibras instances on same page cause global state conflicts
- Player initialization race condition with Flutter's own boot sequence

**Warning signs:**
- Console errors about CSP violations or CORS
- Player works in `flutter run -d chrome` but not in deployed builds
- Avatar loads but doesn't animate (assets failed to load silently)
- Blank/white area where the player should be

**Prevention:**
1. Document required CSP headers: `script-src` must allow the VLibras player source, `connect-src` must allow `vlibras.gov.br` and its CDN domains, `worker-src` may be needed for WebGL workers.
2. Test in both `--web-renderer canvaskit` and `--web-renderer html` modes. CanvasKit has different compositing behavior for `HtmlElementView`.
3. Bundle the VLibras player JS locally in the plugin's web assets rather than loading from CDN -- reduces CORS/CSP surface and improves reliability.
4. Register the `HtmlElementView` factory in the plugin's `registerWith()` method, not lazily. Ensure the factory is registered before any widget tries to use it.
5. Handle the player initialization asynchronously -- the JS player likely has a callback/promise for when it's ready. Bridge this to the Dart side via `dart:js_interop`.
6. If the VLibras player uses global variables (window.vlibras or similar), ensure only one instance exists or namespace them.

**Phase to address:** Phase 2 (web integration). After mobile is working, Web brings its own unique challenges.

**Confidence:** MEDIUM -- CSP/CORS specifics depend on the actual VLibras web player implementation, which I couldn't verify. The general pattern is well-established.

---

### Pitfall 6: pub.dev Score Killed by Platform Declaration and Documentation Gaps

**What goes wrong:** The plugin gets a low pub.dev score (below 100/160 or worse) because of incorrect `pubspec.yaml` platform declarations, missing API documentation, analysis warnings, or platform-specific files that don't follow conventions. A low score means low visibility and low trust from potential users.

**Why it happens:** pub.dev's scoring algorithm (pana) checks specific things: platform support declarations, dartdoc coverage, static analysis cleanliness, example app presence, license, and changelog. Plugin developers focused on making the native code work often forget these meta-requirements until publishing time.

**Consequences:**
- Low "likes" and adoption due to poor pub.dev visibility
- Users see "NOT SUPPORTED" badges for platforms that actually work
- Dart analyzer warnings in the plugin code reduce the "health" score
- Missing `example/` directory costs points

**Warning signs:**
- Running `dart pub publish --dry-run` shows warnings
- Running `pana` locally produces a low score
- Platform badges on pub.dev don't show the expected platforms

**Prevention:**
1. Set up `pubspec.yaml` correctly from day 1:
   ```yaml
   flutter:
     plugin:
       platforms:
         android:
           package: com.example.vlibras_flutter
           pluginClass: VLibrasFlutterPlugin
         ios:
           pluginClass: VLibrasFlutterPlugin
         web:
           pluginClass: VLibrasFlutterWeb
           fileName: vlibras_flutter_web.dart
   ```
2. Add dartdoc comments (`///`) to every public API member. Pana checks documentation coverage.
3. Include a working `example/` app that demonstrates core usage.
4. Run `dart analyze` with zero warnings in CI.
5. Include `LICENSE`, `CHANGELOG.md`, and a complete `README.md` with usage examples.
6. Run `dart pub publish --dry-run` regularly during development.
7. Add a GitHub Actions workflow that runs `pana` to track score over time.

**Phase to address:** Phase 1 (project scaffolding). Must be baked into the project structure from the start. Retrofitting documentation and structure is painful.

**Confidence:** HIGH -- pub.dev scoring criteria are publicly documented and stable.

---

### Pitfall 7: Method Channel Serialization Bottleneck for Rich State

**What goes wrong:** The VLibras plugin needs to communicate state between Dart and native: translation progress, avatar animation state, errors, loading progress. Developers start with simple `MethodChannel` calls (`translate(text)` returns `void`, errors come as exceptions). As requirements grow (progress updates, animation callbacks, multiple simultaneous translations), the MethodChannel becomes a bottleneck and the API becomes a mess of string-keyed method calls.

**Why it happens:** `MethodChannel` is request-response. It's great for `translate("hello")` but terrible for streaming state updates like "loading model... 30%... 60%... ready... animating... done." Developers don't plan for bidirectional streaming communication upfront and end up with hacky polling or dozens of one-off method names.

**Consequences:**
- No way to show translation progress to the user
- Dart side doesn't know if the native SDK crashed or is still loading
- Error handling becomes inconsistent (some errors are return values, some are exceptions, some are silently swallowed)
- Adding new native-to-Dart events requires touching code in 4 places (Dart channel, Android handler, iOS handler, and the widget)

**Warning signs:**
- Growing list of method names in the channel handler (`"translate"`, `"getStatus"`, `"isReady"`, `"getProgress"`, `"onError"`, ...)
- Polling the native side with a timer to check status
- Inconsistent error handling across platforms

**Prevention:**
1. Use `EventChannel` alongside `MethodChannel` from the start. MethodChannel for commands (Dart -> Native), EventChannel for state stream (Native -> Dart).
2. Define a sealed state class in Dart:
   ```dart
   sealed class VLibrasState {
     VLibrasInitializing()
     VLibrasReady()
     VLibrasTranslating(String text, double progress)
     VLibrasError(String message)
   }
   ```
3. On the native side, serialize state as a Map and send through EventChannel. On Dart side, deserialize into the sealed class.
4. Use Pigeon (Flutter's code generation tool for platform channels) to type-check the interface between Dart and native. This eliminates string-keyed method calls and catches type mismatches at compile time.

**Phase to address:** Phase 1 (API design). The channel architecture must be designed before implementing features.

**Confidence:** HIGH -- MethodChannel vs EventChannel patterns are stable Flutter architecture concerns.

---

## Moderate Pitfalls

---

### Pitfall 8: Unity-based SDK Memory and Thread Issues on Mobile

**What goes wrong:** The VLibras SDK (both Android and iOS) likely embeds a Unity runtime for 3D avatar rendering. Unity creates its own threads, allocates significant memory (100-300MB), and manages its own OpenGL/Metal context. When embedded in a Flutter plugin, the Unity runtime may conflict with Flutter's rendering thread, leak memory when the view is disposed, or crash when the app goes to background and comes back.

**Prevention:**
1. Implement proper `onPause`/`onResume` (Android) and `applicationDidEnterBackground`/`applicationWillEnterForeground` (iOS) handling in the native plugin code.
2. Dispose the Unity instance when the VLibras view is removed from the widget tree. Do NOT keep it alive hoping to "reuse" it -- Unity re-initialization is safer than managing a zombie Unity instance.
3. Test extensively with Android's "Don't keep activities" developer option enabled.
4. Monitor memory with Xcode Instruments and Android Profiler during extended use.
5. Consider lazy initialization: don't start the Unity runtime until the user actually navigates to a VLibras screen.

**Phase to address:** Phase 2-3 (optimization). Get it working first, then handle lifecycle edge cases.

**Confidence:** MEDIUM -- depends on whether VLibras actually uses Unity runtime (likely based on the WebGL player, but not verified).

---

### Pitfall 9: Federated Plugin vs. Single Plugin Decision Paralysis

**What goes wrong:** Flutter supports "federated plugins" (separate packages for each platform: `vlibras_flutter`, `vlibras_flutter_android`, `vlibras_flutter_ios`, `vlibras_flutter_web`, `vlibras_flutter_platform_interface`). This is the "official" recommendation for large plugins. Developers either (a) over-engineer by starting with federated structure for a small plugin, or (b) start monolithic and painfully migrate later.

**Prevention:**
1. For this project, start with a single plugin package (non-federated). Federated plugins are justified when you expect independent platform maintainers or need to publish platform implementations separately. VLibras is maintained by one team.
2. Still follow good internal separation: put platform-specific code in `lib/src/android/`, `lib/src/ios/`, `lib/src/web/` directories.
3. Define a clear platform interface internally (abstract class) even within the single package. This makes migration to federated structure straightforward if ever needed.
4. If the plugin grows significantly or external contributors want to maintain a platform, migrate to federated at that point.

**Phase to address:** Phase 1 (scaffolding decision). Make this call once and move on.

**Confidence:** HIGH -- Flutter team's own guidance is that federated is optional, not required.

---

### Pitfall 10: Testing Native Plugin Code is Hard -- Skipping Tests Until "Later"

**What goes wrong:** Developers get the plugin working manually, defer writing tests because "testing platform channels is complicated," and then never write them. When bugs appear (especially lifecycle bugs or platform-specific regressions), there's no test suite to catch regressions.

**Prevention:**
1. Use `setMockMethodCallHandler` in unit tests to mock the platform channel. Test the Dart Controller logic in isolation.
2. Write integration tests using `integration_test` package that run on real devices/emulator. Even 3-4 integration tests covering init -> translate -> dispose are invaluable.
3. For the Web platform, use `flutter test --platform chrome` to test HtmlElementView registration.
4. Test the native code separately: Android instrumented tests (Espresso) and iOS XCTest for the native plugin class. Even minimal "does it initialize without crashing" tests help.
5. Add tests in CI from Phase 1. GitHub Actions supports Android emulator and iOS simulator runners.

**Phase to address:** Phase 1 (from the start). Even minimal test scaffolding prevents "test-writing fatigue" later.

**Confidence:** HIGH -- well-known pattern in plugin development.

---

### Pitfall 11: VLibras SDK Version Pinning and Update Strategy

**What goes wrong:** The VLibras SDK is maintained by a government institution (UFPB/RNP). Government SDKs tend to have irregular release cycles, breaking changes without semantic versioning, and limited documentation of changes. If the plugin pins to a specific SDK version and VLibras releases an update (even a minor one), the plugin may break silently or stop working because the backend API changed.

**Prevention:**
1. Document exactly which version of the VLibras SDK (Android and iOS) the plugin is tested against.
2. If possible, vendor the SDK (include the AAR/framework in the plugin repo) rather than pulling from a remote repository. This ensures reproducible builds.
3. Set up a CI job that periodically tests against the latest VLibras SDK to catch breaking changes early.
4. Implement a version check in the plugin: on init, log the detected VLibras SDK version and warn if it's untested.
5. Maintain a compatibility matrix in the README.

**Phase to address:** Phase 1 (dependency setup) and ongoing maintenance.

**Confidence:** MEDIUM -- specific to VLibras's release practices, which I couldn't verify. The general risk is well-established for government/institutional SDKs.

---

## Minor Pitfalls

---

### Pitfall 12: ProGuard/R8 Stripping Native SDK Classes on Android

**What goes wrong:** In release builds, Android's R8 optimizer strips classes it thinks are unused. If the VLibras SDK uses reflection or JNI to load classes dynamically (common with Unity-based SDKs), R8 strips them and the SDK crashes at runtime -- but only in release builds.

**Prevention:**
1. Include a `proguard-rules.pro` in the plugin's `android/` directory with keep rules for VLibras SDK classes.
2. In the plugin's `build.gradle`, reference these rules with `consumerProguardFiles`.
3. Always test release builds (`flutter run --release`), not just debug builds.

**Phase to address:** Phase 2 (release build validation).

**Confidence:** HIGH -- standard Android plugin concern.

---

### Pitfall 13: iOS App Transport Security (ATS) Blocking VLibras Network Calls

**What goes wrong:** The VLibras SDK may make network calls to government servers (e.g., to download translation data or 3D model updates). If these servers don't support HTTPS or use self-signed certificates, iOS's ATS blocks them silently. The avatar loads but translations don't work.

**Prevention:**
1. Identify all network endpoints the VLibras SDK contacts (inspect with Charles Proxy or mitmproxy during development).
2. If any endpoints require ATS exceptions, document them and include the required `Info.plist` entries in the plugin's README.
3. Do NOT add a blanket `NSAllowsArbitraryLoads = YES` -- this causes App Store review issues. Add domain-specific exceptions only.

**Phase to address:** Phase 1-2 (iOS integration testing).

**Confidence:** MEDIUM -- depends on VLibras's actual network behavior.

---

### Pitfall 14: Web Build Size Explosion

**What goes wrong:** The VLibras web player includes a WebGL/Unity-based 3D engine. When bundled with the Flutter web app, the total JS/WASM payload can exceed 30-50MB, making the web deployment impractically slow.

**Prevention:**
1. Load the VLibras web player lazily -- don't include it in the main Flutter web build. Load the JS/WASM on demand when the user first requests VLibras.
2. Use a CDN for VLibras assets rather than bundling them with the Flutter web app.
3. Implement a loading indicator while VLibras player initializes.
4. Document expected web payload size in the README so users aren't surprised.

**Phase to address:** Phase 2 (web optimization).

**Confidence:** MEDIUM -- depends on VLibras web player's actual bundle size.

---

### Pitfall 15: Keyboard and Accessibility Tree Conflicts

**What goes wrong:** Ironically, an accessibility plugin can break other accessibility features. PlatformViews on Android and iOS have their own accessibility nodes. The VLibras native view may intercept accessibility focus, prevent screen readers from reading surrounding Flutter widgets, or cause keyboard navigation issues.

**Prevention:**
1. Test with TalkBack (Android) and VoiceOver (iOS) enabled.
2. Set proper `Semantics` labels on the VLibras widget in Flutter.
3. If the native view steals accessibility focus, use `ExcludeSemantics` or `BlockSemantics` strategically and provide alternative accessibility information.
4. Document accessibility behavior in the README -- users of an accessibility plugin will care deeply about this.

**Phase to address:** Phase 3 (polish and accessibility).

**Confidence:** HIGH -- PlatformView accessibility issues are well-documented.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation | Severity |
|-------------|---------------|------------|----------|
| Project scaffolding | Pitfall 6: Bad pubspec structure | Use `flutter create --template=plugin` as starting point, validate with `pana` | High |
| Project scaffolding | Pitfall 9: Federated vs single | Start single, separate internally | Medium |
| API design | Pitfall 1: Lifecycle mismatch | Design ready-state protocol before coding | Critical |
| API design | Pitfall 7: MethodChannel bottleneck | Plan EventChannel from the start, consider Pigeon | High |
| Android integration | Pitfall 2: Gradle/AAR conflicts | Test in multi-plugin app early | Critical |
| Android integration | Pitfall 12: ProGuard stripping | Include proguard-rules.pro, test release builds | High |
| iOS integration | Pitfall 3: Architecture/linking | Test device + simulator immediately | Critical |
| iOS integration | Pitfall 13: ATS blocking | Identify network endpoints early | Medium |
| Platform view rendering | Pitfall 4: PlatformView performance | Use Hybrid Composition on Android, test 3D rendering | High |
| Web integration | Pitfall 5: CSP/CORS | Bundle JS locally, document CSP requirements | High |
| Web integration | Pitfall 14: Build size explosion | Lazy-load player, use CDN for assets | Medium |
| SDK dependency | Pitfall 11: Version pinning | Vendor SDK, document tested versions | Medium |
| Testing | Pitfall 10: Deferred tests | Set up test scaffolding in Phase 1 | Medium |
| Lifecycle/memory | Pitfall 8: Unity memory/threads | Handle app lifecycle events, test background/foreground | Medium |
| Polish | Pitfall 15: Accessibility conflicts | Test with screen readers | Medium |

---

## Sources

- Flutter PlatformViews documentation (flutter.dev) -- HIGH confidence basis for Pitfalls 1, 4, 15
- Flutter plugin development guide (flutter.dev/docs/development/packages-and-plugins) -- HIGH confidence basis for Pitfalls 6, 9
- Flutter MethodChannel/EventChannel API docs -- HIGH confidence basis for Pitfall 7
- Android Gradle Plugin compatibility documentation -- HIGH confidence basis for Pitfall 2
- CocoaPods and Xcode linking behavior -- HIGH confidence basis for Pitfall 3
- pub.dev scoring (pub.dev/help/scoring) -- HIGH confidence basis for Pitfall 6
- General experience with Unity-in-Flutter embedding patterns -- MEDIUM confidence basis for Pitfalls 8, 14
- VLibras-specific details (SDK version behavior, network endpoints, exact CSP requirements) -- LOW confidence, could not verify against actual SDK repositories
