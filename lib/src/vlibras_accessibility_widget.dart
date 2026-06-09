import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'vlibras_controller.dart';
import 'vlibras_settings_labels.dart';
import 'vlibras_settings_panel.dart';
import 'vlibras_view.dart';
import 'vlibras_value.dart';

// ── Gov.br official color palette ────────────────────────────────────────────
const Color _kAvatarBg = Color(0xFFDCE8F5);
const Color _kSidebarBg = Colors.transparent;
const Color _kIconInactive = Color(0xFFB0BEC5);

// ── Default gradient for the collapsed floating button ───────────────────────
const Gradient _kButtonIconGradient = LinearGradient(
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
  colors: [Color(0xFF3690FA), Color(0xFF2266D2)],
);
const double _kDockSideMargin = 0.0;
const double _kDockVerticalMargin = 8.0;

enum _VLibrasDockSide { left, right }

// ── VLibras sign-language figure SVG (path only, no background) ──────────────
const String _kVLibrasIconSvg = '''
<svg width="40" height="40" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M14.3515 8.00885C14.2659 8.02229 14.0952 8.12725 13.9722 8.24213C13.7501 8.44966 13.7489 8.4543 13.7954 8.95863C13.8212 9.23785 13.873 9.84616 13.9104 10.3105C14.2022 13.9301 14.2501 15.014 14.1218 15.0933C13.906 15.2267 13.787 15.0254 11.7744 11.1229C11.0845 9.7851 10.953 9.64412 10.5264 9.78488C9.84976 10.0082 9.90301 10.3457 10.984 12.685C11.1227 12.9851 11.2361 13.2431 11.2361 13.2584C11.2361 13.2738 11.3578 13.5507 11.5068 13.8737C12.3139 15.6253 12.5242 16.3377 12.2637 16.4377C12.0791 16.5085 11.7503 16.3324 11.48 16.0181C11.3425 15.8582 11.1733 15.664 11.1041 15.5866C11.0348 15.5093 10.8383 15.2718 10.6674 15.059C10.4965 14.8462 10.3404 14.6563 10.3205 14.6369C10.3006 14.6176 9.97505 14.2328 9.59714 13.7818C9.21915 13.3308 8.86093 12.943 8.80099 12.92C8.45635 12.7878 8 13.0487 8 13.3779C8 13.6653 8.6909 14.8215 10.129 16.9405C11.0303 18.2684 11.2421 18.7465 11.4461 19.9131C11.8781 22.3846 12.466 23.8997 13.2266 24.5023C13.7444 24.9126 13.759 24.9156 14.9781 24.8635L16.0946 24.8158L16.943 23.6835C17.4096 23.0607 17.828 22.5037 17.8729 22.4456C18.1983 22.0239 19.0448 20.5299 19.0448 20.3774C19.0448 20.3556 18.6049 20.3579 18.0673 20.3823C17.4053 20.4125 16.9455 20.3987 16.6427 20.3399C16.1178 20.2377 15.4567 19.9369 15.094 19.6351C14.5216 19.1588 14.3534 18.3134 14.7102 17.7047C14.9767 17.2499 15.3462 17.0548 16.1229 16.9585C16.7506 16.8808 17.4221 16.6978 18.3941 16.3399L18.9041 16.1521V15.3306C18.9041 14.489 19.0647 11.5539 19.1866 10.1698C19.2823 9.08146 19.2839 9.09328 19.0167 8.8261C18.8321 8.64157 18.7189 8.58691 18.5211 8.58691C18.0228 8.58691 17.9956 8.65571 17.5021 11.1555C17.2578 12.3932 17.0138 13.6591 16.9598 13.9686C16.842 14.6442 16.7495 14.8932 16.5939 14.9529C16.3906 15.031 16.2003 14.7126 16.1089 14.1418C16.0627 13.8531 15.9423 13.0945 15.8413 12.4561C15.6543 11.2736 15.2804 9.05832 15.2005 8.6586C15.1525 8.41877 14.8376 8.05999 14.6342 8.01349C14.5644 7.99752 14.4372 7.99541 14.3515 8.00885ZM23.723 15.2495C23.41 15.3238 22.5004 15.6532 22.0856 15.8425C21.8429 15.9533 21.6258 16.0439 21.6033 16.0439C21.5808 16.0439 20.988 16.3278 20.286 16.6749C18.8037 17.4076 17.0871 18.0136 16.4932 18.0138C16.0849 18.0139 15.6455 18.1946 15.6116 18.3762C15.5739 18.5794 16.0014 18.9814 16.4285 19.1441C16.8072 19.2883 16.9061 19.2943 18.2628 19.2542C19.4753 19.2186 19.7325 19.2289 19.9271 19.3213C20.2619 19.4801 20.3539 19.7508 20.243 20.2514C20.13 20.7618 19.5007 22.024 18.9935 22.7575C18.6639 23.2342 16.7021 25.845 15.5625 27.3235C15.1558 27.8512 15.1376 28.12 15.4851 28.4676C15.9352 28.9176 15.8771 28.9577 18.2957 26.5266C20.5532 24.2577 20.7416 24.1089 20.8437 24.5159C20.9058 24.7631 20.92 24.727 19.9164 26.8681C19.7465 27.2303 19.6076 27.5367 19.6076 27.5488C19.6076 27.561 19.493 27.8185 19.353 28.1212C18.2031 30.607 18.1562 30.774 18.489 31.197C18.608 31.3484 18.6899 31.3796 18.962 31.3778C19.1429 31.3766 19.3398 31.337 19.3994 31.2898C19.459 31.2427 19.8045 30.666 20.1673 30.0082C20.8028 28.8558 21.1759 28.1882 21.492 27.6375C22.6596 25.6031 22.6539 25.6114 22.8653 25.6114C23.0004 25.6114 23.0041 25.6442 22.9623 26.4732C22.9242 27.2301 22.8281 28.1321 22.5632 30.2193C22.4631 31.0073 22.4759 31.6696 22.5942 31.8257C22.7334 32.0094 23.2169 32.0613 23.4383 31.9163C23.6656 31.7673 23.7716 31.3909 24.035 29.7972C24.593 26.419 24.7329 25.7764 24.9539 25.5765C25.0901 25.4532 25.0998 25.4533 25.2421 25.5821C25.323 25.6554 25.4182 25.7695 25.4536 25.8357C25.4891 25.9018 25.5956 26.6936 25.6905 27.5952C25.9573 30.1327 25.9803 30.2641 26.1891 30.4479C26.4199 30.6511 26.6555 30.6487 26.897 30.4411C27.0809 30.2829 27.0915 30.2366 27.1524 29.3331C27.1873 28.8145 27.2018 27.7887 27.1845 27.0535C27.1509 25.6219 27.2168 24.4232 27.3521 24.0053C27.3981 23.8633 27.6176 23.3198 27.84 22.7974C28.0624 22.2751 28.3782 21.4362 28.5417 20.9332C29.0456 19.3828 29.0076 18.138 28.4388 17.5662C28.318 17.4448 27.9543 17.2033 27.6306 17.0296C27.2171 16.8078 26.828 16.5127 26.3226 16.0375C25.7453 15.4948 25.5399 15.3452 25.2827 15.2804C24.9702 15.2018 24.0047 15.1826 23.723 15.2495ZM29.2115 17.3062C29.1841 17.3926 29.2353 17.6285 29.3384 17.8907C29.5664 18.4703 29.6183 18.9806 29.5192 19.6669C29.3915 20.5513 29.3968 20.6483 29.5752 20.6737C29.8161 20.708 29.9389 20.4344 30.0285 19.663C30.1261 18.8228 30.0404 18.1825 29.7513 17.5916C29.5434 17.1667 29.2971 17.0365 29.2115 17.3062ZM30.4891 17.549C30.4684 17.6029 30.5153 17.8483 30.5933 18.0942C30.7771 18.6736 30.7418 19.5889 30.5087 20.2863C30.3628 20.7228 30.3585 20.7749 30.4599 20.8763C30.7 21.1165 30.946 20.7848 31.1134 19.995C31.2908 19.1582 31.216 18.1188 30.9415 17.6059C30.8481 17.4314 30.5487 17.3937 30.4891 17.549ZM11.0411 23.5833C10.8962 23.7282 10.9436 23.9348 11.2481 24.4858C11.7649 25.421 13.0134 26.4918 13.3049 26.25C13.5114 26.0786 13.4297 25.9206 12.9961 25.653C12.4543 25.3186 11.9773 24.7755 11.6197 24.0858C11.3346 23.536 11.2029 23.4216 11.0411 23.5833ZM10.041 24.0274C9.92968 24.1616 10.0187 24.4934 10.3433 25.1541C10.7889 26.0611 11.7528 26.9914 12.1062 26.8557C12.2933 26.784 12.2451 26.5002 12.0237 26.3694C11.4365 26.0225 10.866 25.2432 10.5674 24.3803C10.4121 23.9312 10.225 23.8057 10.041 24.0274Z" fill="#FDFDFD"/>
</svg>
''';

// ── Sidebar avatar circle (shows initial letter) ──────────────────────────────
class _AvatarCircleButton extends StatelessWidget {
  const _AvatarCircleButton({
    required this.initial,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
  });

  final String initial;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : _kIconInactive,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ── "Acessar link" confirmation tooltip (gov.br style) ───────────────────────
class _LinkTooltip extends StatelessWidget {
  const _LinkTooltip({required this.position, required this.color});

  final Offset position;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const double w = 130;
    final sw = MediaQuery.sizeOf(context).width;
    final left = (position.dx - w / 2).clamp(8.0, sw - w - 8.0);
    return Positioned(
      left: left,
      top: position.dy + 14,
      child: IgnorePointer(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: w,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Acessar link',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

/// A self-contained accessibility widget that adds a floating VLibras
/// translation button to any Flutter app.
///
/// Wrap your [MaterialApp] (or any widget) with this to get a floating button
/// pinned to the right side of the screen. Tapping the button expands a panel
/// showing the VLibras 3D avatar. While the panel is open, tapping any [Text]
/// widget inside [child] automatically translates that text into LIBRAS.
///
/// The widget owns the full [VLibrasController] lifecycle — you do not need
/// to create, initialize, or dispose the controller yourself.
///
/// **Usage — via `MaterialApp.builder`** (required):
/// ```dart
/// MaterialApp(
///   builder: (context, child) =>
///       VLibrasAccessibilityWidget(child: child!),
///   home: MyHomePage(),
/// )
/// ```
///
/// The widget must live **inside** `MaterialApp` so that `Directionality`,
/// `MediaQuery`, `Theme` and `Navigator` are available as ancestors.
/// Placing it above `MaterialApp` causes "No Directionality widget found"
/// and similar errors.
class VLibrasAccessibilityWidget extends StatefulWidget {
  const VLibrasAccessibilityWidget({
    super.key,
    required this.child,
    this.visible = true,
    this.primaryColor = const Color(0xFF003F86),
    this.avatarWidth = 280.0,
    this.avatarHeight = 320.0,
    this.buttonSize = 56.0,
    this.showSettingsButton = true,
    this.settingsLabels = const VLibrasSettingsLabels(),
    this.translateUrl,
    this.buttonIconGradient,
  });

  /// Whether the VLibras floating button and panel are shown.
  ///
  /// Set to `false` to hide the widget during splash screens or loading states.
  /// When toggled back to `true` the collapsed button reappears.
  /// Defaults to `true`.
  final bool visible;

  /// Primary colour used for the floating button, header, footer, and
  /// interactive accents. Defaults to the official gov.br blue (`#003F86`).
  final Color primaryColor;

  /// The app content to wrap. Text taps on this subtree trigger translation.
  final Widget child;

  /// Width of the expanded avatar window. Defaults to 280.
  final double avatarWidth;

  /// Height of the expanded avatar window. Defaults to 320.
  final double avatarHeight;

  /// Size of the collapsed floating button. Defaults to 56.
  final double buttonSize;

  /// When `true` (default), a secondary ⚙️ button is rendered alongside the
  /// close button while the avatar panel is open. Tapping it reveals a
  /// [VLibrasSettingsPanel] overlay inline with the avatar.
  final bool showSettingsButton;

  /// Labels passed to the internal [VLibrasSettingsPanel]. Override for i18n.
  final VLibrasSettingsLabels settingsLabels;

  /// Custom translation API endpoint. When null the default VLibras endpoint
  /// (`https://traducao2.vlibras.gov.br/dl/translate`) is used.
  final String? translateUrl;

  /// Gradient applied to the background of the collapsed floating button.
  ///
  /// When null, defaults to the standard VLibras blue gradient
  /// (`#3690FA` → `#2266D2`). Pass any [LinearGradient] or [RadialGradient]
  /// to override the button background colour.
  ///
  /// Example:
  /// ```dart
  /// buttonIconGradient: LinearGradient(
  ///   colors: [Colors.green, Colors.teal],
  /// )
  /// ```
  final Gradient? buttonIconGradient;

  @override
  State<VLibrasAccessibilityWidget> createState() =>
      _VLibrasAccessibilityWidgetState();
}

class _VLibrasAccessibilityWidgetState
    extends State<VLibrasAccessibilityWidget> {
  late final VLibrasController _controller;
  bool _isExpanded = false;
  bool _isSettingsOpen = false;
  bool _isAvatarPickerOpen = false;
  _VLibrasDockSide _dockSide = _VLibrasDockSide.right;
  double? _dockCenterY;
  Offset? _dragTopLeft;

  // ── Double-tap confirmation state ─────────────────────────────────────────
  Offset? _pendingTapGlobal;
  bool _passingThrough = false;

  // Key on widget.child so hit tests bypass the opaque interceptor sibling.
  final _childKey = GlobalKey();

  // ── Avatar display names ──────────────────────────────────────────────────
  static const _kAvatarLabels = {
    VLibrasAvatar.icaro: 'Ícaro',
    VLibrasAvatar.hosana: 'Hosana',
    VLibrasAvatar.guga: 'Guga',
  };

  @override
  void initState() {
    super.initState();
    _controller = VLibrasController(translateUrl: widget.translateUrl);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _controller.initialize(),
    );
  }

  @override
  void didUpdateWidget(VLibrasAccessibilityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Collapse and clean up when the widget is hidden.
    if (!widget.visible && oldWidget.visible) {
      _dismissLinkTooltip();
      setState(() {
        _isExpanded = false;
        _isSettingsOpen = false;
        _isAvatarPickerOpen = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Tooltip helpers ───────────────────────────────────────────────────────
  // Rendered inside our own Stack — no Overlay needed (widget lives above the
  // Navigator when placed in MaterialApp.builder, so Overlay.of() would fail).
  void _showLinkTooltip(Offset globalPosition) {
    setState(() => _pendingTapGlobal = globalPosition);
  }

  void _dismissLinkTooltip() {
    setState(() => _pendingTapGlobal = null);
  }

  // Temporarily disables interception so a synthetic tap reaches child widgets.
  void _passThroughTap(Offset globalPosition) {
    setState(() => _passingThrough = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      GestureBinding.instance.handlePointerEvent(
        PointerDownEvent(position: globalPosition, pointer: 99),
      );
      GestureBinding.instance.handlePointerEvent(
        PointerUpEvent(position: globalPosition, pointer: 99),
      );
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _passingThrough = false);
      });
    });
  }

  // ── Tap handler: first tap translates + shows tooltip; second tap passes ──
  void _onContentTap(TapUpDetails details) {
    if (_passingThrough) return;
    if (!_isExpanded) return;

    // Use the Stack's render object only to compute the panel bounds.
    final stackRo = context.findRenderObject();
    if (stackRo is! RenderBox) return;

    // Ignore taps that land inside the VLibras panel itself.
    final size = stackRo.size;
    final padding = MediaQuery.of(context).padding;
    final panelSize = _panelSize(size, padding);
    final panelRect = _rectFor(size, padding, panelSize);
    if (panelRect.contains(details.localPosition)) return;

    // Second tap near the same position → activate the element.
    if (_pendingTapGlobal != null) {
      final dist = (details.globalPosition - _pendingTapGlobal!).distance;
      if (dist < 44) {
        _dismissLinkTooltip();
        _passThroughTap(details.globalPosition);
        return;
      }
    }

    // New tap → dismiss previous tooltip and handle fresh.
    _dismissLinkTooltip();

    // Hit-test widget.child directly (bypasses the opaque interceptor sibling).
    final childRo = _childKey.currentContext?.findRenderObject();
    if (childRo is RenderBox) {
      final result = BoxHitTestResult();
      childRo.hitTest(result, position: details.localPosition);

      // Translate any paragraph text under the tap.
      for (final entry in result.path) {
        final target = entry.target;
        if (target is RenderParagraph) {
          final text = target.text
              .toPlainText(includeSemanticsLabels: false)
              .trim();
          if (text.isEmpty) continue;
          _controller.translate(text);
          break;
        }
      }

      // Show "Acessar link" only when the hit path contains an interactive
      // element. Every widget with onTap (GestureDetector, InkWell, Button…)
      // inserts a RenderSemanticsAnnotations with onTap != null into the
      // render tree, regardless of whether semantics are enabled.
      if (_hasInteractiveTarget(result)) {
        _pendingTapGlobal = details.globalPosition;
        _showLinkTooltip(details.globalPosition);
      }
    }
  }

  // Returns true when the hit path contains a widget that handles taps
  // (GestureDetector, InkWell, ElevatedButton, ListTile, etc.).
  // Every such widget inserts a RenderSemanticsAnnotations with onTap != null
  // into the render tree, making this check reliable without enabling semantics.
  static bool _hasInteractiveTarget(BoxHitTestResult result) {
    for (final entry in result.path) {
      if (entry.target case final RenderSemanticsAnnotations sa) {
        if (sa.properties.onTap != null) return true;
      }
    }
    return false;
  }

  static double _clampDouble(double value, double min, double max) {
    if (max < min) return min;
    return value.clamp(min, max).toDouble();
  }

  Size _buttonExtent() {
    final size = widget.buttonSize + 12;
    return Size(size, size);
  }

  Size _panelSize(Size viewport, EdgeInsets padding) {
    final maxWidth =
        viewport.width - padding.left - padding.right - 2 * _kDockSideMargin;
    final maxHeight =
        viewport.height -
        padding.top -
        padding.bottom -
        2 * _kDockVerticalMargin;

    return Size(
      _clampDouble(widget.avatarWidth, 0, maxWidth),
      _clampDouble(widget.avatarHeight, 0, maxHeight),
    );
  }

  Offset _clampTopLeft(
    Offset topLeft,
    Size viewport,
    EdgeInsets padding,
    Size elementSize,
  ) {
    final minLeft = padding.left + _kDockSideMargin;
    final minTop = padding.top + _kDockVerticalMargin;
    final maxLeft =
        viewport.width - padding.right - _kDockSideMargin - elementSize.width;
    final maxTop =
        viewport.height -
        padding.bottom -
        _kDockVerticalMargin -
        elementSize.height;

    return Offset(
      _clampDouble(topLeft.dx, minLeft, maxLeft),
      _clampDouble(topLeft.dy, minTop, maxTop),
    );
  }

  Rect _rectFor(Size viewport, EdgeInsets padding, Size elementSize) {
    if (_dragTopLeft != null) {
      final topLeft = _clampTopLeft(
        _dragTopLeft!,
        viewport,
        padding,
        elementSize,
      );
      return topLeft & elementSize;
    }

    final minTop = padding.top + _kDockVerticalMargin;
    final maxTop =
        viewport.height -
        padding.bottom -
        _kDockVerticalMargin -
        elementSize.height;
    final centerY = _dockCenterY ?? viewport.height / 2;
    final top = _clampDouble(centerY - elementSize.height / 2, minTop, maxTop);
    final left = _dockSide == _VLibrasDockSide.left
        ? padding.left + _kDockSideMargin
        : viewport.width - padding.right - _kDockSideMargin - elementSize.width;

    return Rect.fromLTWH(left, top, elementSize.width, elementSize.height);
  }

  void _startDrag(Size viewport, EdgeInsets padding, Size elementSize) {
    setState(() {
      _dragTopLeft = _rectFor(viewport, padding, elementSize).topLeft;
    });
  }

  void _updateDrag(
    DragUpdateDetails details,
    Size viewport,
    EdgeInsets padding,
    Size elementSize,
  ) {
    final current =
        _dragTopLeft ?? _rectFor(viewport, padding, elementSize).topLeft;
    setState(() {
      _dragTopLeft = _clampTopLeft(
        current + details.delta,
        viewport,
        padding,
        elementSize,
      );
    });
  }

  void _endDrag(Size viewport, EdgeInsets padding, Size elementSize) {
    final dragTopLeft = _dragTopLeft;
    if (dragTopLeft == null) return;

    final rect =
        _clampTopLeft(dragTopLeft, viewport, padding, elementSize) &
        elementSize;

    setState(() {
      _dockSide = rect.center.dx < viewport.width / 2
          ? _VLibrasDockSide.left
          : _VLibrasDockSide.right;
      _dockCenterY = rect.center.dy;
      _dragTopLeft = null;
    });
  }

  BorderRadius _dockedBorderRadius() {
    if (_dragTopLeft != null) return BorderRadius.circular(8);

    return _dockSide == _VLibrasDockSide.left
        ? const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          );
  }

  // ── Collapsed floating button (center-right) ──────────────────────────────
  // ignore: unused_element
  Widget _buildFloatingButton() {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.centerRight,
        child: Semantics(
          label: 'Conteúdo acessível em Libras usando o VLibras',
          button: true,
          child: Material(
            color: Colors.transparent,
            elevation: 6,
            shadowColor: Colors.black38,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            child: InkWell(
              onTap: () => setState(() => _isExpanded = true),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              child: Container(
                width: widget.buttonSize + 12,
                decoration: BoxDecoration(
                  gradient: widget.buttonIconGradient ?? _kButtonIconGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.string(
                      _kVLibrasIconSvg,
                      width: 45,
                      height: 45,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Expanded panel ─────────────────────────────────────────────────────────
  // ignore: unused_element
  Widget _buildAvatarPanel(BuildContext context, VLibrasValue value) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topOffset = (screenHeight - widget.avatarHeight) / 2;
    final isLoading =
        value.status == VLibrasStatus.initializing ||
        value.status == VLibrasStatus.idle;

    return Positioned(
      right: 0,
      top: topOffset,
      width: widget.avatarWidth,
      height: widget.avatarHeight,
      child: Material(
        elevation: 8,
        // Opaque white background prevents app content from bleeding through
        // transparent areas — critical on Android Hybrid Composition WebViews.
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          bottomLeft: Radius.circular(8),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMiddleArea(value, isLoading)),
            _buildFooter(value),
          ],
        ),
      ),
    );
  }

  // ── Header bar ─────────────────────────────────────────────────────────────
  Widget _buildDraggableFloatingButton() {
    final mediaQuery = MediaQuery.of(context);
    final viewport = mediaQuery.size;
    final padding = mediaQuery.padding;
    final buttonExtent = _buttonExtent();
    final rect = _rectFor(viewport, padding, buttonExtent);
    final borderRadius = _dockedBorderRadius();

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        onTap: () => setState(() => _isExpanded = true),
        onPanStart: (_) => _startDrag(viewport, padding, buttonExtent),
        onPanUpdate: (details) =>
            _updateDrag(details, viewport, padding, buttonExtent),
        onPanEnd: (_) => _endDrag(viewport, padding, buttonExtent),
        child: Semantics(
          label: 'Conteudo acessivel em Libras usando o VLibras',
          button: true,
          child: Material(
            color: Colors.transparent,
            elevation: 6,
            shadowColor: Colors.black38,
            borderRadius: borderRadius,
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.buttonIconGradient ?? _kButtonIconGradient,
                borderRadius: borderRadius,
              ),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              alignment: Alignment.center,
              child: SvgPicture.string(
                _kVLibrasIconSvg,
                width: widget.buttonSize - 11,
                height: widget.buttonSize - 11,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableHeader(
    Size viewport,
    EdgeInsets padding,
    Size panelSize,
  ) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => _startDrag(viewport, padding, panelSize),
      onPanUpdate: (details) =>
          _updateDrag(details, viewport, padding, panelSize),
      onPanEnd: (_) => _endDrag(viewport, padding, panelSize),
      child: _buildHeader(),
    );
  }

  Widget _buildDraggableAvatarPanel(BuildContext context, VLibrasValue value) {
    final mediaQuery = MediaQuery.of(context);
    final viewport = mediaQuery.size;
    final padding = mediaQuery.padding;
    final panelSize = _panelSize(viewport, padding);
    final rect = _rectFor(viewport, padding, panelSize);
    final borderRadius = _dockedBorderRadius();
    final isLoading =
        value.status == VLibrasStatus.initializing ||
        value.status == VLibrasStatus.idle;

    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Material(
        elevation: 8,
        color: Colors.white,
        borderRadius: borderRadius,
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            _buildDraggableHeader(viewport, padding, panelSize),
            Expanded(child: _buildMiddleArea(value, isLoading)),
            _buildFooter(value),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 40,
      color: widget.primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (widget.showSettingsButton)
            Semantics(
              label: widget.settingsLabels.title,
              button: true,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: () => setState(() {
                  _isSettingsOpen = !_isSettingsOpen;
                  if (_isSettingsOpen) _isAvatarPickerOpen = false;
                }),
              ),
            )
          else
            const SizedBox(width: 32),
          const Expanded(
            child: Text(
              'VLIBRAS',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 2,
              ),
            ),
          ),
          Semantics(
            label: widget.settingsLabels.close,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () {
                _dismissLinkTooltip();
                setState(() {
                  _isExpanded = false;
                  _isSettingsOpen = false;
                  _isAvatarPickerOpen = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Middle area: avatar (full width) + sidebar overlay ───────────────────
  //
  // Z-order (back → front):
  //   1. WebView (full width — avatar centered)
  //   2. Sidebar (left overlay)
  //   3. Settings overlay (covers everything including sidebar)
  Widget _buildMiddleArea(VLibrasValue value, bool isLoading) {
    return Stack(
      children: [
        // ── 1. Avatar/WebView: full width ───────────────────────────────
        Positioned.fill(child: _buildAvatarArea(value, isLoading)),

        // ── 2. Sidebar: above the WebView ───────────────────────────────
        Positioned(left: 0, top: 0, bottom: 0, child: _buildSidebar(value)),

        // ── 3. Settings overlay: above everything, including sidebar ────
        if (_isSettingsOpen) Positioned.fill(child: _buildSettingsOverlay()),
      ],
    );
  }

  Widget _buildSettingsOverlay() {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.white,
          primaryContainer: widget.primaryColor.withValues(alpha: 0.8),
          surface: widget.primaryColor,
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Colors.white,
          thumbColor: Colors.white,
          inactiveTrackColor: Colors.white30,
          overlayColor: Colors.white24,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.all(Colors.white30),
        ),
        iconTheme: const IconThemeData(color: Colors.white70),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white, fontSize: 13),
          titleMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Material(
        color: widget.primaryColor,
        child: VLibrasSettingsPanel(
          controller: _controller,
          labels: widget.settingsLabels,
          onClose: () => setState(() => _isSettingsOpen = false),
        ),
      ),
    );
  }

  // ── Left sidebar ───────────────────────────────────────────────────────────
  //
  // The avatar row uses AnimatedSize around a Row with conditional children.
  // Only the circles that should be visible are in the tree — no overflow,
  // no clip hack, no debug stripes. AnimatedSize smoothly animates the Row
  // width as circles are added or removed.
  Widget _buildSidebar(VLibrasValue value) {
    final others = VLibrasAvatar.values
        .where((a) => a != value.avatar)
        .toList();

    return Container(
      color: _kSidebarBg,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // First slot: always the selected avatar.
                _AvatarCircleButton(
                  initial: _kAvatarLabels[value.avatar]![0],
                  isSelected: true,
                  primaryColor: widget.primaryColor,
                  onTap: () => setState(() {
                    _isAvatarPickerOpen = !_isAvatarPickerOpen;
                    if (_isAvatarPickerOpen) _isSettingsOpen = false;
                  }),
                ),
                // Remaining two appear laterally when picker opens.
                if (_isAvatarPickerOpen) ...[
                  const SizedBox(width: 4),
                  _AvatarCircleButton(
                    initial: _kAvatarLabels[others[0]]![0],
                    isSelected: false,
                    primaryColor: widget.primaryColor,
                    onTap: () {
                      _controller.setAvatar(others[0]);
                      setState(() => _isAvatarPickerOpen = false);
                    },
                  ),
                  const SizedBox(width: 4),
                  _AvatarCircleButton(
                    initial: _kAvatarLabels[others[1]]![0],
                    isSelected: false,
                    primaryColor: widget.primaryColor,
                    onTap: () {
                      _controller.setAvatar(others[1]);
                      setState(() => _isAvatarPickerOpen = false);
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar area ────────────────────────────────────────────────────────────
  Widget _buildAvatarArea(VLibrasValue value, bool isLoading) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: _kAvatarBg,
          child: VLibrasView(controller: _controller),
        ),

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
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Maps speed enum ↔ discrete slider double (0 | 1 | 2).
  static double _speedToSlider(VLibrasSpeed s) => s.index.toDouble();
  static VLibrasSpeed _sliderToSpeed(double v) =>
      VLibrasSpeed.values[v.round().clamp(0, VLibrasSpeed.values.length - 1)];

  static String _speedLabel(VLibrasSpeed s) => switch (s) {
    VLibrasSpeed.slow => '1x',
    VLibrasSpeed.normal => '1,5x',
    VLibrasSpeed.fast => '2x',
  };

  // ── Footer bar ─────────────────────────────────────────────────────────────
  Widget _buildFooter(VLibrasValue value) {
    return Container(
      height: 44,
      color: widget.primaryColor,
      padding: const EdgeInsets.only(left: 10, right: 14),
      child: Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white38,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
                valueIndicatorColor: Colors.white,
                valueIndicatorTextStyle: TextStyle(
                  color: widget.primaryColor,
                  fontSize: 12,
                ),
              ),
              child: Slider(
                value: _speedToSlider(value.speed),
                min: 0,
                max: 2,
                divisions: 2,
                label: _speedLabel(value.speed),
                onChanged: (v) => _controller.setSpeed(_sliderToSpeed(v)),
              ),
            ),
          ),
          Text(
            _speedLabel(value.speed),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // While hidden (e.g. splash screen) render only the child — no button,
    // no interceptor, no overhead.
    if (!widget.visible) return widget.child;

    return Stack(
      children: [
        // ① App content — keyed so _onContentTap can hit-test it directly,
        //    bypassing the opaque interceptor sibling above it.
        KeyedSubtree(key: _childKey, child: widget.child),

        // ② Tap interceptor — full-screen opaque sibling placed ABOVE
        //    widget.child but BELOW the VLibras panel. Stack hit-tests from
        //    last child to first; the panel (④) wins for its own area first,
        //    then the interceptor catches everything else. Removed during
        //    pass-through so the synthetic tap reaches widget.child's buttons.
        if (_isExpanded && !_passingThrough)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _onContentTap,
            ),
          ),

        // ③ "Acessar link" tooltip — IgnorePointer so it doesn't interfere
        //    with the interceptor below it.
        if (_pendingTapGlobal != null)
          _LinkTooltip(
            position: _pendingTapGlobal!,
            color: widget.primaryColor,
          ),

        // ④ VLibras panel / button — topmost, handles its own taps first.
        ValueListenableBuilder<VLibrasValue>(
          valueListenable: _controller,
          builder: (context, value, __) => _isExpanded
              ? _buildDraggableAvatarPanel(context, value)
              : _buildDraggableFloatingButton(),
        ),
      ],
    );
  }
}
