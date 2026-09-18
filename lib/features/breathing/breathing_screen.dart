import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

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
  late AnimationController _controller;
  int _cycleCount = 0;
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
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0D14),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Breathe with the circle',
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
    if (_controller.status == AnimationStatus.forward) return 'Breathe in';
    if (_controller.status == AnimationStatus.reverse) return 'Breathe out';
    return 'Hold';
  }
}
