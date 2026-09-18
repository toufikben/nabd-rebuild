import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/breathing_pattern.dart';
import 'breathing_state.dart';

class BreathingEngine {
  BreathingEngine(this.pattern)
      : _plan = _buildPhasePlan(pattern),
        state = ValueNotifier<BreathingState>(
          BreathingState.initial(pattern),
        );

  final BreathingPattern pattern;
  final ValueNotifier<BreathingState> state;
  final List<_PhaseSegment> _plan;
  final Stopwatch _stopwatch = Stopwatch();

  Timer? _timer;
  bool _paused = false;
  bool _finished = false;
  bool _disposed = false;

  void start() {
    if (_disposed) return;

    _timer?.cancel();
    _timer = null;

    _stopwatch
      ..reset()
      ..start();

    _paused = false;
    _finished = false;

    state.value = BreathingState.initial(pattern);

    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      _onTick,
    );
  }

  void pause() {
    if (_disposed) return;
    if (_paused || _finished) return;

    _paused = true;
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();

    state.value = state.value.copyWith(isPaused: true);
  }

  void resume() {
    if (_disposed) return;
    if (!_paused || _finished) return;

    _paused = false;
    _stopwatch.start();

    state.value = state.value.copyWith(isPaused: false);

    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      _onTick,
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
  }

  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    state.dispose();
  }

  void _onTick(Timer _) {
    if (_disposed || _paused || _finished) return;

    final int elapsedMs = _stopwatch.elapsedMilliseconds;
    final next = _computeStateFrom(elapsedMs);

    if (next.isFinished) {
      _finished = true;
      _timer?.cancel();
      _timer = null;
      _stopwatch.stop();
    }

    state.value = next;
  }

  BreathingState _computeStateFrom(int elapsedMs) {
    final int totalCycleMs = pattern.cycleSec * 1000;

    if (totalCycleMs <= 0 || pattern.recommendedCycles <= 0) {
      return BreathingState(
        phase: BreathingPhase.finished,
        cycleNumber: 0,
        totalCycles: pattern.recommendedCycles,
        secondInPhase: 0,
        phaseDurationSec: 0,
        progress: 0.0,
        isPaused: false,
        isFinished: true,
      );
    }

    final int cycleIndex = elapsedMs ~/ totalCycleMs;
    final int msInCycle = elapsedMs % totalCycleMs;
    final int cycleNumber = cycleIndex + 1;

    if (cycleNumber > pattern.recommendedCycles) {
      return BreathingState(
        phase: BreathingPhase.finished,
        cycleNumber: pattern.recommendedCycles,
        totalCycles: pattern.recommendedCycles,
        secondInPhase: 0,
        phaseDurationSec: 0,
        progress: 0.0,
        isPaused: false,
        isFinished: true,
      );
    }

    int cursor = 0;

    for (final seg in _plan) {
      if (msInCycle < cursor + seg.durationMs) {
        final int elapsedInPhaseMs = msInCycle - cursor;
        final int secondInPhase = elapsedInPhaseMs ~/ 1000;
        final int phaseDurationSec = seg.durationMs ~/ 1000;

        final double raw = seg.durationMs == 0
            ? 0.0
            : elapsedInPhaseMs / seg.durationMs;

        double progress;

        switch (seg.phase) {
          case BreathingPhase.inhale:
            progress = raw;
            break;
          case BreathingPhase.holdIn:
            progress = 1.0;
            break;
          case BreathingPhase.exhale:
            progress = 1.0 - raw;
            break;
          case BreathingPhase.holdOut:
            progress = 0.0;
            break;
          case BreathingPhase.finished:
            progress = 0.0;
            break;
        }

        return BreathingState(
          phase: seg.phase,
          cycleNumber: cycleNumber,
          totalCycles: pattern.recommendedCycles,
          secondInPhase: secondInPhase,
          phaseDurationSec: phaseDurationSec,
          progress: progress,
          isPaused: false,
          isFinished: false,
        );
      }

      cursor += seg.durationMs;
    }

    final fallback = _plan.last;

    return BreathingState(
      phase: fallback.phase,
      cycleNumber: cycleNumber,
      totalCycles: pattern.recommendedCycles,
      secondInPhase: 0,
      phaseDurationSec: fallback.durationMs ~/ 1000,
      progress: 0.0,
      isPaused: false,
      isFinished: false,
    );
  }

  List<_PhaseSegment> _buildPhasePlan(BreathingPattern p) {
    final segments = <_PhaseSegment>[];

    if (p.inhaleSec > 0) {
      segments.add(
        _PhaseSegment(BreathingPhase.inhale, p.inhaleSec * 1000),
      );
    }

    if (p.holdInSec > 0) {
      segments.add(
        _PhaseSegment(BreathingPhase.holdIn, p.holdInSec * 1000),
      );
    }

    if (p.exhaleSec > 0) {
      segments.add(
        _PhaseSegment(BreathingPhase.exhale, p.exhaleSec * 1000),
      );
    }

    if (p.holdOutSec > 0) {
      segments.add(
        _PhaseSegment(BreathingPhase.holdOut, p.holdOutSec * 1000),
      );
    }

    return segments;
  }
}

class _PhaseSegment {
  const _PhaseSegment(this.phase, this.durationMs);

  final BreathingPhase phase;
  final int durationMs;
}
