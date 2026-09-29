import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/features/gratitude/gratitude_journal_screen.dart';

void main() {
  test('every dated journal key still parses', () {
    expect(journalDateFromKey('gratitude_2026_9_28'), DateTime(2026, 9, 28));
    expect(journalDateFromKey('gratitude_2026_12_1'), DateTime(2026, 12, 1));
  });

  test('the garden key is not a journal date', () {
    // The garden keeps its flowers in one list under a key that shares the
    // journal's prefix. Reading it as a journal entry used to date every flower
    // to 1 Jan 1970 and print the stored map instead of its text.
    expect(journalDateFromKey('gratitude_items'), isNull);
    expect(journalDateFromKey('gratitude_2026_9'), isNull);
  });

  test('the garden really stores its flowers under that key', () {
    // If the garden ever changes the key, the skip above must change with it.
    final source = File('lib/features/gratitude/gratitude_garden_screen.dart')
        .readAsStringSync();
    expect(source, contains("'gratitude_items'"));
  });
}
