import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/monthly_summary.dart';
import 'package:nabd/models/journal_entry.dart';

JournalEntry _entry(DateTime at, {String mood = '', String text = 'a b c',
    List<String> tags = const [], bool dream = false}) =>
    JournalEntry(
      title: '',
      content: text,
      createdAt: at,
      updatedAt: at,
      mood: mood,
      tags: tags,
      isDream: dream,
    );

void main() {
  final entries = [
    _entry(DateTime(2026, 9, 1, 9), mood: 'sad', tags: ['work']),
    _entry(DateTime(2026, 9, 2, 9), mood: 'happy', tags: ['work', 'family']),
    _entry(DateTime(2026, 9, 3, 21), mood: 'happy', text: 'one two'),
    _entry(DateTime(2026, 9, 10, 9), mood: 'joyful', text: ''),
    _entry(DateTime(2026, 9, 11, 9), dream: true, mood: 'joyful'),
    _entry(DateTime(2026, 8, 20, 9), mood: 'sad'),
    _entry(DateTime(2026, 10, 1, 9), mood: 'happy'),
  ];

  test('counts only the month and leaves dreams out', () {
    final s = MonthlySummary.compute(entries, DateTime(2026, 9, 15));
    expect(s.entries, 4);
    expect(s.words, 3 + 3 + 2 + 0);
    expect(s.daysWritten, 4);
    expect(s.daysInMonth, 30);
    expect(s.longestStreak, 3);
  });

  test('reads moods, tags and the brightest moment', () {
    final s = MonthlySummary.compute(entries, DateTime(2026, 9, 15));
    expect(s.topMoods.first.$1.id, 'happy');
    expect(s.topMoods.first.$2, 2);
    expect(s.topTags.first, ('work', 2));
    expect(s.brightest!.createdAt, DateTime(2026, 9, 10, 9));
    expect(s.dailyMood, hasLength(30));
    expect(s.dailyMood[4], isNull);
    expect(s.moodChange, greaterThan(0));
  });

  test('an empty month is empty, not an error', () {
    final s = MonthlySummary.compute(entries, DateTime(2026, 3, 1));
    expect(s.isEmpty, isTrue);
    expect(s.averageMood, isNull);
    expect(s.brightest, isNull);
  });

  test('last month is offered only in the first week', () {
    expect(MonthlySummary.offerLastMonth(entries, DateTime(2026, 10, 3)), isTrue);
    expect(MonthlySummary.offerLastMonth(entries, DateTime(2026, 10, 9)), isFalse);
    expect(MonthlySummary.offerLastMonth(entries, DateTime(2026, 5, 2)), isFalse);
  });
}
