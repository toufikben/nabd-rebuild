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
    'exhale.mp3',
    'fireplace_crackle.mp3',
    'flute_dawn.mp3',
    'garden_birds.mp3',
    'harp_soft.mp3',
    'inhale.mp3',
    'nabd_pulse.m4a',
    'ocean_soft.mp3',
    'oud_soft.mp3',
    'paper_turn.mp3',
    'rain_soft.mp3',
    'silent_river_water.mp3',
    'tibetan_bowl.mp3',
    'ui_bloom.m4a',
    'ui_drop.m4a',
    'wind_gentle.mp3',
  };

  /// True when the given asset file name (with extension) is bundled.
  static bool hasSoundFile(String fileName) =>
      availableSounds.contains(fileName);

  /// Resolves a bare sound id to a bundled file, preferring mp3, then the
  /// app's own synthesised m4a, then wav.
  static String? resolveSoundFile(String soundId) {
    for (final ext in const ['.mp3', '.m4a', '.wav']) {
      if (availableSounds.contains('$soundId$ext')) return '$soundId$ext';
    }
    return null;
  }

  static String fallbackSound(String requested) {
    return resolveSoundFile(requested) != null ? requested : 'rain_soft';
  }
}
