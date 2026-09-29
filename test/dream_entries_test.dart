import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/models/journal_entry.dart';
import 'package:nabd/services/database_service.dart';

/// The dream journal writes into `journal_entries` with this shape, so the
/// tests store exactly this and nothing invented.
Map<String, dynamic> _dreamMap({
  String id = 'dream-1',
  String content = 'I flew over the old city',
  DateTime? createdAt,
}) =>
    {
      'id': id,
      'title': 'A flight',
      'content': content,
      'createdAt': (createdAt ?? DateTime(2026, 9, 1)).toIso8601String(),
      'isDream': true,
      'isLucid': false,
      'isNightmare': false,
      'clarity': 3,
    };

JournalEntry _entry({
  String? id,
  String content = 'an ordinary entry',
  DateTime? at,
}) =>
    JournalEntry(
      id: id,
      title: 't',
      content: content,
      createdAt: at ?? DateTime(2026, 9, 1),
      updatedAt: at ?? DateTime(2026, 9, 1),
    );

void main() {
  late Directory directory;
  late Box box;
  late DatabaseService db;

  setUp(() async {
    await Hive.close();
    directory = await Directory.systemTemp.createTemp('nabd_dreams');
    Hive.init(directory.path);
    box = await Hive.openBox<dynamic>('journal_entries');
    db = DatabaseService();
  });

  tearDown(() async {
    await Hive.close();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  group('the dream flag survives storage', () {
    test('a stored dream reads back as a dream', () {
      expect(JournalEntry.fromMap(_dreamMap()).isDream, isTrue);
    });

    test('an ordinary entry is not a dream', () {
      final map = _entry().toMap();
      expect(map['isDream'], isFalse);
      expect(JournalEntry.fromMap(map).isDream, isFalse);
    });

    test('editing an entry does not turn it into a dream', () async {
      final entry = _entry(id: 'keep');
      await db.addEntry(entry, isPro: true);
      await db.updateEntry(entry.copyWith(content: 'edited'));
      final stored =
          JournalEntry.fromMap(Map<dynamic, dynamic>.from(box.get('keep') as Map));
      expect(stored.isDream, isFalse);
      expect(stored.content, 'edited');
    });
  });

  group('dreams stay out of the journal', () {
    test('the journal lists only entries', () async {
      await box.put('dream-1', _dreamMap());
      await db.addEntry(_entry(), isPro: true);

      expect(db.getAllEntries().map((e) => e.content), ['an ordinary entry']);
    });

    test('the entry count excludes dreams', () async {
      await box.put('dream-1', _dreamMap());
      await db.addEntry(_entry(), isPro: true);

      expect(db.getEntryCount(), 1);
    });

    test('search never returns a dream', () async {
      await box.put('dream-1', _dreamMap());
      await db.addEntry(_entry(), isPro: true);

      expect(db.searchEntries('flew'), isEmpty);
      expect(db.searchEntries('ordinary'), hasLength(1));
    });

    test('word and monthly totals exclude dreams', () async {
      await box.put('dream-1', _dreamMap());
      await db.addEntry(_entry(content: 'one two three'), isPro: true);

      expect(db.getWordCount(), 3);
      expect(db.getCurrentMonthEntryCount(DateTime(2026, 9, 15)), 1);
    });

    test('a dream day does not build a streak', () async {
      await box.put('dream-1', _dreamMap(createdAt: DateTime(2026, 8, 3)));

      expect(db.getStreakData(), isEmpty);
      expect(db.getMoodDistribution(), isEmpty);
    });

    test('the free monthly limit is not filled by dreams', () async {
      for (var i = 0; i < 7; i++) {
        await box.put('dream-$i', _dreamMap(id: 'dream-$i'));
      }

      expect(db.canCreateFreeEntry(), isTrue);
      await db.addEntry(_entry());
      expect(db.canCreateFreeEntry(), isFalse);
    });
  });
}
