import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/word_frequency.dart';

void main() {
  group('splitting', () {
    test('Arabic words stay whole', () {
      // The defect this replaces: the cloud split on [\s\u0600-\u06FF], which
      // treats every Arabic letter as a separator, so this sentence produced
      // single letters instead of three words.
      expect(
        wordsIn('أشعر بالهدوء اليوم'),
        ['أشعر', 'بالهدوء', 'اليوم'],
      );
    });

    test('Persian and Urdu are not torn apart either', () {
      expect(wordsIn('امروز آرام هستم'), contains('امروز'));
      expect(wordsIn('آج میں پرسکون ہوں'), contains('پرسکون'));
    });

    test('English punctuation separates, apostrophes do not', () {
      expect(
        wordsIn("I don't feel well-being, honestly."),
        ["don't", 'feel', 'well-being', 'honestly'],
      );
    });

    test('mixed Arabic and English in one entry both survive', () {
      final words = wordsIn('اليوم كان calm and quiet');
      expect(words, containsAll(['اليوم', 'calm', 'quiet']));
    });

    test('numbers alone are not words', () {
      expect(wordsIn('2026 was 3 times better'), isNot(contains('2026')));
      expect(wordsIn('2026 was 3 times better'), isNot(contains('3')));
    });

    test('short words are dropped but the length is a parameter', () {
      expect(wordsIn('go to bed', minLength: 3), isNot(contains('go')));
      expect(wordsIn('go to bed', minLength: 2), contains('go'));
    });

    test('stop words are dropped in every shipped language', () {
      expect(wordsIn('the cat and the dog'), ['cat', 'dog']);
      expect(wordsIn('الكتاب في البيت'), ['الكتاب', 'البيت']);
      expect(wordsIn('le chat et le chien'), ['chat', 'chien']);
    });
  });

  group('frequencies', () {
    test('counted across entries, most frequent first', () {
      final result = wordFrequencies([
        'كتابة كتابة كتابة',
        'كتابة هدوء',
        'هدوء',
      ]);

      expect(result.first.word, 'كتابة');
      expect(result.first.count, 4);
      expect(result[1].word, 'هدوء');
      expect(result[1].count, 2);
    });

    test('equal counts keep a stable order', () {
      final first = wordFrequencies(['beta alpha gamma']);
      final second = wordFrequencies(['beta alpha gamma']);

      expect(first.map((e) => e.word), second.map((e) => e.word));
      expect(first.map((e) => e.word).toList(), ['alpha', 'beta', 'gamma']);
    });

    test('the limit caps the result without changing the order', () {
      final result = wordFrequencies(
        ['alpha alpha beta gamma'],
        limit: 2,
      );

      expect(result, hasLength(2));
      expect(result.first.word, 'alpha');
    });

    test('an empty journal produces nothing', () {
      expect(wordFrequencies(const []), isEmpty);
      expect(wordFrequencies(['']), isEmpty);
    });
  });
}
