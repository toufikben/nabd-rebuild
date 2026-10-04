import '../models/journal_entry.dart';
import '../models/mood.dart';

enum DayPart { morning, afternoon, evening, night }

DayPart dayPartOf(DateTime when) {
  final hour = when.toLocal().hour;
  if (hour >= 5 && hour < 12) return DayPart.morning;
  if (hour >= 12 && hour < 17) return DayPart.afternoon;
  if (hour >= 17 && hour < 22) return DayPart.evening;
  return DayPart.night;
}

/// An average mood score (1–10) over [count] entries.
class MoodAverage {
  const MoodAverage(this.average, this.count);
  final double average;
  final int count;
}

class TagEffect {
  const TagEffect(this.tag, this.average, this.difference, this.count);
  final String tag;
  final double average;

  /// How far this tag's average sits from the overall one (positive = better).
  final double difference;
  final int count;
}

/// When and around what the writer tends to feel better or worse, computed
/// on the phone from the moods already chosen on entries. Nothing is shown
/// until there is enough to say something honest: [minEntries] scored
/// entries overall, and [minPerGroup] in any day, time or tag that is named.
class MoodPatterns {
  MoodPatterns._(this.overall, this.byWeekday, this.byDayPart, this.tags);

  static const minEntries = 7;
  static const minPerGroup = 2;
  static const minPerTag = 3;

  final MoodAverage overall;
  final Map<int, MoodAverage> byWeekday; // DateTime.monday..sunday
  final Map<DayPart, MoodAverage> byDayPart;
  final List<TagEffect> tags; // strongest effect first

  bool get hasEnough => overall.count >= minEntries;

  /// The weekday with the highest / lowest average, among days with enough
  /// entries; null when no day stands out by at least half a point.
  int? get calmestWeekday => _extreme(byWeekday, best: true);
  int? get hardestWeekday => _extreme(byWeekday, best: false);
  DayPart? get calmestDayPart => _extreme(byDayPart, best: true);
  DayPart? get hardestDayPart => _extreme(byDayPart, best: false);

  K? _extreme<K>(Map<K, MoodAverage> groups, {required bool best}) {
    final eligible =
        groups.entries.where((e) => e.value.count >= minPerGroup).toList();
    if (eligible.length < 2) return null;
    eligible.sort((a, b) => a.value.average.compareTo(b.value.average));
    final pick = best ? eligible.last : eligible.first;
    final gap = (pick.value.average - overall.average).abs();
    return gap >= 0.5 ? pick.key : null;
  }

  static MoodPatterns compute(Iterable<JournalEntry> entries) {
    final scored = <(JournalEntry, int)>[];
    for (final entry in entries) {
      final mood = Mood.getById(entry.mood);
      if (mood != null) scored.add((entry, mood.value));
    }
    MoodAverage averageOf(Iterable<int> values) {
      final list = values.toList();
      if (list.isEmpty) return const MoodAverage(0, 0);
      return MoodAverage(list.reduce((a, b) => a + b) / list.length, list.length);
    }

    final overall = averageOf(scored.map((s) => s.$2));
    final weekdays = <int, List<int>>{};
    final parts = <DayPart, List<int>>{};
    final tags = <String, List<int>>{};
    for (final (entry, value) in scored) {
      final local = entry.createdAt.toLocal();
      weekdays.putIfAbsent(local.weekday, () => []).add(value);
      parts.putIfAbsent(dayPartOf(local), () => []).add(value);
      for (final tag in entry.tags.toSet()) {
        tags.putIfAbsent(tag, () => []).add(value);
      }
    }
    final tagEffects = [
      for (final MapEntry(key: tag, value: values) in tags.entries)
        if (values.length >= minPerTag)
          TagEffect(tag, averageOf(values).average,
              averageOf(values).average - overall.average, values.length),
    ]
      ..removeWhere((t) => t.difference.abs() < 0.5)
      ..sort((a, b) => b.difference.abs().compareTo(a.difference.abs()));

    return MoodPatterns._(
      overall,
      weekdays.map((k, v) => MapEntry(k, averageOf(v))),
      parts.map((k, v) => MapEntry(k, averageOf(v))),
      tagEffects.take(3).toList(),
    );
  }
}
