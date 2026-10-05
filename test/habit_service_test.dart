import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/models/journal_entry.dart';
import 'package:nabd/services/habit_service.dart';

void main() {
  late Directory dir;
  late Box box;
  late HabitService service;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('habits');
    Hive.init(dir.path);
    box = await Hive.openBox('content_test');
    service = HabitService(box: box);
  });

  tearDown(() async {
    await box.deleteFromDisk();
    await dir.delete(recursive: true);
  });

  test('ticks a day on and off', () async {
    final habit = Habit(presetId: 'walk', emoji: '🚶');
    await service.add(habit);
    final day = DateTime(2026, 10, 5, 18);
    await service.toggle(habit.id, day);
    expect(service.isDone(habit.id, DateTime(2026, 10, 5)), isTrue);
    await service.toggle(habit.id, day);
    expect(service.isDone(habit.id, day), isFalse);
  });

  test('archive keeps the history, delete removes it', () async {
    final keep = Habit(name: 'Music', emoji: '✨');
    final drop = Habit(presetId: 'water', emoji: '💧');
    await service.add(keep);
    await service.add(drop);
    await service.toggle(keep.id, DateTime(2026, 10, 1));
    await service.toggle(drop.id, DateTime(2026, 10, 1));
    await service.archive(keep.id);
    await service.delete(drop.id);
    expect(service.active(), isEmpty);
    expect(service.all().single.archived, isTrue);
    expect(service.doneDays(keep.id), {'2026-10-01'});
    expect(service.doneDays(drop.id), isEmpty);
  });

  test('a streak counts from yesterday while today is still open', () {
    final days = {'2026-10-02', '2026-10-03', '2026-10-04'};
    expect(HabitService.streak(days, DateTime(2026, 10, 5)), 3);
    expect(HabitService.streak({...days, '2026-10-05'}, DateTime(2026, 10, 5)), 4);
    expect(HabitService.streak(days, DateTime(2026, 10, 7)), 0);
  });

  test('mood link compares days with and without the habit', () {
    JournalEntry e(int day, String mood) => JournalEntry(
          title: '',
          content: '',
          createdAt: DateTime(2026, 9, day, 20),
          updatedAt: DateTime(2026, 9, day, 20),
          mood: mood,
        );
    final entries = [
      for (var d = 1; d <= 4; d++) e(d, 'happy'),
      for (var d = 5; d <= 8; d++) e(d, 'sad'),
    ];
    final done = {for (var d = 1; d <= 4; d++) '2026-09-0$d'};
    final link = HabitService.moodLink(done, entries)!;
    expect(link.withHabit, 9);
    expect(link.without, 4);
    expect(HabitService.moodLink(done, entries.take(6)), isNull);
  });
}
