import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'vlibras_controller.dart';
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
/// Example:
/// ```dart
/// VLibrasAccessibilityWidget(
///   child: MaterialApp(home: MyHomePage()),
/// )
/// ```
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

  @override
  State<VLibrasAccessibilityWidget> createState() =>
      _VLibrasAccessibilityWidgetState();
}

class _VLibrasAccessibilityWidgetState
    extends State<VLibrasAccessibilityWidget> {
  late final VLibrasController _controller;
  bool _isExpanded = false;

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

  Widget _buildAvatarPanel(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topOffset = (screenHeight - widget.avatarHeight) / 2;

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
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _isExpanded = false),
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
            builder: (context, _, __) => _isExpanded
                ? _buildAvatarPanel(context)
                : _buildFloatingButton(),
          ),
        ],
      ),
    );
  }
}
