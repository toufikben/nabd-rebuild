/// The thinking behind the smart daily reminder. Pure functions, computed on
/// the phone from entry timestamps only, so they are easy to test and nothing
/// ever leaves the device.
class SmartReminder {
  const SmartReminder._();

  /// How far back the writing habit is read.
  static const lookback = Duration(days: 60);

  /// Fewer entries than this say nothing reliable about a habit.
  static const minimumEntries = 5;

  /// Reminders planned ahead. The plan is renewed on every launch and every
  /// time the app goes to the background, so this only matters for someone
  /// who stops opening the app, and then two weeks of reminders is plenty.
  static const planDays = 14;

  /// The reminder time that fits when this person usually writes: a quarter
  /// of an hour before the busiest half hour of the last [lookback], with
  /// each half hour also counting its neighbours so a habit that straddles
  /// a boundary is not split in two. Null until there is enough history.
  static ({int hour, int minute})? suggestTime(
    Iterable<DateTime> writtenAt, {
    required DateTime now,
  }) {
    final since = now.subtract(lookback);
    final slots = List<int>.filled(48, 0);
    var total = 0;
    for (final time in writtenAt) {
      if (time.isBefore(since) || time.isAfter(now)) continue;
      slots[time.hour * 2 + time.minute ~/ 30]++;
      total++;
    }
    if (total < minimumEntries) return null;

    var best = 0;
    var bestScore = -1;
    for (var slot = 0; slot < 48; slot++) {
      final score =
          slots[(slot + 47) % 48] + 2 * slots[slot] + slots[(slot + 1) % 48];
      if (score > bestScore) {
        best = slot;
        bestScore = score;
      }
    }
    final minutes = (best * 30 - 15 + 24 * 60) % (24 * 60);
    return (hour: minutes ~/ 60, minute: minutes % 60);
  }

  /// The moments to remind, one a day at [hour]:[minute] for [planDays]
  /// days, skipping today if something was already written today or the
  /// time has passed. A day with an entry never gets a nudge.
  static List<DateTime> plan({
    required int hour,
    required int minute,
    required Iterable<DateTime> writtenAt,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final wroteToday = writtenAt.any((t) =>
        t.year == today.year && t.month == today.month && t.day == today.day);
    return [
      for (var day = 0; day < planDays; day++)
        if (!(day == 0 && wroteToday))
          DateTime(today.year, today.month, today.day + day, hour, minute),
    ].where((when) => when.isAfter(now)).toList();
  }
}
