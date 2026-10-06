import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// The palette a user picks in Settings. The stored names of the first three
/// are kept for existing users; the labels shown are colour names.
enum GenderTheme { neutral, feminine, masculine, forest, sunset, lavender, ink }

/// The colours behind one palette.
class Palette {
  const Palette(this.primary, this.secondary, this.lightBackground,
      this.darkBackground);

  final Color primary;
  final Color secondary;
  final Color lightBackground;
  final Color darkBackground;
}

class GenderThemes {
  /// The default family; covers Arabic and Latin.
  static const fontFamily = 'IBMPlexSansArabic';

  /// Bundled families tried, in order, for letters the chosen family lacks
  /// (an Arabic word in an English entry, a Cyrillic name...). Anything
  /// left over falls to the phone's own fonts.
  static const fallbackFamilies = ['IBMPlexSansArabic', 'Nunito'];

  static const palettes = <GenderTheme, Palette>{
    GenderTheme.neutral: Palette(AppColors.primary, AppColors.secondary,
        Color(0xFFFAF8F5), AppColors.darkBackground),
    GenderTheme.feminine: Palette(AppColors.femininePrimary,
        AppColors.feminineSecondary, AppColors.feminineBackground,
        Color(0xFF171116)),
    GenderTheme.masculine: Palette(AppColors.masculinePrimary,
        AppColors.masculineSecondary, AppColors.masculineBackground,
        Color(0xFF0F151B)),
    GenderTheme.forest: Palette(Color(0xFF3F7D58), Color(0xFFB08D57),
        Color(0xFFF6F8F3), Color(0xFF101511)),
    GenderTheme.sunset: Palette(Color(0xFFD0643F), Color(0xFFC2486F),
        Color(0xFFFFF7F2), Color(0xFF1A1210)),
    GenderTheme.lavender: Palette(Color(0xFF8A6FC9), Color(0xFF5FA8B5),
        Color(0xFFF8F6FD), Color(0xFF141220)),
    GenderTheme.ink: Palette(Color(0xFF3E4A5C), Color(0xFF8C7A5B),
        Color(0xFFF7F6F3), Color(0xFF111215)),
  };

  /// One palette in one brightness, set in [family] (null: the system font).
  static ThemeData build(
    GenderTheme palette, {
    Brightness brightness = Brightness.light,
    String? family = fontFamily,
  }) {
    final colours = palettes[palette]!;
    return _theme(
      colours.primary,
      colours.secondary,
      brightness,
      brightness == Brightness.dark
          ? colours.darkBackground
          : colours.lightBackground,
      family,
    );
  }

  static ThemeData neutralTheme({Brightness brightness = Brightness.light}) =>
      build(GenderTheme.neutral, brightness: brightness);

  /// Arabic needs more line height than Latin to keep its marks clear of the
  /// line above, so the whole scale breathes a little more than Material's.
  static TextTheme _textTheme(
      TextTheme base, ColorScheme scheme, String? family) {
    final fallback = [
      for (final f in fallbackFamilies)
        if (f != family) f,
    ];
    TextStyle? tune(TextStyle? style, {FontWeight? weight, double? height}) =>
        style?.copyWith(
          fontFamily: family,
          fontFamilyFallback: fallback,
          fontWeight: weight ?? style.fontWeight,
          height: height ?? 1.45,
          letterSpacing: 0,
        );
    return base.copyWith(
      displayLarge: tune(base.displayLarge, weight: FontWeight.w700, height: 1.2),
      displayMedium: tune(base.displayMedium, weight: FontWeight.w700, height: 1.2),
      displaySmall: tune(base.displaySmall, weight: FontWeight.w700, height: 1.25),
      headlineLarge: tune(base.headlineLarge, weight: FontWeight.w700, height: 1.3),
      headlineMedium: tune(base.headlineMedium, weight: FontWeight.w700, height: 1.3),
      headlineSmall: tune(base.headlineSmall, weight: FontWeight.w700, height: 1.35),
      titleLarge: tune(base.titleLarge, weight: FontWeight.w700, height: 1.35),
      titleMedium: tune(base.titleMedium, weight: FontWeight.w600),
      titleSmall: tune(base.titleSmall, weight: FontWeight.w600),
      bodyLarge: tune(base.bodyLarge, height: 1.7),
      bodyMedium: tune(base.bodyMedium, height: 1.6),
      bodySmall: tune(base.bodySmall, height: 1.5),
      labelLarge: tune(base.labelLarge, weight: FontWeight.w600),
      labelMedium: tune(base.labelMedium, weight: FontWeight.w600),
      labelSmall: tune(base.labelSmall, weight: FontWeight.w600),
    ).apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }

  static ThemeData _theme(
    Color seed,
    Color secondary,
    Brightness brightness,
    Color background,
    String? family,
  ) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    ).copyWith(
      primary: dark ? null : seed,
      secondary: secondary,
      tertiary: AppColors.pulse,
      surface: dark ? AppColors.darkSurface : const Color(0xFFFFFFFF),
      surfaceContainerLowest: dark ? const Color(0xFF0E0D13) : Colors.white,
      surfaceContainerLow: dark ? AppColors.darkSurface : const Color(0xFFFFFDFB),
      surfaceContainer: dark ? AppColors.darkSurfaceAlt : const Color(0xFFF4F1EC),
      surfaceContainerHigh: dark ? const Color(0xFF2B2935) : const Color(0xFFEEEAE4),
      surfaceContainerHighest:
          dark ? const Color(0xFF33303E) : const Color(0xFFE7E2DB),
      outline: dark ? const Color(0xFF4A4655) : const Color(0xFFD9D3CB),
      outlineVariant: dark ? const Color(0xFF34313D) : const Color(0xFFE8E3DC),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: family,
      fontFamilyFallback: [
        for (final f in fallbackFamilies)
          if (f != family) f,
      ],
    );
    final text = _textTheme(base.textTheme, scheme, family);
    final radius = BorderRadius.circular(20);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleLarge?.copyWith(fontSize: 21),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: dark ? scheme.surfaceContainer : Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? scheme.surfaceContainer : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: const StadiumBorder(),
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outline),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const StadiumBorder(),
          textStyle: text.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: dark ? scheme.surfaceContainerLow : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelSmall?.copyWith(
            fontSize: 11.5,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.onPrimaryContainer
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        extendedTextStyle: text.labelLarge?.copyWith(fontSize: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: dark ? scheme.surfaceContainer : Colors.white,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        labelStyle: text.labelMedium,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        iconColor: scheme.primary,
        titleTextStyle: text.titleSmall,
        subtitleTextStyle:
            text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? scheme.surfaceContainerLow : Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? scheme.surfaceContainerLow : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: text.titleLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? const Icon(Icons.check, size: 14)
              : null,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
