import 'package:flutter/material.dart';

import 'vlibras_controller.dart';
import 'vlibras_settings_labels.dart';
import 'vlibras_value.dart';

/// A pre-built settings panel for the VLibras player.
///
/// Renders three sections — speed, avatar, subtitles — each wired to the given
/// [controller]. Re-renders automatically when [VLibrasController.value] changes.
///
/// Place this widget inside a [Dialog], [BottomSheet], [Drawer] or your own
/// [Overlay]. It has an intrinsic width of ~320dp and vertical size driven
/// by content.
class VLibrasSettingsPanel extends StatelessWidget {
  const VLibrasSettingsPanel({
    super.key,
    required this.controller,
    this.onClose,
    this.labels = const VLibrasSettingsLabels(),
  });

  /// The controller whose settings this panel displays and mutates.
  final VLibrasController controller;

  /// Invoked when the close button is tapped. Close button is hidden when null.
  final VoidCallback? onClose;

  /// User-facing strings. Defaults are in Portuguese.
  final VLibrasSettingsLabels labels;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final value = controller.value;
        return SizedBox(
          width: 320,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildSpeedSection(value),
                const SizedBox(height: 16),
                _buildAvatarSection(value),
                const SizedBox(height: 16),
                _buildSubtitlesSection(value),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return Row(
      children: [
        Expanded(child: Text(labels.title, style: titleStyle)),
        if (onClose != null)
          Semantics(
            label: labels.close,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
          ),
      ],
    );
  }

  Widget _buildSpeedSection(VLibrasValue value) {
    final currentLabel = switch (value.speed) {
      VLibrasSpeed.slow => labels.speedSlow,
      VLibrasSpeed.normal => labels.speedNormal,
      VLibrasSpeed.fast => labels.speedFast,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(labels.speed)),
            Text(
              currentLabel,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.directions_walk, size: 20),
            Expanded(
              child: Slider(
                min: 0,
                max: (VLibrasSpeed.values.length - 1).toDouble(),
                divisions: VLibrasSpeed.values.length - 1,
                value: value.speed.index.toDouble(),
                onChanged: (v) =>
                    controller.setSpeed(VLibrasSpeed.values[v.round()]),
              ),
            ),
            const Icon(Icons.directions_run, size: 20),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarSection(VLibrasValue value) {
    Widget radio(VLibrasAvatar a, String label) => Expanded(
          child: RadioListTile<VLibrasAvatar>(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(label),
            value: a,
            groupValue: value.avatar,
            onChanged: (next) {
              if (next != null) controller.setAvatar(next);
            },
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(labels.avatar),
        const SizedBox(height: 8),
        Row(children: [
          radio(VLibrasAvatar.icaro, labels.avatarIcaro),
          radio(VLibrasAvatar.hosana, labels.avatarHosana),
          radio(VLibrasAvatar.guga, labels.avatarGuga),
        ]),
      ],
    );
  }

  Widget _buildSubtitlesSection(VLibrasValue value) {
    return Row(
      children: [
        const Icon(Icons.closed_caption, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(labels.subtitles)),
        Switch(
          value: value.subtitlesEnabled,
          onChanged: controller.setSubtitles,
        ),
      ],
    );
  }
}
