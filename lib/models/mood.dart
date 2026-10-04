import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';

/// Mood — المشاعر الموسّعة (20 مشاعر).
class Mood {
  final String id;
  final String emoji;
  final Color color;
  final int value; // 1-10 (للإحصائيات)
  final String category; // positive, negative, neutral, complex

  const Mood({
    required this.id,
    required this.emoji,
    required this.color,
    required this.value,
    required this.category,
  });

  /// The mood's name in [languageCode], from the string tables
  /// (`mood.<id>` in l10n/<code>.json), falling back to English.
  String label(String languageCode) =>
      S.of(languageCode)['mood.$id'] ?? S.en['mood.$id'] ?? id;

  String get labelEn => label('en');
  String get labelAr => label('ar');

  /// 20 مشاعر مصنّفة.
  static const List<Mood> all = [
    // ─── 😊 إيجابية ───
    Mood(id: 'happy', emoji: '😊', color: Color(0xFF64DD17), value: 9, category: 'positive'),
    Mood(id: 'joyful', emoji: '😁', color: Color(0xFF00C853), value: 10, category: 'positive'),
    Mood(id: 'grateful', emoji: '🙏', color: Color(0xFF009688), value: 9, category: 'positive'),
    Mood(id: 'excited', emoji: '🤩', color: Color(0xFFFFB300), value: 9, category: 'positive'),
    Mood(id: 'proud', emoji: '😌', color: Color(0xFF7CB342), value: 8, category: 'positive'),
    Mood(id: 'loved', emoji: '🥰', color: Color(0xFFEC407A), value: 10, category: 'positive'),
    Mood(id: 'in_love', emoji: '❤️', color: Color(0xFFE91E63), value: 10, category: 'positive'),
    Mood(id: 'peaceful', emoji: '😇', color: Color(0xFF4DD0E1), value: 8, category: 'positive'),
    Mood(id: 'hopeful', emoji: '🌟', color: Color(0xFFFFD54F), value: 8, category: 'positive'),
    Mood(id: 'calm', emoji: '🧘', color: Color(0xFF81C784), value: 7, category: 'positive'),

    // ─── 😐 محايدة ───
    Mood(id: 'okay', emoji: '😐', color: Color(0xFFFFD600), value: 6, category: 'neutral'),
    Mood(id: 'tired', emoji: '😴', color: Color(0xFF9E9E9E), value: 5, category: 'neutral'),
    Mood(id: 'confused', emoji: '😕', color: Color(0xFFBCAAA4), value: 5, category: 'neutral'),
    Mood(id: 'indifferent', emoji: '😑', color: Color(0xFFBDBDBD), value: 5, category: 'neutral'),

    // ─── 😢 سلبية ───
    Mood(id: 'sad', emoji: '😢', color: Color(0xFF5C6BC0), value: 4, category: 'negative'),
    Mood(id: 'lonely', emoji: '😔', color: Color(0xFF7986CB), value: 3, category: 'negative'),
    Mood(id: 'anxious', emoji: '😰', color: Color(0xFF7E57C2), value: 3, category: 'negative'),
    Mood(id: 'angry', emoji: '😠', color: Color(0xFFD50000), value: 2, category: 'negative'),
    Mood(id: 'frustrated', emoji: '😤', color: Color(0xFFFF6D00), value: 3, category: 'negative'),
    Mood(id: 'depressed', emoji: '😭', color: Color(0xFF311B92), value: 1, category: 'negative'),
  ];

  static const List<Mood> journalMoods = [
    allHappy,
    allPeaceful,
    allGrateful,
    allExcited,
    _journalNeutral,
    allTired,
    allAnxious,
    allSad,
    allAngry,
    _journalDisappointed,
  ];

  static const allHappy = Mood(id: 'happy', emoji: '😊', color: Color(0xFF64DD17), value: 9, category: 'positive');
  static const allPeaceful = Mood(id: 'peaceful', emoji: '😇', color: Color(0xFF4DD0E1), value: 8, category: 'positive');
  static const allGrateful = Mood(id: 'grateful', emoji: '🙏', color: Color(0xFF009688), value: 9, category: 'positive');
  static const allExcited = Mood(id: 'excited', emoji: '🤩', color: Color(0xFFFFB300), value: 9, category: 'positive');
  static const allTired = Mood(id: 'tired', emoji: '😴', color: Color(0xFF9E9E9E), value: 5, category: 'neutral');
  static const allAnxious = Mood(id: 'anxious', emoji: '😰', color: Color(0xFF7E57C2), value: 3, category: 'negative');
  static const allSad = Mood(id: 'sad', emoji: '😢', color: Color(0xFF5C6BC0), value: 4, category: 'negative');
  static const allAngry = Mood(id: 'angry', emoji: '😠', color: Color(0xFFD50000), value: 2, category: 'negative');
  static const _journalNeutral = Mood(id: 'neutral', emoji: '😐', color: Color(0xFFFFD600), value: 6, category: 'neutral');
  static const _journalDisappointed = Mood(id: 'disappointed', emoji: '😞', color: Color(0xFFFF6D00), value: 3, category: 'negative');

  static Mood? getById(String id) {
    try {
      return [...all, ...journalMoods].firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// تسمية الفئة.
  static String categoryLabel(String category, String langCode) {
    final key = 'moodCategory.${const {'positive', 'negative', 'neutral'}.contains(category) ? category : 'complex'}';
    return S.of(langCode)[key] ?? S.en[key]!;
  }

}
