import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../services/review_prompt.dart';

/// BreathingScreen — تمرين تنفس قبل الكتابة.
///
/// الفكرة: تهدئة الجهاز العصبي قبل التعبير العاطفي.
class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  late AppLocalizations l10n;
  late AnimationController _controller;
  int _cycleCount = 0;
  bool _finished = false;
  static const _totalCycles = 4;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _startCycle();
  }

  Future<void> _startCycle() async {
    while (_cycleCount < _totalCycles && mounted) {
      // Inhale (4s)
      await _controller.forward(from: 0);
      if (!mounted) return;

      // Hold (2s)
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      // Exhale (4s)
      await _controller.reverse();
      if (!mounted) return;

      // Rest (2s)
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      setState(() => _cycleCount++);
    }

    if (mounted) {
      // A whole session done is a good moment to ask for a rating.
      unawaited(ReviewPrompt().recordWin());
      setState(() => _finished = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    if (_finished) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0D14),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 72,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.t('breathing.done'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_totalCycles / $_totalCycles',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.t('dialog.done')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.t('breathing.title'),
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 60),

            // Breathing circle
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = 0.5 + _controller.value * 0.5;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.8),
                          AppColors.primaryGlow.withValues(alpha: 0.6),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getPhaseLabel(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 60),

            // Cycle counter
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalCycles, (i) {
                final active = i < _cycleCount;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            Text(
              '$_cycleCount / $_totalCycles',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _getPhaseLabel() {
    if (_controller.status == AnimationStatus.forward)
      return l10n.t('breathing.in');
    if (_controller.status == AnimationStatus.reverse)
      return l10n.t('breathing.out');
    return l10n.t('breathing.hold');
  }
}
