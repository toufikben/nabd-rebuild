import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/models/journal_entry.dart';
import 'package:nabd/services/motivation_service.dart';
import 'package:nabd/services/r_personal_service.dart';

JournalEntry _entry({
  required String id,
  required DateTime createdAt,
  required String mood,
}) {
  return JournalEntry(
    id: id,
    title: id,
    content: id,
    createdAt: createdAt,
    updatedAt: createdAt,
    mood: mood,
  );
}

void main() {
  group('R-Personal', () {
    test('resolves only within the exact three-to-ninety-day Duration window',
        () {
      final originalDate = DateTime(2026, 1, 1, 12);
      final entries = [
        _entry(id: 'original', createdAt: originalDate, mood: 'sad'),
        _entry(
          id: 'too-early',
          createdAt: originalDate.add(const Duration(days: 2, hours: 23)),
          mood: 'happy',
        ),
        _entry(
          id: 'too-late',
          createdAt: originalDate.add(const Duration(days: 90, hours: 1)),
          mood: 'happy',
        ),
      ];

      final echoes = RPersonalService.calculateEchoes(entries);
      expect(echoes, hasLength(1));
      expect(echoes.single.resolution, isNull);
    });

    test('accepts exact three-day and ninety-day positive entries', () {
      final originalDate = DateTime(2026, 1, 1, 12);
      final entries = [
        _entry(id: 'original', createdAt: originalDate, mood: 'sad'),
        _entry(
          id: 'three-days',
          createdAt: originalDate.add(const Duration(days: 3)),
          mood: 'happy',
        ),
        _entry(
          id: 'ninety-days',
          createdAt: originalDate.add(const Duration(days: 90)),
          mood: 'peaceful',
        ),
      ];

      final echoes = RPersonalService.calculateEchoes(entries);
      expect(echoes.single.resolution?.id, 'three-days');
    });

    test('Sage refresh excludes the currently displayed quote', () {
      final current = MotivationService.getTodayQuoteArabic();
      final refreshed = MotivationService.getRandomQuoteArabic(
        excludingQuote: current.$1,
      );
      expect(refreshed.$1, isNot(current.$1));
    });
  });
}
