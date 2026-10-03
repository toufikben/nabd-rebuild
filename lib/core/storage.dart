import 'package:hive_flutter/hive_flutter.dart';

/// Every encrypted Hive box the app owns. Encryption, migration, key
/// rotation, Delete All and backup all walk this one list, so a new box can
/// never be forgotten by one of them.
class HiveBoxes {
  const HiveBoxes._();

  static const journal = 'journal_entries';
  static const settings = 'settings';
  static const moods = 'moods';
  static const tags = 'tags';
  static const garden = 'garden';

  /// Everything the user wrote or earned outside the journal itself:
  /// letters, worries, gratitude, achievements and the like.
  static const content = 'content';

  static const all = <String>[journal, settings, moods, tags, garden, content];
}

/// Keys of user-authored data. They used to live in the settings box, which
/// made a backup merge overwrite them along with the theme and language.
class ContentKeys {
  const ContentKeys._();

  static const futureLetters = 'future_letters';
  static const unsentLetters = 'unsent_letters';
  static const timeCapsules = 'time_capsules';
  static const legacyEntries = 'legacy_entries';
  static const gratitudeItems = 'gratitude_items';
  static const worryBox = 'worry_box';
  static const unlockedAchievements = 'unlocked_achievements';
  static const joinedChallenges = 'joined_challenges';
  static const echoResolutions = 'echo_resolutions';
  static const sessionsCompleted = 'sessions_completed_total';
  static const wisdom = 'wisdom_state';

  /// Day keys of the gratitude journal (`gratitude_<y>_<m>_<d>`) and the
  /// weekly pulse snapshots.
  static const gratitudeDayPrefix = 'gratitude_';
  static const weeklyPulsePrefix = 'weekly_pulse_';

  static const exact = <String>{
    futureLetters,
    unsentLetters,
    timeCapsules,
    legacyEntries,
    gratitudeItems,
    worryBox,
    unlockedAchievements,
    joinedChallenges,
    echoResolutions,
    sessionsCompleted,
    wisdom,
  };

  static bool isContentKey(String key) =>
      exact.contains(key) ||
      key.startsWith(gratitudeDayPrefix) ||
      key.startsWith(weeklyPulsePrefix);
}

Box contentBox() => Hive.box(HiveBoxes.content);

/// Moves user content out of the settings box, once. Copies first and only
/// then deletes, so an interruption can at worst leave a duplicate that the
/// next launch finishes moving.
class ContentBoxMigration {
  const ContentBoxMigration._();

  static Future<int> run({required Box settings, required Box content}) async {
    final keys = settings.keys
        .map((key) => key.toString())
        .where(ContentKeys.isContentKey)
        .toList();
    if (keys.isEmpty) return 0;
    for (final key in keys) {
      // Content already in the new box wins: it was written after a move.
      if (!content.containsKey(key)) {
        await content.put(key, settings.get(key));
      }
    }
    await content.flush();
    await settings.deleteAll(keys);
    return keys.length;
  }
}
