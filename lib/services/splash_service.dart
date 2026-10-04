import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/app_settings.dart';

/// SplashService - drives the launch cue.
///
/// The sound id is stored without an extension, so the extension has to be
/// resolved at load time; hard-coding one extension once made the cue silent.
class SplashService {
  /// The default launch cue: a soft chord that swells in like a breath and
  /// settles (3 s), chosen by the owner after listening on a phone.
  /// Synthesised by `scripts/synth_ambience.py`, so it is original.
  static const signatureSound = 'splash_breath';

  /// The launch sounds a person can pick in Settings, default first.
  static const choices = <String>[
    'splash_breath',
    'splash_chime',
    'splash_heart_bowl',
    'splash_kalimba',
    'nabd_pulse',
  ];

  /// If the chosen cue cannot be decoded, fall back to the default, then to
  /// a bowl, the gentlest sound the app has.
  static const _candidates = <String>[
    signatureSound,
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

  /// Resolves a sound id to a bundled asset (see [AppSettings.resolveSoundFile]).
  /// Returns null when none exists.
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
