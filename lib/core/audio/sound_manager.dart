import 'package:audioplayers/audioplayers.dart';
import '../constants/app_constants.dart';

/// Port từ modules/preloadSounds.js + components/Sound.js
///
/// Preload 3 sound khi app khởi động để phát tức thì khi scan
class SoundManager {
  SoundManager._();
  static final SoundManager instance = SoundManager._();

  final AudioPlayer _player = AudioPlayer();

  // ─── Init ─────────────────────────────────────────────────────

  Future<void> init() async {
    // Cấu hình audio player
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  // ─── Play ─────────────────────────────────────────────────────

  /// Phát sound khi scan thành công (1-beep.mp3)
  Future<void> playCorrect() => _play(AppConstants.soundCorrect);

  /// Phát sound khi có lỗi (error_sound.mp3)
  Future<void> playError() => _play(AppConstants.soundError);

  /// Phát sound cảnh báo (2-beep.mp3)
  Future<void> playWarning() => _play(AppConstants.soundWarning);

  Future<void> _play(String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // Bỏ qua lỗi sound — không ảnh hưởng logic nghiệp vụ
    }
  }

  // ─── Dispose ──────────────────────────────────────────────────

  Future<void> dispose() => _player.dispose();
}
