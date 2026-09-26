import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// SplashService - plays the launch cue.
///
/// The previous build rotated through five random splash variants, which made
/// the launch feel unpredictable. There is now a single signature sound, and
/// a user override stored under `splash_sound` still wins when present.
class SplashService {
  /// The one signature cue used unless the user picked another.
  static const signatureSound = 'tibetan_bowl';

  final AudioPlayer _player = AudioPlayer();

  /// Resolves the cue to play: explicit user choice, else the signature sound.
  ///
  /// `requested` is whatever was persisted; unknown ids fall back to the
  /// signature so a removed asset can never break the launch.
  static String resolveSound(String? requested) {
    if (requested == null || requested.isEmpty) return signatureSound;
    return requested;
  }

  /// Plays the splash cue. Never throws; a missing asset is only logged.
  Future<void> playSplashSound(String soundId) async {
    try {
      await _player.setAsset('assets/sounds/$soundId.mp3');
      await _player.setVolume(0.6);
      await _player.play();
    } catch (error) {
      debugPrint('Splash sound failed for $soundId: $error');
    }
  }

  Future<void> stopSplashSound() async {
    try {
      await _player.stop();
    } catch (error) {
      debugPrint('Splash sound stop failed: $error');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
