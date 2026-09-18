import 'package:flutter/material.dart';

/// Mood — المشاعر الموسّعة (20 مشاعر).
class Mood {
  final String id;
  final String emoji;
  final String labelEn;
  final String labelAr;
  final Color color;
  final int value; // 1-10 (للإحصائيات)
  final String category; // positive, negative, neutral, complex

  const Mood({
    required this.id,
    required this.emoji,
    required this.labelEn,
    required this.labelAr,
    required this.color,
    required this.value,
    required this.category,
  });

  /// 20 مشاعر مصنّفة.
  static const List<Mood> all = [
    // ─── 😊 إيجابية ───
    Mood(id: 'happy', emoji: '😊', labelEn: 'Happy', labelAr: 'سعيد',
        color: Color(0xFF64DD17), value: 9, category: 'positive'),
    Mood(id: 'joyful', emoji: '😁', labelEn: 'Joyful', labelAr: 'مبتهج',
        color: Color(0xFF00C853), value: 10, category: 'positive'),
    Mood(id: 'grateful', emoji: '🙏', labelEn: 'Grateful', labelAr: 'ممتن',
        color: Color(0xFF009688), value: 9, category: 'positive'),
    Mood(id: 'excited', emoji: '🤩', labelEn: 'Excited', labelAr: 'متحمس',
        color: Color(0xFFFFB300), value: 9, category: 'positive'),
    Mood(id: 'proud', emoji: '😌', labelEn: 'Proud', labelAr: 'فخور',
        color: Color(0xFF7CB342), value: 8, category: 'positive'),
    Mood(id: 'loved', emoji: '🥰', labelEn: 'Loved', labelAr: 'محبوب',
        color: Color(0xFFEC407A), value: 10, category: 'positive'),
    Mood(id: 'in_love', emoji: '❤️', labelEn: 'In Love', labelAr: 'حب',
        color: Color(0xFFE91E63), value: 10, category: 'positive'),
    Mood(id: 'peaceful', emoji: '😇', labelEn: 'Peaceful', labelAr: 'هادئ',
        color: Color(0xFF4DD0E1), value: 8, category: 'positive'),
    Mood(id: 'hopeful', emoji: '🌟', labelEn: 'Hopeful', labelAr: 'متفائل',
        color: Color(0xFFFFD54F), value: 8, category: 'positive'),
    Mood(id: 'calm', emoji: '🧘', labelEn: 'Calm', labelAr: 'رائق',
        color: Color(0xFF81C784), value: 7, category: 'positive'),

    // ─── 😐 محايدة ───
    Mood(id: 'okay', emoji: '😐', labelEn: 'Okay', labelAr: 'لا بأس',
        color: Color(0xFFFFD600), value: 6, category: 'neutral'),
    Mood(id: 'tired', emoji: '😴', labelEn: 'Tired', labelAr: 'متعب',
        color: Color(0xFF9E9E9E), value: 5, category: 'neutral'),
    Mood(id: 'confused', emoji: '😕', labelEn: 'Confused', labelAr: 'مرتبك',
        color: Color(0xFFBCAAA4), value: 5, category: 'neutral'),
    Mood(id: 'indifferent', emoji: '😑', labelEn: 'Indifferent', labelAr: 'غير مبالي',
        color: Color(0xFFBDBDBD), value: 5, category: 'neutral'),

    // ─── 😢 سلبية ───
    Mood(id: 'sad', emoji: '😢', labelEn: 'Sad', labelAr: 'حزين',
        color: Color(0xFF5C6BC0), value: 4, category: 'negative'),
    Mood(id: 'lonely', emoji: '😔', labelEn: 'Lonely', labelAr: 'وحيد',
        color: Color(0xFF7986CB), value: 3, category: 'negative'),
    Mood(id: 'anxious', emoji: '😰', labelEn: 'Anxious', labelAr: 'قلق',
        color: Color(0xFF7E57C2), value: 3, category: 'negative'),
    Mood(id: 'angry', emoji: '😠', labelEn: 'Angry', labelAr: 'غاضب',
        color: Color(0xFFD50000), value: 2, category: 'negative'),
    Mood(id: 'frustrated', emoji: '😤', labelEn: 'Frustrated', labelAr: 'محبط',
        color: Color(0xFFFF6D00), value: 3, category: 'negative'),
    Mood(id: 'depressed', emoji: '😭', labelEn: 'Low mood indicators', labelAr: 'مؤشرات مزاج منخفض',
        color: Color(0xFF311B92), value: 1, category: 'negative'),
  ];

  static Mood? getById(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// التسمية حسب اللغة.
  String label(String langCode) {
    return langCode == 'ar' ? labelAr : labelEn;
  }

  /// تسمية الفئة.
  static String categoryLabel(String category, String langCode) {
    switch (category) {
      case 'positive':
        return langCode == 'ar' ? 'إيجابية' : 'Positive';
      case 'negative':
        return langCode == 'ar' ? 'سلبية' : 'Negative';
      case 'neutral':
        return langCode == 'ar' ? 'محايدة' : 'Neutral';
      default:
        return langCode == 'ar' ? 'مختلطة' : 'Mixed';
    }
  }
}
