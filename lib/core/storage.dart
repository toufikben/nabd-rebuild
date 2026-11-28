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
  static const habits = 'habits';
  static const habitChecks = 'habit_checks';

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
    habits,
    habitChecks,
  };

  static bool isContentKey(String key) =>
      exact.contains(key) ||
      key.startsWith(gratitudeDayPrefix) ||
      key.startsWith(weeklyPulsePrefix);
}

Box contentBox() => Hive.box(HiveBoxes.content);

/// Reads a setting without trusting its stored type.
///
/// A box is not a schema: a backup written by an older build, a half-finished
/// write, or a value a bug put under the wrong key all arrive here. `as bool`
/// on a stored `1` throws, and the splash screen reads its settings before the
/// first frame, so one bad value there locks the writer out of the app on every
/// launch. These readers return the fallback instead and never throw.
bool readBool(Box box, String key, {required bool fallback}) {
  final raw = box.get(key);
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final text = raw.trim().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
  }
  return fallback;
}

String? readString(Box box, String key) {
  final raw = box.get(key);
  if (raw == null) return null;
  if (raw is String) return raw;
  return raw.toString();
}

/// The stored number, or [fallback] when the value is missing or not a number.
int readInt(Box box, String key, {required int fallback}) {
  final raw = box.get(key);
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim()) ?? fallback;
  return fallback;
}

/// The stored list as strings, dropping anything that is not list-shaped.
List<String> readStringList(Box box, String key) {
  final raw = box.get(key);
  if (raw is! Iterable) return <String>[];
  return [
    for (final item in raw)
      if (item != null) item.toString(),
  ];
}

/// The stored list, whatever it holds, or an empty list when the value is not
/// list-shaped. Callers that decode each item do their own type checks.
List<Object?> readList(Box box, String key) {
  final raw = box.get(key);
  if (raw is! Iterable) return <Object?>[];
  return raw.toList();
}

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

  /// Time capsules and letters to the future were the same idea kept in two
  /// places. Capsules become future letters that open on the same date.
  static Future<int> foldTimeCapsules(Box content) async {
    final capsules = content.get(ContentKeys.timeCapsules);
    if (capsules is! Iterable) return 0;
    final raw = content.get(ContentKeys.futureLetters);
    final letters = <Map<dynamic, dynamic>>[
      if (raw is Iterable) ...raw.whereType<Map>(),
    ];
    final known = letters.map((letter) => letter['id']?.toString()).toSet();
    var folded = 0;
    for (final capsule in capsules.whereType<Map>()) {
      final id = capsule['id']?.toString() ?? '';
      if (id.isEmpty || known.contains(id)) continue;
      final title = capsule['title']?.toString().trim() ?? '';
      final body = capsule['content']?.toString().trim() ?? '';
      letters.add({
        'id': id,
        'text': title.isEmpty ? body : '$title\n\n$body',
        'createdAt': capsule['createdAt'],
        'unlockDate': capsule['unlockAt'],
      });
      folded++;
    }
    await content.put(ContentKeys.futureLetters, letters);
    await content.delete(ContentKeys.timeCapsules);
    return folded;
  }
}
