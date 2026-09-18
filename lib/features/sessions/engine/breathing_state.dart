import 'package:flutter/foundation.dart';

import '../models/breathing_pattern.dart';

enum BreathingPhase {
  inhale,
  holdIn,
  exhale,
  holdOut,
  finished,
}

@immutable
class BreathingState {
  const BreathingState({
    required this.phase,
    required this.cycleNumber,
    required this.totalCycles,
    required this.secondInPhase,
    required this.phaseDurationSec,
    required this.progress,
    required this.isPaused,
    required this.isFinished,
  });

  factory BreathingState.initial(BreathingPattern pattern) {
    return BreathingState(
      phase: BreathingPhase.inhale,
      cycleNumber: 1,
      totalCycles: pattern.recommendedCycles,
      secondInPhase: 0,
      phaseDurationSec: pattern.inhaleSec,
      progress: 0.0,
      isPaused: false,
      isFinished: false,
    );
  }

  final BreathingPhase phase;
  final int cycleNumber;
  final int totalCycles;
  final int secondInPhase;
  final int phaseDurationSec;
  final double progress;
  final bool isPaused;
  final bool isFinished;

  int get secondsLeftInPhase {
    final left = phaseDurationSec - secondInPhase;
    return left < 0 ? 0 : left;
  }

  BreathingState copyWith({
    BreathingPhase? phase,
    int? cycleNumber,
    int? totalCycles,
    int? secondInPhase,
    int? phaseDurationSec,
    double? progress,
    bool? isPaused,
    bool? isFinished,
  }) {
    return BreathingState(
      phase: phase ?? this.phase,
      cycleNumber: cycleNumber ?? this.cycleNumber,
      totalCycles: totalCycles ?? this.totalCycles,
      secondInPhase: secondInPhase ?? this.secondInPhase,
      phaseDurationSec: phaseDurationSec ?? this.phaseDurationSec,
      progress: progress ?? this.progress,
      isPaused: isPaused ?? this.isPaused,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}
