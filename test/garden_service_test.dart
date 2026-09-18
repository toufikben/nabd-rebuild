import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/models/seed.dart';

void main() {
  group('Seed', () {
    test('has 10 seeds', () {
      expect(Seed.all.length, 10);
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

    test('advances to stage 1 at 3 points', () {
      final seed = PlantedSeed(
        id: 'test',
        seedTypeId: 'love',
        plantedAt: DateTime.now(),
        growthPoints: 3,
      );

      expect(seed.growthStage, 1);
    });

    test('advances to stage 5 at 100 points', () {
      final seed = PlantedSeed(
        id: 'test',
        seedTypeId: 'love',
        plantedAt: DateTime.now(),
        growthPoints: 100,
      );

      expect(seed.growthStage, 5);
      expect(seed.progress, 1.0);
    });

    test('needs water when not watered today', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final key = yesterday.year * 10000 +
          yesterday.month * 100 +
          yesterday.day;

      final seed = PlantedSeed(
        id: 'test',
        seedTypeId: 'love',
        plantedAt: DateTime.now(),
        lastWateredDay: key,
      );

      expect(seed.needsWater(DateTime.now()), true);
    });
  });
}
