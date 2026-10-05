import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/storage.dart';
import '../models/journal_entry.dart';
import '../models/mood.dart';

/// A small daily habit that tends to lift the mood: a walk, water, a call.
///
/// A preset has a [presetId] and is named from the string tables, so it
/// follows the app language; a custom habit keeps the [name] it was given.
class Habit {
  Habit({
    String? id,
    this.presetId,
    this.name = '',
    required this.emoji,
    DateTime? createdAt,
    this.archived = false,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String? presetId;
  final String name;
  final String emoji;
  final DateTime createdAt;
  final bool archived;

  String nameKey() => 'habit.preset.$presetId';

  Habit copyWith({bool? archived}) => Habit(
        id: id,
        presetId: presetId,
        name: name,
        emoji: emoji,
        createdAt: createdAt,
        archived: archived ?? this.archived,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        if (presetId != null) 'preset': presetId,
        'name': name,
        'emoji': emoji,
        'createdAt': createdAt.toIso8601String(),
        'archived': archived,
      };

  static Habit? fromMap(Object? raw) {
    if (raw is! Map || raw['id'] is! String) return null;
    return Habit(
      id: raw['id'] as String,
      presetId: raw['preset'] as String?,
      name: raw['name'] as String? ?? '',
      emoji: raw['emoji'] as String? ?? '•',
      createdAt: DateTime.tryParse('${raw['createdAt']}') ?? DateTime.now(),
      archived: raw['archived'] == true,
    );
  }

  /// Small, kind, doable in minutes. Ids are permanent: they name strings.
  static const presets = <(String, String)>[
    ('walk', '🚶'),
    ('water', '💧'),
    ('outside', '🌤️'),
    ('stretch', '🤸'),
    ('breathe', '🌬️'),
    ('call', '📞'),
    ('read', '📖'),
    ('gratitude', '🙏'),
    ('screens', '📵'),
    ('sleep', '🌙'),
  ];
}

/// How a habit and the mood go together: the average mood on days it was
/// done against days it was not, over days that have a journal mood.
class HabitMoodLink {
  const HabitMoodLink(this.withHabit, this.without);

  final double withHabit;
  final double without;

  double get difference => withHabit - without;

  /// Enough days on each side for the comparison to mean something.
  static const minimumDays = 4;
}

/// Habits live in the content box: the list of habits as records with ids,
/// and check-ins as plain `habitId|yyyy-mm-dd` strings, so a backup merge
/// joins both without losing a day.
class HabitService {
  HabitService({Box? box}) : _box = box;

  final Box? _box;
  Box get _content => _box ?? contentBox();

  static String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  List<Habit> all() => [
        for (final raw in _content.get(ContentKeys.habits) as List? ?? const [])
          if (Habit.fromMap(raw) case final habit?) habit,
      ];

  List<Habit> active() => all().where((h) => !h.archived).toList();

  Set<String> _checks() => {
        for (final raw in _content.get(ContentKeys.habitChecks) as List? ?? const [])
          if (raw is String) raw,
      };

  Future<void> _saveHabits(List<Habit> habits) =>
      _content.put(ContentKeys.habits, [for (final h in habits) h.toMap()]);

  Future<void> add(Habit habit) => _saveHabits([...all(), habit]);

  Future<void> archive(String id) => _saveHabits([
        for (final h in all()) h.id == id ? h.copyWith(archived: true) : h,
      ]);

  Future<void> delete(String id) async {
    await _saveHabits(all().where((h) => h.id != id).toList());
    await _content.put(ContentKeys.habitChecks,
        _checks().where((c) => !c.startsWith('$id|')).toList());
  }

  bool isDone(String id, DateTime day) => _checks().contains('$id|${dayKey(day)}');

  Future<void> toggle(String id, DateTime day) async {
    final checks = _checks();
    final key = '$id|${dayKey(day)}';
    if (!checks.remove(key)) checks.add(key);
    await _content.put(ContentKeys.habitChecks, checks.toList());
  }

  Set<String> doneDays(String id) => {
        for (final check in _checks())
          if (check.startsWith('$id|')) check.substring(id.length + 1),
      };

  /// Consecutive days done, counting back from today, or from yesterday when
  /// today is not done yet (the day is not over).
  static int streak(Set<String> doneDays, DateTime today) {
    var day = DateTime(today.year, today.month, today.day);
    if (!doneDays.contains(dayKey(day))) {
      day = DateTime(day.year, day.month, day.day - 1);
    }
    var count = 0;
    while (doneDays.contains(dayKey(day))) {
      count++;
      day = DateTime(day.year, day.month, day.day - 1);
    }
    return count;
  }

  /// Compares the journal mood on days with and without the habit, only on
  /// days that have a mood. Null until both sides have enough days.
  static HabitMoodLink? moodLink(
    Set<String> doneDays,
    Iterable<JournalEntry> entries,
  ) {
    final byDay = <String, List<int>>{};
    for (final e in entries) {
      final mood = Mood.getById(e.mood);
      if (mood == null || e.isDream) continue;
      byDay.putIfAbsent(dayKey(e.createdAt), () => []).add(mood.value);
    }
    final withHabit = <double>[];
    final without = <double>[];
    byDay.forEach((day, values) {
      final average = values.reduce((a, b) => a + b) / values.length;
      (doneDays.contains(day) ? withHabit : without).add(average);
    });
    if (withHabit.length < HabitMoodLink.minimumDays ||
        without.length < HabitMoodLink.minimumDays) {
      return null;
    }
    double mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;
    return HabitMoodLink(mean(withHabit), mean(without));
  }
}
