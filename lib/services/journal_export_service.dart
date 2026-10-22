import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/l10n/languages.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';

/// Turns the journal into a readable document: Markdown for notes apps and
/// archives, PDF for printing or keeping. Unlike a `.nabd` backup these are
/// not encrypted, so the screen says so before saving them.
class JournalExportService {
  JournalExportService({Future<ByteData> Function(String asset)? loadAsset})
      : _loadAsset = loadAsset ?? rootBundle.load;

  final Future<ByteData> Function(String asset) _loadAsset;

  static final _arabic = RegExp('[؀-ۿ]');

  static bool isArabicText(String text) => _arabic.hasMatch(text);

  /// Oldest first, the way a diary is read.
  static List<JournalEntry> _ordered(List<JournalEntry> entries) =>
      [...entries]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  String toMarkdown(
    List<JournalEntry> entries, {
    required String title,
    required String languageCode,
  }) {
    final dateFormat = DateFormat.yMMMMEEEEd(languageCode).add_jm();
    final buffer = StringBuffer('# $title\n\n');
    for (final entry in _ordered(entries)) {
      final mood = Mood.getById(entry.mood);
      buffer.writeln('## ${dateFormat.format(entry.createdAt)}');
      if (entry.title.trim().isNotEmpty) {
        buffer.writeln('\n### ${entry.title.trim()}');
      }
      final meta = [
        if (mood != null) '${mood.emoji} ${mood.label(languageCode)}',
        ...entry.tags.map((tag) => '#$tag'),
      ];
      if (meta.isNotEmpty) buffer.writeln('\n_${meta.join(' · ')}_');
      buffer
        ..writeln()
        ..writeln(entry.content.trim())
        ..writeln()
        ..writeln('---')
        ..writeln();
    }
    return buffer.toString();
  }

  Future<Uint8List> toPdf(
    List<JournalEntry> entries, {
    required String title,
    required String languageCode,
  }) async {
    final language = appLanguages.firstWhere(
      (l) => l.code == languageCode,
      orElse: () => appLanguages.firstWhere((l) => l.code == 'en'),
    );
    // A PDF cannot borrow the phone's fonts, so it uses the bundled family
    // that draws the language, with Plex for any Arabic in the entries.
    final family =
        language.fonts.isEmpty ? 'IBMPlexSansArabic' : language.fonts.first;
    final regular = pw.Font.ttf(
      await _loadAsset('assets/fonts/$family-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await _loadAsset('assets/fonts/$family-Bold.ttf'),
    );
    final arabic = family == 'IBMPlexSansArabic'
        ? <pw.Font>[]
        : [
            pw.Font.ttf(
              await _loadAsset('assets/fonts/IBMPlexSansArabic-Regular.ttf'),
            ),
          ];
    final rtl = language.rtl;
    final dateFormat = DateFormat.yMMMMEEEEd(languageCode);
    final document = pw.Document(title: title, creator: 'Nabd');

    pw.TextDirection directionOf(String text) =>
        isArabicText(text) ? pw.TextDirection.rtl : pw.TextDirection.ltr;

    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      theme: pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        fontFallback: arabic,
      ),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Text(
              title,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.center,
        child: pw.Text(
          '${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 24),
        for (final entry in _ordered(entries)) ...[
          pw.Text(
            dateFormat.format(entry.createdAt),
            style:
                const pw.TextStyle(fontSize: 10, color: PdfColors.deepPurple),
          ),
          if (entry.title.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                entry.title.trim(),
                textDirection: directionOf(entry.title),
                style:
                    pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
              ),
            ),
          if (Mood.getById(entry.mood) != null || entry.tags.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 2),
              child: pw.Text(
                [
                  if (Mood.getById(entry.mood) != null)
                    Mood.getById(entry.mood)!.label(languageCode),
                  ...entry.tags.map((tag) => '#$tag'),
                ].join('  ·  '),
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
            ),
          pw.SizedBox(height: 6),
          for (final paragraph
              in entry.content.trim().split(RegExp(r'\n\s*\n')))
            if (paragraph.trim().isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(
                  paragraph.trim(),
                  textDirection: directionOf(paragraph),
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
                ),
              ),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 10),
        ],
      ],
    ));
    return document.save();
  }
}
