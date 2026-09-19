import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'audio_service.dart';

/// SoundscapeService — أصوات محيطة فعلية للكتابة.
class SoundscapeService extends StateNotifier<SoundscapeState> {
  SoundscapeService() : super(const SoundscapeState()) {
    load();
    _audioService.ambientState.addListener(_onAmbientStateChanged);
  }

  final AudioService _audioService = AudioService.instance;

  Future<void> toggle() async {
    final enabled = !state.enabled;
    if (enabled) {
      final started = await _playCurrent();
      if (!mounted) return;
      state = state.copyWith(enabled: started);
      await Hive.box('settings').put('soundscape_enabled', started);
    } else {
      state = state.copyWith(enabled: false);
      await Hive.box('settings').put('soundscape_enabled', false);
      await _audioService.stopAmbient(AmbientSource.soundscape);
    }
  }

  Future<void> setType(String type) async {
    state = state.copyWith(type: type);
    await Hive.box('settings').put('soundscape_type', type);
    if (state.enabled) await _playCurrent();
  }

  Future<void> setVolume(double volume) async {
    final safeVolume = volume.clamp(0.0, 1.0).toDouble();
    state = state.copyWith(volume: safeVolume);
    await Hive.box('settings').put('soundscape_volume', safeVolume);
    await _audioService.setVolume(safeVolume);
  }

  void load() {
    final box = Hive.box('settings');
    state = SoundscapeState(
      enabled: box.get('soundscape_enabled', defaultValue: false) as bool,
      type: box.get('soundscape_type', defaultValue: 'rain') as String,
      volume:
          (box.get('soundscape_volume', defaultValue: 0.5) as num).toDouble(),
    );
  }

  Future<bool> _playCurrent() async {
    try {
      return await _audioService.playAmbient(
        AmbientSource.soundscape,
        assetPath: 'assets/sounds/${_assetFor(state.type)}.mp3',
      );
    } catch (error) {
      debugPrint('Soundscape failed for ${state.type}: $error');
      return false;
    }
  }

  void _onAmbientStateChanged() {
    if (!mounted) return;
    if (state.enabled &&
        _audioService.ambientState.value.source != AmbientSource.soundscape) {
      state = state.copyWith(enabled: false);
      unawaited(Hive.box('settings').put('soundscape_enabled', false));
    }
  }

  String _assetFor(String type) {
    switch (type) {
      case 'birds':
        return 'birds_distant';
      case 'rain':
        return 'rain_soft';
      case 'night':
        return 'tibetan_bowl';
      case 'forest':
        return 'birds_distant';
      case 'ocean':
        return 'ocean_soft';
      case 'cafe':
        return 'cafe_ambience';
      case 'fire':
        return 'fireplace_crackle';
      case 'wind':
        return 'wind_gentle';
      default:
        return 'rain_soft';
    }
  }

  @override
  void dispose() {
    _audioService.ambientState.removeListener(_onAmbientStateChanged);
    super.dispose();
  }
}

class SoundscapeState {
  final bool enabled;
  final String type;
  final double volume;

  const SoundscapeState({
    this.enabled = false,
    this.type = 'rain',
    this.volume = 0.5,
  });

  SoundscapeState copyWith({
    bool? enabled,
    String? type,
    double? volume,
  }) =>
      SoundscapeState(
        enabled: enabled ?? this.enabled,
        type: type ?? this.type,
        volume: volume ?? this.volume,
      );
}

class SoundscapeOption {
  final String id;
  final String emoji;
  final String labelEn;
  final String labelAr;

  const SoundscapeOption({
    required this.id,
    required this.emoji,
    required this.labelEn,
    required this.labelAr,
  });

  static const all = [
    SoundscapeOption(id: 'rain', emoji: '🌧️', labelEn: 'Rain', labelAr: 'مطر'),
    SoundscapeOption(
        id: 'forest', emoji: '🌲', labelEn: 'Forest', labelAr: 'غابة'),
    SoundscapeOption(
        id: 'ocean', emoji: '🌊', labelEn: 'Ocean', labelAr: 'محيط'),
    SoundscapeOption(id: 'cafe', emoji: '☕', labelEn: 'Café', labelAr: 'مقهى'),
    SoundscapeOption(
        id: 'fire', emoji: '🔥', labelEn: 'Fireplace', labelAr: 'مدفأة'),
    SoundscapeOption(
        id: 'night', emoji: '🌙', labelEn: 'Night', labelAr: 'ليل'),
    SoundscapeOption(id: 'wind', emoji: '💨', labelEn: 'Wind', labelAr: 'رياح'),
    SoundscapeOption(
        id: 'birds', emoji: '🐦', labelEn: 'Birds', labelAr: 'طيور'),
  ];
}

final soundscapeProvider =
    StateNotifierProvider<SoundscapeService, SoundscapeState>(
  (ref) => SoundscapeService(),
);
