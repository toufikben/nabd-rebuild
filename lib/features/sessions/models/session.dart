import '../../../core/l10n/app_strings.dart';
import 'breathing_pattern.dart';
import 'session_activity.dart';

class Session {
  const Session({
    required this.id,
    required this.emoji,
    required this.isFree,
    required this.colorKey,
    required this.breathingPattern,
    required this.activity,
    this.ambientSound,
  });

  final String id;
  final String emoji;
  final bool isFree;
  final String colorKey;
  final BreathingPattern breathingPattern;
  final SessionActivity activity;
  final String? ambientSound;

  /// The feeling this session is for, in [languageCode]
  /// (`session.<id>.label`). Before this, every language saw the Arabic.
  String labelFor(String languageCode) =>
      S.of(languageCode)['session.$id.label'] ?? S.en['session.$id.label']!;
}
