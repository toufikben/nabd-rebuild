import 'package:flutter/material.dart';

/// AppColors — brand constants.
///
/// The text and surface colours below used to be fixed light-mode values, so
/// text rendered near-black on the dark scaffold and became unreadable in dark
/// mode. They are now resolved from [brightness], which `NabdApp` keeps in sync
/// with the active theme.
class AppColors {
  /// السمة النشطة. تضبطها `NabdApp` قبل بناء الودجت.
  static Brightness brightness = Brightness.light;

  static bool get isDark => brightness == Brightness.dark;

  static const primary = Color(0xFF6750A4);
  static const primaryGlow = Color(0xFF8B7AC7);
  static const primaryDark = Color(0xFF4F378B);
  static const primaryLight = Color(0xFFE9DDFF);
  static const secondary = Color(0xFF3F7D70);
  static const secondaryLight = Color(0xFFD4EEE7);
  static const success = Color(0xFF277A63);
  static const warning = Color(0xFF9A6500);
  static const danger = Color(0xFFBA1A1A);
  static const femininePrimary = Color(0xFF9A4774);
  static const feminineSecondary = Color(0xFF705A9E);
  static const masculinePrimary = Color(0xFF4E6096);
  static const masculineSecondary = Color(0xFF39736D);

  // ── Brightness-aware colours ──────────────────────────────────────────
  static Color get background =>
      isDark ? darkBackground : const Color(0xFFF8F7FC);
  static Color get surface => isDark ? darkSurface : const Color(0xFFFFFFFF);
  static Color get surfaceAlt =>
      isDark ? const Color(0xFF25222A) : const Color(0xFFF1EFF6);
  static Color get border =>
      isDark ? const Color(0xFF48434D) : const Color(0xFFDAD6E2);
  static Color get textPrimary =>
      isDark ? darkTextPrimary : const Color(0xFF1B1821);
  static Color get textSecondary =>
      isDark ? darkTextSecondary : const Color(0xFF625D69);
  static Color get textTertiary =>
      isDark ? darkTextTertiary : const Color(0xFF88818F);

  // ── Fixed base colours ────────────────────────────────────────────────
  static const feminineBackground = Color(0xFFFCF7FA);
  static const masculineBackground = Color(0xFFF6F8FC);
  static const darkBackground = Color(0xFF111014);
  static const darkSurface = Color(0xFF1C1A20);
  static const darkSurfaceAlt = Color(0xFF25222A);
  static const darkTextPrimary = Color(0xFFF0ECF4);
  static const darkTextSecondary = Color(0xFFC9C3CF);
  static const darkTextTertiary = Color(0xFF99929F);
}
