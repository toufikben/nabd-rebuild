// lib/features/sessions/screens/session_runner_screen.dart
//
// R1.2-B — شاشة تشغيل الجلسة.
// - يعتمد على BreathingEngine الحالي (R1.2-A). لا Engine جديد.
// - يعرض BreathingCircle + RunnerControls.
// - لا Activities حقيقية، لا TTS، ولا Audio مستقل داخل الشاشة.
// - لا Riverpod: ValueListenableBuilder + listener واحد.
// - لا Timer جديد داخل الشاشة.
//
// المسار المستقبلي: /sessions/run?id=<sessionId>
//
// الاعتماديات المؤجلة:
// - SessionsData.byId(...) — patch منفصل على sessions_data.dart.
// - route '/sessions/run' + '/sessions' — patch منفصل على router.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../data/sessions_data.dart';
import '../engine/breathing_engine.dart';
import '../engine/breathing_state.dart';
import '../models/session.dart';
import '../widgets/breathing_circle.dart';
import '../widgets/runner_controls.dart';
import '../../../services/audio_service.dart';

const Map<String, Color> _sessionAccentMap = <String, Color>{
  'red': Color(0xFFE74C3C),
  'blue': Color(0xFF5B7C99),
  'amber': Color(0xFFD4A017),
  'gray': Color(0xFF7F8C8D),
  'purple': Color(0xFF8E7CC3),
  'indigo': Color(0xFF2C3E50),
  'gold': Color(0xFFE8B84B),
  'teal': Color(0xFF16A085),
};

const bool _hasPremium = false;

class SessionRunnerScreen extends StatefulWidget {
  const SessionRunnerScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  State<SessionRunnerScreen> createState() => _SessionRunnerScreenState();
}

class _SessionRunnerScreenState extends State<SessionRunnerScreen> {
  Session? _session;
  BreathingEngine? _engine;

  bool _invalid = false;
  bool _premiumLocked = false;
  bool _completionHandled = false;
  bool _showSuccess = false;
  int? _ambientRequestId;

  @override
  void initState() {
    super.initState();

    final Session? session = SessionsData.byId(widget.sessionId);

    if (session == null) {
      _invalid = true;
      return;
    }

    _session = session;

    if (!session.isFree && !_hasPremium) {
      _premiumLocked = true;
      return;
    }

    final engine = BreathingEngine(session.breathingPattern);
    _engine = engine;

    engine.state.addListener(_onEngineState);
    engine.start();
    unawaited(_startSessionAmbient(session));
  }

  @override
  void dispose() {
    final engine = _engine;
    final ambientRequestId = _ambientRequestId;

    if (engine != null) {
      engine.state.removeListener(_onEngineState);
      engine.dispose();
    }

    unawaited(_stopSessionAmbient(ambientRequestId));
    _ambientRequestId = null;
    _engine = null;
    super.dispose();
  }

  Future<void> _startSessionAmbient(Session session) async {
    final String? ambientSound = session.ambientSound;
    if (ambientSound == null || ambientSound.isEmpty) return;

    final requestId = AudioService.instance.beginAmbientRequest();
    _ambientRequestId = requestId;

    // AudioService owns the single ambient player and deliberately gives a
    // configured Session priority over Garden/Silent ambient playback.
    final started = await AudioService.instance.playAmbient(
      AmbientSource.session,
      assetPath: ambientSound,
      requestId: requestId,
    );
    if ((!mounted || _ambientRequestId != requestId) && started) {
      await AudioService.instance.stopAmbient(
        AmbientSource.session,
        requestId: requestId,
      );
    }
  }

  Future<void> _stopSessionAmbient([int? requestId]) {
    return AudioService.instance.stopAmbient(
      AmbientSource.session,
      requestId: requestId ?? _ambientRequestId,
    );
  }

  void _onEngineState() {
    if (!mounted) return;

    final BreathingState? state = _engine?.state.value;
    if (state == null || !state.isFinished) return;
    if (_completionHandled) return;

    _completionHandled = true;
    _handleCompletion();
  }

  Future<void> _handleCompletion() async {
    if (!mounted) return;

    await _stopSessionAmbient(_ambientRequestId);
    if (!mounted) return;

    setState(() {
      _showSuccess = true;
    });

    await _incrementCompletedTotal();

    await Future<void>.delayed(
      const Duration(milliseconds: 800),
    );

    if (!mounted) return;

    _navigateToSessions();
  }

  Future<void> _incrementCompletedTotal() async {
    try {
      final box = Hive.box('settings');
      final Object? raw = box.get('sessions_completed_total');
      final int current = raw is int ? raw : 0;

      await box.put(
        'sessions_completed_total',
        current + 1,
      );
    } catch (_) {
      // لا نعطل تجربة الجلسة إذا تعذر تحديث العداد.
    }
  }

  void _navigateToSessions() {
    if (!mounted) return;
    context.go('/sessions');
  }

  void _onPauseToggle() {
    final engine = _engine;
    if (engine == null) return;

    if (engine.state.value.isPaused) {
      engine.resume();
    } else {
      engine.pause();
    }
  }

  Future<void> _onExit() async {
    _engine?.stop();
    await _stopSessionAmbient(_ambientRequestId);

    if (!mounted) return;

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/sessions');
    }
  }

  Color _accentFor(BuildContext context) {
    final session = _session;

    if (session == null) {
      return Theme.of(context).colorScheme.primary;
    }

    return _sessionAccentMap[session.colorKey] ??
        Theme.of(context).colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (_invalid) {
      return _buildInvalid(context);
    }

    if (_premiumLocked) {
      return _buildPremiumLocked(context);
    }

    final session = _session!;
    final engine = _engine!;
    final theme = Theme.of(context);
    final Color accent = _accentFor(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;
        if (_completionHandled) return;

        _onExit();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: _buildAppBar(theme, session),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _showSuccess
              ? _buildSuccess(theme, accent)
              : _buildRunning(theme, engine, accent),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    ThemeData theme,
    Session session,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: _showSuccess
          ? null
          : IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'إنهاء',
              onPressed: _onExit,
            ),
      title: Text(
        session.emotionLabel,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildRunning(
    ThemeData theme,
    BreathingEngine engine,
    Color accent,
  ) {
    return ValueListenableBuilder<BreathingState>(
      key: const ValueKey('running'),
      valueListenable: engine.state,
      builder: (
        BuildContext context,
        BreathingState state,
        Widget? child,
      ) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 4,
              ),
              child: Center(
                child: Text(
                  'الدورة ${state.cycleNumber} من ${state.totalCycles}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: BreathingCircle(
                  state: state,
                  accentColor: accent,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: RunnerControls(
                isPaused: state.isPaused,
                onPauseToggle: _onPauseToggle,
                onStop: _onExit,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuccess(
    ThemeData theme,
    Color accent,
  ) {
    return Center(
      key: const ValueKey('success'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.check_circle_rounded,
            size: 80,
            color: accent,
          ),
          const SizedBox(height: 24),
          Text(
            'أحسنت',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalid(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'رجوع',
          onPressed: _onExit,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 20),
              Text(
                'الجلسة غير متاحة',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _onExit,
                child: const Text('رجوع'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumLocked(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: _onExit,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Premium Session',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This session is available with Premium.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _onExit,
                child: const Text('Back to Sessions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
