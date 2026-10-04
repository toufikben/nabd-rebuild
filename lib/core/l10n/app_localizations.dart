import 'package:flutter/material.dart';

import 'app_strings.dart';
import 'languages.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);
  static const delegate = _Delegate();

  /// Every language the app ships, from l10n/languages.json.
  static final List<Locale> supportedLocales = [
    for (final language in appLanguages) Locale(language.code),
  ];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  /// The shipped language for this locale, or English.
  AppLanguage get language => appLanguages.firstWhere(
        (l) => l.code == locale.languageCode,
        orElse: () => appLanguages.firstWhere((l) => l.code == 'en'),
      );

  /// Looks a key up in this language, falling back to English and then to
  /// the key itself so a missing translation is visible rather than blank.
  String t(String key) => S.of(locale.languageCode)[key] ?? S.en[key] ?? key;

  /// Back-compat shim for the older inline pair style.
  String text(String key) => t(key);

  /// Looks a key up without falling back, so callers can tell a translation
  /// from a miss. Needed for values that come from stored data.
  String? tryT(String key) => S.of(locale.languageCode)[key];

  bool get isArabic => locale.languageCode == 'ar';
  bool get isRtl => language.rtl;

  String get echoes => t('hub.feature.echoes.title');
  String get resolvedEcho => t('l10n.resolvedEcho');
  String get awaitingEcho => t('l10n.awaitingEcho');
  String get laterPositiveEntry => t('l10n.laterPositiveEntry');
  String get original => t('l10n.original');
  String get resolved => t('l10n.resolved');
  String get echoesEmpty => t('l10n.echoesEmpty');
  String get sage => t('hub.feature.sage.title');
  String get quietThought => t('l10n.quietThought');
  String get sageLocalNote => t('l10n.sageLocalNote');
  String get refresh => t('l10n.refresh');
  String get unknownMood => t('l10n.unknownMood');
  String get moodWeather => t('hub.feature.weather.title');
  String get today => t('l10n.today');
  String get thisMonth => t('l10n.this_month');
}

class _Delegate extends LocalizationsDelegate<AppLocalizations> {
  const _Delegate();
  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .any((l) => l.languageCode == locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);
  @override
  bool shouldReload(_Delegate old) => false;
}
