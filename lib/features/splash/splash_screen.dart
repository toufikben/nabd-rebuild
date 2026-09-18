import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/app_settings.dart';
import '../../services/splash_service.dart';
import '../../services/biometric_service.dart';

/// SplashScreen — يعرض splash عشوائي من 5 (لا يكرر السابق).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final int _splashId;
  final SplashService _splash = SplashService();

  @override
  void initState() {
    super.initState();
    _splashId = SplashService.getNextSplash();
    _boot();
  }

  Future<void> _boot() async {
    final box = Hive.box('settings');
    final soundEnabled =
        box.get('splash_sound_enabled', defaultValue: true) as bool;
    final customSound = box.get('splash_sound') as String?;
    final requestedSound =
        customSound ?? SplashService.defaultSoundFor(_splashId);
    final sound = AppSettings.fallbackSound(requestedSound);

    if (soundEnabled && AppSettings.splashSoundEnabled) {
      await _splash.playSplashSound(sound);
    }

    await Future.delayed(const Duration(milliseconds: 3200));
    await _splash.stopSplashSound();

    if (!mounted) return;

    // إذا لا بذرة → شاشة اختيار البذرة
    final gardenBox = Hive.box('garden');
    final settings = Hive.box('settings');
    final onboardingCompleted =
        settings.get('onboarding_completed', defaultValue: false) == true;
    if (!onboardingCompleted && gardenBox.isEmpty) {
      context.go('/seed-selection');
    } else if (BiometricService().shouldShowLock()) {
      context.go('/lock');
    } else {
      context.go('/home');
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
    switch (_splashId) {
      case 2:
        return _newDawnSplash();
      case 3:
        return _bookToButterflySplash();
      case 4:
        return _candleSplash();
      case 5:
        return _circleOfLifeSplash();
      default:
        return _firstSeedSplash();
    }
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
            const Text('🌰', style: TextStyle(fontSize: 60))
                .animate()
                .moveY(begin: -100, end: 0, duration: 1000.ms)
                .fadeIn(),
            const SizedBox(height: 20),
            const Text('🌱', style: TextStyle(fontSize: 100))
                .animate()
                .fadeIn(delay: 1200.ms)
                .scale(
                    delay: 1200.ms,
                    duration: 600.ms,
                    curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            _buildBrand(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Splash 2: New Dawn
  // ═══════════════════════════════════════════════════════════
  Widget _newDawnSplash() {
    return Container(
      key: const ValueKey('dawn'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0A0D14),
            Color(0xFFFF7B54),
            Color(0xFFFFD54F),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          stops: [0.2, 0.75, 1.0],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌅', style: TextStyle(fontSize: 120))
                .animate()
                .scale(duration: 1500.ms, curve: Curves.easeOutCubic)
                .fadeIn(),
            const SizedBox(height: 30),
            _buildBrand(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Splash 3: Book to Butterfly ⭐ (المفضل لديك)
  // ═══════════════════════════════════════════════════════════
  Widget _bookToButterflySplash() {
    return Container(
      key: const ValueKey('book_butterfly'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C1810), Color(0xFF1A1F3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Book opens
                const Text('📖', style: TextStyle(fontSize: 100))
                    .animate()
                    .scale(duration: 800.ms, curve: Curves.easeOutBack)
                    .then()
                    .shake(delay: 800.ms, duration: 200.ms),

                // Butterflies fly out (5 butterflies with different paths)
                ...List.generate(5, (i) {
                  final angle = (i / 5) * math.pi * 2;
                  final targetX = math.cos(angle) * 120;
                  final targetY = -150 - i * 20.0;

                  return Transform.translate(
                    offset: Offset(targetX, targetY),
                    child: const Text('🦋', style: TextStyle(fontSize: 28)),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 1000 + i * 150))
                      .moveY(
                        begin: 0,
                        end: -60,
                        duration: 1500.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .then()
                      .moveX(
                        begin: 0,
                        end: i % 2 == 0 ? 20 : -20,
                        duration: 800.ms,
                        curve: Curves.easeInOut,
                      );
                }),
              ],
            ),
            const SizedBox(height: 40),
            _buildBrand(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Splash 4: Candle
  // ═══════════════════════════════════════════════════════════
  Widget _candleSplash() {
    return Container(
      key: const ValueKey('candle'),
      color: const Color(0xFF0A0D14),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFB74D).withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Center(
                child: Text('🕯️', style: TextStyle(fontSize: 100)),
              ),
            )
                .animate()
                .fadeIn(duration: 1200.ms)
                .then()
                .shimmer(duration: 2000.ms, color: const Color(0xFFFFD54F)),
            const SizedBox(height: 30),
            _buildBrand(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Splash 5: Circle of Life
  // ═══════════════════════════════════════════════════════════
  Widget _circleOfLifeSplash() {
    return Container(
      key: const ValueKey('circle'),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF1A0B2E), Color(0xFF0A0D14)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(3, (i) {
                  return Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF6C5CE7).withValues(alpha: 0.5),
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(delay: Duration(milliseconds: i * 300))
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        end: const Offset(3, 3),
                        duration: 2500.ms,
                      )
                      .fadeOut();
                }),
                const Text('🌳', style: TextStyle(fontSize: 120))
                    .animate()
                    .fadeIn(delay: 800.ms)
                    .scale(delay: 800.ms, duration: 1000.ms),
              ],
            ),
            const SizedBox(height: 30),
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
