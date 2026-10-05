import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/l10n/languages.dart';
import 'package:nabd/core/theme/app_fonts.dart';
import 'package:nabd/core/theme/gender_themes.dart';

const _latin = AppLanguage(
    code: 'xx', nativeName: 'X', rtl: false, speechLocale: 'xx-XX',
    fonts: ['IBMPlexSansArabic', 'Nunito', 'Lora']);
const _cyrillic = AppLanguage(
    code: 'yy', nativeName: 'Y', rtl: false, speechLocale: 'yy-YY',
    fonts: ['Nunito', 'Lora']);
const _cjk = AppLanguage(
    code: 'zz', nativeName: 'Z', rtl: false, speechLocale: 'zz-ZZ', fonts: []);

void main() {
  test('automatic picks the first family that draws the language', () {
    expect(AppFont.auto.familyFor(_latin), 'IBMPlexSansArabic');
    expect(AppFont.auto.familyFor(_cyrillic), 'Nunito');
    expect(AppFont.auto.familyFor(_cjk), isNull);
  });

  test('a family that cannot draw the language falls back', () {
    expect(AppFont.plex.familyFor(_cyrillic), 'Nunito');
    expect(AppFont.lora.familyFor(_cjk), isNull);
    expect(AppFont.lora.familyFor(_latin), 'Lora');
    expect(AppFont.system.familyFor(_latin), isNull);
  });

  test('only drawable fonts are offered', () {
    expect(AppFontFamily.choicesFor(_cjk), [AppFont.auto, AppFont.system]);
    expect(AppFontFamily.choicesFor(_cyrillic),
        [AppFont.auto, AppFont.nunito, AppFont.lora, AppFont.system]);
  });

  test('unknown stored values read as automatic', () {
    expect(AppFontFamily.parse('lora'), AppFont.lora);
    expect(AppFontFamily.parse(null), AppFont.auto);
    expect(AppFontFamily.parse('comic'), AppFont.auto);
  });

  test('every palette builds in both brightnesses with any font', () {
    for (final palette in GenderTheme.values) {
      for (final brightness in Brightness.values) {
        for (final family in [null, 'Nunito']) {
          final theme = GenderThemes.build(palette,
              brightness: brightness, family: family);
          // No family leaves Material's platform default, the system font.
          if (family != null) {
            expect(theme.textTheme.bodyMedium?.fontFamily, family);
          }
          expect(theme.textTheme.bodyMedium?.fontFamilyFallback,
              isNot(contains(family)));
        }
      }
    }
  });

  test('every shipped language can be drawn or uses the system font', () {
    for (final language in appLanguages) {
      expect(
        AppFont.auto.familyFor(language),
        language.fonts.isEmpty ? isNull : language.fonts.first,
      );
    }
  });
}
