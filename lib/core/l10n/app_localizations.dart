import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);
  static const delegate = _Delegate();
  static const supportedLocales = [Locale('ar'), Locale('en'), Locale('fr'), Locale('es'), Locale('de'), Locale('it'), Locale('pt'), Locale('ru'), Locale('tr'), Locale('zh'), Locale('ja'), Locale('ko'), Locale('hi'), Locale('id'), Locale('fa'), Locale('ur')];
  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  String text(String key) => key;
}
class _Delegate extends LocalizationsDelegate<AppLocalizations> { const _Delegate(); @override bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode); @override Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale); @override bool shouldReload(_Delegate old) => false; }
