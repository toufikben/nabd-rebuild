import 'package:flutter/material.dart';

import '../core/l10n/app_strings.dart';

/// Seed — بذرة نفسية يمكن زراعتها.
class Seed {
  final String id;
  final String emoji;
  final String sproutEmoji;
  final String saplingEmoji;
  final String treeEmoji;
  final String flowerEmoji;
  final List<Color> colors;
  final List<String> relatedMoods;

  const Seed({
    required this.id,
    required this.emoji,
    required this.sproutEmoji,
    required this.saplingEmoji,
    required this.treeEmoji,
    required this.flowerEmoji,
    required this.colors,
    required this.relatedMoods,
  });

  /// Name and description in [languageCode], from the string tables
  /// (`seed.<id>.name|description`), falling back to English.
  String nameFor(String languageCode) =>
      S.of(languageCode)['seed.$id.name'] ?? S.en['seed.$id.name']!;
  String descriptionFor(String languageCode) =>
      S.of(languageCode)['seed.$id.description'] ??
      S.en['seed.$id.description']!;

  String get nameEn => nameFor('en');
  String get nameAr => nameFor('ar');

  static const all = <Seed>[
    Seed(
      id: 'love',
      emoji: '🌹',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌳',
      flowerEmoji: '🌹',
      colors: [Color(0xFFE91E63), Color(0xFFEC407A)],
      relatedMoods: ['loved', 'in_love', 'grateful', 'happy'],
    ),
    Seed(
      id: 'joy',
      emoji: '☀️',
      sproutEmoji: '🌱',
      saplingEmoji: '🌻',
      treeEmoji: '🌳',
      flowerEmoji: '🌻',
      colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
      relatedMoods: ['joyful', 'happy', 'excited'],
    ),
    Seed(
      id: 'peace',
      emoji: '🌲',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌲',
      flowerEmoji: '🍃',
      colors: [Color(0xFF4DD0E1), Color(0xFF26A69A)],
      relatedMoods: ['peaceful', 'calm', 'grateful'],
    ),
    Seed(
      id: 'hope',
      emoji: '🌸',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌳',
      flowerEmoji: '🌸',
      colors: [Color(0xFFF48FB1), Color(0xFFF06292)],
      relatedMoods: ['hopeful', 'proud', 'excited'],
    ),
    Seed(
      id: 'gratitude',
      emoji: '🌻',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌳',
      flowerEmoji: '🌻',
      colors: [Color(0xFFFFB74D), Color(0xFFFB8C00)],
      relatedMoods: ['grateful', 'happy', 'peaceful'],
    ),
    Seed(
      id: 'courage',
      emoji: '💪',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌳',
      flowerEmoji: '🍁',
      colors: [Color(0xFFD32F2F), Color(0xFFE57373)],
      relatedMoods: ['proud', 'excited', 'hopeful'],
    ),
    Seed(
      id: 'patience',
      emoji: '🌿',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🫒',
      flowerEmoji: '🌰',
      colors: [Color(0xFF7CB342), Color(0xFF558B2F)],
      relatedMoods: ['calm', 'peaceful', 'tired'],
    ),
    Seed(
      id: 'wisdom',
      emoji: '🌙',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌳',
      flowerEmoji: '🪷',
      colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
      relatedMoods: ['peaceful', 'grateful', 'proud'],
    ),
    Seed(
      id: 'creativity',
      emoji: '🌺',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌳',
      flowerEmoji: '🌺',
      colors: [Color(0xFFEC407A), Color(0xFFAB47BC)],
      relatedMoods: ['excited', 'joyful', 'hopeful'],
    ),
    Seed(
      id: 'growth',
      emoji: '🌳',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌳',
      flowerEmoji: '🍀',
      colors: [Color(0xFF00B88A), Color(0xFF00897B)],
      relatedMoods: ['proud', 'hopeful', 'excited'],
    ),
  ];

  static Seed? getById(String id) {
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// الحصول على الإيموجي حسب مرحلة النمو.
  String emojiForStage(int stage) {
    switch (stage) {
      case 0:
        return emoji; // seed
      case 1:
        return sproutEmoji; // sprout
      case 2:
        return saplingEmoji; // sapling
      case 3:
      case 4:
      case 5:
      default:
        return treeEmoji; // tree
    }
  }
}

/// PlantedSeed — بذرة مزروعة فعلية.
class PlantedSeed {
  final String id;
  final String seedTypeId;
  final DateTime plantedAt;
  final int growthPoints; // 0-100
  final int daysCared;
  final int lastWateredDay;
  final bool isComplete;
  final String? completionCertificate;

  const PlantedSeed({
    required this.id,
    required this.seedTypeId,
    required this.plantedAt,
    this.growthPoints = 0,
    this.daysCared = 0,
    this.lastWateredDay = 0,
    this.isComplete = false,
    this.completionCertificate,
  });

  /// Growth stage (0-5). The meaningful thresholds are 25/50/75/100 so a
  /// seed needs weeks of care, not a handful of entries.
  int get growthStage {
    if (growthPoints >= 100) return 5;
    if (growthPoints >= 75) return 4;
    if (growthPoints >= 50) return 3;
    if (growthPoints >= 25) return 2;
    if (growthPoints >= 10) return 1;
    return 0;
  }

  /// Growth as a fraction from 0 to 1.
  double get progress => growthPoints / 100;

  /// Whole days since the last watering, or 0 when never watered.
  int daysWithoutWater(DateTime now) {
    if (lastWateredDay <= 0) return 0;
    final year = lastWateredDay ~/ 10000;
    final month = (lastWateredDay ~/ 100) % 100;
    final day = lastWateredDay % 100;
    final last = DateTime(year, month, day);
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(last).inDays.clamp(0, 3650).toInt();
  }

  /// A completed seed never needs water again. After two dry days the garden
  /// looks thirsty, but no points are lost.
  bool needsWater(DateTime now) => !isComplete && lastWateredDay < _dayKey(now);

  bool isThirsty(DateTime now) => !isComplete && daysWithoutWater(now) >= 2;

  DateTime? get completedAt {
    final parts = completionCertificate?.split('|');
    if (parts == null || parts.length < 3) return null;
    return DateTime.tryParse(parts[2]);
  }

  static int _dayKey(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  Seed? get seed => Seed.getById(seedTypeId);

  Map<String, dynamic> toMap() => {
        'id': id,
        'seedTypeId': seedTypeId,
        'plantedAt': plantedAt.toIso8601String(),
        'growthPoints': growthPoints,
        'daysCared': daysCared,
        'lastWateredDay': lastWateredDay,
        'isComplete': isComplete,
        'completionCertificate': completionCertificate,
      };

  factory PlantedSeed.fromMap(Map<dynamic, dynamic> m) => PlantedSeed(
        id: m['id']?.toString() ?? '',
        seedTypeId: m['seedTypeId']?.toString() ?? 'love',
        plantedAt: DateTime.tryParse(m['plantedAt']?.toString() ?? '') ??
            DateTime.now(),
        growthPoints: (m['growthPoints'] as num?)?.toInt() ?? 0,
        daysCared: (m['daysCared'] as num?)?.toInt() ?? 0,
        lastWateredDay: (m['lastWateredDay'] as num?)?.toInt() ?? 0,
        isComplete: m['isComplete'] == true,
        completionCertificate: m['completionCertificate']?.toString(),
      );

  PlantedSeed copyWith({
    int? growthPoints,
    int? daysCared,
    int? lastWateredDay,
    bool? isComplete,
    String? completionCertificate,
  }) =>
      PlantedSeed(
        id: id,
        seedTypeId: seedTypeId,
        plantedAt: plantedAt,
        growthPoints: growthPoints ?? this.growthPoints,
        daysCared: daysCared ?? this.daysCared,
        lastWateredDay: lastWateredDay ?? this.lastWateredDay,
        isComplete: isComplete ?? this.isComplete,
        completionCertificate:
            completionCertificate ?? this.completionCertificate,
      );
}
