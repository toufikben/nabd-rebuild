import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/mood_patterns.dart';
import 'package:nabd/models/journal_entry.dart';

JournalEntry _entry(DateTime when, String mood, [List<String> tags = const []]) =>
    JournalEntry(
      title: '',
      content: '',
      createdAt: when,
      updatedAt: when,
      mood: mood,
      tags: tags,
    );

void main() {
  // 2026-10-02 is a Friday, 2026-10-05 a Monday.
  final friday = DateTime(2026, 10, 2);
  final monday = DateTime(2026, 10, 5);

  test('says nothing until there are enough scored entries', () {
    final patterns = MoodPatterns.compute([
      for (var i = 0; i < 6; i++) _entry(friday.add(Duration(hours: 9 + i)), 'happy'),
      _entry(friday, ''), // no mood: not counted
    ]);
    expect(patterns.overall.count, 6);
    expect(patterns.hasEnough, isFalse);
  });

  test('finds the calmest and hardest weekday and time of day', () {
    final entries = [
      for (var w = 0; w < 3; w++) ...[
        _entry(friday.add(Duration(days: 7 * w, hours: 9)), 'peaceful'), // 8
        _entry(monday.add(Duration(days: 7 * w, hours: 23)), 'anxious'), // 3
      ],
      _entry(friday.add(const Duration(hours: 10)), 'happy'), // 9
    ];
    final patterns = MoodPatterns.compute(entries);
    expect(patterns.hasEnough, isTrue);
    expect(patterns.calmestWeekday, DateTime.friday);
    expect(patterns.hardestWeekday, DateTime.monday);
    expect(patterns.calmestDayPart, DayPart.morning);
    expect(patterns.hardestDayPart, DayPart.night);
  });

  test('a day with a single entry is never named', () {
    final entries = [
      for (var i = 0; i < 8; i++) _entry(friday.add(Duration(days: 7 * i)), 'okay'),
      _entry(monday, 'sad'),
    ];
    final patterns = MoodPatterns.compute(entries);
    expect(patterns.hardestWeekday, isNull);
  });

  test('tags that move the mood, strongest first, need three entries', () {
    final entries = [
      for (var i = 0; i < 3; i++) _entry(friday.add(Duration(days: i)), 'happy', ['family']),
      for (var i = 0; i < 3; i++) _entry(monday.add(Duration(days: i)), 'sad', ['work']),
      for (var i = 0; i < 2; i++) _entry(monday.add(Duration(days: 10 + i)), 'angry', ['traffic']),
      _entry(friday, 'okay'),
    ];
    final patterns = MoodPatterns.compute(entries);
    expect(patterns.tags.map((t) => t.tag), containsAll(['family', 'work']));
    expect(patterns.tags.map((t) => t.tag), isNot(contains('traffic')));
    final family = patterns.tags.firstWhere((t) => t.tag == 'family');
    expect(family.difference, greaterThan(0));
  });

  test('day parts follow the clock', () {
    expect(dayPartOf(DateTime(2026, 1, 1, 5)), DayPart.morning);
    expect(dayPartOf(DateTime(2026, 1, 1, 12)), DayPart.afternoon);
    expect(dayPartOf(DateTime(2026, 1, 1, 17)), DayPart.evening);
    expect(dayPartOf(DateTime(2026, 1, 1, 22)), DayPart.night);
    expect(dayPartOf(DateTime(2026, 1, 1, 4, 59)), DayPart.night);
  });
}
