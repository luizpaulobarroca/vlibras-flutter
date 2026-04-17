import 'package:flutter/foundation.dart';

/// Playback speed presets accepted by the VLibras Unity player.
///
/// Values map to Unity's speed multiplier: 0.5x (slow), 1.0x (normal), 1.5x (fast).
enum VLibrasSpeed {
  slow(0.5),
  normal(1.0),
  fast(1.5);

  const VLibrasSpeed(this.multiplier);

  /// The raw speed multiplier passed to the Unity player.
  final double multiplier;
}

/// The avatar personas supported by the VLibras Unity player.
///
/// The [id] is the exact string expected by `player.changeAvatar(name)`.
enum VLibrasAvatar {
  icaro('icaro'),
  hosana('hosana'),
  guga('guga');

  const VLibrasAvatar(this.id);

  /// The string accepted by the Unity player's `changeAvatar` message.
  final String id;
}

/// The possible states of the VLibras translation lifecycle.
enum VLibrasStatus {
  /// Controller created but [VLibrasController.initialize] not yet called.
  idle,

  /// [VLibrasController.initialize] is in progress.
  initializing,

  /// Initialized and ready to accept [VLibrasController.translate] calls.
  ready,

  /// A translation request has been accepted and is awaiting player response.
  translating,

  /// The avatar is currently animating the translation.
  playing,

  /// An error occurred during [VLibrasController.initialize] or [VLibrasController.translate].
  error,
}

/// Immutable value object representing the current state of [VLibrasController].
///
/// Consumers use [VLibrasController.value] to read the current state, and
/// subscribe via [ChangeNotifier.addListener] or [ValueListenableBuilder].
@immutable
class VLibrasValue {
  /// The current lifecycle status.
  final VLibrasStatus status;

  /// A human-readable error message when [status] is [VLibrasStatus.error],
  /// or `null` otherwise.
  final String? error;

  /// Creates a [VLibrasValue].
  const VLibrasValue({
    this.status = VLibrasStatus.idle,
    this.error,
  });

  /// Whether this value contains an error message.
  bool get hasError => error != null;

  /// Returns a copy of this value with the given fields replaced.
  ///
  /// Pass [clearError] as `true` to explicitly set [error] to `null`.
  VLibrasValue copyWith({
    VLibrasStatus? status,
    String? error,
    bool clearError = false,
  }) {
    return VLibrasValue(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VLibrasValue &&
        other.status == status &&
        other.error == error;
  }

  @override
  int get hashCode => Object.hash(status, error);

  @override
  String toString() => 'VLibrasValue(status: $status, error: $error)';
}
