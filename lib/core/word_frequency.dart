/// Word frequency for the word cloud and the Insights summary.
///
/// Two screens counted words before this, each with its own stop-word list and
/// its own splitter. One of the splitters was wrong in a way that only shows in
/// the app's own language: it split on `[\s\u0600-\u06FF]`, treating every
/// Arabic letter as a separator, so an Arabic entry produced one-letter
/// fragments instead of words. Arabic, Persian and Urdu all write with the
/// same block, which is why that shipped unnoticed in an Arabic-first app.
///
/// The splitter here separates on whitespace and punctuation only, and the
/// stop words cover the languages that ship.
library;

/// Words that carry no meaning on their own, in the languages the app speaks.
const Set<String> stopWords = {
  // English
  'the', 'and', 'for', 'with', 'this', 'that', 'from', 'have', 'has', 'had',
  'are', 'was', 'were', 'been', 'be', 'is', 'it', 'its', 'as', 'at', 'by',
  'you', 'your', 'yours', 'they', 'them', 'their', 'his', 'her', 'hers',
  'she', 'he', 'we', 'our', 'us', 'me', 'my', 'mine', 'i', 'a', 'an', 'to',
  'of', 'in', 'on', 'or', 'but', 'not', 'no', 'so', 'if', 'then', 'than',
  'there', 'here', 'what', 'when', 'who', 'how', 'all', 'any', 'some', 'can',
  'will', 'would', 'could', 'should', 'do', 'does', 'did', 'just', 'very',
  // Arabic
  'في', 'من', 'على', 'إلى', 'عن', 'مع', 'هذا', 'هذه', 'ذلك', 'تلك',
  'التي', 'الذي', 'الذين', 'أنا', 'أنت', 'أنتم', 'هو', 'هي', 'نحن', 'هم',
  'كان', 'كانت', 'يكون', 'و', 'أو', 'ثم', 'لا', 'ما', 'لم', 'لن', 'قد',
  'لقد', 'إن', 'أن', 'كل', 'بعض', 'يا', 'بعد', 'قبل', 'بين', 'عند', 'حتى',
  'كما', 'لكن', 'هناك', 'هنا', 'أي', 'كيف', 'متى', 'أين', 'لماذا',
  // French, Spanish, German, Portuguese, Italian (the Latin languages that
  // ship) — the short function words that would otherwise dominate a cloud.
  'le', 'la', 'les', 'un', 'une', 'des', 'du', 'de', 'et', 'est', 'que',
  'qui', 'pour', 'dans', 'sur', 'pas', 'au', 'aux', 'ce', 'cette', 'je',
  'tu', 'il', 'elle', 'nous', 'vous', 'ils', 'elles', 'el', 'los', 'las',
  'una', 'y', 'es', 'en', 'por', 'para', 'con', 'que', 'der', 'die', 'das',
  'und', 'ist', 'ein', 'eine', 'nicht', 'ich', 'du', 'er', 'sie', 'wir',
  'os', 'as', 'um', 'uma', 'e', 'é', 'o', 'di', 'che', 'non', 'per',
};

/// Splits on whitespace and punctuation, keeping letters of every script
/// together. Apostrophes and hyphens stay inside a word, so `don't` and
/// `well-being` count as one.
final RegExp _splitter = RegExp(
  r'''[^\p{L}\p{M}\p{N}'’\-]+''',
  unicode: true,
);

/// The words of [text] worth counting: lowercased, at least [minLength]
/// letters, no digits-only tokens, no stop words.
List<String> wordsIn(String text, {int minLength = 3}) {
  final out = <String>[];
  for (final raw in text.toLowerCase().split(_splitter)) {
    final word = raw.replaceAll(RegExp(r"^[-'’]+|[-'’]+$"), '');
    if (word.length < minLength) continue;
    if (stopWords.contains(word)) continue;
    if (RegExp(r'^[\p{N}]+$', unicode: true).hasMatch(word)) continue;
    out.add(word);
  }
  return out;
}

/// How often each word appears, most frequent first.
///
/// [limit] caps the result; the cloud and the Insights list show a different
/// number of words but must agree on the order.
List<({String word, int count})> wordFrequencies(
  Iterable<String> texts, {
  int minLength = 3,
  int? limit,
}) {
  final counts = <String, int>{};
  for (final text in texts) {
    for (final word in wordsIn(text, minLength: minLength)) {
      counts[word] = (counts[word] ?? 0) + 1;
    }
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      // A stable order for equal counts, so the same journal always produces
      // the same cloud instead of reshuffling between openings.
      return byCount != 0 ? byCount : a.key.compareTo(b.key);
    });
  final capped = limit == null ? sorted : sorted.take(limit);
  return [for (final entry in capped) (word: entry.key, count: entry.value)];
}
