import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

enum AmbientSource {
  silent,
  garden,
  session,
  soundscape,
}

enum AmbientPlaybackStatus {
  idle,
  loading,
  ready,
  playing,
  paused,
  error,
}

class AmbientPlaybackState {
  final AmbientSource? source;
  final AmbientPlaybackStatus status;
  final String? errorMessage;

  const AmbientPlaybackState({
    this.source,
    this.status = AmbientPlaybackStatus.idle,
    this.errorMessage,
  });

  AmbientPlaybackState copyWith({
    AmbientSource? source,
    AmbientPlaybackStatus? status,
    String? errorMessage,
    bool clearSource = false,
    bool clearError = false,
  }) {
    return AmbientPlaybackState(
      source: clearSource ? null : source ?? this.source,
      status: status ?? this.status,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

enum SoundGardenPlaybackStatus { idle, loading, playing, error }

class SoundGardenPlaybackState {
  final String? ownerId;
  final SoundGardenPlaybackStatus status;
  final String? errorMessage;

  const SoundGardenPlaybackState({
    this.ownerId,
    this.status = SoundGardenPlaybackStatus.idle,
    this.errorMessage,
  });
}

class AudioService {
  AudioService._internal();

  static final AudioService instance = AudioService._internal();

  factory AudioService() => instance;

  static const _defaultAmbientAssets = <AmbientSource, String>{
    AmbientSource.silent: 'assets/sounds/silent_river_water.mp3',
    AmbientSource.garden: 'assets/sounds/عصافير.mp3',
    AmbientSource.session: 'assets/sounds/flute_dawn.mp3',
    AmbientSource.soundscape: 'assets/sounds/rain_soft.mp3',
  };

  final just_audio.AudioPlayer _ambientPlayer = just_audio.AudioPlayer();
  final just_audio.AudioPlayer _cuePlayer = just_audio.AudioPlayer();
  final ValueNotifier<AmbientPlaybackState> ambientState = ValueNotifier(
    const AmbientPlaybackState(),
  );
  final ValueNotifier<Map<String, SoundGardenPlaybackState>> soundGardenState =
      ValueNotifier(const <String, SoundGardenPlaybackState>{});
  final Map<String, just_audio.AudioPlayer> _soundGardenPlayers = {};
  final Map<String, int> _soundGardenGenerations = {};

  double _ambientVolume = 0.5;
  AmbientSource? _requestedSource;
  int _ambientGeneration = 0;
  int _cueGeneration = 0;
  bool _disposed = false;

  double get ambientVolume => _ambientVolume;

  int beginAmbientRequest() => ++_ambientGeneration;

  int beginCueRequest() => ++_cueGeneration;

  static const maxSoundGardenTracks = 4;

  Future<bool> playSoundGardenTrack({
    required String id,
    required String assetPath,
    required String ownerId,
  }) async {
    if (_disposed) return false;
    final current = soundGardenState.value[id];
    if (current?.status == SoundGardenPlaybackStatus.playing ||
        current?.status == SoundGardenPlaybackStatus.loading) {
      return true;
    }
    final activeCount = soundGardenState.value.values
        .where((state) =>
            state.status == SoundGardenPlaybackStatus.playing ||
            state.status == SoundGardenPlaybackStatus.loading)
        .length;
    if (activeCount >= maxSoundGardenTracks) return false;

    final generation = (_soundGardenGenerations[id] ?? 0) + 1;
    _soundGardenGenerations[id] = generation;
    final player = just_audio.AudioPlayer();
    _soundGardenPlayers[id] = player;
    _setSoundGardenState(
      id,
      SoundGardenPlaybackState(
        ownerId: ownerId,
        status: SoundGardenPlaybackStatus.loading,
      ),
    );

    try {
      await player.setLoopMode(just_audio.LoopMode.one);
      await player.setVolume(_ambientVolume);
      await player.setAsset(assetPath);
      if (!_soundGardenRequestIsCurrent(id, ownerId, generation, player)) {
        await player.dispose();
        return false;
      }
      await player.play();
      if (!_soundGardenRequestIsCurrent(id, ownerId, generation, player)) {
        await player.stop();
        await player.dispose();
        return false;
      }
      _setSoundGardenState(
        id,
        SoundGardenPlaybackState(
          ownerId: ownerId,
          status: SoundGardenPlaybackStatus.playing,
        ),
      );
      return true;
    } catch (error) {
      if (_soundGardenRequestIsCurrent(id, ownerId, generation, player)) {
        _setSoundGardenState(
          id,
          SoundGardenPlaybackState(
            ownerId: ownerId,
            status: SoundGardenPlaybackStatus.error,
            errorMessage: 'Unable to play sound: $error',
          ),
        );
      }
      await player.dispose();
      return false;
    }
  }

  Future<void> stopSoundGardenTrack({
    required String id,
    required String ownerId,
  }) async {
    final current = soundGardenState.value[id];
    if (_disposed || current?.ownerId != ownerId) return;
    _soundGardenGenerations[id] = (_soundGardenGenerations[id] ?? 0) + 1;
    final player = _soundGardenPlayers.remove(id);
    _setSoundGardenState(id, const SoundGardenPlaybackState());
    if (player != null) {
      await player.stop();
      await player.dispose();
    }
  }

  Future<void> stopAllSoundGardenTracks(String ownerId) async {
    final ids = soundGardenState.value.entries
        .where((entry) => entry.value.ownerId == ownerId)
        .map((entry) => entry.key)
        .toList();
    for (final id in ids) {
      await stopSoundGardenTrack(id: id, ownerId: ownerId);
    }
  }

  bool _soundGardenRequestIsCurrent(
    String id,
    String ownerId,
    int generation,
    just_audio.AudioPlayer player,
  ) =>
      !_disposed &&
      _soundGardenGenerations[id] == generation &&
      _soundGardenPlayers[id] == player &&
      soundGardenState.value[id]?.ownerId == ownerId;

  void _setSoundGardenState(String id, SoundGardenPlaybackState state) {
    if (_disposed) return;
    final next =
        Map<String, SoundGardenPlaybackState>.from(soundGardenState.value);
    if (state.status == SoundGardenPlaybackStatus.idle) {
      next.remove(id);
    } else {
      next[id] = state;
    }
    soundGardenState.value = next;
  }

  Future<bool> requestAmbient(
    AmbientSource source, {
    String? assetPath,
    int? requestId,
  }) async {
    if (_disposed || !_canTakeAmbientPriority(source)) return false;

    final generation = requestId ?? ++_ambientGeneration;
    if (generation != _ambientGeneration) return false;

    final current = ambientState.value;
    if (assetPath == null &&
        current.source == source &&
        current.status != AmbientPlaybackStatus.error &&
        current.status != AmbientPlaybackStatus.idle) {
      return true;
    }

    try {
      _requestedSource = source;
      ambientState.value = AmbientPlaybackState(
        source: source,
        status: AmbientPlaybackStatus.loading,
      );
      await _ambientPlayer.stop();
      await _ambientPlayer.setLoopMode(just_audio.LoopMode.one);
      await _ambientPlayer.setVolume(_ambientVolume);
      await _ambientPlayer.setAsset(
        assetPath ?? _defaultAmbientAssets[source]!,
      );
      if (_disposed ||
          _requestedSource != source ||
          generation != _ambientGeneration) {
        return false;
      }
      ambientState.value = AmbientPlaybackState(
        source: source,
        status: AmbientPlaybackStatus.ready,
      );
      return true;
    } catch (error) {
      if (generation == _ambientGeneration) {
        _setAmbientError(source, 'Unable to load ambient audio: $error');
      }
      return false;
    }
  }

  Future<bool> playAmbient(
    AmbientSource source, {
    String? assetPath,
    int? requestId,
  }) async {
    final generation = requestId ?? ++_ambientGeneration;
    final isReady = await requestAmbient(
      source,
      assetPath: assetPath,
      requestId: generation,
    );
    if (!isReady || _disposed) return false;

    try {
      await _ambientPlayer.play();
      if (!_disposed && generation == _ambientGeneration) {
        ambientState.value = AmbientPlaybackState(
          source: source,
          status: AmbientPlaybackStatus.playing,
        );
      }
      return true;
    } catch (error) {
      if (generation == _ambientGeneration) {
        _setAmbientError(source, 'Unable to play ambient audio: $error');
      }
      return false;
    }
  }

  Future<void> pause() async {
    if (_disposed) return;

    try {
      await _ambientPlayer.pause();
      final current = ambientState.value;
      if (current.source != null &&
          current.status != AmbientPlaybackStatus.idle) {
        ambientState.value = AmbientPlaybackState(
          source: current.source,
          status: AmbientPlaybackStatus.paused,
        );
      }
    } catch (error) {
      _setAmbientError(
          ambientState.value.source, 'Unable to pause audio: $error');
    }
  }

  Future<void> resume() async {
    if (_disposed) return;

    final current = ambientState.value;
    if (current.source == null ||
        current.status == AmbientPlaybackStatus.idle ||
        current.status == AmbientPlaybackStatus.loading ||
        current.status == AmbientPlaybackStatus.error) {
      return;
    }

    try {
      await _ambientPlayer.play();
      if (!_disposed) {
        ambientState.value = AmbientPlaybackState(
          source: current.source,
          status: AmbientPlaybackStatus.playing,
        );
      }
    } catch (error) {
      _setAmbientError(current.source, 'Unable to resume audio: $error');
    }
  }

  Future<void> stop() async {
    if (_disposed) return;

    ++_ambientGeneration;

    try {
      await _ambientPlayer.stop();
    } catch (error) {
      debugPrint('Unable to stop ambient audio: $error');
    } finally {
      _requestedSource = null;
      if (!_disposed) {
        ambientState.value = const AmbientPlaybackState();
      }
    }
  }

  Future<void> stopAmbient(
    AmbientSource source, {
    int? requestId,
  }) async {
    if (_disposed ||
        ambientState.value.source != source ||
        (requestId != null && requestId != _ambientGeneration)) {
      return;
    }
    await stop();
  }

  Future<void> setVolume(double volume) async {
    if (_disposed) return;

    _ambientVolume = volume.clamp(0.0, 1.0).toDouble();
    try {
      await _ambientPlayer.setVolume(_ambientVolume);
      for (final player in _soundGardenPlayers.values) {
        await player.setVolume(_ambientVolume);
      }
    } catch (error) {
      debugPrint('Unable to set ambient volume: $error');
    }
  }

  Future<bool> playCue(
    String assetPath, {
    double volume = 1.0,
    int? requestId,
  }) async {
    if (_disposed) return false;

    final generation = requestId ?? ++_cueGeneration;
    if (generation != _cueGeneration) return false;

    try {
      await _cuePlayer.stop();
      await _cuePlayer.setVolume(volume.clamp(0.0, 1.0).toDouble());
      await _cuePlayer.setAsset(assetPath);
      if (_disposed || generation != _cueGeneration) return false;
      await _cuePlayer.play();
      return !_disposed && generation == _cueGeneration;
    } catch (error) {
      debugPrint('Unable to play cue $assetPath: $error');
      return false;
    }
  }

  Future<void> stopCue() async {
    if (_disposed) return;

    ++_cueGeneration;

    try {
      await _cuePlayer.stop();
    } catch (error) {
      debugPrint('Unable to stop cue audio: $error');
    }
  }

  bool _canTakeAmbientPriority(AmbientSource source) {
    final current = ambientState.value;
    final currentSource = current.source;
    if (currentSource == null || current.status == AmbientPlaybackStatus.idle) {
      return true;
    }

    return _priority(source) >= _priority(currentSource);
  }

  int _priority(AmbientSource source) {
    switch (source) {
      case AmbientSource.garden:
        return 1;
      case AmbientSource.silent:
        return 2;
      case AmbientSource.session:
        return 3;
      case AmbientSource.soundscape:
        return 1;
    }
  }

  void _setAmbientError(AmbientSource? source, String message) {
    debugPrint(message);
    if (_disposed) return;
    ambientState.value = AmbientPlaybackState(
      source: source,
      status: AmbientPlaybackStatus.error,
      errorMessage: message,
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_ambientPlayer.stop());
    unawaited(_cuePlayer.stop());
    unawaited(_ambientPlayer.dispose());
    unawaited(_cuePlayer.dispose());
    for (final player in _soundGardenPlayers.values) {
      unawaited(player.stop());
      unawaited(player.dispose());
    }
    _soundGardenPlayers.clear();
    soundGardenState.dispose();
    ambientState.dispose();
  }
}
