import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/app_settings.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/storage.dart';
import '../../services/audio_service.dart';

class _AmbienceOption {
  const _AmbienceOption({
    required this.file,
    required this.icon,
    required this.labelKey,
  });

  final String file;
  final IconData icon;
  final String labelKey;

  String get asset => 'assets/sounds/$file';
}

const List<_AmbienceOption> _ambienceOptions = [
  _AmbienceOption(
    file: 'rain_soft.m4a',
    icon: Icons.water_drop_outlined,
    labelKey: 'silent.sound.rain',
  ),
  _AmbienceOption(
    file: 'ocean_soft.m4a',
    icon: Icons.waves_rounded,
    labelKey: 'silent.sound.ocean',
  ),
  _AmbienceOption(
    file: 'garden_birds.m4a',
    icon: Icons.forest_outlined,
    labelKey: 'silent.sound.birds',
  ),
];

class SilentCompanionScreen extends StatefulWidget {
  const SilentCompanionScreen({super.key});

  @override
  State<SilentCompanionScreen> createState() => _SilentCompanionScreenState();
}

class _SilentCompanionScreenState extends State<SilentCompanionScreen> {
  static const String _soundKey = 'silent_sound_file';

  late AppLocalizations l10n;
  final AudioService _audioService = AudioService.instance;
  String _soundFile = 'rain_soft.m4a';

  _AmbienceOption get _selectedOption => _ambienceOptions.firstWhere(
        (option) => option.file == _soundFile,
        orElse: () => _ambienceOptions.first,
      );

  @override
  void initState() {
    super.initState();
    _soundFile = _loadSoundFile();
  }

  String _loadSoundFile() {
    try {
      final Object? stored =
          Hive.box(HiveBoxes.settings).get(_soundKey);
      if (stored is String && AppSettings.hasSoundFile(stored)) {
        return stored;
      }
    } catch (_) {
      // The settings box is not open yet; keep the default sound.
    }
    return 'rain_soft.m4a';
  }

  Future<void> _selectSound(_AmbienceOption option) async {
    if (option.file == _soundFile) return;
    setState(() => _soundFile = option.file);
    try {
      await Hive.box(HiveBoxes.settings).put(_soundKey, option.file);
    } catch (_) {
      // A failed preference write must not stop the selection.
    }

    final state = _audioService.ambientState.value;
    if (state.source != AmbientSource.silent) return;
    switch (state.status) {
      case AmbientPlaybackStatus.playing:
      case AmbientPlaybackStatus.loading:
        await _audioService.playAmbient(
          AmbientSource.silent,
          assetPath: _selectedOption.asset,
        );
        return;
      case AmbientPlaybackStatus.ready:
      case AmbientPlaybackStatus.paused:
        await _audioService.requestAmbient(
          AmbientSource.silent,
          assetPath: _selectedOption.asset,
        );
        return;
      case AmbientPlaybackStatus.idle:
      case AmbientPlaybackStatus.error:
        return;
    }
  }

  Future<void> _handleMainAction(AmbientPlaybackState state) async {
    if (state.source != null && state.source != AmbientSource.silent) {
      if (state.source == AmbientSource.session) return;
      await _audioService.playAmbient(
        AmbientSource.silent,
        assetPath: _selectedOption.asset,
      );
      return;
    }

    switch (state.status) {
      case AmbientPlaybackStatus.loading:
        return;
      case AmbientPlaybackStatus.error:
        await _audioService.requestAmbient(
          AmbientSource.silent,
          assetPath: _selectedOption.asset,
        );
        return;
      case AmbientPlaybackStatus.playing:
        await _audioService.pause();
        return;
      case AmbientPlaybackStatus.ready:
      case AmbientPlaybackStatus.paused:
        await _audioService.resume();
        return;
      case AmbientPlaybackStatus.idle:
        await _audioService.playAmbient(
          AmbientSource.silent,
          assetPath: _selectedOption.asset,
        );
        return;
    }
  }

  void _setVolume(double value) {
    unawaited(_audioService.setVolume(value));
    setState(() {});
  }

  String _statusText(AmbientPlaybackState state, AppLocalizations l10n) {
    if (state.source == AmbientSource.session) {
      return l10n.t('silent.sessionActive');
    }
    if (state.source == AmbientSource.garden) {
      return l10n.t('silent.gardenActive');
    }
    switch (state.status) {
      case AmbientPlaybackStatus.loading:
        return l10n.t('silent.loading');
      case AmbientPlaybackStatus.error:
        return state.errorMessage ?? l10n.t('silent.loadFailed');
      case AmbientPlaybackStatus.playing:
        return l10n.t('silent.playing');
      case AmbientPlaybackStatus.ready:
      case AmbientPlaybackStatus.paused:
        return l10n.t('silent.tapToBegin');
      case AmbientPlaybackStatus.idle:
        return l10n.t('silent.tapToBegin');
    }
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('silent.title')),
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
                        _selectedOption.icon,
                        size: 96,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.t('silent.tagline'),
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.t('silent.body'),
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        l10n.t('silent.sound'),
                        style: textTheme.labelLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final option in _ambienceOptions)
                            ChoiceChip(
                              avatar: Icon(
                                option.icon,
                                size: 18,
                                color: option.file == _soundFile
                                    ? colors.onSecondaryContainer
                                    : colors.onSurfaceVariant,
                              ),
                              showCheckmark: false,
                              label: Text(l10n.t(option.labelKey)),
                              selected: option.file == _soundFile,
                              onSelected: sessionIsActive
                                  ? null
                                  : (_) => unawaited(_selectSound(option)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 28),
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
                        _statusText(state, l10n),
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
