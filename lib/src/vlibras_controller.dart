import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'vlibras_value.dart';
import 'vlibras_platform.dart';
import 'platform/unsupported_platform.dart'
    if (dart.library.js_interop) 'platform/web_platform.dart'
    if (dart.library.io) 'platform/mobile_platform.dart';

/// Controller for VLibras translation lifecycle.
///
/// Extends [ChangeNotifier] and implements [ValueListenable<VLibrasValue>]
/// so it works with both [ValueListenableBuilder] and [ListenableBuilder].
///
/// Usage:
/// ```dart
/// final controller = VLibrasController();
/// await controller.initialize();
/// await controller.translate('Olá mundo');
/// controller.dispose();
/// ```
///
/// On Flutter Web, calling [VLibrasController()] (no platform argument)
/// automatically selects `VLibrasWebPlatform` via conditional import.
/// On non-web platforms, the default constructor throws [UnsupportedError].
///
/// The `playing` state is a reachable enum value. In Phase 2, the controller
/// does not transition to [VLibrasStatus.playing] autonomously — Phase 3 will
/// push that transition via platform callbacks once the web player is wired up.
class VLibrasController extends ChangeNotifier
    implements ValueListenable<VLibrasValue> {
  /// Creates a [VLibrasController].
  ///
  /// Pass a [platform] to inject a custom implementation (useful for testing).
  /// If omitted on Flutter Web, `VLibrasWebPlatform` is used automatically.
  /// If omitted on non-web platforms, [UnsupportedError] is thrown.
  VLibrasController({VLibrasPlatform? platform}) {
    _platform = platform ?? createDefaultPlatform(_onPlatformStatus);
  }

  late final VLibrasPlatform _platform;
  VLibrasValue _value = const VLibrasValue();

  /// The current state of the VLibras translation lifecycle.
  @override
  VLibrasValue get value => _value;

  /// Updates [_value] and notifies listeners only when the value changes.
  void _setValue(VLibrasValue newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  /// Forwards platform status callbacks to the controller's value.
  void _onPlatformStatus(VLibrasStatus status) {
    _setValue(_value.copyWith(status: status));
  }

  /// Initializes the underlying VLibras platform.
  ///
  /// Transitions: idle -> initializing -> ready (success)
  ///                                   -> error (failure)
  ///
  /// Idempotent: if the controller is not in [VLibrasStatus.idle], this is a
  /// no-op. Errors from the platform are caught and stored in
  /// [VLibrasValue.error] — they never propagate to the caller (ERR-01).
  Future<void> initialize() async {
    if (_value.status != VLibrasStatus.idle) return;
    _setValue(_value.copyWith(status: VLibrasStatus.initializing));
    try {
      await _platform.initialize();
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

  /// Requests translation of [text] into LIBRAS.
  ///
  /// Transitions: any state -> translating (clears error on entry)
  ///                        -> error (on platform failure)
  ///
  /// This cancels any ongoing translation and restarts from translating,
  /// making it safe to call from any state including [VLibrasStatus.playing]
  /// or [VLibrasStatus.error]. Errors from the platform are caught and stored
  /// in [VLibrasValue.error] — they never propagate to the caller (ERR-01).
  Future<void> translate(String text) async {
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

  /// Called by [VLibrasView] to attach the DOM element to the platform.
  ///
  /// Only called on Flutter Web. The [element] is the HTMLDivElement created
  /// by HtmlElementView.fromTagName. Delegating to the platform allows
  /// VLibrasWebPlatform to call player.load(element).
  ///
  /// Using `as dynamic` avoids importing web-only types in this file.
  /// The cast is safe — this method is only called from VLibrasView on web
  /// where VLibrasWebPlatform is the concrete type.
  void attachElement(Object element) {
    // ignore: avoid_dynamic_calls
    (_platform as dynamic).attachToElement(element);
  }

  /// Called by [VLibrasView] on non-web platforms to get the native view widget.
  ///
  /// Uses dynamic dispatch to avoid importing mobile-only types here.
  Widget buildMobileView() {
    // ignore: avoid_dynamic_calls
    return (_platform as dynamic).buildView() as Widget;
  }

  // Phase 3 will add pause(), stop(), resume(), repeat(), setSpeed() by
  // delegating to _platform and managing state transitions accordingly.

  @override
  void dispose() {
    _platform.dispose(); // platform resources first
    super.dispose(); // ChangeNotifier listeners second
  }
}
