import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';

/// SplashService — يدير السبلاش الدوّار + الأصوات.
class SplashService {
  /// The signature launch cue: a synthesised water drop with a decaying echo,
  /// 3.0s long so it lines up with the splash dwell time.
  static const signatureSound = 'splash_drop';

  final AudioPlayer _player = AudioPlayer();

  /// يشغّل ملف الصوت المضمّن المرتبط بالـsplash.
  Future<void> playSplashSound(String soundId) async {
    try {
      await _player.setAsset('assets/sounds/$soundId.mp3');
      await _player.setVolume(0.65);
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

  /// يعيد splash التالي (لا يكرر السابق مباشرة).
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

  /// Every splash variant now shares one cue so the launch is repeatable.
  /// The splashId is still accepted so callers keep working.
  static String defaultSoundFor(int splashId) => signatureSound;
}

class SplashOption {
  final int id;
  final String name;
  final String description;
  final String emoji;
  final List<String> sounds;

  const SplashOption({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.sounds,
  });

  static const all = [
    SplashOption(
      id: 1,
      name: 'First Seed',
      description: 'بذرة تسقط وتنبت',
      emoji: '🌱',
      sounds: ['splash_rain'],
    ),
    SplashOption(
      id: 2,
      name: 'New Dawn',
      description: 'شروق الشمس خلف الجبال',
      emoji: '🌅',
      sounds: ['splash_flute', 'birds_distant'],
    ),
    SplashOption(
      id: 3,
      name: 'Book to Butterfly',
      description: 'كتاب يتحول إلى فراشات',
      emoji: '🦋',
      sounds: ['paper_turn', 'splash_harp'],
    ),
    SplashOption(
      id: 4,
      name: 'Candle Light',
      description: 'شمعة تضيء غرفة دافئة',
      emoji: '🕯️',
      sounds: ['splash_oud', 'whisper_gentle'],
    ),
    SplashOption(
      id: 5,
      name: 'Circle of Life',
      description: 'دائرة ضوء تكشف شجرة',
      emoji: '💫',
      sounds: ['splash_bowl', 'drums_soft'],
    ),
  ];
}
