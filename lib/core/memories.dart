import '../models/journal_entry.dart';

/// How far back a memory is: a month, six months, or a number of years.
class MemoryAge {
  const MemoryAge.months(this.months) : years = 0;
  const MemoryAge.years(this.years) : months = 0;

  final int months;
  final int years;

  /// The string key that names this age (see `memories.*` in app_strings).
  String get labelKey {
    if (years == 0) return months == 1 ? 'memories.1m' : 'memories.6m';
    if (years == 1) return 'memories.1y';
    if (years == 2) return 'memories.2y';
    return 'memories.ny';
  }

  @override
  bool operator ==(Object other) =>
      other is MemoryAge && other.months == months && other.years == years;

  @override
  int get hashCode => Object.hash(months, years);
}

class Memory {
  const Memory(this.age, this.entry);
  final MemoryAge age;
  final JournalEntry entry;
}

/// "On this day": entries written on today's calendar date one month, six
/// months, or whole years ago. Matching is by local calendar date, so a
/// late-night entry counts for the day it was written on. Dates that do not
/// exist in the earlier month (31 March → 31 February) are skipped rather
/// than shifted, so a memory is always exactly the same date.
class Memories {
  static List<Memory> onThisDay(Iterable<JournalEntry> entries, DateTime now) {
    final byDay = <(int, int, int), List<JournalEntry>>{};
    for (final entry in entries) {
      final d = entry.createdAt.toLocal();
      byDay.putIfAbsent((d.year, d.month, d.day), () => []).add(entry);
    }
    final today = now.toLocal();
    final memories = <Memory>[];

    void collect(MemoryAge age, int year, int month) {
      final shifted = DateTime(year, month, today.day);
      if (shifted.month != ((month - 1) % 12 + 12) % 12 + 1) return;
      final found = byDay[(shifted.year, shifted.month, shifted.day)];
      if (found == null) return;
      found.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      memories.addAll(found.map((e) => Memory(age, e)));
    }

    collect(const MemoryAge.months(1), today.year, today.month - 1);
    collect(const MemoryAge.months(6), today.year, today.month - 6);
    for (var years = 1; years <= 10; years++) {
      collect(MemoryAge.years(years), today.year - years, today.month);
    }
    return memories;
  }
}
