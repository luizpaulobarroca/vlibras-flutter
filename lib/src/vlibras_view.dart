import 'package:flutter/widgets.dart';
import 'vlibras_controller.dart';

/// A Flutter Web widget that renders the VLibras 3D avatar.
///
/// Fills the constraints provided by its parent. Use [SizedBox], [Expanded],
/// or any sizing widget to control dimensions.
///
/// During [VLibrasStatus.initializing], the area appears blank or black.
/// Use [ValueListenableBuilder] with [VLibrasController.value] to show a
/// loading indicator outside this widget.
///
/// Example:
/// ```dart
/// SizedBox(
///   width: 400,
///   height: 300,
///   child: VLibrasView(controller: controller),
/// )
/// ```
class VLibrasView extends StatefulWidget {
  const VLibrasView({super.key, required this.controller});

  final VLibrasController controller;

  @override
  State<VLibrasView> createState() => _VLibrasViewState();
}

class _VLibrasViewState extends State<VLibrasView> {
  void _onElementCreated(Object element) {
    // Use dynamic dispatch to avoid importing package:web (web-only types)
    // in this file. This keeps the barrel export VM-compatible.
    // ignore: avoid_dynamic_calls
    final div = element as dynamic;
    div.id = 'vlibras-player';
    div.style.width = '100%';
    div.style.height = '100%';
    div.style.background = 'transparent';
    widget.controller.attachElement(element);
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView.fromTagName(
      key: const Key('vlibras-player-view'),
      tagName: 'div',
      onElementCreated: _onElementCreated,
    );
  }
}
