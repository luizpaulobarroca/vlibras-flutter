# Project Research Summary

**Project:** vlibras_flutter
**Domain:** Flutter plugin multiplataforma para traducao texto-para-LIBRAS via VLibras SDK
**Researched:** 2026-03-22
**Confidence:** MEDIUM

## Executive Summary

The vlibras_flutter project is a cross-platform Flutter plugin that wraps the existing VLibras SDK (Android, iOS, and Web) to translate Portuguese text into Brazilian Sign Language (LIBRAS) via an animated 3D avatar. The expert approach for this class of product follows the Controller+Widget pattern established by official Flutter plugins like `video_player` and `webview_flutter`: a `VLibrasController` (ChangeNotifier/ValueNotifier) manages state and commands, while a `VLibrasView` widget embeds the native rendering surface per platform using PlatformViews (AndroidView, UiKitView, HtmlElementView). The plugin should be a single-package (non-federated) structure with an internal platform interface abstraction, using Dart `dart:js_interop` + `package:web` for the web layer and MethodChannel/EventChannel for mobile platforms.

The recommended approach is to build Web-first, then Android, then iOS. The VLibras web player is the most mature and publicly accessible of the three SDKs, and JavaScript interop provides the fastest iteration cycle. Starting with Web allows validating the entire Dart API (controller, state machine, lifecycle) before tackling the complexity of native platform views and their associated dependency management (Gradle AAR for Android, CocoaPods for iOS). Once the Dart-side API is solid, adding mobile platforms is primarily a matter of implementing the platform channel layer -- the architecture does not change.

The single most significant risk is the unknown state of the VLibras native SDKs. Their distribution format (Maven coordinates, CocoaPods spec, CDN URL), exact API surface, minimum platform version requirements, and licensing for third-party redistribution via pub.dev could not be verified during research. This gap must be resolved at the very start of implementation -- before writing any platform-specific code. The secondary risk cluster is PlatformView performance with 3D/WebGL content (black frame flicker on Android, z-ordering on Web, Unity memory pressure on mobile), which requires per-platform validation and cannot be fully addressed at the design stage.

## Key Findings

### Recommended Stack

The plugin targets Flutter >= 3.22.0 / Dart >= 3.5.0 with Kotlin (Android) and Swift (iOS) as native languages. The key architectural decision is to use a single-package plugin (not federated), since one author maintains all three platforms and desktop is out of scope. For platform communication, the research produced a split recommendation: STACK.md recommends Pigeon for type-safe code generation; ARCHITECTURE.md argues plain MethodChannel/EventChannel is sufficient given the narrow API surface (init, translate, dispose, events). **Recommendation: start with plain MethodChannel/EventChannel for simplicity; adopt Pigeon only if the API surface grows beyond 5-6 methods.** This avoids build_runner overhead while keeping the door open.

**Core technologies:**
- **Flutter 3.22+ / Dart 3.5+**: Stable SDK with mature plugin support, `dart:js_interop` (replaces deprecated `dart:js`), and current PlatformView APIs
- **`dart:js_interop` + `package:web`**: Official replacements for deprecated `dart:html` and `dart:js` -- required for web implementation
- **HtmlElementView (Web)**: Embeds the VLibras web player DOM element directly in the Flutter widget tree -- no webview_flutter needed on web
- **MethodChannel + EventChannel (Mobile)**: Commands flow Dart-to-native via MethodChannel; state/events stream native-to-Dart via EventChannel
- **plugin_platform_interface**: Official base class for platform abstraction, enabling testability and future federation

### Expected Features

**Must have (table stakes -- 11 features):**
- VLibrasController (ChangeNotifier-based, manages lifecycle and state)
- VLibrasView widget (renders platform-specific native view)
- `translate(String text)` method (core functionality)
- State management via ValueNotifier (uninitialized, loading, ready, translating, error)
- Lifecycle management (explicit initialize/dispose)
- Error handling (errors exposed via state, never swallowed silently)
- Android, iOS, and Web platform support
- Example app and API documentation (pub.dev requirements)

**Should have (differentiators -- prioritized for v1.x):**
- Translation queue (enqueue multiple texts in sequence) -- strongest differentiator, no existing VLibras wrapper offers this
- VLibrasBuilder convenience widget (typed ValueListenableBuilder)
- Accessibility Semantics on the VLibras widget (an accessibility plugin must itself be accessible)
- `VLibras.isSupported` platform capability query

**Defer to v2+:**
- Granular progress callbacks (depends on SDK API -- may be infeasible without SDK fork)
- Avatar visual customization (depends on SDK support)
- Translation speed control (depends on SDK support)
- Compact/mini-player mode
- Preloading/warm-up (optimization -- premature before v1 is stable)

### Architecture Approach

The architecture follows a three-layer design: a public Dart API layer (Controller + View), an abstract platform interface layer (VLibrasPlatform with singleton instance pattern), and platform-specific implementation layers (Android/iOS via MethodChannel + PlatformView factories, Web via JS interop + HtmlElementView). Each VLibrasController manages its own view instance via a unique viewId, allowing multiple concurrent VLibras views. State flows upward from native SDKs through EventChannel to the controller's ValueNotifier, which widgets observe reactively.

**Major components:**
1. **VLibrasController** -- Public API. Extends ValueNotifier, holds VLibrasValue (immutable state object), sends commands through VLibrasPlatform
2. **VLibrasView** -- StatefulWidget. Renders AndroidView/UiKitView/HtmlElementView based on platform, shows loading/error states
3. **VLibrasPlatform** -- Abstract interface with singleton instance. Decouples controller from platform specifics, enables mock testing
4. **Platform implementations** -- VLibrasAndroid (Kotlin + MethodChannel), VLibrasIos (Swift + MethodChannel), VLibrasWeb (dart:js_interop, no channel needed)
5. **Native plugin classes** -- VLibrasFlutterPlugin.kt and .swift: register channels, manage PlatformViewFactories, bridge to VLibras SDKs

### Critical Pitfalls

1. **Controller vs. Native View lifecycle mismatch** -- Controller may send commands before the native view exists or after it is destroyed. Prevention: implement a "ready" protocol via EventChannel; guard all calls behind ready state; tie controller disposal to widget lifecycle. Address in Phase 1.

2. **Android Gradle/AAR dependency conflicts** -- VLibras Android SDK's transitive dependencies (likely Unity-based) will conflict with host app dependencies. Prevention: use `implementation` (not `api`) scope, test in multi-plugin apps early, document minSdkVersion requirements. Address in Phase 2.

3. **iOS CocoaPods architecture/linking issues** -- Pre-compiled VLibras iOS SDK may lack simulator slices, causing development-blocking build failures. Prevention: test device + simulator immediately, document any simulator limitations, validate podspec early. Address in Phase 3.

4. **PlatformView performance with 3D content** -- Android Virtual Display mode causes black flicker with GPU-heavy content; Web HtmlElementView has z-ordering limitations. Prevention: use Hybrid Composition on Android, design UI to avoid overlaying Flutter widgets on the player on Web. Address per-platform during integration.

5. **Web CSP/CORS blocking VLibras player** -- The web player loads external JS and assets; Content Security Policy may block in production while working in debug. Prevention: bundle JS locally when possible, document required CSP headers, test deployed builds early. Address in Phase 2.

## Implications for Roadmap

Based on combined research, the following phase structure is recommended. The ordering is driven by three principles: (a) validate the Dart API before adding platform complexity, (b) tackle the highest-risk unknowns (SDK investigation) first, (c) defer optimization and differentiators until core is stable.

### Phase 1: Foundation and SDK Investigation
**Rationale:** Everything depends on the Controller+Platform Interface architecture being correct, and on understanding the actual VLibras SDK APIs. Getting either wrong means rewriting later.
**Delivers:** VLibrasValue/VLibrasState data classes, VLibrasPlatform abstract interface, VLibrasController with full state machine, VLibrasView skeleton (placeholder), unit tests with mock platform, and -- critically -- documented findings from inspecting the three VLibras SDKs.
**Addresses:** TS-01 (Controller), TS-07 (State), TS-08 (Lifecycle), TS-09 (Error handling), project scaffolding (pubspec.yaml, analysis_options.yaml, example/ skeleton, LICENSE, CHANGELOG)
**Avoids:** Pitfall 1 (lifecycle mismatch -- design ready protocol upfront), Pitfall 6 (bad pubspec -- set up correctly from day 1), Pitfall 7 (MethodChannel bottleneck -- design EventChannel from the start), Pitfall 9 (federation paralysis -- decide single-package and move on), Pitfall 10 (deferred tests -- test scaffolding from day 1)

### Phase 2: Web Platform Implementation
**Rationale:** Web-first because the VLibras web player is publicly accessible, JS interop is simpler than native platform channels, and the iteration cycle (hot reload in browser) is fastest. This phase validates the entire Dart API end-to-end before adding native complexity.
**Delivers:** Working VLibrasView on Flutter Web, HtmlElementView integration with VLibras web player, JS interop bridge, full translate flow (text in, avatar animates, state updates), integration tests in Chrome.
**Addresses:** TS-02 (VLibrasView), TS-03 (translate), TS-06 (Web support)
**Avoids:** Pitfall 5 (CSP/CORS -- bundle JS locally, test deployed builds), Pitfall 14 (web build size -- lazy-load player assets)

### Phase 3: Android Platform Implementation
**Rationale:** Android follows Web because it is the dominant mobile platform in Brazil (~85% market share) and has more accessible tooling/debugging than iOS. The Dart API is already validated from Phase 2.
**Delivers:** Working VLibrasView on Android, Kotlin plugin class, PlatformViewFactory, AAR/Gradle integration with VLibras Android SDK, integration tests on emulator/device.
**Addresses:** TS-04 (Android support)
**Avoids:** Pitfall 2 (Gradle dependency hell -- test in multi-plugin app), Pitfall 4 (PlatformView performance -- use Hybrid Composition), Pitfall 8 (Unity memory -- implement pause/resume), Pitfall 12 (ProGuard stripping -- include proguard-rules.pro, test release builds)

### Phase 4: iOS Platform Implementation
**Rationale:** iOS is last because CocoaPods/Xcode has the highest integration friction and the pattern is already proven on Android. Same architecture, different native language.
**Delivers:** Working VLibrasView on iOS, Swift plugin class, FlutterPlatformViewFactory, CocoaPods integration with VLibras iOS SDK, integration tests on simulator/device.
**Addresses:** TS-05 (iOS support)
**Avoids:** Pitfall 3 (architecture/linking -- test simulator + device immediately), Pitfall 13 (ATS blocking -- identify network endpoints)

### Phase 5: Publication Readiness
**Rationale:** pub.dev has concrete, measurable requirements (example app, dartdoc coverage, pana score, changelog). Bundling these into a dedicated phase ensures they are not forgotten under pressure to ship.
**Delivers:** Complete example/ app demonstrating all platforms, full dartdoc coverage on public API, README with quickstart and platform requirements, CHANGELOG, pana score validation, `flutter pub publish --dry-run` passing cleanly.
**Addresses:** TS-10 (Example app), TS-11 (Documentation)
**Avoids:** Pitfall 6 (pub.dev score killed by gaps)

### Phase 6: Differentiators and Polish
**Rationale:** These features add significant value but do not block adoption. They should come after the core is stable and published.
**Delivers:** Translation queue (DF-01), VLibrasBuilder widget (DF-05), Accessibility Semantics (DF-06), platform capability query (DF-10), cross-platform polish.
**Addresses:** DF-01, DF-05, DF-06, DF-10
**Avoids:** Pitfall 15 (accessibility tree conflicts -- test with TalkBack/VoiceOver)

### Phase Ordering Rationale

- **SDK investigation is front-loaded** because it is the single biggest risk and every other decision depends on it. If the SDKs are not distributable or have API limitations, the entire roadmap shifts.
- **Web before mobile** because it validates the Dart API with the least friction. Refactoring the controller/state/lifecycle at the Dart level is cheap; refactoring after three native implementations exist is expensive.
- **Android before iOS** because Brazil is Android-dominant and the tooling is more accessible. The pattern established on Android translates directly to iOS.
- **Publication as a separate phase** because pub.dev compliance (example, docs, score) is a distinct workstream that gets deprioritized if mixed with feature work.
- **Differentiators last** because they depend on the core being correct and stable, and several (DF-02, DF-03, DF-04) depend on SDK capabilities that may not exist.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 1:** Needs investigation of VLibras SDK repositories (API surface, distribution format, licensing, minimum platform versions). This is the most critical research gap.
- **Phase 2:** Needs validation of VLibras web player embedding approach (exact JS API, script loading, CSS/DOM requirements, CDN URL).
- **Phase 3:** Needs investigation of VLibras Android SDK packaging (AAR vs Maven, Unity dependency tree, minSdkVersion).
- **Phase 4:** Needs investigation of VLibras iOS SDK packaging (CocoaPods vs XCFramework, architecture slices, deployment target).

Phases with standard patterns (skip research-phase):
- **Phase 5:** pub.dev publication requirements are well-documented and stable. Standard checklist execution.
- **Phase 6:** All differentiator features use standard Dart/Flutter patterns (queues, builder widgets, Semantics). Implementation is straightforward once the core exists.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Flutter plugin tooling (Pigeon, plugin_platform_interface, dart:js_interop) is well-documented. Exact VLibras SDK versions and distribution format are LOW confidence. |
| Features | MEDIUM | Table stakes and anti-features are HIGH confidence (based on established Flutter plugin patterns). Differentiators that depend on SDK capabilities are LOW confidence. |
| Architecture | HIGH | Controller+Widget, platform interface singleton, MethodChannel+EventChannel, PlatformView embedding are all canonical Flutter patterns with extensive documentation. |
| Pitfalls | HIGH | Core pitfalls (lifecycle mismatch, Gradle conflicts, iOS linking, PlatformView performance) are the most-reported issues in Flutter plugin development. VLibras-specific pitfalls (SDK versioning, CSP details) are MEDIUM. |

**Overall confidence:** MEDIUM -- The Flutter plugin architecture patterns are solid (HIGH), but the VLibras SDK specifics represent a significant knowledge gap that could invalidate assumptions about distribution, API surface, and platform requirements.

### Gaps to Address

- **VLibras SDK distribution and API:** The format (AAR/Maven, CocoaPods/XCFramework, CDN JS) and public API of all three VLibras SDKs must be determined by cloning and inspecting the repositories at github.com/spbgovbr-vlibras/. This is blocking for Phases 2-4.
- **VLibras licensing:** Whether the SDKs can be redistributed as dependencies of a third-party pub.dev package needs legal clarification. Government open-source licenses vary.
- **HtmlElementView + Unity WebGL compatibility:** The VLibras web player uses Unity WebGL for 3D rendering. Whether this works reliably inside HtmlElementView (vs. a standalone page) needs practical testing.
- **AndroidView Hybrid Composition with VLibras:** Whether the VLibras Android SDK's native View (likely Unity-based) renders correctly in Hybrid Composition mode needs device testing.
- **Pigeon vs. plain MethodChannel:** STACK.md recommends Pigeon; ARCHITECTURE.md recommends plain channels. Resolve based on actual API surface discovered during SDK investigation -- if > 5 methods, use Pigeon.
- **Cold start time:** The 3D avatar initialization time on each platform is unknown and affects UX decisions (loading states, preloading strategy).

## Sources

### Primary (HIGH confidence)
- Flutter official docs: Developing Packages and Plugins -- https://docs.flutter.dev/packages-and-plugins/developing-packages
- Flutter official docs: Platform Channels -- https://docs.flutter.dev/platform-integration/platform-channels
- Flutter PlatformViews documentation -- https://docs.flutter.dev/platform-integration/android/platform-views
- pub.dev scoring criteria -- https://pub.dev/help/scoring
- plugin_platform_interface pattern -- referenced in official Flutter docs

### Secondary (MEDIUM confidence)
- Flutter video_player and webview_flutter plugin architecture -- training data knowledge of canonical patterns
- VLibras project context from PROJECT.md -- confirmed scope and platform targets
- pub.dev conventions and pana analysis tool -- stable and well-documented
- Android Gradle Plugin and CocoaPods linking behavior -- general Flutter plugin development knowledge

### Tertiary (LOW confidence)
- VLibras SDK repositories (github.com/spbgovbr-vlibras/) -- referenced but not accessed during research
- VLibras web player public URL and JS API (vlibras.gov.br) -- needs validation
- VLibras SDK internal architecture (Unity runtime assumption) -- inferred, not confirmed
- Exact package versions (Pigeon ^22.0.0, web ^1.0.0, etc.) -- need pub.dev verification at implementation time

---
*Research completed: 2026-03-22*
*Ready for roadmap: yes*
