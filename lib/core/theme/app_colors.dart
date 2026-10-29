import 'package:flutter/material.dart';

/// AppColors — the Nabd palette.
///
/// A calm dusk indigo carries the brand; a warm coral is the "pulse", used
/// sparingly for the heartbeat moments (streak, launch, favourites); a soft
/// teal stands for growth (garden, sessions). Surfaces are warm off-whites in
/// light mode and deep ink in dark mode, so long reading stays easy on the eye.
///
/// The text and surface getters follow [brightness], which `NabdApp` keeps in
/// sync with the active theme. New code should prefer `Theme.of(context)`.
class AppColors {
  /// The active brightness, set by `NabdApp` before descendants build.
  static Brightness brightness = Brightness.light;

  static bool get isDark => brightness == Brightness.dark;

  // ── Brand ─────────────────────────────────────────────────────────────
  static const primary = Color(0xFF5B4FCF);
  static const primaryGlow = Color(0xFF8C82F0);
  static const primaryDark = Color(0xFF3F35A3);
  static const primaryLight = Color(0xFFE6E2FF);
  static const pulse = Color(0xFFE8746A);
  static const pulseLight = Color(0xFFFFE1DC);
  static const secondary = Color(0xFF2F9E8F);
  static const secondaryLight = Color(0xFFD3F1EB);
  static const success = Color(0xFF2E8B6E);
  static const warning = Color(0xFFB7791F);
  static const danger = Color(0xFFC4413A);

  /// The colour of the native launch window (`background.png`). The first
  /// Flutter frame uses the same ink so the splash does not flash a different
  /// background between the system splash and the app's own one.
  static const splashBackground = Color(0xFF0A0D14);

  /// Alternative palettes the user can pick in Settings.
  static const femininePrimary = Color(0xFFB4537E);
  static const feminineSecondary = Color(0xFF7D62B8);
  static const masculinePrimary = Color(0xFF2F6690);
  static const masculineSecondary = Color(0xFF3A8D84);

  /// The dusk gradient behind the lock screen and Pro.
  static const brandGradient = LinearGradient(
    colors: [Color(0xFF3F35A3), Color(0xFF5B4FCF), Color(0xFF8C6FE0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// The warmer gradient for celebration moments.
  static const pulseGradient = LinearGradient(
    colors: [Color(0xFFE8746A), Color(0xFFF2A65A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Brightness-aware colours ──────────────────────────────────────────
  static Color get background =>
      isDark ? darkBackground : const Color(0xFFFAF8F5);
  static Color get surface => isDark ? darkSurface : const Color(0xFFFFFFFF);
  static Color get surfaceAlt =>
      isDark ? darkSurfaceAlt : const Color(0xFFF2EFEA);
  static Color get border =>
      isDark ? const Color(0xFF3A3742) : const Color(0xFFE4DFD8);
  static Color get textPrimary =>
      isDark ? darkTextPrimary : const Color(0xFF1D1B26);
  static Color get textSecondary =>
      isDark ? darkTextSecondary : const Color(0xFF5E5A6B);
  static Color get textTertiary =>
      isDark ? darkTextTertiary : const Color(0xFF8E8999);

  // ── Fixed base colours ────────────────────────────────────────────────
  static const feminineBackground = Color(0xFFFCF6F8);
  static const masculineBackground = Color(0xFFF5F8FA);
  static const darkBackground = Color(0xFF121118);
  static const darkSurface = Color(0xFF1B1A23);
  static const darkSurfaceAlt = Color(0xFF24222E);
  static const darkTextPrimary = Color(0xFFF1EFF7);
  static const darkTextSecondary = Color(0xFFC6C2D2);
  static const darkTextTertiary = Color(0xFF948FA3);
}
