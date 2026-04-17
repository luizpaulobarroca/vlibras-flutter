import 'vlibras_value.dart';

/// Abstract platform interface for VLibras operations.
///
/// Concrete implementations are provided per-platform (e.g., web in Phase 3).
/// Tests inject a `MockVLibrasPlatform` via [VLibrasController]'s constructor.
abstract class VLibrasPlatform {
  /// Initializes the underlying VLibras player.
  Future<void> initialize();

  /// Requests translation of [text] into LIBRAS.
  Future<void> translate(String text);

  /// Pauses the current animation.
  Future<void> pause();

  /// Stops the current animation and resets player state.
  Future<void> stop();

  /// Resumes a paused animation.
  Future<void> resume();

  /// Repeats the last translation from the beginning.
  Future<void> repeat();

  /// Sets the animation playback [speed] (e.g., 1.0 = normal, 0.5 = half speed).
  Future<void> setSpeed(double speed);

  /// Sets the active avatar persona.
  Future<void> setAvatar(VLibrasAvatar avatar);

  /// Applies the desired subtitles state.
  ///
  /// Implementations that can only toggle should assume the caller already
  /// verified the desired state differs from the current one.
  Future<void> setSubtitles(bool enabled);

  /// Releases all resources held by this platform instance.
  ///
  /// Synchronous to match [ChangeNotifier.dispose] contract.
  void dispose();
}
