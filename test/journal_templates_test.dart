import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/journal_templates.dart';
import 'package:nabd/core/l10n/app_strings.dart';

void main() {
  test('every template has a title, hint and body in both languages', () {
    for (final template in JournalTemplate.all) {
      for (final key in [template.titleKey, template.hintKey, template.bodyKey]) {
        expect(S.ar[key], isNotNull, reason: key);
        expect(S.en[key], isNotNull, reason: key);
      }
    }
  });

  test('an empty page becomes the template, cursor after the first heading', () {
    final (text, cursor) = JournalTemplate.insert('', 'Situation:\n\nThought:\n');
    expect(text, 'Situation:\n\nThought:\n');
    expect(cursor, 'Situation:\n'.length);
  });

  test('existing writing is kept and the template follows a blank line', () {
    final (text, cursor) = JournalTemplate.insert('Today was long.  \n', 'Q:\nA');
    expect(text, 'Today was long.\n\nQ:\nA');
    expect(cursor, 'Today was long.\n\nQ:\n'.length);
  });
}
