import 'package:flutter/material.dart';

/// A guided page: headings the writer fills in. Text lives in app_strings
/// under `template.<id>.title|hint|body`.
class JournalTemplate {
  const JournalTemplate(this.id, this.icon);

  final String id;
  final IconData icon;

  String get titleKey => 'template.$id.title';
  String get hintKey => 'template.$id.hint';
  String get bodyKey => 'template.$id.body';

  static const all = <JournalTemplate>[
    JournalTemplate('thought', Icons.psychology_alt_outlined),
    JournalTemplate('gratitude', Icons.favorite_outline_rounded),
    JournalTemplate('morning', Icons.wb_twilight_rounded),
    JournalTemplate('evening', Icons.nights_stay_outlined),
    JournalTemplate('weekly', Icons.date_range_outlined),
  ];

  /// Puts [body] into [current] text: alone if the page is empty, otherwise
  /// after a blank line. Returns the new text and where the cursor should go:
  /// the end of the first heading line, ready for the first answer.
  static (String text, int cursor) insert(String current, String body) {
    final base = current.trimRight();
    final prefix = base.isEmpty ? '' : '$base\n\n';
    final text = '$prefix$body';
    final firstBreak = body.indexOf('\n');
    final cursor = prefix.length + (firstBreak < 0 ? body.length : firstBreak + 1);
    return (text, cursor);
  }
}
