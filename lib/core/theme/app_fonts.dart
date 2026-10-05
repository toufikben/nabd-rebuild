import '../l10n/languages.dart';

/// The reading style a user picks. Automatic chooses the first bundled
/// family that draws every letter of the app language, and the phone's own
/// font for scripts none of them cover (Chinese, Hindi...).
enum AppFont { auto, plex, nunito, lora, system }

extension AppFontFamily on AppFont {
  /// The bundled family behind this choice; null for the system font.
  String? get bundledFamily => switch (this) {
        AppFont.plex => 'IBMPlexSansArabic',
        AppFont.nunito => 'Nunito',
        AppFont.lora => 'Lora',
        AppFont.auto || AppFont.system => null,
      };

  static AppFont parse(Object? stored) => AppFont.values.firstWhere(
        (f) => f.name == stored,
        orElse: () => AppFont.auto,
      );

  /// The family the theme uses for [language]. A bundled family that cannot
  /// draw the language falls back to the automatic choice, so a font picked
  /// in English never turns Japanese into boxes.
  String? familyFor(AppLanguage language) {
    final automatic = language.fonts.isEmpty ? null : language.fonts.first;
    return switch (this) {
      AppFont.system => null,
      AppFont.auto => automatic,
      _ => language.fonts.contains(bundledFamily) ? bundledFamily : automatic,
    };
  }

  /// The choices worth offering in [language]: automatic, the bundled
  /// families that draw it, and the system font.
  static List<AppFont> choicesFor(AppLanguage language) => [
        AppFont.auto,
        for (final font in [AppFont.plex, AppFont.nunito, AppFont.lora])
          if (language.fonts.contains(font.bundledFamily)) font,
        AppFont.system,
      ];
}
