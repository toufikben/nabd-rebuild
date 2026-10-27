import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/models/seed.dart';
import 'package:nabd/services/garden_service.dart';
import 'package:nabd/services/motivation_service.dart';

void main() {
  group('Seed', () {
    test('has 16 seeds', () {
      expect(Seed.all.length, 16);
    });

    test('every unlock requirement names a real achievement', () {
      for (final seed in Seed.all.where((s) => s.unlockAchievement != null)) {
        expect(
          Achievement.all.any((a) => a.id == seed.unlockAchievement),
          isTrue,
          reason: '${seed.id} needs unknown ${seed.unlockAchievement}',
        );
      }
    });

    test('a gated seed stays locked until its achievement is earned', () {
      final gated = Seed.all.firstWhere((s) => s.unlockAchievement != null);
      expect(gated.isUnlocked({}), isFalse);
      expect(gated.isUnlocked({gated.unlockAchievement!}), isTrue);
    });

    test('the first seeds need no achievement', () {
      expect(Seed.all.where((s) => s.unlockAchievement == null), isNotEmpty);
      expect(Seed.getById('love')!.isUnlocked({}), isTrue);
    });

    test('every seed is listed once and the garden cap leaves a choice', () {
      expect(Seed.all.map((s) => s.id).toSet(), hasLength(Seed.all.length));
      expect(GardenService.maxSeeds, lessThan(Seed.all.length));
    });

    test('all seeds have required fields', () {
      for (final seed in Seed.all) {
        expect(seed.id, isNotEmpty);
        expect(seed.nameEn, isNotEmpty);
        expect(seed.nameAr, isNotEmpty);
        expect(seed.emoji, isNotEmpty);
        expect(seed.colors.length, 2);
      }
    });

    test('getById finds love seed', () {
      final love = Seed.getById('love');
      expect(love, isNotNull);
      expect(love!.nameAr, 'الحب');
    });
  });

  group('PlantedSeed', () {
    test('starts at stage 0', () {
      final seed = PlantedSeed(
        id: 'test',
        seedTypeId: 'love',
        plantedAt: DateTime.now(),
      );

      expect(seed.growthStage, 0);
      expect(seed.progress, 0.0);
      expect(seed.isComplete, false);
    });

    test('advances to stage 1 at 10 points', () {
      final seed = PlantedSeed(
        id: 'test',
        seedTypeId: 'love',
        plantedAt: DateTime.now(),
        growthPoints: 10,
      );

      expect(seed.growthStage, 1);
    });

    test('advances through the 25/50/75 thresholds', () {
      PlantedSeed at(int points) => PlantedSeed(
            id: 'test',
            seedTypeId: 'love',
            plantedAt: DateTime.now(),
            growthPoints: points,
          );

      expect(at(24).growthStage, 1);
      expect(at(25).growthStage, 2);
      expect(at(49).growthStage, 2);
      expect(at(50).growthStage, 3);
      expect(at(74).growthStage, 3);
      expect(at(75).growthStage, 4);
      expect(at(99).growthStage, 4);
    });

    test('advances to stage 5 at 100 points', () {
      final seed = PlantedSeed(
        id: 'test',
        seedTypeId: 'love',
        plantedAt: DateTime.now(),
        growthPoints: 100,
        isComplete: true,
      );

      expect(seed.growthStage, 5);
      expect(seed.progress, 1.0);
    });

    test('needs water when not watered today', () {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final key =
          yesterday.year * 10000 + yesterday.month * 100 + yesterday.day;

      final seed = PlantedSeed(
        id: 'test',
        seedTypeId: 'love',
        plantedAt: now,
        lastWateredDay: key,
      );

      expect(seed.needsWater(now), true);
      expect(seed.isThirsty(now), false);
    });

    test('is thirsty after two dry days', () {
      final now = DateTime.now();
      final twoDaysAgo = now.subtract(const Duration(days: 2));
      final key =
          twoDaysAgo.year * 10000 + twoDaysAgo.month * 100 + twoDaysAgo.day;

      final seed = PlantedSeed(
        id: 'test',
        seedTypeId: 'love',
        plantedAt: now,
        lastWateredDay: key,
      );

      expect(seed.daysWithoutWater(now), 2);
      expect(seed.isThirsty(now), true);
    });

    test('a completed seed never needs water', () {
      final seed = PlantedSeed(
        id: 'test',
        seedTypeId: 'love',
        plantedAt: DateTime.now(),
        growthPoints: 100,
        isComplete: true,
      );

      expect(seed.needsWater(DateTime.now()), false);
      expect(seed.isThirsty(DateTime.now()), false);
    });

    test('reads the completion date from the certificate', () {
      final seed = PlantedSeed(
        id: 'test',
        seedTypeId: 'love',
        plantedAt: DateTime.now(),
        growthPoints: 100,
        isComplete: true,
        completionCertificate:
            'garden.certificate|love|2026-10-21T12:34:56.000',
      );

      expect(seed.completedAt, DateTime(2026, 10, 21, 12, 34, 56));
    });
  });
}
