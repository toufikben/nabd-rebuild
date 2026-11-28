import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/core/gratitude.dart';
import 'package:nabd/core/storage.dart';
import 'package:nabd/services/motivation_service.dart';

void main() {
  group('day keys', () {
    test('every dated key still parses', () {
      expect(gratitudeDateFromKey('gratitude_2026_9_28'), DateTime(2026, 9, 28));
      expect(gratitudeDateFromKey('gratitude_2026_12_1'), DateTime(2026, 12, 1));
    });

    test('anything that is not a day is not a date', () {
      expect(gratitudeDateFromKey('gratitude_items'), isNull);
      expect(gratitudeDateFromKey('gratitude_2026_9'), isNull);
      expect(gratitudeDateFromKey('weekly_pulse_2026_9_1'), isNull);
      // DateTime would roll 31 September into October; the key must not.
      expect(gratitudeDateFromKey('gratitude_2026_9_31'), isNull);
      expect(gratitudeDateFromKey('gratitude_2026_2_30'), isNull);
    });

    test('the key the app writes is the key it reads', () {
      final day = DateTime(2026, 9, 5);
      expect(gratitudeDayKey(day), 'gratitude_2026_9_5');
      expect(gratitudeDateFromKey(gratitudeDayKey(day)), day);
    });
  });

  group('one store', () {
    late Directory directory;
    late Box box;

    setUp(() async {
      await Hive.close();
      directory = await Directory.systemTemp.createTemp('nabd_gratitude');
      Hive.init(directory.path);
      box = await Hive.openBox<dynamic>(HiveBoxes.content);
    });

    tearDown(() async {
      await Hive.close();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('a line written in the garden is a gratitude day', () async {
      // The defect this replaces: the garden kept its own list, so a flower
      // never appeared in the journal and never counted towards the
      // achievement.
      await addGratitude(box, 'the sun came out', day: DateTime(2026, 9, 5));

      expect(gratitudeLinesFor(box, DateTime(2026, 9, 5)),
          ['the sun came out']);
      expect(AchievementService.gratitudeDayCount(box), 1);
      final entries = gratitudeEntries(box);
      expect(entries, hasLength(1));
      expect(entries.single.date, DateTime(2026, 9, 5));
    });

    test('empty slots are not lines', () async {
      await box.put('gratitude_2026_9_5', ['', '  ', 'a moment']);

      expect(gratitudeLinesFor(box, DateTime(2026, 9, 5)), ['a moment']);
      expect(gratitudeEntries(box).single.text, 'a moment');
    });

    test('deleting one line keeps the others and their positions', () async {
      await box.put('gratitude_2026_9_5', ['first', 'second', 'third']);
      final second = gratitudeEntries(box)[1];

      await removeGratitude(box, second);

      // Blanked, not spliced: the third line must not jump into the second
      // prompt's field.
      expect(box.get('gratitude_2026_9_5'), ['first', '', 'third']);
      expect(gratitudeLinesFor(box, DateTime(2026, 9, 5)), ['first', 'third']);
      expect(gratitudeEntries(box).last.slot, 2);
      expect(AchievementService.gratitudeDayCount(box), 1);
    });

    test('the journal keeps a flower planted today', () async {
      // The garden appends to the same day the journal writes its three
      // prompts to. Saving the prompts must not delete the flower.
      await box.put('gratitude_2026_9_5', ['prompt one', 'prompt two']);
      await addGratitude(box, 'a flower', day: DateTime(2026, 9, 5));

      await saveGratitudeSlots(box, DateTime(2026, 9, 5), ['edited', '', '']);

      expect(box.get('gratitude_2026_9_5'), ['edited', '', '', 'a flower']);
      expect(gratitudeLinesFor(box, DateTime(2026, 9, 5)),
          ['edited', 'a flower']);
    });

    test('a blank middle prompt stays blank', () async {
      await box.put('gratitude_2026_9_5', ['one', '', 'three']);

      expect(gratitudeSlotsFor(box, DateTime(2026, 9, 5)),
          ['one', '', 'three']);
      expect(gratitudeLinesFor(box, DateTime(2026, 9, 5)), ['one', 'three']);
    });

    test('the same words twice deletes only one of them', () async {
      await box.put('gratitude_2026_9_5', ['same', 'same']);
      final entries = gratitudeEntries(box);

      await removeGratitude(box, entries.first);

      expect(gratitudeLinesFor(box, DateTime(2026, 9, 5)), ['same']);
    });

    test('newest day first', () async {
      await addGratitude(box, 'older', day: DateTime(2026, 9, 4));
      await addGratitude(box, 'newer', day: DateTime(2026, 9, 5));

      expect(gratitudeEntries(box).map((e) => e.text), ['newer', 'older']);
    });

    test('the old garden list folds into dated days, once', () async {
      await box.put(ContentKeys.gratitudeItems, [
        {'id': '1', 'text': 'a flower', 'createdAt': '2026-09-05T10:00:00.000'},
        {'id': '2', 'text': 'another', 'createdAt': '2026-09-05T11:00:00.000'},
      ]);

      expect(await foldGratitudeItems(box), 2);
      expect(box.containsKey(ContentKeys.gratitudeItems), isFalse);
      expect(gratitudeLinesFor(box, DateTime(2026, 9, 5)),
          ['a flower', 'another']);
      expect(AchievementService.gratitudeDayCount(box), 1);

      // A second launch must not duplicate anything, and must not throw on the
      // key that is already gone.
      expect(await foldGratitudeItems(box), 0);
      expect(gratitudeEntries(box), hasLength(2));
    });

    test('folding skips a line the day already holds', () async {
      await box.put('gratitude_2026_9_5', ['a flower']);
      await box.put(ContentKeys.gratitudeItems, [
        {'text': 'a flower', 'createdAt': '2026-09-05T10:00:00.000'},
      ]);

      expect(await foldGratitudeItems(box), 0);
      expect(box.get('gratitude_2026_9_5'), ['a flower']);
    });

    test('no screen keeps its own gratitude store', () {
      // If a screen starts writing flowers to a key of its own again, the two
      // views drift apart and this whole class of defect comes back.
      final screens = [
        'lib/features/gratitude/gratitude_garden_screen.dart',
        'lib/features/gratitude/gratitude_journal_screen.dart',
      ];
      for (final path in screens) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains("'gratitude_items'")), reason: path);
        expect(source, contains('core/gratitude.dart'), reason: path);
      }
    });
  });
}
