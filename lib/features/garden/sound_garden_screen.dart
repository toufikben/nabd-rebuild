import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../services/audio_service.dart';

class SoundGardenScreen extends StatefulWidget {
  const SoundGardenScreen({super.key});

  @override
  State<SoundGardenScreen> createState() => _SoundGardenScreenState();
}

class _SoundGardenScreenState extends State<SoundGardenScreen> {
  static const _tracks =
      <({String id, String nameKey, String emoji, String asset})>[
    (
      id: 'rain',
      nameKey: 'garden.sounds.rain',
      emoji: '🌧️',
      asset: 'assets/sounds/rain_soft.m4a',
    ),
    (
      id: 'ocean',
      nameKey: 'garden.sounds.ocean',
      emoji: '🌊',
      asset: 'assets/sounds/ocean_soft.m4a',
    ),
    (
      id: 'wind',
      nameKey: 'garden.sounds.wind',
      emoji: '🍃',
      asset: 'assets/sounds/wind_gentle.m4a',
    ),
    (
      id: 'fireplace',
      nameKey: 'garden.sounds.fireplace',
      emoji: '🔥',
      asset: 'assets/sounds/fireplace_crackle.m4a',
    ),
    (
      id: 'night',
      nameKey: 'garden.sounds.night',
      emoji: '🌙',
      asset: 'assets/sounds/night_crickets.m4a',
    ),
    (
      id: 'birds',
      nameKey: 'garden.sounds.birds',
      emoji: '🐦',
      asset: 'assets/sounds/birds_distant.m4a',
    ),
    (
      id: 'harp',
      nameKey: 'garden.sounds.harp',
      emoji: '🎵',
      asset: 'assets/sounds/harp_soft.m4a',
    ),
    (
      id: 'oud',
      nameKey: 'garden.sounds.oud',
      emoji: '🎶',
      asset: 'assets/sounds/oud_soft.m4a',
    ),
  ];

  final _audio = AudioService.instance;
  late final String _ownerId;

  @override
  void initState() {
    super.initState();
    _ownerId = 'sound-garden-${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  void dispose() {
    unawaited(_audio.stopAllSoundGardenTracks(_ownerId));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).t('garden.sounds.title')),
        actions: [
          ValueListenableBuilder<Map<String, SoundGardenPlaybackState>>(
            valueListenable: _audio.soundGardenState,
            builder: (context, state, _) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${state.values.where((item) => item.status == SoundGardenPlaybackStatus.playing).length}/${AudioService.maxSoundGardenTracks}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder<Map<String, SoundGardenPlaybackState>>(
        valueListenable: _audio.soundGardenState,
        builder: (context, state, _) {
          final active = state.values
              .where(
                (item) => item.status == SoundGardenPlaybackStatus.playing,
              )
              .length;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                AppLocalizations.of(context).t('garden.sounds.subtitle'),
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 20),
              ..._tracks.map((track) {
                final playback = state[track.id];
                final isPlaying =
                    playback?.status == SoundGardenPlaybackStatus.playing;
                final isLoading =
                    playback?.status == SoundGardenPlaybackStatus.loading;
                final limitReached =
                    !isPlaying && active >= AudioService.maxSoundGardenTracks;
                return Card(
                  child: ListTile(
                    leading:
                        Text(track.emoji, style: const TextStyle(fontSize: 26)),
                    title: Text(l10n.t(track.nameKey)),
                    subtitle: isLoading
                        ? Text(AppLocalizations.of(context).t('garden.sounds.loading'))
                        : playback?.status == SoundGardenPlaybackStatus.error
                            ? Text(AppLocalizations.of(context).t('garden.sounds.failed'))
                            : null,
                    trailing: IconButton(
                      tooltip: isPlaying
                          ? l10n.t('common.stop')
                          : l10n.t('common.play'),
                      onPressed: isLoading || limitReached
                          ? null
                          : () async {
                              if (isPlaying) {
                                await _audio.stopSoundGardenTrack(
                                  id: track.id,
                                  ownerId: _ownerId,
                                );
                              } else {
                                await _audio.playSoundGardenTrack(
                                  id: track.id,
                                  assetPath: track.asset,
                                  ownerId: _ownerId,
                                );
                              }
                            },
                      icon: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(isPlaying
                              ? Icons.stop_circle
                              : Icons.play_circle),
                    ),
                  ),
                );
              }),
              if (active >= AudioService.maxSoundGardenTracks)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    AppLocalizations.of(context).t('garden.sounds.limit'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
