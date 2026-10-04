import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/models/journal_entry.dart';
import 'package:nabd/models/seed.dart';
import 'package:nabd/services/garden_service.dart';

JournalEntry _entry(String content, {String mood = ''}) => JournalEntry(
      title: '',
      content: content,
      mood: mood,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

void main() {
  late Directory directory;
  late GardenService garden;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nabd_garden');
    Hive.init(directory.path);
    await Hive.openBox<dynamic>('garden');
    await Hive.openBox<dynamic>('settings');
    garden = GardenService();
    await garden.plantSeed(Seed.all.first);
  });

  tearDown(() async {
    garden.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('a hard day grows the seed and is met with care', () async {
    final result = await garden.water(_entry('كان يومًا حزينًا ومتعبًا'));
    expect(result.ok, isTrue);
    expect(result.growthAdded, greaterThan(0));
    expect(result.messageKey, 'garden.water.care');
  });

  test('a neutral entry still grows the seed', () async {
    final result = await garden.water(_entry('went to the market'));
    expect(result.growthAdded, 3);
  });

  test('one day of writing is capped', () async {
    var total = 0;
    WateringResult? last;
    for (var i = 0; i < 10; i++) {
      last = await garden.water(_entry('another short note'));
      total += last.growthAdded;
    }
    expect(total, GardenService.dailyGrowthCap);
    expect(last!.messageKey, 'garden.water.rested');
  });
}
