import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every on-device sweep kept finding the same class of defect: a screen that
/// renders a sentence written straight into the widget tree, so the other
/// language sees it untranslated. A sweep cannot reach every screen, so this
/// test reads the sources instead and checks both directions — English written
/// inline (broken for Arabic users) and Arabic written inline (broken for
/// English users).

/// A user-visible string position: a `Text(...)` call or a named argument that
/// reaches the screen.
final _textPosition = RegExp(
    r'(?:Text|SelectableText)\(\s*|(?:label|title|hintText|helperText|tooltip|semanticLabel|message|body|content|subject)\s*:\s*');

/// Localized lookups are cut out of the line before it is scanned, so a line
/// that mixes a keyed string with a hardcoded one is still inspected. The leading
/// dot keeps `Text(` itself out of the match.
final _localizedCall = RegExp(r"\.t\(\s*'[^']*'\s*\)");

/// `'$d Days'` is the same defect as a plain English `Days` label: the
/// interpolated value is stripped so the words around it can still be judged.
final _interpolation = RegExp(r'\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_]*');

final _sentence = RegExp(r"[a-zA-Z]{3,}(?:\s+[a-zA-Z]{3,}){2,}");

/// A named argument like `label:`/`tooltip:` must not hold an English word at
/// all — `label: 'Seeds'` and `tooltip: 'Back'` were both shipped defects.
final _anyWord = RegExp(r'[A-Za-z]{2,}');

/// Two English words in a `Text(` are a phrase, not a brand or an initialism.
final _twoWords = RegExp(r'[A-Za-z]{2,}\s+[A-Za-z]{2,}');

final _arabic = RegExp('[؀-ۿ]');
final _constKeyword = RegExp(r'\bconst\s+');

/// A line that ends on an open text position, so the literal is on the next line.
final _opensTextPosition = RegExp(
    r'(?:Text|SelectableText)\($|(?:label|title|hintText|helperText|tooltip|semanticLabel|message|body|content|subject)\s*:$');

/// Lines that hardcode a user-visible English or Arabic literal in this file's
/// own scope.
List<String> hardcodedSentences(Iterable<String> lines) {
  final found = <String>[];
  var pending = false;
  for (var i = 0; i < lines.length; i++) {
    final text = lines.elementAt(i).trim();
    if (text.startsWith('//')) continue;
    if (text.contains("'//")) continue;
    // Localized lookups and the `const` keyword come out first so every string
    // position on the line is inspected, not just the first one.
    final line = text
        .replaceAll(_localizedCall, 'x')
        .replaceAll(_constKeyword, ' ')
        .trim();

    var flagged = false;
    if (pending && text.startsWith("'")) {
      final stripped = line.replaceAll(_interpolation, ' ');
      if (_arabic.hasMatch(stripped) || _sentence.hasMatch(stripped)) {
        found.add('${i + 1}: $text');
        pending = false;
        continue;
      }
    }
    for (final match in _textPosition.allMatches(line)) {
      final rest = line.substring(match.end).trimLeft();
      if (!rest.startsWith("'")) continue;
      final stripped = rest.replaceAll(_interpolation, ' ');
      final isCountLabel = _interpolation.hasMatch(rest);
      final isLabel = !match.group(0)!.startsWith('Text') || isCountLabel;
      if (_arabic.hasMatch(stripped) ||
          _sentence.hasMatch(stripped) ||
          (isLabel && _anyWord.hasMatch(stripped)) ||
          _twoWords.hasMatch(stripped.replaceFirst("'", ''))) {
        flagged = true;
        break;
      }
    }
    pending = _opensTextPosition.hasMatch(line);
    if (flagged) {
      found.add('${i + 1}: $text');
      continue;
    }
    if (text.startsWith("'") && _sentence.hasMatch(text)) {
      // continuation of a multi-line literal whose Text( opened earlier
      found.add('${i + 1}: $text');
    }
  }
  return found;
}

List<File> _dartFiles() => [
      Directory('lib/features'),
      Directory('lib/widgets'),
    ]
        .where((d) => d.existsSync())
        .expand((d) => d.listSync(recursive: true).whereType<File>())
        .where((f) => f.path.endsWith('.dart'))
        .toList();

void main() {
  test('the detector really catches a planted sentence', () {
    // Guards against a vacuously green scan.
    expect(
      hardcodedSentences([
        "              Text('Every journal entry helps your seed grow.',",
        "                'Letters you write but never send. '",
        "                  label: 'Seeds',",
        "          tooltip: 'Back',",
      ]),
      hasLength(4),
    );
    expect(hardcodedSentences([
      "              Text(l10n.t('garden.seedHelp')),",
      "            const Icon(Icons.spa, size: 20),",
      "                  label: Text(l10n.t('common.all')),",
      "                  value: '0xFF00B88A',",
      "      static const _storageKey = 'wisdom_state',",
    ]), isEmpty);
  });

  test('the detector catches the holes the sweeps slipped through', () {
    // A line that localizes one string must not excuse a second, hardcoded one.
    expect(
      hardcodedSentences([
        "              subtitle: Text(l10n.t('x')), trailing: Text('Not sent yet'),",
      ]),
      hasLength(1),
    );
    // Interpolated counts used to hide the English word next to them.
    expect(
      hardcodedSentences([
        "            label: Text('\$d Days'),",
        "            title: '\$_year in review',",
      ]),
      hasLength(2),
    );
    // Arabic written inline is the mirror defect: fine in Arabic, broken in English.
    expect(
      hardcodedSentences([
        "          title: const Text('مذكرة الامتنان'),",
        "              hintText: 'شخص أقدّره...',",
      ]),
      hasLength(2),
    );
    // ...and the fixed spelling of the same line stays green.
    expect(
      hardcodedSentences([
        "            label: Text('\$d \${l10n.t('stats.range.days')}'),",
      ]),
      isEmpty,
    );
    // A literal on the line below Text( was invisible to the old scan.
    expect(
      hardcodedSentences([
        '                    Text(',
        "                      'لا توجد مشاعر مسجلة بعد',",
      ]),
      hasLength(1),
    );
  });

  test('no English sentence is hardcoded into a widget', () {
    final offenders = <String>[];
    for (final file in _dartFiles()) {
      for (final hit in hardcodedSentences(file.readAsLinesSync())) {
        offenders.add('${file.path}  $hit');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('no screen forces right-to-left on its own', () {
    // Wrapping a screen in Directionality(rtl) freezes it in Arabic layout even
    // when the app language is English; the locale already drives direction.
    final offenders = _dartFiles()
        .map((f) => f.path)
        .where((p) => File(p).readAsStringSync().contains('TextDirection.rtl'))
        .toList();
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
