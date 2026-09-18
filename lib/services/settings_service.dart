import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/theme/gender_themes.dart';

class SettingsService { static Future<void> init() async {} }
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());
class ThemeModeNotifier extends StateNotifier<ThemeMode> { ThemeModeNotifier() : super(ThemeMode.system) { _load(); } void _load() { state = switch (Hive.box('settings').get('themeMode', defaultValue: 'system')) { 'light' => ThemeMode.light, 'dark' => ThemeMode.dark, _ => ThemeMode.system }; } Future<void> setTheme(String value) async { await Hive.box('settings').put('themeMode', value); _load(); } }
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());
class LocaleNotifier extends StateNotifier<Locale> { LocaleNotifier() : super(const Locale('en')) { _load(); } void _load() { state = Locale(Hive.box('settings').get('language', defaultValue: 'en') as String); } Future<void> setLanguage(String value) async { await Hive.box('settings').put('language', value); state = Locale(value); } }
final genderThemeProvider = StateNotifierProvider<GenderThemeNotifier, GenderTheme>((ref) => GenderThemeNotifier());
class GenderThemeNotifier extends StateNotifier<GenderTheme> { GenderThemeNotifier() : super(GenderTheme.neutral) { _load(); } void _load() { final value = Hive.box('settings').get('genderTheme', defaultValue: 'neutral'); state = value == 'feminine' ? GenderTheme.feminine : value == 'masculine' ? GenderTheme.masculine : GenderTheme.neutral; } Future<void> setGenderTheme(String value) async { await Hive.box('settings').put('genderTheme', value); _load(); } }
