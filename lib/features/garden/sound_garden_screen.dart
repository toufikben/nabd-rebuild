import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/audio_service.dart';

class SoundGardenScreen extends StatefulWidget {
  const SoundGardenScreen({super.key});

  @override
  State<SoundGardenScreen> createState() => _SoundGardenScreenState();
}

class _SoundGardenScreenState extends State<SoundGardenScreen> {
  static const _tracks =
      <({String id, String name, String emoji, String asset})>[
    (
      id: 'rain',
      name: 'Soft rain',
      emoji: '🌧️',
      asset: 'assets/sounds/rain_soft.mp3',
    ),
    (
      id: 'ocean',
      name: 'Ocean',
      emoji: '🌊',
      asset: 'assets/sounds/ocean_soft.mp3',
    ),
    (
      id: 'wind',
      name: 'Gentle wind',
      emoji: '🍃',
      asset: 'assets/sounds/wind_gentle.mp3',
    ),
    (
      id: 'fireplace',
      name: 'Fireplace',
      emoji: '🔥',
      asset: 'assets/sounds/fireplace_crackle.mp3',
    ),
    (
      id: 'cafe',
      name: 'Cafe',
      emoji: '☕',
      asset: 'assets/sounds/cafe_ambience.mp3',
    ),
    (
      id: 'birds',
      name: 'Distant birds',
      emoji: '🐦',
      asset: 'assets/sounds/birds_distant.mp3',
    ),
    (
      id: 'harp',
      name: 'Soft harp',
      emoji: '🎵',
      asset: 'assets/sounds/harp_soft.mp3',
    ),
    (
      id: 'oud',
      name: 'Soft oud',
      emoji: '🎶',
      asset: 'assets/sounds/oud_soft.mp3',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Garden'),
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
              const Text(
                'Mix up to four sounds to create your own calm space.',
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
                    title: Text(track.name),
                    subtitle: isLoading
                        ? const Text('Loading...')
                        : playback?.status == SoundGardenPlaybackStatus.error
                            ? const Text('Unable to play this sound')
                            : null,
                    trailing: IconButton(
                      tooltip: isPlaying
                          ? 'Stop ${track.name}'
                          : 'Play ${track.name}',
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
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'Four sounds are already playing. Stop one before adding another.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
