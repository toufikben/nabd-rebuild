import 'dart:math' as math;

/// VoiceToneService — كشف نبرة الصوت (مبسط).
///
/// الفكرة: بعض المشاعر لا تظهر في الكلمات بل في الصوت.
class VoiceToneService {
  /// تحليل موجز للطاقة العاطفية من مستويات الصوت.
  ToneAnalysis analyze(List<double> soundLevels) {
    if (soundLevels.isEmpty) {
      return const ToneAnalysis(
        tone: 'neutral',
        intensity: 0,
        confidence: 0,
      );
    }

    final avg = soundLevels.reduce((a, b) => a + b) / soundLevels.length;
    final variance = soundLevels
            .map((v) => math.pow(v - avg, 2))
            .reduce((a, b) => a + b) /
        soundLevels.length;
    final stdDev = math.sqrt(variance.toDouble());

    // Analyze pattern
    String tone;
    double confidence;

    if (stdDev > 0.3) {
      tone = 'agitated';
      confidence = 0.7;
    } else if (avg > 0.7) {
      tone = 'energetic';
      confidence = 0.6;
    } else if (avg < 0.2) {
      tone = 'calm';
      confidence = 0.7;
    } else {
      tone = 'neutral';
      confidence = 0.5;
    }

    return ToneAnalysis(
      tone: tone,
      intensity: avg,
      confidence: confidence,
    );
  }

  /// اقتراح mood من نبرة الصوت.
  String? suggestMoodFromTone(String tone) {
    switch (tone) {
      case 'agitated':
        return 'frustrated';
      case 'energetic':
        return 'excited';
      case 'calm':
        return 'peaceful';
      case 'neutral':
        return 'okay';
      default:
        return null;
    }
  }
}

class ToneAnalysis {
  final String tone;
  final double intensity;
  final double confidence;

  const ToneAnalysis({
    required this.tone,
    required this.intensity,
    required this.confidence,
  });

  String labelAr() {
    switch (tone) {
      case 'agitated':
        return 'متوتر';
      case 'energetic':
        return 'نشيط';
      case 'calm':
        return 'هادئ';
      default:
        return 'محايد';
    }
  }
}
