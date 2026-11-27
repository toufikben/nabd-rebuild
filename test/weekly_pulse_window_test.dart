import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/r_personal_service.dart';

void main() {
  group('weeklyPulseWindow', () {
    // A weekly Pulse covers the last week that has fully ended. Weeks end on
    // Sunday, so asking on any of the seven days must return a finished week,
    // never one that is still being written and never an empty result.
    test('a Monday looks back at the week that ended yesterday', () {
      final (start, end) = weeklyPulseWindow(DateTime(2026, 11, 23)); // Monday
      expect(end, DateTime(2026, 11, 22)); // Sunday
      expect(start, DateTime(2026, 11, 16));
      expect(end.difference(start).inDays, 6);
    });

    test('a Sunday reports the week before, not the one being written', () {
      final (start, end) = weeklyPulseWindow(DateTime(2026, 11, 22)); // Sunday
      expect(end, DateTime(2026, 11, 15));
      expect(start, DateTime(2026, 11, 9));
    });

    test('every day of the week returns a complete finished week', () {
      // 2026-11-22 is a Sunday; walk the whole following week.
      for (var i = 0; i < 7; i++) {
        final day = DateTime(2026, 11, 22 + i);
        final (start, end) = weeklyPulseWindow(day);
        expect(end.weekday, DateTime.sunday, reason: 'on $day');
        expect(end.difference(start).inDays, 6, reason: 'on $day');
        expect(
          end.isBefore(day),
          isTrue,
          reason: 'on $day the week must already be over, got $end',
        );
      }
    });

    test('the window is the same all week until the next Sunday passes', () {
      final monday = weeklyPulseWindow(DateTime(2026, 11, 23));
      final saturday = weeklyPulseWindow(DateTime(2026, 11, 28));
      expect(monday, saturday);
    });

    test('time of day does not shift the window', () {
      final early = weeklyPulseWindow(DateTime(2026, 11, 23, 0, 1));
      final late = weeklyPulseWindow(DateTime(2026, 11, 23, 23, 59));
      expect(early, late);
    });
  });
}
