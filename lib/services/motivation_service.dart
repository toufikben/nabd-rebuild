import 'package:hive_flutter/hive_flutter.dart';

import '../core/l10n/app_strings.dart';

import '../core/streak.dart';
import '../models/journal_entry.dart';
import '../core/storage.dart';

/// MotivationService — الاقتباسات + الإنجازات + التحديات.
class MotivationService {
  /// The quote library: `quote.<n>.text|author` in every language's
  /// string table, so each language reads the same 15 quotes in its own words.
  static const quoteCount = 15;

  static (String, String) _quote(String languageCode, int n) {
    final table = S.of(languageCode);
    return (
      table['quote.$n.text'] ?? S.en['quote.$n.text']!,
      table['quote.$n.author'] ?? S.en['quote.$n.author']!,
    );
  }

  /// Today's quote (stable for the day) in [languageCode]. Screens that
  /// show a quote of the day on the same visit pass different [offset]s so
  /// they do not all repeat the same one.
  static (String, String) getTodayQuoteFor(String languageCode,
      {int offset = 0}) {
    final day = DateTime.now().difference(DateTime(2025)).inDays;
    return _quote(languageCode, (day + offset) % quoteCount + 1);
  }

  /// Offsets per screen for [getTodayQuoteFor].
  static const motivationOffset = 7;
  static const wisdomOffset = 19;

  /// A random quote in [languageCode], not the one shown, if asked.
  static (String, String) getRandomQuoteFor(String languageCode,
      {String? excludingQuote}) {
    final start = DateTime.now().microsecondsSinceEpoch % quoteCount;
    for (var offset = 0; offset < quoteCount; offset++) {
      final candidate = _quote(languageCode, (start + offset) % quoteCount + 1);
      if (candidate.$1 != excludingQuote) return candidate;
    }
    return _quote(languageCode, start + 1);
  }

  static (String, String) getTodayQuote() => getTodayQuoteFor('en');

  static (String, String) getRandomQuote() => getRandomQuoteFor('en');

  static (String, String) getTodayQuoteArabic() => getTodayQuoteFor('ar');

  static (String, String) getRandomQuoteArabic({String? excludingQuote}) =>
      getRandomQuoteFor('ar', excludingQuote: excludingQuote);
}

/// Achievement — إنجاز يفتحه المستخدم.
class Achievement {
  final String id;
  final String emoji;
  final int requirement;
  final String requirementType;

  /// Title and description in [languageCode]
  /// (`achievement.<id>.title|description`), falling back to English.
  String titleFor(String languageCode) =>
      S.of(languageCode)['achievement.$id.title'] ??
      S.en['achievement.$id.title']!;
  String descriptionFor(String languageCode) =>
      S.of(languageCode)['achievement.$id.description'] ??
      S.en['achievement.$id.description']!;

  String get titleEn => titleFor('en');
  String get titleAr => titleFor('ar');

  /// The achievement with [id], or null when the id is unknown — a seed that
  /// names an achievement this build no longer has still loads.
  static Achievement? getById(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  const Achievement({
    required this.id,
    required this.emoji,
    required this.requirement,
    required this.requirementType,
  });

  static const all = [
    Achievement(
      id: 'first_entry',
      emoji: '🌱',
      requirement: 1,
      requirementType: 'entries',
    ),
    Achievement(
      id: 'seven_entries',
      emoji: '🌿',
      requirement: 7,
      requirementType: 'entries',
    ),
    Achievement(
      id: 'thirty_entries',
      emoji: '🌳',
      requirement: 30,
      requirementType: 'entries',
    ),
    Achievement(
      id: 'streak_3',
      emoji: '🔥',
      requirement: 3,
      requirementType: 'streak',
    ),
    Achievement(
      id: 'streak_7',
      emoji: '⭐',
      requirement: 7,
      requirementType: 'streak',
    ),
    Achievement(
      id: 'streak_30',
      emoji: '🏆',
      requirement: 30,
      requirementType: 'streak',
    ),
    Achievement(
      id: 'words_1000',
      emoji: '✍️',
      requirement: 1000,
      requirementType: 'words',
    ),
    Achievement(
      id: 'words_10000',
      emoji: '📚',
      requirement: 10000,
      requirementType: 'words',
    ),
    Achievement(
      id: 'moods_variety',
      emoji: '🎨',
      requirement: 10,
      requirementType: 'moods',
    ),
    Achievement(
      id: 'gratitude_7',
      emoji: '🙏',
      requirement: 7,
      requirementType: 'gratitude',
    ),
  ];
}

/// AchievementService — فحص الإنجازات المفتوحة.
class AchievementService {
  Box get _box => contentBox();

  Set<String> get unlockedIds {
    final raw =
        _box.get('unlocked_achievements', defaultValue: <dynamic>[]) as List;
    return raw.map((e) => e.toString()).toSet();
  }

  /// فحص الإنجازات الجديدة.
  List<Achievement> checkNew({
    required int entries,
    required int streak,
    required int words,
    required int moods,
    required int gratitudeDays,
  }) {
    final unlocked = unlockedIds;
    final newOnes = <Achievement>[];

    for (final a in Achievement.all) {
      if (unlocked.contains(a.id)) continue;

      bool ok = false;
      switch (a.requirementType) {
        case 'entries':
          ok = entries >= a.requirement;
          break;
        case 'streak':
          ok = streak >= a.requirement;
          break;
        case 'words':
          ok = words >= a.requirement;
          break;
        case 'moods':
          ok = moods >= a.requirement;
          break;
        case 'gratitude':
          ok = gratitudeDays >= a.requirement;
          break;
      }

      if (ok) newOnes.add(a);
    }

    return newOnes;
  }

  Future<void> unlock(Achievement a) async {
    final ids = unlockedIds..add(a.id);
    await _box.put('unlocked_achievements', ids.toList());
  }

  /// Distinct gratitude journal days saved in [box]. The garden stores its
  /// flowers under the same `gratitude_` prefix, so only day-shaped keys with
  /// at least one non-empty line count.
  static int gratitudeDayCount(Box box) {
    var days = 0;
    for (final key in box.keys) {
      final name = key.toString();
      if (!name.startsWith('gratitude_')) continue;
      final date = _journalDateFromKey(name);
      if (date == null) continue;
      final raw = box.get(key);
      if (raw is! Iterable) continue;
      final hasText = raw.any((item) => item?.toString().trim().isNotEmpty ?? false);
      if (hasText) days++;
    }
    return days;
  }

  /// `gratitude_<y>_<m>_<d>` stands for a journal day; anything else in the
  /// same prefix belongs to the garden or to an older writer. The parts are
  /// checked against the date they build because `DateTime.parse` happily
  /// rolls an impossible day like `2026-9-31` into the next month.
  static DateTime? _journalDateFromKey(String key) {
    final parts = key.split('_');
    if (parts.length != 4) return null;
    final year = int.tryParse(parts[1]);
    final month = int.tryParse(parts[2]);
    final day = int.tryParse(parts[3]);
    if (year == null || month == null || day == null) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) return null;
    return date;
  }

  /// The progress numbers every achievement is judged on, from the journal as
  /// it is now. The streak is the longest run ever, so a past week of writing
  /// is never "un-earned" by a missed day.
  static Map<String, int> progressFor(List<JournalEntry> entries, Box settings) {
    return {
      'entries': entries.length,
      'streak': StreakCalculator.longest(entries.map((e) => e.createdAt)),
      'words': entries.fold<int>(
        0,
        (sum, e) => sum +
            (e.content.trim().isEmpty
                ? 0
                : e.content.trim().split(RegExp(r'\s+')).length),
      ),
      'moods': entries
          .map((e) => e.mood)
          .where((m) => m.isNotEmpty)
          .toSet()
          .length,
      'gratitude': gratitudeDayCount(settings),
    };
  }

  /// Unlocks whatever the journal now qualifies for. The single caller-facing
  /// entry point, used after a save and when the achievements screen opens.
  Future<List<Achievement>> unlockFromJournal(
    List<JournalEntry> entries,
    Box settings,
  ) {
    final progress = progressFor(entries, settings);
    return unlockEligible(
      entries: progress['entries']!,
      streak: progress['streak']!,
      words: progress['words']!,
      moods: progress['moods']!,
      gratitudeDays: progress['gratitude']!,
    );
  }

  /// Unlocks every achievement the stats qualify for and returns the new ones.
  Future<List<Achievement>> unlockEligible({
    required int entries,
    required int streak,
    required int words,
    required int moods,
    required int gratitudeDays,
  }) async {
    final fresh = checkNew(
      entries: entries,
      streak: streak,
      words: words,
      moods: moods,
      gratitudeDays: gratitudeDays,
    );
    for (final achievement in fresh) {
      await unlock(achievement);
    }
    return fresh;
  }
}
