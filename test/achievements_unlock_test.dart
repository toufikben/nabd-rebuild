import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/services/motivation_service.dart';

void main() {
  late Directory directory;
  late Box settings;

  setUp(() async {
    await Hive.close();
    directory = await Directory.systemTemp.createTemp('nabd_achievements');
    Hive.init(directory.path);
    // Gratitude days and unlocked achievements live in the content box.
    settings = await Hive.openBox<dynamic>('content');
  });

  tearDown(() async {
    await Hive.close();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  group('gratitude days', () {
    test('counts the days that hold something', () async {
      await settings.put('gratitude_2026_9_1', ['a', 'b']);
      await settings.put('gratitude_2026_9_2', ['c']);

      expect(AchievementService.gratitudeDayCount(settings), 2);
    });

    test('ignores the garden flowers stored under the same prefix', () async {
      await settings.put('gratitude_2026_9_1', ['a']);
      await settings.put('gratitude_items', [
        {'id': '1', 'text': 'flower'}
      ]);

      expect(AchievementService.gratitudeDayCount(settings), 1);
    });

    test('ignores an empty day', () async {
      await settings.put('gratitude_2026_9_1', ['a']);
      await settings.put('gratitude_2026_9_2', <String>[]);
      await settings.put('gratitude_2026_9_3', ['   ']);

      expect(AchievementService.gratitudeDayCount(settings), 1);
    });

    test('ignores a day key that is not a date', () async {
      await settings.put('gratitude_2026_9_1', ['a']);
      await settings.put('gratitude_nonsense', ['a']);
      await settings.put('gratitude_2026_9_31', ['a']);

      expect(AchievementService.gratitudeDayCount(settings), 1);
    });
  });

  group('unlocking', () {
    test('a qualifying achievement is opened and remembered', () async {
      final fresh = await AchievementService().unlockEligible(
        entries: 1,
        streak: 0,
        words: 0,
        moods: 0,
        gratitudeDays: 0,
      );

      expect(fresh.map((a) => a.id), contains('first_entry'));
      expect(AchievementService().unlockedIds, contains('first_entry'));
    });

    test('the gratitude achievement reads the real count', () async {
      for (var day = 1; day <= 7; day++) {
        await settings.put('gratitude_2026_9_$day', ['thanks']);
      }

      final fresh = await AchievementService().unlockEligible(
        entries: 0,
        streak: 0,
        words: 0,
        moods: 0,
        gratitudeDays: AchievementService.gratitudeDayCount(settings),
      );

      expect(fresh.map((a) => a.id), contains('gratitude_7'));
    });

    test('an achievement is offered once, not on every visit', () async {
      final first = await AchievementService().unlockEligible(
        entries: 12,
        streak: 0,
        words: 0,
        moods: 0,
        gratitudeDays: 0,
      );
      expect(first.map((a) => a.id), contains('seven_entries'));

      final second = await AchievementService().unlockEligible(
        entries: 12,
        streak: 0,
        words: 0,
        moods: 0,
        gratitudeDays: 0,
      );
      expect(second, isEmpty);
    });
  });
}
