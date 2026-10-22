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
  static const _archivePrefix = 'archive_';
  static const _seasonKey = 'garden_season';
  static const maxSeeds = 10;

  final _ai = LocalAIService();

  void _load() {
    if (!mounted) return;
    final box = Hive.box(_box);
    final seeds = <PlantedSeed>[];
    final seedTypes = <String>{};
    final duplicateKeys = <dynamic>[];

    for (final key in box.keys) {
      if (key.toString().startsWith(_archivePrefix)) continue;
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

  /// Seasons that were archived after every seed bloomed. They share the
  /// garden box under an `archive_` prefix, so backups and Delete All already
  /// cover them without a second box to forget.
  List<ArchivedSeed> get archivedSeeds {
    final box = Hive.box(_box);
    final archived = <ArchivedSeed>[];
    for (final key in box.keys) {
      if (!key.toString().startsWith(_archivePrefix)) continue;
      final raw = box.get(key);
      if (raw is! Map) continue;
      final map = Map<dynamic, dynamic>.from(raw);
      archived.add(ArchivedSeed(
        seed: PlantedSeed.fromMap(map),
        season: (map['season'] as num?)?.toInt() ?? 1,
      ));
    }
    archived.sort((a, b) {
      final season = b.season.compareTo(a.season);
      if (season != 0) return season;
      return a.seed.plantedAt.compareTo(b.seed.plantedAt);
    });
    return archived;
  }

  int get currentSeason {
    final value = Hive.box('settings').get(_seasonKey);
    return value is int ? value : 1;
  }

  bool get everySeedComplete =>
      state.seeds.isNotEmpty && state.seeds.every((seed) => seed.isComplete);

  /// Archives the finished garden and starts an empty next season. The
  /// archived seeds stay visible in [archivedSeeds] and can still share
  /// their certificates.
  Future<int> startNewSeason() async {
    if (!everySeedComplete) {
      throw StateError('Every seed must bloom before a new season');
    }
    final box = Hive.box(_box);
    final season = currentSeason;
    for (final seed in state.seeds) {
      await box.put(
        '$_archivePrefix${season}_${seed.id}',
        {...seed.toMap(), 'season': season},
      );
    }
    for (final seed in state.seeds) {
      await box.delete(seed.id);
    }
    final settings = Hive.box('settings');
    await settings.putAll({
      _seasonKey: season + 1,
      _growthDayKey: 0,
      _growthTodayKey: 0,
    });
    if (mounted) _load();
    return season + 1;
  }

  /// Refresh persisted Garden data when returning to the screen.
  void refresh() => _load();

  /// اختيار بذرة أولى.
  Future<PlantedSeed> plantSeed(Seed seed) async {
    if (state.seeds.length >= maxSeeds) {
      throw StateError('Maximum $maxSeeds seeds reached');
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

  /// The most growth one watering can give. One entry a day is enough to
  /// water the garden; extra entries the same day do not add points.
  static const dailyGrowthCap = 6;
  static const _growthDayKey = 'garden_growth_day';
  static const _growthTodayKey = 'garden_growth_today';

  /// Waters the neediest seed after the first journal entry of the day.
  ///
  /// The garden rewards the act of writing, never the mood: an honest entry on
  /// a hard day grows the seed as much as a happy one, and is acknowledged
  /// with extra care instead of being treated as a drought.
  ///   • any entry → +3
  ///   • a longer entry → +2 (over 100 words) or +5 (over 300 words)
  ///   • a hard day (negative mood or tone) → +2 care
  ///   • at most [dailyGrowthCap] points per watering
  ///
  /// Only the first entry of the day waters; later entries return the
  /// `garden.water.rested` message and change nothing.
  Future<WateringResult> water(JournalEntry entry) async {
    if (state.seeds.isEmpty) {
      return const WateringResult(
        ok: false,
        messageKey: 'garden.water.noSeed',
      );
    }

    final now = DateTime.now();
    final today = _dayKey(now);
    final settings = Hive.box('settings');
    if (settings.get(_growthDayKey) == today) {
      return const WateringResult(
        ok: true,
        messageKey: 'garden.water.rested',
      );
    }

    final target = _findTargetSeed();
    if (target == null) {
      return const WateringResult(
        ok: true,
        messageKey: 'garden.water.noTargets',
      );
    }

    final sentiment = _ai.analyzeSentiment(entry.content);
    final trimmed = entry.content.trim();
    final wordCount =
        trimmed.isEmpty ? 0 : trimmed.split(RegExp(r'\s+')).length;
    final hardDay =
        sentiment < -0.1 || Mood.getById(entry.mood)?.category == 'negative';

    var growth = 3;
    if (wordCount > 300) {
      growth += 5;
    } else if (wordCount > 100) {
      growth += 2;
    }
    if (hardDay) growth += 2;
    growth = growth.clamp(0, dailyGrowthCap).toInt();

    final messageKey = hardDay
        ? 'garden.water.care'
        : sentiment > 0.3
            ? 'garden.water.growing'
            : sentiment > 0.1
                ? 'garden.water.gentle'
                : 'garden.water.drizzle';

    final newPoints = (target.growthPoints + growth).clamp(0, 100).toInt();
    final wasComplete = target.isComplete;
    final isNowComplete = newPoints >= 100;

    final updated = target.copyWith(
      growthPoints: newPoints,
      daysCared: target.daysCared + (target.lastWateredDay != today ? 1 : 0),
      lastWateredDay: today,
      isComplete: isNowComplete,
      completionCertificate:
          isNowComplete && !wasComplete ? _generateCertificate(target) : null,
    );

    await Hive.box(_box).put(updated.id, updated.toMap());
    await settings.putAll({
      _growthDayKey: today,
      _growthTodayKey: growth,
    });
    if (mounted) _load();

    return WateringResult(
      ok: true,
      messageKey: messageKey,
      growthAdded: growth,
      isComplete: isNowComplete && !wasComplete,
      seed: updated,
    );
  }

  static int _dayKey(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;

  /// حذف بذرة.
  Future<void> removeSeed(String id) async {
    await Hive.box(_box).delete(id);
    if (mounted) _load();
    if (state.seeds.isEmpty) {
      await Hive.box('settings').delete(_growthDayKey);
    }
  }

  /// The seed that should receive today's watering.
  PlantedSeed? _findTargetSeed() {
    final growing = state.seeds.where((seed) => !seed.isComplete).toList();
    if (growing.isEmpty) return null;
    // Sort by needs water first, then by lowest growth.
    growing.sort((a, b) {
      final aNeeds = a.needsWater(DateTime.now()) ? 0 : 1;
      final bNeeds = b.needsWater(DateTime.now()) ? 0 : 1;
      if (aNeeds != bNeeds) return aNeeds - bNeeds;
      return a.growthPoints.compareTo(b.growthPoints);
    });
    return growing.first;
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

class ArchivedSeed {
  final PlantedSeed seed;
  final int season;

  const ArchivedSeed({required this.seed, required this.season});
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
