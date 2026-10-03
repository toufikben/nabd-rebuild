import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/storage.dart';
import '../models/journal_entry.dart';
import '../models/tag.dart';
import 'media_vault.dart';

class DatabaseService {
  DatabaseService({MediaVault? media}) : _media = media;

  final MediaVault? _media;
  MediaVault get media => _media ?? MediaVault();

  Box get entriesBox => Hive.box(HiveBoxes.journal);
  Box get tagsBox => Hive.box(HiveBoxes.tags);

  /// Decoded entries, shared by every instance. Decoding the whole box on
  /// every read made screens and the tag cleanup quadratic. Any change to the
  /// box, from here or from another writer, drops the cache.
  static List<JournalEntry>? _cache;
  static Box? _watched;
  static StreamSubscription<BoxEvent>? _watch;

  /// Forgets the decoded entries. Writers outside this service (a restore,
  /// the dream journal) call it so the next read is fresh immediately.
  static void invalidate() => _cache = null;

  List<JournalEntry> _allIncludingDreams() {
    final box = entriesBox;
    if (!identical(_watched, box)) {
      unawaited(_watch?.cancel());
      _watched = box;
      _cache = null;
      _watch = box.watch().listen((_) => _cache = null);
    }
    return _cache ??= List.unmodifiable(
      box.values
          .whereType<Map>()
          .map((e) => JournalEntry.fromMap(Map<dynamic, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }
  Future<void> addEntry(JournalEntry entry, {bool isPro = false}) async {
    if (!isPro && !canCreateFreeEntry()) {
      throw const EntryLimitExceededException();
    }
    invalidate();
    await entriesBox.put(entry.id, entry.toMap());
  }

  Future<void> updateEntry(JournalEntry entry) async {
    final raw = entriesBox.get(entry.id);
    invalidate();
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
    invalidate();
    await entriesBox.delete(id);
    if (raw is! Map) return;
    final removed = JournalEntry.fromMap(Map<dynamic, dynamic>.from(raw));
    await _deleteUnreferencedMedia([
      ...removed.imagePaths,
      if (removed.audioPath != null) removed.audioPath!,
    ]);
  }

  /// Deletes media no entry (journal or dream) still points at.
  Future<void> _deleteUnreferencedMedia(List<String> candidates) async {
    if (candidates.isEmpty) return;
    final remaining = _allIncludingDreams();
    final referenced = {
      ...remaining.expand((e) => e.imagePaths),
      ...remaining.map((e) => e.audioPath).whereType<String>(),
    };
    for (final path in candidates) {
      if (referenced.contains(path)) continue;
      try {
        await media.delete(path);
      } catch (error) {
        debugPrint('Media cleanup failed for $path: $error');
      }
    }
  }

  /// Deletes media files a discarded draft created and no entry kept.
  Future<void> discardDraftMedia(List<String> paths) =>
      _deleteUnreferencedMedia(paths);

  /// Moves media of older entries into the encrypted vault with relative
  /// paths. Safe to run on every launch: converted entries are skipped.
  Future<int> encryptLegacyMedia() async {
    var converted = 0;
    for (final entry in _allIncludingDreams()) {
      final needs = entry.imagePaths.any(_isLegacyMedia) ||
          (entry.audioPath != null && _isLegacyMedia(entry.audioPath!));
      if (!needs) continue;
      final images = <String>[];
      for (final path in entry.imagePaths) {
        final moved = await media.encryptLegacy(path, folder: MediaVault.imagesDir);
        if (moved != null) images.add(moved);
      }
      final audio = entry.audioPath == null
          ? null
          : await media.encryptLegacy(entry.audioPath!, folder: MediaVault.audioDir);
      invalidate();
      await entriesBox.put(
        entry.id,
        entry.copyWith(imagePaths: images, audioPath: audio).toMap(),
      );
      converted++;
    }
    return converted;
  }

  static bool _isLegacyMedia(String path) =>
      !MediaVault.isEncrypted(path) || path.startsWith('/');

  /// Dreams share this box with the journal, so every read here decides:
  /// analytics, search, counts and the free monthly limit see journal entries
  /// only. The dream screen reads the box itself.
  List<JournalEntry> getAllEntries() =>
      _allIncludingDreams().where((e) => !e.isDream).toList();

  /// One entry by id, dreams included, or null.
  JournalEntry? findEntry(String id) {
    for (final entry in _allIncludingDreams()) {
      if (entry.id == id) return entry;
    }
    return null;
  }
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
  int getEntryCount() => getAllEntries().length;

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
    final updated = <String, Map<String, dynamic>>{
      for (final entry in getAllEntries())
        if (entry.tags.contains(tagName))
          entry.id: entry
              .copyWith(
                tags: entry.tags.where((tag) => tag != tagName).toList(),
                updatedAt: entry.updatedAt,
              )
              .toMap(),
    };
    if (updated.isEmpty) return;
    invalidate();
    await entriesBox.putAll(updated);
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
