import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio/just_audio.dart';

/// SoundscapeService — أصوات محيطة فعلية للكتابة.
class SoundscapeService extends StateNotifier<SoundscapeState> {
  SoundscapeService() : super(const SoundscapeState()) {
    load();
  }

  final AudioPlayer _player = AudioPlayer();

  Future<void> toggle() async {
    final enabled = !state.enabled;
    state = state.copyWith(enabled: enabled);
    await Hive.box('settings').put('soundscape_enabled', enabled);
    if (enabled) {
      await _playCurrent();
    } else {
      await _player.stop();
    }
  }

  Future<void> setType(String type) async {
    state = state.copyWith(type: type);
    await Hive.box('settings').put('soundscape_type', type);
    if (state.enabled) await _playCurrent();
  }

  Future<void> setVolume(double volume) async {
    final safeVolume = volume.clamp(0.0, 1.0);
    state = state.copyWith(volume: safeVolume);
    await Hive.box('settings').put('soundscape_volume', safeVolume);
    await _player.setVolume(safeVolume);
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

  Future<void> _playCurrent() async {
    try {
      await _player.setAsset('assets/sounds/${_assetFor(state.type)}.mp3');
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(state.volume);
      await _player.play();
    } catch (error) {
      debugPrint('Soundscape failed for ${state.type}: $error');
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
    _player.dispose();
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
