import 'package:hive_flutter/hive_flutter.dart';

import '../models/journal_entry.dart';
import '../models/mood.dart';
import 'database_service.dart';

class PersonalLetter {
  const PersonalLetter({
    required this.id,
    required this.kind,
    required this.address,
    required this.content,
    required this.createdAt,
    this.unlockDate,
  });

  final String id;
  final PersonalLetterKind kind;
  final String address;
  final String content;
  final DateTime createdAt;
  final DateTime? unlockDate;

  bool get isFuture => kind == PersonalLetterKind.future;

  Map<String, dynamic> toMap() => {
        'id': id,
        if (isFuture) 'text': content else 'content': content,
        if (isFuture) 'unlockDate': unlockDate?.toIso8601String(),
        if (!isFuture) 'to': address,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PersonalLetter.fromMap(
    Map<dynamic, dynamic> map, {
    required PersonalLetterKind kind,
  }) {
    return PersonalLetter(
      id: map['id']?.toString() ?? '',
      kind: kind,
      address: map['to']?.toString() ?? 'My future self',
      content: (map['content'] ?? map['text'])?.toString() ?? '',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      unlockDate: DateTime.tryParse(map['unlockDate']?.toString() ?? ''),
    );
  }
}

enum PersonalLetterKind { future, unsent }

class EchoRecord {
  const EchoRecord({required this.original, required this.resolution});

  final JournalEntry original;
  final JournalEntry? resolution;

  bool get isResolved => resolution != null;
}

class WeeklyPulse {
  const WeeklyPulse({
    required this.weekKey,
    required this.entryCount,
    required this.wordCount,
    required this.positiveCount,
    required this.negativeCount,
    required this.averageMood,
    required this.insufficientData,
  });

  final String weekKey;
  final int entryCount;
  final int wordCount;
  final int positiveCount;
  final int negativeCount;
  final double averageMood;
  final bool insufficientData;

  Map<String, dynamic> toMap() => {
        'weekKey': weekKey,
        'entryCount': entryCount,
        'wordCount': wordCount,
        'positiveCount': positiveCount,
        'negativeCount': negativeCount,
        'averageMood': averageMood,
        'insufficientData': insufficientData,
      };

  factory WeeklyPulse.fromMap(Map<dynamic, dynamic> map) => WeeklyPulse(
        weekKey: map['weekKey']?.toString() ?? '',
        entryCount: (map['entryCount'] as num?)?.toInt() ?? 0,
        wordCount: (map['wordCount'] as num?)?.toInt() ?? 0,
        positiveCount: (map['positiveCount'] as num?)?.toInt() ?? 0,
        negativeCount: (map['negativeCount'] as num?)?.toInt() ?? 0,
        averageMood: (map['averageMood'] as num?)?.toDouble() ?? 0,
        insufficientData: map['insufficientData'] == true,
      );
}

class RPersonalService {
  RPersonalService({DatabaseService? database})
      : _database = database ?? DatabaseService();

  static const futureLettersKey = 'future_letters';
  static const unsentLettersKey = 'unsent_letters';
  static const echoResolutionsKey = 'echo_resolutions';
  static const weeklyPulsePrefix = 'weekly_pulse_';

  final DatabaseService _database;
  Box get _settings => Hive.box('settings');

  List<PersonalLetter> getLetters() {
    final future = _readLetters(futureLettersKey, PersonalLetterKind.future);
    final unsent = _readLetters(unsentLettersKey, PersonalLetterKind.unsent);
    return [...future, ...unsent]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveLetter(PersonalLetter letter) async {
    final key = letter.isFuture ? futureLettersKey : unsentLettersKey;
    final existing = _readLetters(key, letter.kind);
    final values = [
      ...existing.where((item) => item.id != letter.id).map((e) => e.toMap()),
      letter.toMap(),
    ];
    await _settings.put(key, values);
  }

  Future<void> deleteLetter(PersonalLetter letter) async {
    final key = letter.isFuture ? futureLettersKey : unsentLettersKey;
    final values = _readLetters(
      key,
      letter.kind,
    ).where((item) => item.id != letter.id).map((e) => e.toMap()).toList();
    await _settings.put(key, values);
  }

  List<PersonalLetter> _readLetters(String key, PersonalLetterKind kind) {
    final raw = _settings.get(key, defaultValue: <dynamic>[]);
    if (raw is! Iterable) return const [];
    return raw
        .whereType<Map>()
        .map((item) => PersonalLetter.fromMap(item, kind: kind))
        .where((item) => item.id.isNotEmpty && item.content.trim().isNotEmpty)
        .toList();
  }

  Future<List<EchoRecord>> loadEchoes() async {
    final entries = _database.getAllEntries();
    final records = calculateEchoes(entries);
    final resolutions = <String, String>{
      for (final record in records)
        if (record.resolution != null)
          record.original.id: record.resolution!.id,
    };
    final old = _settings.get(echoResolutionsKey);
    if (old is! Map || !_mapsEqual(old, resolutions)) {
      await _settings.put(echoResolutionsKey, resolutions);
    }
    return records;
  }

  static List<EchoRecord> calculateEchoes(List<JournalEntry> entries) {
    final ordered = [...entries]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final echoes = <EchoRecord>[];
    for (final original in ordered) {
      final mood = Mood.getById(original.mood);
      if (mood == null || mood.category != 'negative') continue;
      JournalEntry? resolution;
      for (final candidate in ordered) {
        final difference = candidate.createdAt.difference(original.createdAt);
        final candidateMood = Mood.getById(candidate.mood);
        if (difference >= const Duration(days: 3) &&
            difference <= const Duration(days: 90) &&
            candidate.createdAt.isAfter(original.createdAt) &&
            candidateMood?.category == 'positive') {
          resolution = candidate;
          break;
        }
      }
      echoes.add(EchoRecord(original: original, resolution: resolution));
    }
    return echoes.reversed.toList();
  }

  Future<WeeklyPulse?> loadWeeklyPulse([DateTime? now]) async {
    final current = now ?? DateTime.now();
    if (current.weekday != DateTime.sunday) return null;
    final sunday = DateTime(current.year, current.month, current.day);
    final weekStart = sunday.subtract(const Duration(days: 6));
    final key = _dateKey(sunday);
    final stored = _settings.get('$weeklyPulsePrefix$key');
    if (stored is Map) return WeeklyPulse.fromMap(stored);

    final entries = _database.getAllEntries().where((entry) {
      final day = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      return !day.isBefore(weekStart) && !day.isAfter(sunday);
    }).toList();
    final moods = entries.map((e) => Mood.getById(e.mood)).whereType<Mood>();
    final pulse = WeeklyPulse(
      weekKey: key,
      entryCount: entries.length,
      wordCount: entries.fold(0, (sum, e) => sum + _words(e.content)),
      positiveCount: moods.where((m) => m.category == 'positive').length,
      negativeCount: moods.where((m) => m.category == 'negative').length,
      averageMood: moods.isEmpty
          ? 0
          : moods.fold<int>(0, (sum, mood) => sum + mood.value) / moods.length,
      insufficientData: entries.isEmpty,
    );
    await _settings.put('$weeklyPulsePrefix$key', pulse.toMap());
    return pulse;
  }

  static int _words(String value) =>
      value.trim().isEmpty ? 0 : value.trim().split(RegExp(r'\s+')).length;

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static bool _mapsEqual(Map<dynamic, dynamic> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in b.entries) {
      if (a[entry.key]?.toString() != entry.value) return false;
    }
    return true;
  }
}
