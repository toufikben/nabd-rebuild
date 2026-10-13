// lib/features/sessions/screens/session_runner_screen.dart
//
// R1.2-B — شاشة تشغيل الجلسة.
// - يعتمد على BreathingEngine الحالي (R1.2-A). لا Engine جديد.
// - يعرض BreathingCircle + RunnerControls.
// - لا Activities حقيقية، لا TTS، ولا Audio مستقل داخل الشاشة.
// - لا Timer جديد داخل الشاشة.
//
// المسار المستقبلي: /sessions/run?id=<sessionId>
//
// الاعتماديات المؤجلة:
// - SessionsData.byId(...) — patch منفصل على sessions_data.dart.
// - route '/sessions/run' + '/sessions' — patch منفصل على router.dart.

import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../services/monetization_service.dart';
import '../data/sessions_data.dart';
import '../engine/breathing_engine.dart';
import '../engine/breathing_state.dart';
import '../models/session.dart';
import '../session_access.dart';
import '../widgets/breathing_circle.dart';
import '../widgets/runner_controls.dart';
import '../../../services/audio_service.dart';
import '../../../services/review_prompt.dart';
import '../../../services/ui_sounds.dart';
import '../../../core/storage.dart';

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

class SessionRunnerScreen extends ConsumerStatefulWidget {
  const SessionRunnerScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  ConsumerState<SessionRunnerScreen> createState() =>
      _SessionRunnerScreenState();
}

class _SessionRunnerScreenState extends ConsumerState<SessionRunnerScreen> {
  late AppLocalizations l10n;
  Session? _session;
  BreathingEngine? _engine;

  bool _invalid = false;
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
  }

  /// The engine only starts once the entitlement says the session is open, so
  /// a Pro customer whose purchase resolves a frame late is not locked out.
  void _ensureStarted(Session session) {
    if (_engine != null) return;

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
    unawaited(UiSounds.play(UiSound.complete));

    setState(() {
      _showSuccess = true;
    });

    await _incrementCompletedTotal();
    unawaited(ReviewPrompt().recordWin());

    await Future<void>.delayed(
      const Duration(milliseconds: 800),
    );

    if (!mounted) return;

    _navigateToSessions();
  }

  Future<void> _incrementCompletedTotal() async {
    try {
      final box = contentBox();
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
    l10n = AppLocalizations.of(context);
    if (_invalid) {
      return _buildInvalid(context);
    }

    final session = _session!;
    final isPro = ref.watch(monetizationProvider).isPro;
    if (sessionIsLocked(isFree: session.isFree, isPro: isPro)) {
      return _buildPremiumLocked(context);
    }
    _ensureStarted(session);

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
              tooltip: l10n.t('runner.finish'),
              onPressed: _onExit,
            ),
      title: Text(
        session.labelFor(AppLocalizations.of(context).locale.languageCode),
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
                  AppLocalizations.of(context)
                      .t('runner.cycle')
                      .replaceAll('{c}', '${state.cycleNumber}')
                      .replaceAll('{t}', '${state.totalCycles}'),
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
              // Clear of the system navigation bar, which the app draws
              // behind on recent Android versions.
              padding: EdgeInsets.only(
                bottom: 40 + MediaQuery.viewPaddingOf(context).bottom,
              ),
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
            AppLocalizations.of(context).t('sessions.wellDone'),
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
          tooltip: AppLocalizations.of(context).t('common.back'),
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
                AppLocalizations.of(context).t('sessions.unavailable'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _onExit,
                child: Text(AppLocalizations.of(context).t('common.back')),
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
          tooltip: AppLocalizations.of(context).t('common.back'),
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
                l10n.t('session.premium.title'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.t('session.premium.body'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _onExit,
                child: Text(l10n.t('session.back')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

