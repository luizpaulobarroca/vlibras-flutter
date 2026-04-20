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
class VLibrasSettingsPanel extends StatefulWidget {
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
  State<VLibrasSettingsPanel> createState() => _VLibrasSettingsPanelState();
}

class _VLibrasSettingsPanelState extends State<VLibrasSettingsPanel> {
  final LayerLink _avatarLink = LayerLink();
  bool _avatarOpen = false;

  String _avatarLabelFor(VLibrasAvatar a) => switch (a) {
        VLibrasAvatar.icaro => widget.labels.avatarIcaro,
        VLibrasAvatar.hosana => widget.labels.avatarHosana,
        VLibrasAvatar.guga => widget.labels.avatarGuga,
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final value = widget.controller.value;
        return SizedBox(
          width: 320,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
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
              // Floating avatar dropdown list — rendered LAST so it paints on
              // top of the subtitles row. Does not contribute to the Stack's
              // natural size because it follows the target via LayerLink.
              if (_avatarOpen)
                CompositedTransformFollower(
                  link: _avatarLink,
                  targetAnchor: Alignment.bottomRight,
                  followerAnchor: Alignment.topRight,
                  offset: const Offset(0, 4),
                  child: _buildAvatarList(value),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return Row(
      children: [
        Expanded(child: Text(widget.labels.title, style: titleStyle)),
        if (widget.onClose != null)
          Semantics(
            label: widget.labels.close,
            button: true,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
            ),
          ),
      ],
    );
  }

  Widget _buildSpeedSection(VLibrasValue value) {
    final currentLabel = switch (value.speed) {
      VLibrasSpeed.slow => widget.labels.speedSlow,
      VLibrasSpeed.normal => widget.labels.speedNormal,
      VLibrasSpeed.fast => widget.labels.speedFast,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(widget.labels.speed)),
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
                onChanged: (v) => widget.controller
                    .setSpeed(VLibrasSpeed.values[v.round()]),
              ),
            ),
            const Icon(Icons.directions_run, size: 20),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarSection(VLibrasValue value) {
    return Row(
      children: [
        const Icon(Icons.person_outline, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(widget.labels.avatar)),
        CompositedTransformTarget(
          link: _avatarLink,
          child: InkWell(
            onTap: () => setState(() => _avatarOpen = !_avatarOpen),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_avatarLabelFor(value.avatar)),
                  Icon(
                    _avatarOpen
                        ? Icons.arrow_drop_up
                        : Icons.arrow_drop_down,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarList(VLibrasValue value) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(4),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in VLibrasAvatar.values)
              InkWell(
                onTap: () {
                  widget.controller.setAvatar(a);
                  setState(() => _avatarOpen = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: a == value.avatar
                      ? theme.colorScheme.primaryContainer
                      : null,
                  child: Text(_avatarLabelFor(a)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitlesSection(VLibrasValue value) {
    return Row(
      children: [
        const Icon(Icons.closed_caption, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(widget.labels.subtitles)),
        Switch(
          value: value.subtitlesEnabled,
          onChanged: widget.controller.setSubtitles,
        ),
      ],
    );
  }
}
