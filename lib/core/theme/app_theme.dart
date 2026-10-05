import 'package:flutter/material.dart';
import 'gender_themes.dart';

class AppTheme {
  static final light = GenderThemes.neutralTheme();
  static final dark = GenderThemes.neutralTheme(brightness: Brightness.dark);

  static ThemeData getTheme(
    String themeName,
    GenderTheme genderTheme, {
    String? fontFamily = GenderThemes.fontFamily,
  }) =>
      GenderThemes.build(
        genderTheme,
        brightness: themeName == 'dark' ? Brightness.dark : Brightness.light,
        family: fontFamily,
      );
}
