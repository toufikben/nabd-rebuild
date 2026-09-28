import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every on-device Arabic sweep kept finding the same class of defect: a screen
/// that renders an English sentence written straight into the widget tree, so
/// Arabic users see it untranslated. A sweep cannot reach every screen, so this
/// test reads the sources instead.
final _textPosition = RegExp(
    r'(?:Text|SelectableText)\(\s*|(?:label|title|hintText|helperText|tooltip|semanticLabel|message|body|content|subject)\s*:\s*');
final _sentence = RegExp(r"[a-zA-Z]{3,}(?:\s+[a-zA-Z]{3,}){2,}");
/// A one or two-word English label is the other half of the same defect
/// (`label: 'Seeds'`, `tooltip: 'Back'`), so text positions must not hold one.
final _shortLabel = RegExp(r"^'([A-Z]?[a-z]{2,}(?: [A-Z]?[a-z]{2,})?)'[,)]?\s*$");

/// Lines that hardcode a user-visible English sentence in this file's own scope.
List<String> hardcodedSentences(Iterable<String> lines) {
  final found = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final line = lines.elementAt(i);
    final text = line.trim();
    if (text.startsWith('//')) continue;
    if (text.contains("'//")) continue;
    // already localized, or Arabic/other script written inline
    if (text.contains('.t(') || text.contains('l10n.')) continue;
    if (text.runes.any((r) => r >= 0x0600 && r <= 0x06FF)) continue;

    var literal = '';
    final match = _textPosition.firstMatch(line);
    if (match != null) {
      final rest = line.substring(match.end);
      if (!rest.trimLeft().startsWith("'")) continue;
      literal = rest;
      if (_sentence.hasMatch(literal)) {
        found.add('${i + 1}: $text');
        continue;
      }
      final isLabel = !match.group(0)!.startsWith('Text');
      final short = _shortLabel.firstMatch(rest.trimLeft());
      if (isLabel && short != null) found.add('${i + 1}: $text');
      continue;
    } else if (text.startsWith("'")) {
      // continuation of a multi-line literal whose Text( opened on an earlier line
      literal = text;
    } else {
      continue;
    }

    if (_sentence.hasMatch(literal)) found.add('${i + 1}: $text');
  }
  return found;
}

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
      "              Text('ازرع أول بذرة',),",
      "                  label: Text(l10n.t('common.all')),",
      "                  value: '0xFF00B88A',",
    ]), isEmpty);
  });

  test('no English sentence is hardcoded into a widget', () {
    final files = [Directory('lib/features'), Directory('lib/widgets')]
        .where((d) => d.existsSync())
        .expand((d) => d.listSync(recursive: true).whereType<File>())
        .where((f) => f.path.endsWith('.dart'));

    final offenders = <String>[];
    for (final file in files) {
      for (final hit in hardcodedSentences(file.readAsLinesSync())) {
        offenders.add('${file.path}  $hit');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
