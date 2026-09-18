import 'package:flutter/material.dart';

/// MoodWeather — تحويل المزاج إلى طقس بصري.
///
/// الفكرة: المشاعر ليست مجرد emoji — بل مناخ كامل.
enum WeatherType {
  sunny,      // مشمس - سعادة
  partlyCloudy, // غائم جزئيًا - هدوء
  cloudy,     // غائم - محايد
  rainy,      // مطر - حزن
  stormy,     // عاصف - غضب
  foggy,      // ضبابي - قلق
  snowy,      // ثلجي - برود
  rainbow,    // قوس قزح - مختلط
}

class MoodWeather {
  final WeatherType type;
  final String emoji;
  final String labelEn;
  final String labelAr;
  final List<Color> gradient;
  final IconData icon;

  const MoodWeather({
    required this.type,
    required this.emoji,
    required this.labelEn,
    required this.labelAr,
    required this.gradient,
    required this.icon,
  });

  /// تحويل المزاج إلى طقس.
  static MoodWeather fromMoodValue(double avgValue) {
    if (avgValue >= 9) return _sunny;
    if (avgValue >= 7) return _partlyCloudy;
    if (avgValue >= 5) return _cloudy;
    if (avgValue >= 3.5) return _rainy;
    if (avgValue >= 2) return _stormy;
    return _foggy;
  }

  static MoodWeather fromMoodId(String id) {
    switch (id) {
      case 'happy':
      case 'joyful':
      case 'loved':
      case 'in_love':
        return _sunny;
      case 'grateful':
      case 'proud':
      case 'hopeful':
      case 'peaceful':
      case 'calm':
        return _partlyCloudy;
      case 'okay':
      case 'tired':
      case 'indifferent':
        return _cloudy;
      case 'sad':
      case 'lonely':
        return _rainy;
      case 'angry':
      case 'frustrated':
        return _stormy;
      case 'anxious':
      case 'confused':
      case 'depressed':
        return _foggy;
      case 'excited':
        return _rainbow;
      default:
        return _cloudy;
    }
  }

  static const _sunny = MoodWeather(
    type: WeatherType.sunny,
    emoji: '☀️',
    labelEn: 'Sunny',
    labelAr: 'مشمس',
    gradient: [Color(0xFFFFD54F), Color(0xFFFF9800)],
    icon: Icons.wb_sunny,
  );

  static const _partlyCloudy = MoodWeather(
    type: WeatherType.partlyCloudy,
    emoji: '⛅',
    labelEn: 'Partly Cloudy',
    labelAr: 'غائم جزئيًا',
    gradient: [Color(0xFF81D4FA), Color(0xFFFFD54F)],
    icon: Icons.wb_cloudy,
  );

  static const _cloudy = MoodWeather(
    type: WeatherType.cloudy,
    emoji: '☁️',
    labelEn: 'Cloudy',
    labelAr: 'غائم',
    gradient: [Color(0xFF90A4AE), Color(0xFF607D8B)],
    icon: Icons.cloud,
  );

  static const _rainy = MoodWeather(
    type: WeatherType.rainy,
    emoji: '🌧️',
    labelEn: 'Rainy',
    labelAr: 'ممطر',
    gradient: [Color(0xFF546E7A), Color(0xFF37474F)],
    icon: Icons.grain,
  );

  static const _stormy = MoodWeather(
    type: WeatherType.stormy,
    emoji: '⛈️',
    labelEn: 'Stormy',
    labelAr: 'عاصف',
    gradient: [Color(0xFF263238), Color(0xFF000000)],
    icon: Icons.flash_on,
  );

  static const _foggy = MoodWeather(
    type: WeatherType.foggy,
    emoji: '🌫️',
    labelEn: 'Foggy',
    labelAr: 'ضبابي',
    gradient: [Color(0xFFB0BEC5), Color(0xFF78909C)],
    icon: Icons.foggy,
  );

  static const _rainbow = MoodWeather(
    type: WeatherType.rainbow,
    emoji: '🌈',
    labelEn: 'Rainbow',
    labelAr: 'قوس قزح',
    gradient: [Color(0xFFFF6B9D), Color(0xFF6C5CE7)],
    icon: Icons.color_lens,
  );
}
