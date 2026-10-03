import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/journal_entry.dart';
import '../models/mood.dart';
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
    if (!mounted) return;
    final box = Hive.box(_box);
    final seeds = <PlantedSeed>[];
    final seedTypes = <String>{};
    final duplicateKeys = <dynamic>[];

    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        final planted = PlantedSeed.fromMap(Map<dynamic, dynamic>.from(raw));
        if (seedTypes.add(planted.seedTypeId)) {
          seeds.add(planted);
        } else {
          duplicateKeys.add(key);
        }
      }
    }
    for (final key in duplicateKeys) {
      unawaited(box.delete(key));
    }

    state = GardenState(seeds: seeds, hasChosenSeed: seeds.isNotEmpty);
  }

  /// Refresh persisted Garden data when returning to the screen.
  void refresh() => _load();

  /// اختيار بذرة أولى.
  Future<PlantedSeed> plantSeed(Seed seed) async {
    if (state.seeds.length >= _maxSeeds) {
      throw StateError('Maximum $_maxSeeds seeds reached');
    }
    if (state.seeds.any((planted) => planted.seedTypeId == seed.id)) {
      throw StateError('This seed is already planted');
    }

    final planted = PlantedSeed(
      id: const Uuid().v4(),
      seedTypeId: seed.id,
      plantedAt: DateTime.now(),
    );

    await Hive.box(_box).put(planted.id, planted.toMap());
    if (mounted) _load();
    return planted;
  }

  /// The most growth one day of writing can give, so the garden rewards a
  /// daily habit rather than many short entries in one sitting.
  static const dailyGrowthCap = 12;
  static const _growthDayKey = 'garden_growth_day';
  static const _growthTodayKey = 'garden_growth_today';

  /// Waters the neediest seed after a journal entry is saved.
  ///
  /// The garden rewards the act of writing, never the mood: an honest entry on
  /// a hard day grows the seed as much as a happy one, and is acknowledged
  /// with extra care instead of being treated as a drought.
  ///   • any entry → +3
  ///   • a longer entry → +2 (over 100 words) or +5 (over 300 words)
  ///   • a hard day (negative mood or tone) → +2 care
  ///   • at most [dailyGrowthCap] points a day across all entries
  Future<WateringResult> water(JournalEntry entry) async {
    if (state.seeds.isEmpty) {
      return const WateringResult(
        ok: false,
        messageKey: 'garden.water.noSeed',
      );
    }

    final target = _findTargetSeed();
    if (target == null) {
      return const WateringResult(
        ok: false,
        messageKey: 'garden.water.noTargets',
      );
    }

    final sentiment = _ai.analyzeSentiment(entry.content);
    final trimmed = entry.content.trim();
    final wordCount = trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
    final hardDay = sentiment < -0.1 ||
        Mood.getById(entry.mood)?.category == 'negative';

    var growth = 3;
    if (wordCount > 300) {
      growth += 5;
    } else if (wordCount > 100) {
      growth += 2;
    }
    if (hardDay) growth += 2;

    var messageKey = hardDay
        ? 'garden.water.care'
        : sentiment > 0.3
            ? 'garden.water.growing'
            : sentiment > 0.1
                ? 'garden.water.gentle'
                : 'garden.water.drizzle';

    final allowed = _consumeDailyGrowth(growth);
    if (allowed == 0) messageKey = 'garden.water.rested';
    growth = allowed;

    final now = DateTime.now();
    final today = now.year * 10000 + now.month * 100 + now.day;

    final newPoints = (target.growthPoints + growth).clamp(0, 100);
    final wasComplete = target.isComplete;
    final isNowComplete = newPoints >= 100;

    final updated = target.copyWith(
      growthPoints: newPoints,
      daysCared: target.daysCared +
          (growth > 0 && target.lastWateredDay != today ? 1 : 0),
      lastWateredDay: today,
      isComplete: isNowComplete,
      completionCertificate:
          isNowComplete && !wasComplete ? _generateCertificate(target) : null,
    );

    await Hive.box(_box).put(updated.id, updated.toMap());
    if (mounted) _load();

    return WateringResult(
      ok: true,
      messageKey: messageKey,
      growthAdded: growth,
      isComplete: isNowComplete && !wasComplete,
      seed: updated,
    );
  }

  /// Takes up to [wanted] points from today's allowance and returns what was
  /// granted.
  int _consumeDailyGrowth(int wanted) {
    final settings = Hive.box('settings');
    final now = DateTime.now();
    final today = now.year * 10000 + now.month * 100 + now.day;
    final usedToday = settings.get(_growthDayKey) == today
        ? (settings.get(_growthTodayKey) as num?)?.toInt() ?? 0
        : 0;
    final granted = (dailyGrowthCap - usedToday).clamp(0, wanted);
    unawaited(settings.putAll({
      _growthDayKey: today,
      _growthTodayKey: usedToday + granted,
    }));
    return granted;
  }

  /// حذف بذرة.
  Future<void> removeSeed(String id) async {
    await Hive.box(_box).delete(id);
    if (mounted) _load();
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
    // Stored as data, rendered through the string table by the screen.
    return 'garden.certificate|${seed.seedTypeId}|'
        '${DateTime.now().toIso8601String()}';
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
  final String messageKey;
  final int growthAdded;
  final bool isComplete;
  final PlantedSeed? seed;

  const WateringResult({
    required this.ok,
    required this.messageKey,
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
