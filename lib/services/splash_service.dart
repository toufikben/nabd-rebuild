import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';

/// SplashService — يدير السبلاش الدوّار + الأصوات.
class SplashService {
  static const _splashCount = 5;

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

  /// Sound المرتبط بكل splash.
  static String defaultSoundFor(int splashId) {
    switch (splashId) {
      case 1:
        return 'splash_rain';
      case 2:
        return 'splash_flute';
      case 3:
        return 'splash_harp';
      case 4:
        return 'splash_oud';
      case 5:
        return 'splash_bowl';
      default:
        return 'splash_rain';
    }
  }
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
