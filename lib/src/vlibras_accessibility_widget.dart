import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'vlibras_controller.dart';
import 'vlibras_settings_labels.dart';
import 'vlibras_settings_panel.dart';
import 'vlibras_view.dart';
import 'vlibras_value.dart';

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

  @override
  State<VLibrasAccessibilityWidget> createState() =>
      _VLibrasAccessibilityWidgetState();
}

class _VLibrasAccessibilityWidgetState
    extends State<VLibrasAccessibilityWidget> {
  late final VLibrasController _controller;
  bool _isExpanded = false;
  bool _isSettingsOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = VLibrasController();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _controller.initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onContentTap(TapUpDetails details) {
    if (!_isExpanded) return;
    final renderObj = context.findRenderObject();
    if (renderObj is! RenderBox) return;

    final result = BoxHitTestResult();
    renderObj.hitTest(result, position: details.localPosition);

    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderParagraph) {
        final text =
            target.text.toPlainText(includeSemanticsLabels: false).trim();
        if (text.isNotEmpty) {
          _controller.translate(text);
          return;
        }
      }
    }
  }

  Widget _buildFloatingButton() {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: SizedBox(
            width: widget.buttonSize,
            height: widget.buttonSize,
            child: Material(
              color: Colors.blue,
              shape: const CircleBorder(),
              elevation: 6,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _isExpanded = true),
                child: const Icon(
                  Icons.accessibility_new,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                    Semantics(
                      label: widget.settingsLabels.title,
                      button: true,
                      child: IconButton(
                        icon:
                            const Icon(Icons.settings, color: Colors.white),
                        onPressed: () => setState(
                            () => _isSettingsOpen = !_isSettingsOpen),
                      ),
                    ),
                  Semantics(
                    label: widget.settingsLabels.close,
                    button: true,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() {
                        _isExpanded = false;
                        _isSettingsOpen = false;
                      }),
                    ),
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
