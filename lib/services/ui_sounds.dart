import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';

/// Small sounds that mark a moment, never decoration: a page turning when an
/// entry is saved, a drop when the garden is watered, a rising sparkle for an
/// achievement, a bowl when a session ends. Quiet by design and switchable
/// off in Settings.
enum UiSound {
  save('paper_turn.mp3', 0.45),
  water('ui_drop.m4a', 0.6),
  bloom('ui_bloom.m4a', 0.55),
  complete('tibetan_bowl.mp3', 0.5);

  const UiSound(this.file, this.volume);

  final String file;
  final double volume;
}

class UiSounds {
  const UiSounds._();

  static const enabledKey = 'ui_sounds_enabled';

  static AudioPlayer? _player;

  static bool get enabled {
    try {
      return Hive.box('settings').get(enabledKey, defaultValue: true) == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setEnabled(bool value) =>
      Hive.box('settings').put(enabledKey, value);

  static Future<void> play(UiSound sound, {Duration delay = Duration.zero}) async {
    if (!enabled) return;
    try {
      if (delay > Duration.zero) await Future<void>.delayed(delay);
      final player = _player ??= AudioPlayer();
      await player.stop();
      await player.setVolume(sound.volume);
      await player.setAsset('assets/sounds/${sound.file}');
      unawaited(player.play());
    } catch (error) {
      debugPrint('UI sound ${sound.name} not played: $error');
    }
  }
}
