import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/smart_reminder.dart';

void main() {
  final now = DateTime(2026, 10, 4, 12);

  group('suggestTime', () {
    test('stays silent until there is a habit to read', () {
      final few = [for (var d = 1; d <= 4; d++) DateTime(2026, 10, 4 - d, 22, 10)];
      expect(SmartReminder.suggestTime(few, now: now), isNull);
    });

    test('lands a quarter hour before the usual writing time', () {
      final evenings = [
        for (var d = 1; d <= 10; d++) DateTime(2026, 10, 4 - d, 22, 5 + d),
        DateTime(2026, 9, 30, 8, 0), // a stray morning entry
      ];
      final time = SmartReminder.suggestTime(evenings, now: now)!;
      expect((time.hour, time.minute), (21, 45));
    });

    test('ignores entries older than the look-back window', () {
      final old = [for (var d = 0; d < 10; d++) DateTime(2026, 6, 1 + d, 7)];
      final recent = [for (var d = 1; d <= 6; d++) DateTime(2026, 10, 4 - d, 19, 40)];
      final time = SmartReminder.suggestTime([...old, ...recent], now: now)!;
      expect((time.hour, time.minute), (19, 15));
    });

    test('wraps around midnight', () {
      final late = [for (var d = 1; d <= 6; d++) DateTime(2026, 10, 4 - d, 0, 10)];
      final time = SmartReminder.suggestTime(late, now: now)!;
      expect((time.hour, time.minute), (23, 45));
    });
  });

  group('plan', () {
    test('skips today when something was already written', () {
      final plan = SmartReminder.plan(
        hour: 20,
        minute: 0,
        writtenAt: [DateTime(2026, 10, 4, 9)],
        now: now,
      );
      expect(plan.first, DateTime(2026, 10, 5, 20));
      expect(plan, hasLength(SmartReminder.planDays - 1));
    });

    test('keeps today when nothing is written yet', () {
      final plan = SmartReminder.plan(
          hour: 20, minute: 0, writtenAt: const [], now: now);
      expect(plan.first, DateTime(2026, 10, 4, 20));
      expect(plan, hasLength(SmartReminder.planDays));
    });

    test('drops today once the time has passed', () {
      final plan = SmartReminder.plan(
          hour: 8, minute: 0, writtenAt: const [], now: now);
      expect(plan.first, DateTime(2026, 10, 5, 8));
    });
  });
}
