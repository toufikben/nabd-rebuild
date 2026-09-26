import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/app_settings.dart';
import '../../services/splash_service.dart';
import '../../services/biometric_service.dart';

/// SplashScreen - the launch screen. It shows immediately and hands over as
/// soon as the encrypted store is readable.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SplashService _splash = SplashService();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    // Navigate as soon as the data is readable. Waiting on the audio clip made
    // the launch feel like a blank screen froze before the splash appeared.
    final minDisplay = Future.delayed(
      const Duration(milliseconds: 900),
    );
    if (!mounted) return;
    await _routeAfterSplash();
    await minDisplay;
  }

  Future<void> _routeAfterSplash() async {
    final box = Hive.box('settings');
    final soundEnabled =
        box.get('splash_sound_enabled', defaultValue: true) as bool;
    final sound = SplashService.resolveSound(box.get('splash_sound') as String?);

    if (soundEnabled && AppSettings.splashSoundEnabled) {
      // Do not block the first frame on audio setup.
      unawaited(_splash.playSplashSound(sound));
    }

    if (!mounted) return;

    // إذا لا بذرة → شاشة اختيار البذرة
    final gardenBox = Hive.box('garden');
    final settings = Hive.box('settings');
    final onboardingCompleted =
        settings.get('onboarding_completed', defaultValue: false) == true;
    if (!onboardingCompleted && gardenBox.isEmpty) {
      context.go('/seed-selection');
    } else if (BiometricService().shouldShowLock(coldStart: true)) {
      context.go('/lock');
    } else {
      BiometricService().markColdStartComplete();
      context.go('/journal');
    }
  }

  @override
  void dispose() {
    unawaited(_splash.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        child: _buildSplash(),
      ),
    );
  }

  Widget _buildSplash() {
    // One signature splash, matching the single signature sound.
    return _firstSeedSplash();
  }

  // ═══════════════════════════════════════════════════════════
  // Splash 1: First Seed
  // ═══════════════════════════════════════════════════════════
  Widget _firstSeedSplash() {
    return Container(
      key: const ValueKey('seed'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0D14), Color(0xFF1A2A1E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🌰',
              style: TextStyle(fontSize: 60),
            ).animate().moveY(begin: -100, end: 0, duration: 1000.ms).fadeIn(),
            const SizedBox(height: 20),
            const Text('🌱', style: TextStyle(fontSize: 100))
                .animate()
                .fadeIn(delay: 1200.ms)
                .scale(
                  delay: 1200.ms,
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: 24),
            _buildBrand(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Brand (مشترك)
  // ═══════════════════════════════════════════════════════════
  Widget _buildBrand() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF00D2A8)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.favorite, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Nabd',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 1800.ms),
        const SizedBox(height: 8),
        const Text(
          'نبض — Private Journal',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ).animate().fadeIn(delay: 2100.ms),
      ],
    );
  }
}
