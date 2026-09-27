import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/l10n/app_localizations.dart';
import 'package:nabd/core/l10n/app_strings.dart';

void main() {
  group('string table integrity', () {
    test('every Arabic key has an English counterpart', () {
      final missing = S.ar.keys.where((k) => !S.en.containsKey(k)).toList()
        ..sort();
      expect(
        missing,
        isEmpty,
        reason: 'keys missing from the English table: $missing',
      );
    });

    test('every English key has an Arabic counterpart', () {
      final missing = S.en.keys.where((k) => !S.ar.containsKey(k)).toList()
        ..sort();
      expect(
        missing,
        isEmpty,
        reason: 'keys missing from the Arabic table: $missing',
      );
    });

    test('no value is blank', () {
      final blank = <String>[];
      S.ar.forEach((k, v) {
        if (v.trim().isEmpty) blank.add('ar:$k');
      });
      S.en.forEach((k, v) {
        if (v.trim().isEmpty) blank.add('en:$k');
      });
      expect(blank, isEmpty, reason: 'blank values: $blank');
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
      final l10n = AppLocalizations(const Locale('fr'));
      expect(l10n.t('home.title'), 'My Journal');
    });

    test('an unknown key returns the key so the gap is visible', () {
      final l10n = AppLocalizations(const Locale('en'));
      expect(l10n.t('does.not.exist'), 'does.not.exist');
    });

    test('only locales with a real translation are advertised', () {
      // The app ships ar + en only. Advertising more would offer the user a
      // language choice that silently falls back to English.
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
        {'ar', 'en'},
      );
    });
  });
}
