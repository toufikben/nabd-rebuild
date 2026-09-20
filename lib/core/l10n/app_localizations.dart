import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);
  static const delegate = _Delegate();
  static const supportedLocales = [
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
    Locale('es'),
    Locale('de'),
    Locale('it'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh'),
    Locale('ja'),
    Locale('ko'),
    Locale('hi'),
    Locale('id'),
    Locale('fa'),
    Locale('ur')
  ];
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  String text(String key) => key;
  bool get isArabic => locale.languageCode == 'ar';
  String get echoes => _value('echoes', 'Echoes', 'أصداء');
  String get resolvedEcho =>
      _value('resolvedEcho', 'Resolved echo', 'صدى تم تجاوزه');
  String get awaitingEcho => _value(
      'awaitingEcho', 'An echo waiting for a response', 'صدى ينتظر استجابة');
  String get laterPositiveEntry => _value(
      'laterPositiveEntry', 'Later positive entry', 'مدخلة إيجابية لاحقة');
  String get original => _value('original', 'Original', 'الأصلية');
  String get resolved => _value('resolved', 'Resolved', 'تم التجاوز');
  String get echoesEmpty => _value(
      'echoesEmpty',
      'Echoes appear when a difficult mood has a later positive entry 3–90 days afterward.',
      'تظهر الأصداء عندما يتبع مزاج صعب مدخلة إيجابية بعد 3 إلى 90 يومًا.');
  String get sage => _value('sage', 'Sage', 'الحكيم');
  String get quietThought =>
      _value('quietThought', 'A quiet thought', 'فكرة هادئة');
  String get sageLocalNote => _value(
      'sageLocalNote',
      'Sage uses the app’s local library. It changes only when you press Refresh.',
      'يعتمد الحكيم على مكتبة المحتوى المحلية في التطبيق، ولا يتغير إلا عند الضغط على تحديث.');
  String get refresh => _value('refresh', 'Refresh', 'تحديث');
  String get unknownMood =>
      _value('unknownMood', 'Unknown mood', 'مزاج غير معروف');
  String _value(String key, String english, String arabic) =>
      isArabic ? arabic : english;
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
