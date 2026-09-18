import 'breathing_pattern.dart';
import 'session_activity.dart';

class Session {
  const Session({
    required this.id,
    required this.emotionLabel,
    required this.emoji,
    required this.isFree,
    required this.colorKey,
    required this.breathingPattern,
    required this.activity,
    required this.voiceOpening,
    required this.voiceTransition,
    required this.voiceClosing,
    this.ambientSound,
  });

  final String id;
  final String emotionLabel;
  final String emoji;
  final bool isFree;
  final String colorKey;
  final BreathingPattern breathingPattern;
  final SessionActivity activity;
  final String voiceOpening;
  final String voiceTransition;
  final String voiceClosing;
  final String? ambientSound;
}
