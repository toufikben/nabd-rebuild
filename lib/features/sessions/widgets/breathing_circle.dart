import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../engine/breathing_state.dart';

class BreathingCircle extends StatelessWidget {
  const BreathingCircle({
    super.key,
    required this.state,
    this.accentColor,
    this.size = 240,
  });

  final BreathingState state;
  final Color? accentColor;
  final double size;

  Color _accent(BuildContext context) {
    return accentColor ?? Theme.of(context).colorScheme.primary;
  }

  String _phaseLabel(AppLocalizations l10n, BreathingPhase phase) {
    return l10n.t(switch (phase) {
      BreathingPhase.inhale => 'breathing.in',
      BreathingPhase.holdIn => 'breathing.hold',
      BreathingPhase.exhale => 'breathing.out',
      BreathingPhase.holdOut => 'breathing.rest',
      BreathingPhase.finished => 'breathing.done',
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color accent = _accent(context);
    final double progress =
        state.progress.clamp(0.0, 1.0).toDouble();
    final double side = size * (0.55 + 0.45 * progress);

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          width: side,
          height: side,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                accent.withValues(alpha: 0.45),
                accent.withValues(alpha: 0.12),
                accent.withValues(alpha: 0.0),
              ],
              stops: const <double>[0.0, 0.6, 1.0],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _phaseLabel(AppLocalizations.of(context), state.phase),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${state.secondsLeftInPhase}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w300,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
