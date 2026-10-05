import '../models/journal_entry.dart';
import '../models/mood.dart';

/// One calendar month of the journal, boiled down. Pure, so it is tested
/// directly and computed on the phone only.
class MonthlySummary {
  MonthlySummary._({
    required this.month,
    required this.entries,
    required this.words,
    required this.daysWritten,
    required this.daysInMonth,
    required this.longestStreak,
    required this.averageMood,
    required this.previousAverageMood,
    required this.topMoods,
    required this.topTags,
    required this.dailyMood,
    required this.brightest,
  });

  /// The first day of the month.
  final DateTime month;
  final int entries;
  final int words;
  final int daysWritten;
  final int daysInMonth;

  /// Longest run of consecutive days with an entry inside the month.
  final int longestStreak;

  /// Mean mood value (1–10) of entries with a known mood, or null.
  final double? averageMood;
  final double? previousAverageMood;

  /// Most frequent moods, most frequent first, with their counts.
  final List<(Mood, int)> topMoods;
  final List<(String, int)> topTags;

  /// Average mood per day of the month (index 0 is the 1st); null when the
  /// day has no entry with a known mood.
  final List<double?> dailyMood;

  /// The entry with the best mood, the most recent on a tie.
  final JournalEntry? brightest;

  bool get isEmpty => entries == 0;

  /// Mood compared with the month before: positive is lighter. Null when
  /// either month has no mood to compare.
  double? get moodChange => averageMood == null || previousAverageMood == null
      ? null
      : averageMood! - previousAverageMood!;

  static DateTime _monthStart(DateTime d) => DateTime(d.year, d.month);

  static bool _inMonth(DateTime t, DateTime month) =>
      t.year == month.year && t.month == month.month;

  static double? _average(Iterable<JournalEntry> entries) {
    final values = [
      for (final e in entries)
        if (Mood.getById(e.mood) case final mood?) mood.value,
    ];
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static int _wordsIn(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
  }

  static MonthlySummary compute(Iterable<JournalEntry> all, DateTime anyDay) {
    final month = _monthStart(anyDay);
    final previous = DateTime(month.year, month.month - 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final inMonth = all.where((e) => !e.isDream && _inMonth(e.createdAt, month))
        .toList();
    final inPrevious =
        all.where((e) => !e.isDream && _inMonth(e.createdAt, previous));

    final days = <int>{for (final e in inMonth) e.createdAt.day};
    var longest = 0;
    var run = 0;
    for (var day = 1; day <= daysInMonth; day++) {
      run = days.contains(day) ? run + 1 : 0;
      if (run > longest) longest = run;
    }

    final moodCounts = <String, int>{};
    final tagCounts = <String, int>{};
    for (final e in inMonth) {
      if (Mood.getById(e.mood) != null) {
        moodCounts[e.mood] = (moodCounts[e.mood] ?? 0) + 1;
      }
      for (final tag in e.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    List<(String, int)> top(Map<String, int> counts) {
      final list = counts.entries.toList()
        ..sort((a, b) => b.value != a.value
            ? b.value.compareTo(a.value)
            : a.key.compareTo(b.key));
      return [for (final e in list.take(3)) (e.key, e.value)];
    }

    JournalEntry? brightest;
    var best = -1;
    for (final e in inMonth) {
      final value = Mood.getById(e.mood)?.value ?? -1;
      if (brightest == null ||
          value > best ||
          (value == best && e.createdAt.isAfter(brightest.createdAt))) {
        best = value;
        brightest = e;
      }
    }

    return MonthlySummary._(
      month: month,
      entries: inMonth.length,
      words: inMonth.fold(0, (sum, e) => sum + _wordsIn(e.content)),
      daysWritten: days.length,
      daysInMonth: daysInMonth,
      longestStreak: longest,
      averageMood: _average(inMonth),
      previousAverageMood: _average(inPrevious),
      topMoods: [
        for (final (id, count) in top(moodCounts)) (Mood.getById(id)!, count),
      ],
      topTags: top(tagCounts),
      dailyMood: [
        for (var day = 1; day <= daysInMonth; day++)
          _average(inMonth.where((e) => e.createdAt.day == day)),
      ],
      brightest: best > 0 ? brightest : null,
    );
  }

  /// Whether Today should offer last month's summary: during the first week
  /// of a month, when last month has entries.
  static bool offerLastMonth(Iterable<JournalEntry> all, DateTime now) {
    if (now.day > 7) return false;
    final last = DateTime(now.year, now.month - 1);
    return all.any((e) => !e.isDream && _inMonth(e.createdAt, last));
  }
}
