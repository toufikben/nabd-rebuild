class AppSettings {
  const AppSettings._();

  /// يمكن تعطيل صوت البداية مؤقتًا عبر --dart-define.
  static const bool splashSoundEnabled = bool.fromEnvironment(
    'SPLASH_SOUND_ENABLED',
    defaultValue: true,
  );

  /// Reflects the files that actually exist in assets/sounds.
  static const Set<String> availableSounds = {
    'birds_distant.m4a',
    'exhale.m4a',
    'fireplace_crackle.m4a',
    'flute_dawn.m4a',
    'garden_birds.m4a',
    'harp_soft.m4a',
    'inhale.m4a',
    'nabd_pulse.m4a',
    'night_crickets.m4a',
    'ocean_soft.m4a',
    'oud_soft.m4a',
    'paper_turn.m4a',
    'rain_soft.m4a',
    'silent_river_water.m4a',
    'splash_breath.m4a',
    'splash_chime.m4a',
    'splash_heart_bowl.m4a',
    'splash_kalimba.m4a',
    'tibetan_bowl.m4a',
    'ui_bloom.m4a',
    'ui_drop.m4a',
    'wind_gentle.m4a',
  };

  /// True when the given asset file name (with extension) is bundled.
  static bool hasSoundFile(String fileName) =>
      availableSounds.contains(fileName);

  /// Resolves a bare sound id to a bundled file. Every bundled sound is now a
  /// synthesised m4a; mp3 and wav are still accepted for older stored ids.
  static String? resolveSoundFile(String soundId) {
    for (final ext in const ['.m4a', '.mp3', '.wav']) {
      if (availableSounds.contains('$soundId$ext')) return '$soundId$ext';
    }
    return null;
  }

  static String fallbackSound(String requested) {
    return resolveSoundFile(requested) != null ? requested : 'rain_soft';
  }
}
