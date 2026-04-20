import 'package:flutter/foundation.dart';

/// User-facing strings used by [VLibrasSettingsPanel].
///
/// Defaults are in Portuguese. Pass a custom instance to localise the panel
/// without pulling in a full i18n framework.
@immutable
class VLibrasSettingsLabels {
  const VLibrasSettingsLabels({
    this.title = 'Configurações',
    this.speed = 'Velocidade',
    this.speedSlow = 'Devagar',
    this.speedNormal = 'Normal',
    this.speedFast = 'Rápido',
    this.avatar = 'Avatar',
    this.avatarIcaro = 'Ícaro',
    this.avatarHosana = 'Hosana',
    this.avatarGuga = 'Guga',
    this.subtitles = 'Legendas',
    this.close = 'Fechar',
  });

  final String title;
  final String speed;
  final String speedSlow;
  final String speedNormal;
  final String speedFast;
  final String avatar;
  final String avatarIcaro;
  final String avatarHosana;
  final String avatarGuga;
  final String subtitles;
  final String close;
}
