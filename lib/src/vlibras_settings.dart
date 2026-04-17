import 'package:flutter/foundation.dart';

import 'vlibras_value.dart';

/// Immutable, serialisable payload carrying the user-facing VLibras settings.
///
/// Distinct from [VLibrasValue] — this object only contains preferences
/// (speed, avatar, subtitles), not status or error. Meant to be handed to
/// `VLibrasController(onSettingsChanged: ...)` callbacks for persistence.
@immutable
class VLibrasSettings {
  /// Creates a [VLibrasSettings].
  const VLibrasSettings({
    this.speed = VLibrasSpeed.normal,
    this.avatar = VLibrasAvatar.icaro,
    this.subtitlesEnabled = true,
  });

  /// The current playback speed preset.
  final VLibrasSpeed speed;

  /// The selected avatar persona.
  final VLibrasAvatar avatar;

  /// Whether subtitles are currently enabled on the avatar view.
  final bool subtitlesEnabled;

  /// Returns a copy with the given fields replaced.
  VLibrasSettings copyWith({
    VLibrasSpeed? speed,
    VLibrasAvatar? avatar,
    bool? subtitlesEnabled,
  }) {
    return VLibrasSettings(
      speed: speed ?? this.speed,
      avatar: avatar ?? this.avatar,
      subtitlesEnabled: subtitlesEnabled ?? this.subtitlesEnabled,
    );
  }

  /// Serialises this settings payload to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'speed': speed.name,
        'avatar': avatar.name,
        'subtitlesEnabled': subtitlesEnabled,
      };

  /// Parses a [VLibrasSettings] from a JSON map. Falls back to defaults for
  /// any missing or unrecognised fields — never throws.
  factory VLibrasSettings.fromJson(Map<String, dynamic> json) {
    return VLibrasSettings(
      speed: _enumFromName(VLibrasSpeed.values, json['speed']) ??
          VLibrasSpeed.normal,
      avatar: _enumFromName(VLibrasAvatar.values, json['avatar']) ??
          VLibrasAvatar.icaro,
      subtitlesEnabled: json['subtitlesEnabled'] is bool
          ? json['subtitlesEnabled'] as bool
          : true,
    );
  }

  static T? _enumFromName<T extends Enum>(List<T> values, Object? raw) {
    if (raw is! String) return null;
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VLibrasSettings &&
        other.speed == speed &&
        other.avatar == avatar &&
        other.subtitlesEnabled == subtitlesEnabled;
  }

  @override
  int get hashCode => Object.hash(speed, avatar, subtitlesEnabled);

  @override
  String toString() =>
      'VLibrasSettings(speed: $speed, avatar: $avatar, subtitlesEnabled: $subtitlesEnabled)';
}
