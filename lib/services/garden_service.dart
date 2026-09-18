import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/journal_entry.dart';
import '../models/seed.dart';
import 'local_ai_service.dart';

/// GardenService — يدير حديقة البذور.
///
/// المنطق النفسي:
///   • الكتابة اليومية = نمو
///   • مشاعر إيجابية = نمو مضاعف
///   • مشاعر سلبية = عطش (بحاجة للماء)
///   • كتابة 3 أشياء جميلة = سقي
class GardenService extends StateNotifier<GardenState> {
  GardenService() : super(const GardenState()) {
    _load();
  }

  static const _box = 'garden';
  static const _maxSeeds = 10;

  final _ai = LocalAIService();

  void _load() {
    final box = Hive.box(_box);
    final seeds = <PlantedSeed>[];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        seeds.add(PlantedSeed.fromMap(Map<dynamic, dynamic>.from(raw)));
      }
    }

    state = GardenState(seeds: seeds);
  }

  /// اختيار بذرة أولى.
  Future<PlantedSeed> plantSeed(Seed seed) async {
    if (state.seeds.length >= _maxSeeds) {
      throw StateError('Maximum $_maxSeeds seeds reached');
    }

    final planted = PlantedSeed(
      id: const Uuid().v4(),
      seedTypeId: seed.id,
      plantedAt: DateTime.now(),
    );

    await Hive.box(_box).put(planted.id, planted.toMap());
    _load();
    return planted;
  }

  /// "سقي" البذرة بعد كتابة مذكرة.
  ///
  /// المنطق:
  ///   • مذكرة عادية → +2 نقاط نمو
  ///   • مذكرة إيجابية → +5 نقاط
  ///   • مذكرة سلبية → لا نمو + تحتاج للترطيب
  ///   • 3 جمل إيجابية → +8 نقاط
  Future<WateringResult> water(JournalEntry entry) async {
    if (state.seeds.isEmpty) {
      return const WateringResult(
        ok: false,
        message: 'Plant a seed first',
      );
    }

    // Find the most needy seed
    final target = _findTargetSeed();
    if (target == null) {
      return const WateringResult(
        ok: false,
        message: 'No seeds to water',
      );
    }

    // Analyze entry
    final sentiment = _ai.analyzeSentiment(entry.content);
    final wordCount = entry.content.split(RegExp(r'\s+')).length;

    int growth;
    String message;

    if (sentiment > 0.3) {
      // Positive entry
      growth = 5;
      message = 'Your seed is growing beautifully! 🌱';
    } else if (sentiment > 0.1) {
      // Slightly positive
      growth = 3;
      message = 'Your seed got a gentle shower 💧';
    } else if (sentiment > -0.1) {
      // Neutral
      growth = 2;
      message = 'Your seed received a light drizzle 🌦️';
    } else {
      // Negative
      growth = 0;
      message = 'Your seed needs love. Try writing 3 beautiful things 💗';
    }

    // Bonus for longer entries
    if (wordCount > 100) growth += 2;
    if (wordCount > 300) growth += 3;

    final now = DateTime.now();
    final today = now.year * 10000 + now.month * 100 + now.day;

    final newPoints = (target.growthPoints + growth).clamp(0, 100);
    final wasComplete = target.isComplete;
    final isNowComplete = newPoints >= 100;

    final updated = target.copyWith(
      growthPoints: newPoints,
      daysCared: target.daysCared + (growth > 0 ? 1 : 0),
      lastWateredDay: today,
      isComplete: isNowComplete,
      completionCertificate: isNowComplete && !wasComplete
          ? _generateCertificate(target)
          : null,
    );

    await Hive.box(_box).put(updated.id, updated.toMap());
    _load();

    return WateringResult(
      ok: true,
      message: message,
      growthAdded: growth,
      isComplete: isNowComplete && !wasComplete,
      seed: updated,
    );
  }

  /// حذف بذرة.
  Future<void> removeSeed(String id) async {
    await Hive.box(_box).delete(id);
    _load();
  }

  /// البذرة الأكثر احتياجًا.
  PlantedSeed? _findTargetSeed() {
    if (state.seeds.isEmpty) return null;
    // Sort by needs water first, then by lowest growth
    final sorted = [...state.seeds]..sort((a, b) {
        final aNeeds = a.needsWater(DateTime.now()) ? 0 : 1;
        final bNeeds = b.needsWater(DateTime.now()) ? 0 : 1;
        if (aNeeds != bNeeds) return aNeeds - bNeeds;
        return a.growthPoints.compareTo(b.growthPoints);
      });
    return sorted.first;
  }

  String _generateCertificate(PlantedSeed seed) {
    return 'Certificate of Growth\n'
        'Awarded to: You\n'
        'Date: ${DateTime.now().toIso8601String()}\n'
        'For nurturing a ${seed.seed?.nameEn ?? "seed"} to full bloom.';
  }

  /// إحصائيات الحديقة.
  GardenStats getStats() {
    final total = state.seeds.length;
    final completed = state.seeds.where((s) => s.isComplete).length;
    final totalGrowth =
        state.seeds.fold<int>(0, (sum, s) => sum + s.growthPoints);
    final avgGrowth = total == 0 ? 0.0 : totalGrowth / total;

    return GardenStats(
      totalSeeds: total,
      completedSeeds: completed,
      averageGrowth: avgGrowth,
    );
  }

  /// البذرة الرئيسية (الأكبر).
  PlantedSeed? get primarySeed {
    if (state.seeds.isEmpty) return null;
    return state.seeds.reduce(
      (a, b) => a.growthPoints > b.growthPoints ? a : b,
    );
  }
}

class GardenState {
  final List<PlantedSeed> seeds;
  final bool hasChosenSeed;

  const GardenState({
    this.seeds = const [],
    this.hasChosenSeed = false,
  });

  GardenState copyWith({
    List<PlantedSeed>? seeds,
    bool? hasChosenSeed,
  }) =>
      GardenState(
        seeds: seeds ?? this.seeds,
        hasChosenSeed: hasChosenSeed ?? this.hasChosenSeed,
      );
}

class WateringResult {
  final bool ok;
  final String message;
  final int growthAdded;
  final bool isComplete;
  final PlantedSeed? seed;

  const WateringResult({
    required this.ok,
    required this.message,
    this.growthAdded = 0,
    this.isComplete = false,
    this.seed,
  });
}

class GardenStats {
  final int totalSeeds;
  final int completedSeeds;
  final double averageGrowth;

  const GardenStats({
    required this.totalSeeds,
    required this.completedSeeds,
    required this.averageGrowth,
  });
}

final gardenProvider =
    StateNotifierProvider<GardenService, GardenState>((ref) => GardenService());
