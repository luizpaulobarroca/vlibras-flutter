import 'package:flutter/material.dart';
import 'package:vlibras_flutter/vlibras_flutter.dart';

/// Floating avatar that snaps to the nearest screen corner on drag release.
///
/// Uses [AnimatedPositioned] inside a [Stack] for implicit animation.
/// Must be placed as a direct child of a [Stack] widget.
class DraggableAvatar extends StatefulWidget {
  const DraggableAvatar({
    super.key,
    required this.controller,
    required this.availableSize,
    this.size = 200.0,
  });

  final VLibrasController controller;

  /// The available area for the avatar to snap within (Stack bounds).
  final Size availableSize;

  /// Width and height of the avatar in logical pixels. Defaults to 200.
  final double size;

  @override
  State<DraggableAvatar> createState() => _DraggableAvatarState();
}

class _DraggableAvatarState extends State<DraggableAvatar> {
  static const double _margin = 16.0;
  Offset _position = const Offset(_margin, _margin);

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final size = widget.availableSize;
    final cx = _position.dx < size.width / 2
        ? _margin
        : size.width - widget.size - _margin;
    final cy = _position.dy < size.height / 2
        ? _margin
        : size.height - widget.size - _margin;
    setState(() {
      _position = Offset(cx, cy);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      left: _position.dx,
      top: _position.dy,
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: VLibrasView(controller: widget.controller),
      ),
    );
  }
}
