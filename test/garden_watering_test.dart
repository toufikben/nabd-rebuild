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
    expect(result.growthAdded, 5);
    expect(result.messageKey, 'garden.water.care');
  });

  test('a neutral entry still grows the seed', () async {
    final result = await garden.water(_entry('went to the market'));
    expect(result.growthAdded, 3);
    expect(result.messageKey, isNot('garden.water.rested'));
  });

  test('only the first entry of the day waters the garden', () async {
    final first = await garden.water(_entry('went to the market'));
    expect(first.growthAdded, 3);

    final second = await garden.water(_entry('another short note'));
    expect(second.ok, isTrue);
    expect(second.growthAdded, 0);
    expect(second.messageKey, 'garden.water.rested');
    expect(garden.state.seeds.first.growthPoints, 3);
  });

  test('a single watering is capped at six points', () async {
    final long = List.filled(301, 'word').join(' ');
    final result = await garden.water(_entry(long, mood: 'sad'));
    expect(result.growthAdded, GardenService.dailyGrowthCap);
    expect(result.growthAdded, 6);
  });

  test('completing a seed stores a certificate and stops watering it',
      () async {
    final seed = garden.state.seeds.first;
    await Hive.box<dynamic>('garden')
        .put(seed.id, seed.copyWith(growthPoints: 99).toMap());
    garden.refresh();

    final result = await garden.water(_entry('went to the market'));
    expect(result.isComplete, isTrue);
    expect(result.seed!.isComplete, isTrue);
    expect(result.seed!.growthPoints, 100);
    expect(result.seed!.completionCertificate, isNotNull);
    expect(result.seed!.completedAt, isNotNull);
    expect(garden.state.seeds.first.isComplete, isTrue);

    await Hive.box<dynamic>('settings').delete('garden_growth_day');
    final after = await garden.water(_entry('another note'));
    expect(after.ok, isTrue);
    expect(after.messageKey, 'garden.water.noTargets');
    expect(after.growthAdded, 0);
  });

  test('removing a seed frees the garden', () async {
    final id = garden.state.seeds.first.id;
    await garden.removeSeed(id);
    expect(garden.state.seeds, isEmpty);
    final result = await garden.water(_entry('went to the market'));
    expect(result.ok, isFalse);
    expect(result.messageKey, 'garden.water.noSeed');
  });

  test('a completed garden can be archived into a new season', () async {
    final seed = garden.state.seeds.first;
    await Hive.box<dynamic>('garden').put(
      seed.id,
      seed
          .copyWith(
            growthPoints: 100,
            isComplete: true,
            completionCertificate:
                'garden.certificate|${seed.seedTypeId}|2026-10-21T12:00:00.000',
          )
          .toMap(),
    );
    garden.refresh();

    expect(garden.currentSeason, 1);
    final next = await garden.startNewSeason();

    expect(next, 2);
    expect(garden.currentSeason, 2);
    expect(garden.state.seeds, isEmpty);
    expect(garden.archivedSeeds, hasLength(1));
    expect(garden.archivedSeeds.single.season, 1);
    expect(garden.archivedSeeds.single.seed.seedTypeId, seed.seedTypeId);

    garden.dispose();
    garden = GardenService();
    expect(garden.currentSeason, 2);
    expect(garden.state.seeds, isEmpty);
    expect(garden.archivedSeeds, hasLength(1));
  });

  test('a new season waits until every seed has bloomed', () async {
    expect(garden.startNewSeason(), throwsStateError);
    expect(garden.currentSeason, 1);
    expect(garden.archivedSeeds, isEmpty);
  });
}
