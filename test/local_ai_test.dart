import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/local_ai_service.dart';

void main() {
  group('LocalAIService', () {
    final ai = LocalAIService();

    test('detects positive sentiment', () {
      final score = ai.analyzeSentiment(
        'I am so happy today! Everything is wonderful and beautiful.',
      );
      expect(score, greaterThan(0));
    });

    test('detects negative sentiment', () {
      final score = ai.analyzeSentiment(
        'I am sad and lonely. Everything feels terrible and awful.',
      );
      expect(score, lessThan(0));
    });

    test('detects neutral sentiment', () {
      final score = ai.analyzeSentiment('I went to the store today.');
      expect(score.abs(), lessThan(0.2));
    });

    test('detects Arabic positive', () {
      final score = ai.analyzeSentiment(
        'أنا سعيد جدا اليوم. الحياة جميلة ورائعة.',
      );
      expect(score, greaterThan(0));
    });

    test('suggests mood from positive text', () {
      final mood = ai.suggestMood('I feel amazing and joyful!');
      expect(mood, isNotNull);
      expect(['joyful', 'happy', 'grateful'], contains(mood));
    });

    test('suggests mood from negative text', () {
      final mood = ai.suggestMood('I am so sad and depressed today');
      expect(mood, isNotNull);
    });

    test('summarizes long text', () {
      final text = 'First sentence here. '
          'Second sentence with more words about something. '
          'Third sentence. '
          'Fourth sentence about another topic. '
          'Fifth sentence.';
      final summary = ai.summarize(text, maxSentences: 2);
      expect(summary.length, lessThan(text.length));
    });

    test('suggests tags from content', () {
      final tags = ai.suggestTags(
        'I went to work today and had a meeting about my project.',
      );
      expect(tags, contains('work'));
    });
  });
}
