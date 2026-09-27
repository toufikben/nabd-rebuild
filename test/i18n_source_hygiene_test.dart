import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the localizer call sites against the two mistakes that repeatedly
/// broke the analyze job during the i18n rollout:
///
///  1. a `const` widget tree wrapping `AppLocalizations.of(context).t(...)`,
///     which is not a constant expression;
///  2. a screen that calls the localizer without importing it.
void main() {
  final lib = Directory('lib');

  List<File> dartFiles() => lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('no const expression wraps a localizer lookup', () {
    final offenders = <String>[];
    for (final file in dartFiles()) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        final callsLocalizer = line.contains('AppLocalizations.of(context).t(') ||
            line.contains('l10n.t(');
        if (!line.contains('const ')) continue;

        // same line
        if (callsLocalizer) {
          offenders.add('${file.path}:${i + 1}  $line');
          continue;
        }
        // a const constructor whose argument list opens on this line
        if (RegExp(r'^\s*const\s+\w+\($').hasMatch(line) &&
            i + 1 < lines.length) {
          final next = lines[i + 1];
          if (next.contains('AppLocalizations.of(context).t(') ||
              next.contains('l10n.t(')) {
            offenders.add('${file.path}:${i + 1}  $line');
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('every file using the localizer imports it', () {
    final offenders = <String>[];
    for (final file in dartFiles()) {
      final source = file.readAsStringSync();
      final usesLocalizer = source.contains('AppLocalizations.of(context)') ||
          source.contains('l10n.t(') ||
          source.contains('AppLocalizations l10n');
      if (!usesLocalizer) continue;
      if (source.contains('l10n/app_localizations.dart')) continue;
      offenders.add(file.path);
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('no file carries a UTF-8 byte order mark', () {
    // A BOM survives compilation but breaks naive line-based tooling, which
    // is how the source got silently mangled more than once.
    final offenders = <String>[];
    for (final file in dartFiles()) {
      final bytes = file.readAsBytesSync();
      if (bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
