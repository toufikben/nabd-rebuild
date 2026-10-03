import 'l10n/app_localizations.dart';

/// Gentle questions to start writing, one per day so the editor and the
/// home-screen widget agree on today's prompt.
class WritingPrompts {
  const WritingPrompts._();

  static const count = 21;

  static String keyFor(DateTime day) {
    final dayOfYear =
        day.difference(DateTime(day.year)).inDays + day.year * 366;
    return 'prompt.${dayOfYear % count + 1}';
  }

  static String today(AppLocalizations l10n, [DateTime? now]) =>
      l10n.t(keyFor(now ?? DateTime.now()));
}
