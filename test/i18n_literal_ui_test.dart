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

/// A literal sitting in a ternary branch. The shape every earlier pass missed,
/// because the line neither starts with a quote nor opens a `Text(`.
final _ternaryBranch = RegExp(r"(?:^|[^=!<>a-zA-Z_])[?:]\s*'([^']*)'");

/// A condition that picks a string by language: `isArabic ? 'عربي' : 'english'`.
/// That is the fix, so its branches must not be reported as defects.
final _langSwitch = RegExp(r'\b(?:isArabic|langCode|languageCode|locale)\b');

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
    var branchHit = false;
    if (pending && text.startsWith("'")) {
      final stripped = line.replaceAll(_interpolation, ' ');
      if (_arabic.hasMatch(stripped) || _sentence.hasMatch(stripped)) {
        found.add('${i + 1}: $text');
        pending = false;
        continue;
      }
    }
    // Only a line that really branches counts: a `:` with no `?` is a map entry,
    // and a condition that already picks by language is the fix, not the defect.
    final branchAt = line.indexOf('?');
    final isBranch = branchAt >= 0 || line.startsWith(':');
    final pickedByLanguage =
        branchAt >= 0 && _langSwitch.hasMatch(line.substring(0, branchAt));
    if (isBranch && !pickedByLanguage) {
      final tail = branchAt >= 0 ? line.substring(branchAt) : line;
      for (final match in _ternaryBranch.allMatches(tail)) {
        final raw = match.group(1)!;
        final stripped = raw.replaceAll(_interpolation, ' ');
        if (_arabic.hasMatch(stripped) ||
            _sentence.hasMatch(stripped) ||
            _twoWords.hasMatch(stripped) ||
            (_interpolation.hasMatch(raw) &&
                !raw.contains('://') &&
                _anyWord.hasMatch(stripped))) {
          found.add('${i + 1}: $text');
          pending = false;
          branchHit = true;
          break;
        }
      }
    }
    if (branchHit) continue;
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
    expect(
        hardcodedSentences([
          "              Text(l10n.t('garden.seedHelp')),",
          "            const Icon(Icons.spa, size: 20),",
          "                  label: Text(l10n.t('common.all')),",
          "                  value: '0xFF00B88A',",
          "      static const _storageKey = 'wisdom_state',",
        ]),
        isEmpty);
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
    // A ternary branch hid literals from every earlier pass: the line begins
    // with `?` or `:`, so neither the Text( rule nor the continuation rule saw it.
    expect(
      hardcodedSentences([
        "                      ? 'حان وقت المراجعة'",
        "                      : 'متبقٍ \$daysLeft أيام',",
        "              ? 'My future self'",
      ]),
      hasLength(3),
    );
    // ...and the localized spelling of the same ternary stays green.
    expect(
      hardcodedSentences([
        "                      ? l10n.t('worryBox.reviewTime')",
        "                      : l10n.t('worryBox.daysLeft'),",
      ]),
      isEmpty,
    );
    // The branch can also sit after the condition, on one line.
    expect(
      hardcodedSentences([
        "          address: name.isEmpty ? 'My future self' : name,",
      ]),
      hasLength(1),
    );
    // A single-word branch or a localized one stays out of the way.
    expect(
      hardcodedSentences([
        "          icon: ok ? '✅' : '❌',",
        "          address: name.isEmpty ? l10n.t('letters.futureSelf') : name,",
      ]),
      isEmpty,
    );
    // An interpolated English word hidden in a branch is the `Days` defect again.
    expect(
      hardcodedSentences([
        "                        ? 'Unlocks: \${letter.unlockDate.day}/\${letter.unlockDate.month}',",
      ]),
      hasLength(1),
    );
    // ...including the else branch alone on its own line.
    expect(
      hardcodedSentences([
        "                        : 'Written: \${letter.createdAt.day}',",
      ]),
      hasLength(1),
    );
    // A ternary that switches on the language is the fix, not the defect.
    expect(
      hardcodedSentences([
        "            langCode == 'ar' ? 'كيف تشعر؟' : 'How do you feel?',",
      ]),
      isEmpty,
    );
    // A map entry is not a ternary branch.
    expect(
      hardcodedSentences([
        "          'ar': 'العربية',",
        "          {'code': 'ar', 'name': 'العربية'},",
      ]),
      isEmpty,
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
