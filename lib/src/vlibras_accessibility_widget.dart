import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'vlibras_controller.dart';
import 'vlibras_view.dart';
import 'vlibras_value.dart';

/// A self-contained accessibility widget that adds a floating VLibras
/// translation button to any Flutter app.
///
/// Wrap your app content with this widget to get a floating button pinned to
/// the right side of the screen. Tapping the button expands a panel showing
/// the VLibras 3D avatar. While the panel is open, tapping any [Text] widget
/// inside [child] automatically translates that text into LIBRAS.
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
  OverlayEntry? _overlayEntry;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = VLibrasController();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _controller.initialize());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: _buildOverlay);
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _controller.dispose();
    super.dispose();
  }

  void _onContentTap(TapUpDetails details) {
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

  void _hideOverlay() {
    setState(() => _isExpanded = false);
    _overlayEntry?.markNeedsBuild();
  }

  Widget _buildOverlay(BuildContext context) {
    return ValueListenableBuilder<VLibrasValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        if (!_isExpanded) {
          // Collapsed state: floating button pinned to center-right
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
                      onTap: () {
                        setState(() => _isExpanded = true);
                        _overlayEntry!.markNeedsBuild();
                      },
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

        // Expanded state: avatar window panel
        final screenHeight = MediaQuery.of(context).size.height;
        final topOffset = screenHeight / 2 - widget.avatarHeight / 2;

        return Positioned(
          right: 0,
          top: topOffset,
          width: widget.avatarWidth,
          height: widget.avatarHeight,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              fit: StackFit.expand,
              children: [
                VLibrasView(controller: _controller),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _hideOverlay,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: _isExpanded ? _onContentTap : null,
      child: widget.child,
    );
  }
}
