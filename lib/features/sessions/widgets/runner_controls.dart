import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';

class RunnerControls extends StatelessWidget {
  const RunnerControls({
    super.key,
    required this.isPaused,
    required this.onPauseToggle,
    required this.onStop,
  });

  final bool isPaused;
  final VoidCallback onPauseToggle;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _ControlButton(
          icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          label: l10n.t(isPaused ? 'runner.resume' : 'runner.pause'),
          onTap: onPauseToggle,
        ),
        const SizedBox(width: 36),
        _ControlButton(
          icon: Icons.close_rounded,
          label: l10n.t('runner.finish'),
          onTap: onStop,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Icon and label are one button: the label is tappable too, and a
    // screen reader hears "Pause, button" rather than an unnamed icon.
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Material(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.4),
                shape: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(
                    icon,
                    size: 24,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
