import 'dart:convert';
import 'dart:io';
import 'dart:ui';


import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/l10n/app_localizations.dart';
import 'package:nabd/core/l10n/app_strings.dart';
import 'package:nabd/core/l10n/languages.dart';

void main() {
  group('string table integrity', () {
    final placeholder = RegExp(r'\{[a-zA-Z_]+\}');
    String placeholders(String v) =>
        (placeholder.allMatches(v).map((m) => m.group(0)!).toSet().toList()
              ..sort())
            .join();

    for (final entry in S.byLanguage.entries) {
      final code = entry.key;
      final table = entry.value;

      test('$code has exactly the English keys', () {
        final missing = S.en.keys.where((k) => !table.containsKey(k)).toList()
          ..sort();
        final extra = table.keys.where((k) => !S.en.containsKey(k)).toList()
          ..sort();
        expect(missing, isEmpty, reason: '$code is missing: $missing');
        expect(extra, isEmpty, reason: '$code has unknown keys: $extra');
      });

      test('$code has no blank value', () {
        final blank = [
          for (final e in table.entries)
            if (e.value.trim().isEmpty) e.key,
        ];
        expect(blank, isEmpty, reason: 'blank in $code: $blank');
      });

      test('$code keeps every {placeholder}', () {
        final broken = [
          for (final e in S.en.entries)
            if (table[e.key] != null &&
                placeholders(e.value) != placeholders(table[e.key]!))
              e.key,
        ];
        expect(broken, isEmpty, reason: 'placeholders differ in $code: $broken');
      });
    }

    test('generated Dart tables match l10n/*.json', () {
      final languages = (jsonDecode(File('l10n/languages.json')
              .readAsStringSync()) as List)
          .map((l) => (l as Map)['code'] as String)
          .toSet();
      expect(S.byLanguage.keys.toSet(), languages,
          reason: 'run python3 scripts/gen_l10n.py');
      for (final code in languages) {
        final json = (jsonDecode(File('l10n/$code.json').readAsStringSync())
                as Map)
            .cast<String, String>();
        expect(S.of(code), json, reason: 'run python3 scripts/gen_l10n.py');
      }
    });

    test('every shipped language has a name and a speech locale', () {
      for (final language in appLanguages) {
        expect(language.nativeName.trim(), isNotEmpty);
        expect(language.speechLocale, startsWith(language.code));
      }
    });
  });

  group('brand name', () {
    test('Arabic keeps its own name', () {
      expect(S.ar['app.name'], 'نبض');
      expect(S.ar['android.app_name'], 'نبض');
      expect(S.ar['android.widget_title'], 'نبض');
    });

    test('every other language says Pulse', () {
      for (final entry in S.byLanguage.entries) {
        if (entry.key == 'ar') continue;
        expect(entry.value['app.name'], 'Pulse', reason: entry.key);
        expect(entry.value['android.app_name'], 'Pulse', reason: entry.key);
        expect(entry.value['android.widget_title'], 'Pulse',
            reason: entry.key);
      }
    });

    test('the old working title is gone from every non-Arabic string', () {
      // ".nabd" stays: it is the backup file extension, not the brand.
      final leaks = <String>[];
      for (final entry in S.byLanguage.entries) {
        if (entry.key == 'ar') continue;
        for (final string in entry.value.entries) {
          if (string.value.contains('Nabd')) {
            leaks.add('${entry.key}:${string.key}');
          }
        }
      }
      expect(leaks, isEmpty, reason: 'run python3 scripts/gen_l10n.py');
    });
  });

  group('lookup behaviour', () {
    test('Arabic locale returns the Arabic value', () {
      final l10n = AppLocalizations(const Locale('ar'));
      expect(l10n.t('home.title'), S.ar['home.title']);
      expect(l10n.t('settings.title'), 'الإعدادات');
    });

    test('English locale returns the English value', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.t('home.title'), 'My Journal');
      expect(l10n.t('settings.title'), 'Settings');
    });

    test('an untranslated locale falls back to English, not blank', () {
      final l10n = AppLocalizations(const Locale('xx'));
      expect(l10n.t('home.title'), 'My Journal');
    });

    test('an unknown key returns the key so the gap is visible', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.t('does.not.exist'), 'does.not.exist');
    });

    test('only locales with a real translation are advertised', () {
      // Advertising a language without a table would offer the user a
      // choice that silently falls back to English.
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
        S.byLanguage.keys.toSet(),
      );
    });
  });
}
