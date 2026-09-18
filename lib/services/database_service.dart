import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import '../models/journal_entry.dart';
import '../models/tag.dart';

class DatabaseService {
  Box get entriesBox => Hive.box('journal_entries');
  Box get tagsBox => Hive.box('tags');
  Future<void> addEntry(JournalEntry entry, {bool isPro = false}) async {
    if (!isPro && !canCreateFreeEntry()) {
      throw const EntryLimitExceededException();
    }
    await entriesBox.put(entry.id, entry.toMap());
  }

  Future<void> updateEntry(JournalEntry entry) async {
    final raw = entriesBox.get(entry.id);
    await entriesBox.put(entry.id, entry.toMap());
    if (raw is! Map) return;
    final previous = JournalEntry.fromMap(Map<dynamic, dynamic>.from(raw));
    await _deleteUnreferencedMedia([
      ...previous.imagePaths.where((path) => !entry.imagePaths.contains(path)),
      if (previous.audioPath != null && previous.audioPath != entry.audioPath)
        previous.audioPath!,
    ]);
  }

  Future<void> deleteEntry(String id) async {
    final raw = entriesBox.get(id);
    await entriesBox.delete(id);
    if (raw is! Map) return;
    final removed = JournalEntry.fromMap(Map<dynamic, dynamic>.from(raw));
    await _deleteUnreferencedMedia([
      ...removed.imagePaths,
      if (removed.audioPath != null) removed.audioPath!,
    ]);
  }

  Future<void> _deleteUnreferencedMedia(List<String> candidates) async {
    final remaining = getAllEntries();
    final referencedImages = remaining.expand((e) => e.imagePaths).toSet();
    final referencedAudio =
        remaining.map((e) => e.audioPath).whereType<String>().toSet();
    for (final filePath in candidates) {
      final normalized = p.normalize(filePath);
      final isReferenced = referencedImages.contains(filePath) ||
          referencedAudio.contains(filePath);
      if (!isReferenced) {
        final file = File(normalized);
        if (await file.exists()) await file.delete();
      }
    }
  }

  List<JournalEntry> getAllEntries() => entriesBox.values
      .map((e) => JournalEntry.fromMap(Map<dynamic, dynamic>.from(e as Map)))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  List<JournalEntry> getEntriesForDate(DateTime date) => getAllEntries()
      .where((e) =>
          e.createdAt.year == date.year &&
          e.createdAt.month == date.month &&
          e.createdAt.day == date.day)
      .toList();
  List<JournalEntry> searchEntries(String query) {
    final q = query.toLowerCase();
    return getAllEntries()
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.content.toLowerCase().contains(q) ||
            e.tags.any((t) => t.toLowerCase().contains(q)))
        .toList();
  }

  List<JournalEntry> getFavoriteEntries() =>
      getAllEntries().where((e) => e.isFavorite).toList();
  int getEntryCount() => entriesBox.length;

  int getCurrentMonthEntryCount([DateTime? now]) {
    final date = now ?? DateTime.now();
    return getAllEntries()
        .where((entry) =>
            entry.createdAt.year == date.year &&
            entry.createdAt.month == date.month)
        .length;
  }

  bool canCreateFreeEntry({DateTime? now, int limit = 7}) =>
      getCurrentMonthEntryCount(now) < limit;
  int getWordCount() => getAllEntries().fold(
      0,
      (sum, e) =>
          sum +
          (e.content.trim().isEmpty
              ? 0
              : e.content.trim().split(RegExp(r'\s+')).length));
  Future<void> saveTag(Tag tag) => tagsBox.put(tag.id, {
        'id': tag.id,
        'name': tag.name,
        'color': tag.color,
        'usageCount': tag.usageCount
      });

  Future<void> deleteTag(String tagName, String tagId) async {
    await tagsBox.delete(tagId);
    for (final entry in getAllEntries()) {
      if (!entry.tags.contains(tagName)) continue;
      await updateEntry(entry.copyWith(
        tags: entry.tags.where((tag) => tag != tagName).toList(),
      ));
    }
  }

  List<Tag> getAllTags() => tagsBox.isEmpty
      ? Tag.defaultTags
      : tagsBox.values.map((e) {
          final m = Map<dynamic, dynamic>.from(e as Map);
          return Tag(
              id: m['id']?.toString() ?? '',
              name: m['name']?.toString() ?? '',
              color: (m['color'] as num?)?.toInt() ?? 0xFF6C5CE7,
              usageCount: (m['usageCount'] as num?)?.toInt() ?? 0);
        }).toList();
  Map<String, int> getMoodDistribution() {
    final out = <String, int>{};
    for (final e in getAllEntries()) {
      if (e.mood.isNotEmpty) out[e.mood] = (out[e.mood] ?? 0) + 1;
    }
    return out;
  }

  Map<DateTime, int> getStreakData() {
    final out = <DateTime, int>{};
    for (final e in getAllEntries()) {
      final d = DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day);
      out[d] = (out[d] ?? 0) + 1;
    }
    return out;
  }
}

class EntryLimitExceededException implements Exception {
  const EntryLimitExceededException();

  @override
  String toString() => 'Monthly free entry limit reached';
}
