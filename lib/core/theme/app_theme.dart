import 'package:flutter/material.dart';
import 'gender_themes.dart';

class AppTheme {
  static final light = GenderThemes.neutralTheme();
  static final dark = GenderThemes.neutralTheme(brightness: Brightness.dark);

  static ThemeData getTheme(String themeName, GenderTheme genderTheme) {
    final brightness = themeName == 'dark' ? Brightness.dark : Brightness.light;
    switch (genderTheme) {
      case GenderTheme.feminine:
        return GenderThemes.feminineTheme(brightness: brightness);
      case GenderTheme.masculine:
        return GenderThemes.masculineTheme(brightness: brightness);
      case GenderTheme.neutral:
        return GenderThemes.neutralTheme(brightness: brightness);
    }
  }
}
