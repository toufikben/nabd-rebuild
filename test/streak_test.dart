import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/streak.dart';

void main() {
  final now = DateTime(2026, 10, 3, 9);

  test('no writing is no streak', () {
    expect(StreakCalculator.current(const [], now: now), 0);
    expect(StreakCalculator.longest(const []), 0);
  });

  test('counts consecutive days ending today', () {
    final days = [
      DateTime(2026, 10, 3, 8),
      DateTime(2026, 10, 2, 22),
      DateTime(2026, 10, 1, 7),
    ];
    expect(StreakCalculator.current(days, now: now), 3);
    expect(StreakCalculator.wroteToday(days, now: now), isTrue);
  });

  test('a streak survives the morning before today is written', () {
    final days = [DateTime(2026, 10, 2), DateTime(2026, 10, 1)];
    expect(StreakCalculator.current(days, now: now), 2);
    expect(StreakCalculator.wroteToday(days, now: now), isFalse);
  });

  test('a missed day ends the streak', () {
    final days = [DateTime(2026, 10, 1), DateTime(2026, 9, 30)];
    expect(StreakCalculator.current(days, now: now), 0);
  });

  test('several entries on one day count once', () {
    final days = [
      DateTime(2026, 10, 3, 8),
      DateTime(2026, 10, 3, 20),
    ];
    expect(StreakCalculator.current(days, now: now), 1);
  });

  test('daylight saving does not break a run', () {
    // Europe moves clocks on the last Sunday of March and October; a local
    // 23-hour day must still count as one step.
    final days = [
      DateTime(2026, 3, 28, 23, 30),
      DateTime(2026, 3, 29, 0, 30),
      DateTime(2026, 3, 30, 0, 10),
    ];
    expect(StreakCalculator.longest(days), 3);
  });

  test('the longest run is found anywhere in the history', () {
    final days = [
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 2),
      DateTime(2026, 1, 3),
      DateTime(2026, 1, 4),
      DateTime(2026, 2, 1),
      DateTime(2026, 2, 2),
    ];
    expect(StreakCalculator.longest(days), 4);
  });
}
