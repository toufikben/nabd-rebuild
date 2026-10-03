/// The one definition of a writing streak, shared by every screen.
///
/// Days are compared as UTC calendar dates, so a daylight-saving change (a
/// 23 or 25 hour day) can never split or merge two days. A streak stays alive
/// through today: until the user writes, it counts back from yesterday rather
/// than dropping to zero every morning.
class StreakCalculator {
  const StreakCalculator._();

  /// The calendar day of [moment] in local time, as a UTC midnight.
  static DateTime dayOf(DateTime moment) =>
      DateTime.utc(moment.year, moment.month, moment.day);

  static Set<DateTime> daysOf(Iterable<DateTime> moments) =>
      moments.map(dayOf).toSet();

  /// Consecutive days with writing, ending today or, before today's entry,
  /// yesterday.
  static int current(Iterable<DateTime> moments, {DateTime? now}) {
    final days = daysOf(moments);
    if (days.isEmpty) return 0;
    var day = dayOf(now ?? DateTime.now());
    if (!days.contains(day)) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Whether today already has writing, so the UI can tell "keep it going"
  /// apart from "done for today".
  static bool wroteToday(Iterable<DateTime> moments, {DateTime? now}) =>
      daysOf(moments).contains(dayOf(now ?? DateTime.now()));

  /// The longest run of consecutive days ever.
  static int longest(Iterable<DateTime> moments) {
    final days = daysOf(moments).toList()..sort();
    if (days.isEmpty) return 0;
    var longest = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }
    return longest;
  }
}
