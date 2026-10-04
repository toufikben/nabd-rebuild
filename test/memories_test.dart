import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/memories.dart';
import 'package:nabd/models/journal_entry.dart';

JournalEntry _at(DateTime when, [String title = 't']) => JournalEntry(
      title: title,
      content: '',
      createdAt: when,
      updatedAt: when,
    );

void main() {
  test('finds the same date a month, six months and years ago', () {
    final now = DateTime(2026, 10, 4, 9);
    final memories = Memories.onThisDay([
      _at(DateTime(2026, 9, 4, 22), 'month'),
      _at(DateTime(2026, 4, 4, 8), 'six'),
      _at(DateTime(2025, 10, 4, 12), 'year'),
      _at(DateTime(2023, 10, 4, 12), 'three'),
      _at(DateTime(2025, 10, 5, 12), 'not today'),
      _at(DateTime(2026, 10, 4, 7), 'today itself'),
    ], now);
    expect(memories.map((m) => m.entry.title),
        ['month', 'six', 'year', 'three']);
    expect(memories.map((m) => m.age.labelKey),
        ['memories.1m', 'memories.6m', 'memories.1y', 'memories.ny']);
    expect(memories.last.age.years, 3);
  });

  test('crosses the year boundary for months', () {
    final now = DateTime(2026, 2, 10);
    final memories = Memories.onThisDay([
      _at(DateTime(2026, 1, 10), 'january'),
      _at(DateTime(2025, 8, 10), 'august'),
    ], now);
    expect(memories.map((m) => m.entry.title), ['january', 'august']);
  });

  test('skips dates the earlier month does not have', () {
    // 31 March: February has no 31st, so nothing should match on 3 March.
    final memories = Memories.onThisDay([
      _at(DateTime(2026, 3, 3), 'shifted'),
    ], DateTime(2026, 3, 31));
    expect(memories, isEmpty);
  });

  test('29 February only matches leap years', () {
    final memories = Memories.onThisDay([
      _at(DateTime(2024, 2, 29), 'leap'),
      _at(DateTime(2025, 3, 1), 'not a match'),
    ], DateTime(2028, 2, 29));
    expect(memories.map((m) => m.entry.title), ['leap']);
    expect(memories.single.age.years, 4);
  });

  test('several entries on one day keep their order', () {
    final memories = Memories.onThisDay([
      _at(DateTime(2025, 10, 4, 21), 'evening'),
      _at(DateTime(2025, 10, 4, 7), 'morning'),
    ], DateTime(2026, 10, 4));
    expect(memories.map((m) => m.entry.title), ['morning', 'evening']);
  });
}
