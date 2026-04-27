import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'vlibras_controller.dart';
import 'vlibras_settings_labels.dart';
import 'vlibras_settings_panel.dart';
import 'vlibras_view.dart';
import 'vlibras_value.dart';

// ── Gov.br official color palette ────────────────────────────────────────────
const Color _kGovBlue = Color(0xFF003F86);
const Color _kAvatarBg = Color(0xFFDCE8F5);
const Color _kSidebarBg = Colors.transparent;
const Color _kIconInactive = Color(0xFFB0BEC5);


// ── Sidebar circular icon button ─────────────────────────────────────────────
class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bg = active ? _kGovBlue : _kIconInactive;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

// ── Sidebar avatar circle (shows initial letter) ──────────────────────────────
class _AvatarCircleButton extends StatelessWidget {
  const _AvatarCircleButton({
    required this.initial,
    required this.isSelected,
    required this.onTap,
  });

  final String initial;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? _kGovBlue : _kIconInactive,
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
    this.avatarWidth = 280.0,
    this.avatarHeight = 320.0,
    this.buttonSize = 56.0,
    this.showSettingsButton = true,
    this.settingsLabels = const VLibrasSettingsLabels(),
    this.translateUrl,
  });

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
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _controller.initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Text-tap handler: translates only app content, not panel UI ───────────
  void _onContentTap(TapUpDetails details) {
    if (!_isExpanded) return;
    final renderObj = context.findRenderObject();
    if (renderObj is! RenderBox) return;

    // Ignore taps that land inside the VLibras panel itself.
    final size = renderObj.size;
    final panelTop = (size.height - widget.avatarHeight) / 2;
    final panelLeft = size.width - widget.avatarWidth;
    final panelRect =
        Rect.fromLTWH(panelLeft, panelTop, widget.avatarWidth, widget.avatarHeight);
    if (panelRect.contains(details.localPosition)) return;

    final result = BoxHitTestResult();
    renderObj.hitTest(result, position: details.localPosition);

    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderParagraph) {
        final text =
            target.text.toPlainText(includeSemanticsLabels: false).trim();
        if (text.isEmpty) continue;
        _controller.translate(text);
        return;
      }
    }
  }


  // ── Collapsed floating button (center-right) ──────────────────────────────
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
                width: widget.buttonSize + 16,
                decoration: const BoxDecoration(
                  color: _kGovBlue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.accessibility_new,
                        color: Colors.white, size: 30),
                    SizedBox(height: 4),
                    Text(
                      'VLibras',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
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
  Widget _buildHeader() {
    return Container(
      height: 40,
      color: _kGovBlue,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          if (widget.showSettingsButton)
            Semantics(
              label: widget.settingsLabels.title,
              button: true,
              child: IconButton(
                icon:
                    const Icon(Icons.settings, color: Colors.white, size: 18),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
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
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: () => setState(() {
                _isExpanded = false;
                _isSettingsOpen = false;
                _isAvatarPickerOpen = false;
              }),
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
        Positioned.fill(
          child: _buildAvatarArea(value, isLoading),
        ),

        // ── 2. Sidebar: above the WebView ───────────────────────────────
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: _buildSidebar(value),
        ),

        // ── 3. Settings overlay: above everything, including sidebar ────
        if (_isSettingsOpen)
          Positioned.fill(
            child: _buildSettingsOverlay(),
          ),
      ],
    );
  }

  Widget _buildSettingsOverlay() {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          primaryContainer: Color(0xFF1A5EA8),
          surface: _kGovBlue,
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
        color: _kGovBlue,
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
    final others =
        VLibrasAvatar.values.where((a) => a != value.avatar).toList();

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
                    onTap: () {
                      _controller.setAvatar(others[0]);
                      setState(() => _isAvatarPickerOpen = false);
                    },
                  ),
                  const SizedBox(width: 4),
                  _AvatarCircleButton(
                    initial: _kAvatarLabels[others[1]]![0],
                    isSelected: false,
                    onTap: () {
                      _controller.setAvatar(others[1]);
                      setState(() => _isAvatarPickerOpen = false);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SidebarButton(
            icon: Icons.help_outline,
            active: false,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _SidebarButton(
            icon: Icons.more_horiz,
            active: false,
            onTap: () {},
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
                  style:
                      const TextStyle(color: Colors.redAccent, fontSize: 12),
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
      color: _kGovBlue,
      padding: const EdgeInsets.only(left: 10, right: 14),
      child: Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white38,
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
                valueIndicatorColor: Colors.white,
                valueIndicatorTextStyle:
                    const TextStyle(color: _kGovBlue, fontSize: 12),
              ),
              child: Slider(
                value: _speedToSlider(value.speed),
                min: 0,
                max: 2,
                divisions: 2,
                label: _speedLabel(value.speed),
                onChanged: (v) =>
                    _controller.setSpeed(_sliderToSpeed(v)),
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
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: _onContentTap,
      child: Stack(
        children: [
          widget.child,
          ValueListenableBuilder<VLibrasValue>(
            valueListenable: _controller,
            builder: (context, value, __) => _isExpanded
                ? _buildAvatarPanel(context, value)
                : _buildFloatingButton(),
          ),
        ],
      ),
    );
  }
}
