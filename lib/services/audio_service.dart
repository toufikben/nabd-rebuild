import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as just_audio;

enum AmbientSource {
  silent,
  garden,
  session,
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

class AudioService {
  AudioService._internal();

  static final AudioService instance = AudioService._internal();

  factory AudioService() => instance;

  static const _defaultAmbientAssets = <AmbientSource, String>{
    AmbientSource.silent: 'assets/sounds/rain_soft.mp3',
    AmbientSource.garden: 'assets/sounds/birds_distant.mp3',
    AmbientSource.session: 'assets/sounds/flute_dawn.mp3',
  };

  final just_audio.AudioPlayer _ambientPlayer = just_audio.AudioPlayer();
  final just_audio.AudioPlayer _cuePlayer = just_audio.AudioPlayer();
  final ValueNotifier<AmbientPlaybackState> ambientState = ValueNotifier(
    const AmbientPlaybackState(),
  );

  double _ambientVolume = 0.5;
  AmbientSource? _requestedSource;
  bool _disposed = false;

  double get ambientVolume => _ambientVolume;

  Future<bool> requestAmbient(
    AmbientSource source, {
    String? assetPath,
  }) async {
    if (_disposed || !_canTakeAmbientPriority(source)) return false;

    final current = ambientState.value;
    if (current.source == source &&
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
      if (_disposed || _requestedSource != source) return false;
      ambientState.value = AmbientPlaybackState(
        source: source,
        status: AmbientPlaybackStatus.ready,
      );
      return true;
    } catch (error) {
      _setAmbientError(source, 'Unable to load ambient audio: $error');
      return false;
    }
  }

  Future<bool> playAmbient(
    AmbientSource source, {
    String? assetPath,
  }) async {
    final isReady = await requestAmbient(source, assetPath: assetPath);
    if (!isReady || _disposed) return false;

    try {
      await _ambientPlayer.play();
      if (!_disposed) {
        ambientState.value = AmbientPlaybackState(
          source: source,
          status: AmbientPlaybackStatus.playing,
        );
      }
      return true;
    } catch (error) {
      _setAmbientError(source, 'Unable to play ambient audio: $error');
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
      _setAmbientError(ambientState.value.source, 'Unable to pause audio: $error');
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

  Future<void> setVolume(double volume) async {
    if (_disposed) return;

    _ambientVolume = volume.clamp(0.0, 1.0).toDouble();
    try {
      await _ambientPlayer.setVolume(_ambientVolume);
    } catch (error) {
      debugPrint('Unable to set ambient volume: $error');
    }
  }

  Future<bool> playCue(
    String assetPath, {
    double volume = 1.0,
  }) async {
    if (_disposed) return false;

    try {
      await _cuePlayer.stop();
      await _cuePlayer.setVolume(volume.clamp(0.0, 1.0).toDouble());
      await _cuePlayer.setAsset(assetPath);
      await _cuePlayer.play();
      return true;
    } catch (error) {
      debugPrint('Unable to play cue $assetPath: $error');
      return false;
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
    ambientState.dispose();
  }
}
