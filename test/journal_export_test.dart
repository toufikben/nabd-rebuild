import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nabd/models/journal_entry.dart';
import 'package:nabd/services/journal_export_service.dart';

void main() {
  setUpAll(() => initializeDateFormatting());

  final entries = [
    JournalEntry(
      title: 'يوم جميل',
      content: 'كتبت عن البحر.\n\nثم عدت إلى البيت.',
      createdAt: DateTime(2026, 10, 2, 9),
      updatedAt: DateTime(2026, 10, 2, 9),
      mood: 'happy',
      tags: const ['family'],
    ),
    JournalEntry(
      title: 'First',
      content: 'An English morning.',
      createdAt: DateTime(2026, 10, 1, 8),
      updatedAt: DateTime(2026, 10, 1, 8),
    ),
  ];

  final service = JournalExportService(
    loadAsset: (asset) async =>
        ByteData.sublistView(await File(asset).readAsBytes()),
  );

  test('Markdown reads oldest first with titles, mood and tags', () {
    final markdown = service.toMarkdown(
      entries,
      title: 'نبض',
      languageCode: 'ar',
    );
    expect(markdown, startsWith('# نبض'));
    expect(markdown.indexOf('First'), lessThan(markdown.indexOf('يوم جميل')));
    expect(markdown, contains('#family'));
    expect(markdown, contains('كتبت عن البحر.'));
  });

  test('PDF renders Arabic and English pages', () async {
    final bytes = await service.toPdf(
      entries,
      title: 'Nabd',
      languageCode: 'en',
    );
    expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
}
