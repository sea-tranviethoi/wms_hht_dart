import 'package:audioplayers/audioplayers.dart';
import '../constants/app_constants.dart';

/// Ported from modules/preloadSounds.js + components/Sound.js
///
/// Preloads 3 sounds at app startup so they can play instantly on scan
class SoundManager {
  SoundManager._();
  static final SoundManager instance = SoundManager._();

  final AudioPlayer _player = AudioPlayer();

  // ─── Init ─────────────────────────────────────────────────────

  Future<void> init() async {
    // Configure audio player
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  // ─── Play ─────────────────────────────────────────────────────

  /// Play sound on successful scan (1-beep.mp3)
  Future<void> playCorrect() => _play(AppConstants.soundCorrect);

  /// Play sound on error (error_sound.mp3)
  Future<void> playError() => _play(AppConstants.soundError);

  /// Play warning sound (2-beep.mp3)
  Future<void> playWarning() => _play(AppConstants.soundWarning);

  Future<void> _play(String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // Ignore sound errors — they do not affect business logic
    }
  }

  // ─── Dispose ──────────────────────────────────────────────────

  Future<void> dispose() => _player.dispose();
}
