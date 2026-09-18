import 'package:flutter/material.dart';

/// Seed — بذرة نفسية يمكن زراعتها.
class Seed {
  final String id;
  final String nameEn;
  final String nameAr;
  final String emoji;
  final String sproutEmoji;
  final String saplingEmoji;
  final String treeEmoji;
  final String flowerEmoji;
  final List<Color> colors;
  final List<String> relatedMoods;
  final String description;

  const Seed({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.emoji,
    required this.sproutEmoji,
    required this.saplingEmoji,
    required this.treeEmoji,
    required this.flowerEmoji,
    required this.colors,
    required this.relatedMoods,
    required this.description,
  });

  static const all = <Seed>[
    Seed(
      id: 'love',
      nameEn: 'Love',
      nameAr: 'الحب',
      emoji: '🌹',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌳',
      flowerEmoji: '🌹',
      colors: [Color(0xFFE91E63), Color(0xFFEC407A)],
      relatedMoods: ['loved', 'in_love', 'grateful', 'happy'],
      description: 'Nurture love in your life',
    ),
    Seed(
      id: 'joy',
      nameEn: 'Joy',
      nameAr: 'الفرح',
      emoji: '☀️',
      sproutEmoji: '🌱',
      saplingEmoji: '🌻',
      treeEmoji: '🌳',
      flowerEmoji: '🌻',
      colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
      relatedMoods: ['joyful', 'happy', 'excited'],
      description: 'Cultivate everyday joy',
    ),
    Seed(
      id: 'peace',
      nameEn: 'Peace',
      nameAr: 'السلام',
      emoji: '🌲',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌲',
      flowerEmoji: '🍃',
      colors: [Color(0xFF4DD0E1), Color(0xFF26A69A)],
      relatedMoods: ['peaceful', 'calm', 'grateful'],
      description: 'Find inner peace',
    ),
    Seed(
      id: 'hope',
      nameEn: 'Hope',
      nameAr: 'الأمل',
      emoji: '🌸',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌳',
      flowerEmoji: '🌸',
      colors: [Color(0xFFF48FB1), Color(0xFFF06292)],
      relatedMoods: ['hopeful', 'proud', 'excited'],
      description: 'Nurture hope and optimism',
    ),
    Seed(
      id: 'gratitude',
      nameEn: 'Gratitude',
      nameAr: 'الامتنان',
      emoji: '🌻',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌳',
      flowerEmoji: '🌻',
      colors: [Color(0xFFFFB74D), Color(0xFFFB8C00)],
      relatedMoods: ['grateful', 'happy', 'peaceful'],
      description: 'Practice gratitude daily',
    ),
    Seed(
      id: 'courage',
      nameEn: 'Courage',
      nameAr: 'الشجاعة',
      emoji: '💪',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌳',
      flowerEmoji: '🍁',
      colors: [Color(0xFFD32F2F), Color(0xFFE57373)],
      relatedMoods: ['proud', 'excited', 'hopeful'],
      description: 'Build courage and strength',
    ),
    Seed(
      id: 'patience',
      nameEn: 'Patience',
      nameAr: 'الصبر',
      emoji: '🌿',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🫒',
      flowerEmoji: '🌰',
      colors: [Color(0xFF7CB342), Color(0xFF558B2F)],
      relatedMoods: ['calm', 'peaceful', 'tired'],
      description: 'Develop patience',
    ),
    Seed(
      id: 'wisdom',
      nameEn: 'Wisdom',
      nameAr: 'الحكمة',
      emoji: '🌙',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌳',
      flowerEmoji: '🪷',
      colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
      relatedMoods: ['peaceful', 'grateful', 'proud'],
      description: 'Seek wisdom',
    ),
    Seed(
      id: 'creativity',
      nameEn: 'Creativity',
      nameAr: 'الإبداع',
      emoji: '🌺',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌳',
      flowerEmoji: '🌺',
      colors: [Color(0xFFEC407A), Color(0xFFAB47BC)],
      relatedMoods: ['excited', 'joyful', 'hopeful'],
      description: 'Spark creativity',
    ),
    Seed(
      id: 'growth',
      nameEn: 'Growth',
      nameAr: 'النمو',
      emoji: '🌳',
      sproutEmoji: '🌱',
      saplingEmoji: '🌿',
      treeEmoji: '🌳',
      flowerEmoji: '🍀',
      colors: [Color(0xFF00B88A), Color(0xFF00897B)],
      relatedMoods: ['proud', 'hopeful', 'excited'],
      description: 'Embrace personal growth',
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

  /// مرحلة النمو (0-5).
  int get growthStage {
    if (growthPoints >= 100) return 5;
    if (growthPoints >= 60) return 4;
    if (growthPoints >= 25) return 3;
    if (growthPoints >= 10) return 2;
    if (growthPoints >= 3) return 1;
    return 0;
  }

  /// نسبة النمو من 0-100.
  double get progress => growthPoints / 100;

  /// هل تحتاج الماء اليوم؟
  bool needsWater(DateTime now) {
    final today = now.year * 10000 + now.month * 100 + now.day;
    return lastWateredDay < today;
  }

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
        completionCertificate: completionCertificate ?? this.completionCertificate,
      );
}
