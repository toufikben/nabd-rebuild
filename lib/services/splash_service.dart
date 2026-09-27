import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';

import '../core/app_settings.dart';

/// SplashService - drives the launch cue.
///
/// The sound id is stored without an extension, so the extension has to be
/// resolved at load time. An earlier revision hard-coded `.mp3`, which silently
/// failed for the synthesised `.wav` cue.
class SplashService {
  /// Number of distinct splash animations. The sound is shared, but the
  /// animation still rotates so the launch is not identical every time.
  static const _splashCount = 5;

  /// The signature launch cue: a synthesised water drop with a decaying echo
  /// over a soft bowl resonance, 3.0s long to match the splash dwell time.
  static const signatureSound = 'splash_drop';

  /// Preferred cue first, then a proven MP3 so the launch is never silent.
  static const _candidates = <String>['splash_drop', 'tibetan_bowl'];

  final AudioPlayer _player = AudioPlayer();

  /// The most recent load failure, kept for diagnostics.
  String? lastError;

  /// Plays the splash cue, trying each candidate in turn.
  Future<void> playSplashSound(String soundId) async {
    lastError = null;
    final order = <String>[
      soundId,
      ..._candidates.where((id) => id != soundId),
    ];
    for (final id in order) {
      final path = _assetPathFor(id);
      if (path == null) continue;
      try {
        await _player.setAsset(path);
        await _player.setVolume(0.9);
        unawaited(_player.play());
        return;
      } catch (error) {
        lastError = '$path -> $error';
        debugPrint('Splash sound failed for $path: $error');
      }
    }
    debugPrint('Splash sound: no candidate could be played. $lastError');
  }

  /// Resolves a sound id to a bundled asset, preferring `.mp3` and falling back
  /// to `.wav`. Returns null when neither exists.
  String? _assetPathFor(String soundId) {
    final file = AppSettings.resolveSoundFile(soundId);
    return file == null ? null : 'assets/sounds/$file';
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

  /// Returns the next splash id, never the same one twice in a row.
  static int getNextSplash() {
    final box = Hive.box('settings');
    final last = box.get('last_splash_id', defaultValue: 0) as int;

    int next;
    do {
      next = DateTime.now().microsecondsSinceEpoch % _splashCount + 1;
    } while (next == last && _splashCount > 1);

    unawaited(box.put('last_splash_id', next));
    return next;
  }

  /// Every splash variant shares one cue so the launch is repeatable. The
  /// splashId is still accepted so callers keep working.
  static String defaultSoundFor(int splashId) => signatureSound;
}
