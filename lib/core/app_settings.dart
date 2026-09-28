class AppSettings {
  const AppSettings._();

  /// يمكن تعطيل صوت البداية مؤقتًا عبر --dart-define.
  static const bool splashSoundEnabled = bool.fromEnvironment(
    'SPLASH_SOUND_ENABLED',
    defaultValue: true,
  );

  /// Reflects the files that actually exist in assets/sounds.
  static const Set<String> availableSounds = {
    'birds_distant.mp3',
    'cafe_ambience.mp3',
    'drums_soft.mp3',
    'exhale.mp3',
    'fireplace_crackle.mp3',
    'flute_dawn.mp3',
    'garden_birds.mp3',
    'harp_soft.mp3',
    'inhale.mp3',
    'ocean_soft.mp3',
    'oud_soft.mp3',
    'paper_turn.mp3',
    'rain_soft.mp3',
    'silent_river_water.mp3',
    'splash_bowl.mp3',
    'splash_drop.wav',
    'splash_nabd.wav',
    'splash_flute.mp3',
    'splash_harp.mp3',
    'splash_oud.mp3',
    'splash_rain.mp3',
    'tibetan_bowl.mp3',
    'wind_gentle.mp3',
    'whisper_gentle.mp3',
  };

  /// True when the given asset file name (with extension) is bundled.
  static bool hasSoundFile(String fileName) =>
      availableSounds.contains(fileName);

  /// Resolves a bare sound id to a bundled file, preferring mp3 then wav.
  static String? resolveSoundFile(String soundId) {
    for (final ext in const ['.mp3', '.wav']) {
      if (availableSounds.contains('$soundId$ext')) return '$soundId$ext';
    }
    return null;
  }

  static String fallbackSound(String requested) {
    return resolveSoundFile(requested) != null ? requested : 'rain_soft';
  }
}
