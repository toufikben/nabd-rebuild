import 'package:flutter/material.dart';
import 'app_colors.dart';

enum GenderTheme { neutral, feminine, masculine }

class GenderThemes {
  static ThemeData neutralTheme({Brightness brightness = Brightness.light}) =>
      _theme(
          AppColors.primary,
          AppColors.secondary,
          brightness,
          brightness == Brightness.dark
              ? AppColors.darkBackground
              : AppColors.background);

  static ThemeData feminineTheme({Brightness brightness = Brightness.light}) =>
      _theme(
          AppColors.femininePrimary,
          AppColors.feminineSecondary,
          brightness,
          brightness == Brightness.dark
              ? const Color(0xFF171116)
              : AppColors.feminineBackground);

  static ThemeData masculineTheme({Brightness brightness = Brightness.light}) =>
      _theme(
          AppColors.masculinePrimary,
          AppColors.masculineSecondary,
          brightness,
          brightness == Brightness.dark
              ? const Color(0xFF11151E)
              : AppColors.masculineBackground);

  static ThemeData _theme(
      Color seed, Color secondary, Brightness brightness, Color background) {
    final dark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(seedColor: seed, brightness: brightness).copyWith(
      secondary: secondary,
      surface: dark ? AppColors.darkSurface : AppColors.surface,
      surfaceContainerLowest:
          dark ? const Color(0xFF0D0C10) : const Color(0xFFFCFBFF),
      surfaceContainerLow:
          dark ? AppColors.darkSurface : const Color(0xFFF8F6FC),
      surfaceContainer:
          dark ? AppColors.darkSurfaceAlt : const Color(0xFFF2EFF7),
      surfaceContainerHigh:
          dark ? const Color(0xFF2B2830) : const Color(0xFFEDE9F2),
      outline: dark ? const Color(0xFF48434D) : AppColors.border,
      outlineVariant: dark ? const Color(0xFF35313A) : const Color(0xFFE5E1E9),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: scheme.onSurface),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: scheme.outlineVariant)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide(color: scheme.primary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surface,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainer,
        selectedColor: scheme.secondaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        iconColor: scheme.primary,
      ),
    );
  }
}
