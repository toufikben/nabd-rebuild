class AppSettings {
  const AppSettings._();

  /// يمكن تعطيل صوت البداية مؤقتًا عبر --dart-define.
  static const bool splashSoundEnabled = bool.fromEnvironment(
    'SPLASH_SOUND_ENABLED',
    defaultValue: true,
  );

  /// هذه القائمة تعكس الملفات الموجودة فعليًا في assets/sounds.
  static const Set<String> availableSounds = {
    'birds_distant',
    'cafe_ambience',
    'drums_soft',
    'fireplace_crackle',
    'flute_dawn',
    'harp_soft',
    'ocean_soft',
    'oud_soft',
    'paper_turn',
    'rain_soft',
    'splash_bowl',
    'splash_flute',
    'splash_harp',
    'splash_oud',
    'splash_rain',
    'tibetan_bowl',
    'wind_gentle',
    'whisper_gentle',
  };

  static bool hasSoundFile(String soundId) => availableSounds.contains(soundId);

  static String fallbackSound(String requested) {
    return hasSoundFile(requested) ? requested : 'rain_soft';
  }
}
