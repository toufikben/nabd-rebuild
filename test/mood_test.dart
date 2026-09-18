import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/models/mood.dart';

void main() {
  group('Mood', () {
    test('has 20 moods', () {
      expect(Mood.all.length, 20);
    });

    test('all moods have valid categories', () {
      const validCategories = ['positive', 'negative', 'neutral', 'complex'];
      for (final mood in Mood.all) {
        expect(validCategories, contains(mood.category));
      }
    });

    test('getById finds correct mood', () {
      final happy = Mood.getById('happy');
      expect(happy, isNotNull);
      expect(happy!.emoji, '😊');
      expect(happy.category, 'positive');
    });

    test('getById returns null for unknown', () {
      expect(Mood.getById('nonexistent'), isNull);
    });

    test('Arabic label works', () {
      final happy = Mood.getById('happy')!;
      expect(happy.label('ar'), 'سعيد');
      expect(happy.label('en'), 'Happy');
    });

    test('category label works in Arabic', () {
      expect(Mood.categoryLabel('positive', 'ar'), 'إيجابية');
      expect(Mood.categoryLabel('negative', 'ar'), 'سلبية');
    });
  });
}
