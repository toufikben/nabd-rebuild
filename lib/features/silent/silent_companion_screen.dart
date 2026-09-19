import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/audio_service.dart';

class SilentCompanionScreen extends StatefulWidget {
  const SilentCompanionScreen({super.key});

  @override
  State<SilentCompanionScreen> createState() => _SilentCompanionScreenState();
}

class _SilentCompanionScreenState extends State<SilentCompanionScreen> {
  final AudioService _audioService = AudioService.instance;

  Future<void> _handleMainAction(AmbientPlaybackState state) async {
    if (state.source != null && state.source != AmbientSource.silent) {
      if (state.source == AmbientSource.session) return;
      await _audioService.playAmbient(AmbientSource.silent);
      return;
    }

    switch (state.status) {
      case AmbientPlaybackStatus.loading:
        return;
      case AmbientPlaybackStatus.error:
        await _audioService.requestAmbient(AmbientSource.silent);
        return;
      case AmbientPlaybackStatus.playing:
        await _audioService.pause();
        return;
      case AmbientPlaybackStatus.ready:
      case AmbientPlaybackStatus.paused:
        await _audioService.resume();
        return;
      case AmbientPlaybackStatus.idle:
        await _audioService.playAmbient(AmbientSource.silent);
        return;
    }
  }

  void _setVolume(double value) {
    unawaited(_audioService.setVolume(value));
    setState(() {});
  }

  String _statusText(AmbientPlaybackState state) {
    if (state.source == AmbientSource.session) {
      return 'A session is currently playing.';
    }
    if (state.source == AmbientSource.garden) {
      return 'Garden ambience is currently active.';
    }
    switch (state.status) {
      case AmbientPlaybackStatus.loading:
        return 'Loading rain...';
      case AmbientPlaybackStatus.error:
        return state.errorMessage ?? 'Unable to load rain audio.';
      case AmbientPlaybackStatus.playing:
        return 'Rain is playing';
      case AmbientPlaybackStatus.ready:
      case AmbientPlaybackStatus.paused:
        return 'Tap to begin';
      case AmbientPlaybackStatus.idle:
        return 'Tap to begin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Silent Companion'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 420),
            child: Center(
              child: ValueListenableBuilder<AmbientPlaybackState>(
                valueListenable: _audioService.ambientState,
                builder: (context, state, _) {
                  final isPlaying =
                      state.source == AmbientSource.silent &&
                      state.status == AmbientPlaybackStatus.playing;
                  final isLoading =
                      state.source == AmbientSource.silent &&
                      state.status == AmbientPlaybackStatus.loading;
                  final hasError =
                      state.source == AmbientSource.silent &&
                      state.status == AmbientPlaybackStatus.error;
                  final sessionIsActive =
                      state.source == AmbientSource.session;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        size: 96,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Just be here.',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No words. No tasks. Only rain.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: FilledButton(
                          onPressed: sessionIsActive
                              ? null
                              : () => _handleMainAction(state),
                          style: FilledButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: colors.onPrimary,
                                  ),
                                )
                              : Icon(
                                  hasError
                                      ? Icons.refresh
                                      : isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                  size: 40,
                                  color: colors.onPrimary,
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _statusText(state),
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: hasError ? colors.error : colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 280,
                        child: Slider(
                          value: _audioService.ambientVolume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: sessionIsActive ? null : _setVolume,
                          activeColor: colors.primary,
                          inactiveColor: colors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
