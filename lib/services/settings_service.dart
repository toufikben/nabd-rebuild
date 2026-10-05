import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/l10n/languages.dart';
import '../core/theme/app_fonts.dart';
import '../core/theme/gender_themes.dart';

class SettingsService { static Future<void> init() async {} }

/// The phone's language when the app speaks it, English otherwise. Used
/// until the user picks a language, so an Arabic phone opens in Arabic.
String deviceLanguage() {
  final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return stringTables.containsKey(code) ? code : 'en';
}
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());
class ThemeModeNotifier extends StateNotifier<ThemeMode> { ThemeModeNotifier() : super(ThemeMode.system) { _load(); } void _load() { if (!mounted) return; state = switch (Hive.box('settings').get('themeMode', defaultValue: 'system')) { 'light' => ThemeMode.light, 'dark' => ThemeMode.dark, _ => ThemeMode.system }; } Future<void> setTheme(String value) async { await Hive.box('settings').put('themeMode', value); if (mounted) _load(); } }
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());
class LocaleNotifier extends StateNotifier<Locale> { LocaleNotifier() : super(const Locale('en')) { _load(); } void _load() { if (!mounted) return; final stored = Hive.box('settings').get('language'); state = Locale(stored is String ? stored : deviceLanguage()); } Future<void> setLanguage(String value) async { await Hive.box('settings').put('language', value); if (mounted) state = Locale(value); } }
final genderThemeProvider = StateNotifierProvider<GenderThemeNotifier, GenderTheme>((ref) => GenderThemeNotifier());
class GenderThemeNotifier extends StateNotifier<GenderTheme> { GenderThemeNotifier() : super(GenderTheme.neutral) { _load(); } void _load() { if (!mounted) return; final value = Hive.box('settings').get('genderTheme', defaultValue: 'neutral'); state = GenderTheme.values.firstWhere((t) => t.name == value, orElse: () => GenderTheme.neutral); } Future<void> setGenderTheme(String value) async { await Hive.box('settings').put('genderTheme', value); if (mounted) _load(); } }

/// The reading style (font) chosen in Settings.
final appFontProvider = StateNotifierProvider<AppFontNotifier, AppFont>((ref) => AppFontNotifier());

class AppFontNotifier extends StateNotifier<AppFont> {
  AppFontNotifier() : super(AppFont.auto) {
    if (mounted) state = AppFontFamily.parse(Hive.box('settings').get('app_font'));
  }

  Future<void> set(AppFont font) async {
    await Hive.box('settings').put('app_font', font.name);
    if (mounted) state = font;
  }
}
