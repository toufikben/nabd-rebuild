import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/app_settings.dart';
import '../../services/splash_service.dart';
import '../../services/biometric_service.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';

/// The launch screen: the name on the native launch ink, with two rings that
/// expand in time with the two heartbeats of the launch cue. A tap skips it.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SplashService _splash = SplashService();
  late final bool _soundEnabled;
  late final String _sound;

  @override
  void initState() {
    super.initState();
    final box = Hive.box('settings');
    _soundEnabled =
        box.get('splash_sound_enabled', defaultValue: true) as bool &&
        AppSettings.splashSoundEnabled;
    // A choice from Settings, if it still names a bundled sound; anything
    // else (an id from an older version) falls back to the default cue.
    final customSound = box.get('splash_sound') as String?;
    _sound = customSound != null &&
            SplashService.choices.contains(customSound) &&
            AppSettings.resolveSoundFile(customSound) != null
        ? customSound
        : SplashService.signatureSound;
    _boot();
  }

  Future<void> _boot() async {
    // Play the cue without ever letting audio gate the navigation. The previous
    // version awaited setAsset/play directly, so a decoder hiccup on a slow
    // device could strand the user on the splash screen.
    if (_soundEnabled) {
      unawaited(
        _splash
            .playSplashSound(_sound)
            .timeout(const Duration(seconds: 4), onTimeout: () {}),
      );
    }

    // Long enough for both heartbeats and the chord to bloom; the tail keeps
    // ringing softly over the first screen instead of being cut off. Without
    // sound there is nothing to wait for. A tap skips it either way.
    await Future.delayed(
      Duration(milliseconds: _soundEnabled ? 2200 : 1200),
    );
    if (!mounted) return;
    await _routeAway();
  }

  bool _leaving = false;

  Future<void> _skip() async {
    if (!mounted) return;
    await _routeAway();
  }

  /// Leaves the splash. Kept separate so the audio path can never block it.
  Future<void> _routeAway() async {
    if (_leaving) return;
    _leaving = true;
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
      context.go('/today');
    }
  }

  @override
  void dispose() {
    // Let the cue's tail finish over the next screen, then release it.
    final splash = _splash;
    unawaited(Future<void>.delayed(
      const Duration(seconds: 3),
      splash.dispose,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: Container(
          color: AppColors.splashBackground,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // One ring per heartbeat of the cue (0.05 s and 0.33 s).
                      for (final delay in const [50, 330])
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 2,
                            ),
                          ),
                        )
                            .animate(delay: delay.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.8, 1.8),
                              duration: 1100.ms,
                              curve: Curves.easeOutCubic,
                            )
                            .fadeOut(duration: 1100.ms, curve: Curves.easeIn),
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.pulse,
                          size: 48,
                        ),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.92, 0.92),
                            end: const Offset(1.06, 1.06),
                            duration: 140.ms,
                            curve: Curves.easeOut,
                          )
                          .then()
                          .scale(
                            begin: const Offset(1.06, 1.06),
                            end: const Offset(0.96, 0.96),
                            duration: 140.ms,
                          )
                          .then(delay: 20.ms)
                          .scale(
                            begin: const Offset(0.96, 0.96),
                            end: const Offset(1.04, 1.04),
                            duration: 120.ms,
                          )
                          .then()
                          .scale(
                            begin: const Offset(1.04, 1.04),
                            end: const Offset(1, 1),
                            duration: 300.ms,
                            curve: Curves.easeOutBack,
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('app.name'),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ).animate().fadeIn(delay: 450.ms, duration: 600.ms),
                const SizedBox(height: 8),
                Text(
                  l10n.t('splash.tagline'),
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.white70),
                ).animate().fadeIn(delay: 700.ms, duration: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
