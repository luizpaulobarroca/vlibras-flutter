import 'package:flutter/material.dart';

import 'vlibras_controller.dart';
import 'vlibras_settings_labels.dart';
import 'vlibras_value.dart';

/// Settings panel styled after the gov.br VLibras widget.
///
/// Sections:
///   • Avatar    — selectable chips (Ícaro / Hosana / Guga)
///   • Aparência — subtitles toggle
class VLibrasSettingsPanel extends StatelessWidget {
  const VLibrasSettingsPanel({
    super.key,
    required this.controller,
    this.onClose,
    this.labels = const VLibrasSettingsLabels(),
  });

  final VLibrasController controller;
  final VoidCallback? onClose;
  final VLibrasSettingsLabels labels;

  String _avatarLabel(VLibrasAvatar a) => switch (a) {
        VLibrasAvatar.icaro => labels.avatarIcaro,
        VLibrasAvatar.hosana => labels.avatarHosana,
        VLibrasAvatar.guga => labels.avatarGuga,
      };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final value = controller.value;
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              _buildDivider(),
              _buildSectionLabel('Avatar'),
              _buildAvatarChips(value),
              _buildDivider(),
              _buildSectionLabel('Aparência'),
              _buildSubtitlesRow(value),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (onClose != null)
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onClose,
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          )
        else
          const SizedBox(width: 16),
        Expanded(
          child: Text(
            labels.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  // ── Section label ──────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, thickness: 1);

  // ── Avatar chips ───────────────────────────────────────────────────────────
  Widget _buildAvatarChips(VLibrasValue value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: VLibrasAvatar.values.map((a) {
          final selected = a == value.avatar;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_avatarLabel(a)),
              selected: selected,
              onSelected: (_) => controller.setAvatar(a),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Subtitles row ──────────────────────────────────────────────────────────
  Widget _buildSubtitlesRow(VLibrasValue value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.closed_caption_outlined, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(labels.subtitles)),
          Switch(
            value: value.subtitlesEnabled,
            onChanged: controller.setSubtitles,
          ),
        ],
      ),
    );
  }
}
