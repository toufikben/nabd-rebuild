import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/features/worry/worry_box_screen.dart';

void main() {
  group('a worry is reviewed the next day, not 24 hours later', () {
    test('a worry saved at 23:00 is one day away, not zero', () {
      final saved = DateTime(2026, 9, 5, 23, 0);
      final review = DateTime(2026, 9, 6);

      // The defect this replaces: reviewDate was `now + 1 day`, so at 23:00
      // the card read "0 days left" and the worry looked reviewable at once.
      expect(worryDaysUntil(review, saved), 1);
    });

    test('it is reviewable from midnight', () {
      expect(worryDaysUntil(DateTime(2026, 9, 6), DateTime(2026, 9, 6, 0, 0)),
          0);
      expect(worryDaysUntil(DateTime(2026, 9, 6), DateTime(2026, 9, 6, 23, 59)),
          0);
    });

    test('the day before it is still sealed', () {
      expect(worryDaysUntil(DateTime(2026, 9, 6), DateTime(2026, 9, 5, 12)),
          1);
    });

    test('a later day counts the calendar days in between', () {
      expect(worryDaysUntil(DateTime(2026, 9, 9), DateTime(2026, 9, 5, 8)), 4);
    });

    test('an overdue worry never reads negative', () {
      expect(worryDaysUntil(DateTime(2026, 9, 1), DateTime(2026, 9, 5)), -4);
    });
  });
}
