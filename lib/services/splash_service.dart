import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/app_settings.dart';

/// SplashService - drives the launch cue.
///
/// The sound id is stored without an extension, so the extension has to be
/// resolved at load time. An earlier revision hard-coded `.mp3`, which silently
/// failed for the synthesised `.wav` cue.
class SplashService {
  /// The signature launch cue: two soft heartbeats that bloom into a warm
  /// chord over a breath of air (2.6 s). Synthesised by
  /// `scripts/synth_sounds.py`, so it is original and reproducible.
  static const signatureSound = 'nabd_pulse';

  /// If the signature cue cannot be decoded, a bowl is the gentlest fallback.
  static const _candidates = <String>[
    'nabd_pulse',
    'tibetan_bowl',
  ];

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
        await _player.setVolume(0.8);
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
}
