import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/core/storage.dart';
import 'package:nabd/models/journal_entry.dart';
import 'package:nabd/models/tag.dart';
import 'package:nabd/services/database_service.dart';

void main() {
  late Directory directory;
  late DatabaseService db;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nabd_tags');
    Hive.init(directory.path);
    for (final name in HiveBoxes.all) {
      await Hive.openBox<dynamic>(name);
    }
    DatabaseService.invalidate();
    db = DatabaseService();
  });

  tearDown(() async {
    await Hive.close();
    DatabaseService.invalidate();
    await directory.delete(recursive: true);
  });

  Future<void> write(String id, List<String> tags) =>
      Hive.box(HiveBoxes.journal).put(
          id,
          JournalEntry(
            id: id,
            title: '',
            content: 'words',
            tags: tags,
            createdAt: DateTime(2026, 10, 1),
            updatedAt: DateTime(2026, 10, 1),
          ).toMap());

  Tag named(String name) =>
      db.getAllTags().firstWhere((t) => Tag.keyOf(t.name) == Tag.keyOf(name));

  test('tags written on entries are listed and counted', () async {
    await write('a', ['audit1', 'Personal']);
    await write('b', ['#personal']);
    DatabaseService.invalidate();

    expect(named('audit1').usageCount, 1);
    expect(named('Personal').usageCount, 2);
    // Defaults stay on offer alongside them.
    expect(db.getAllTags().any((t) => t.id == 'work'), isTrue);
    expect(db.getAllTags().first.name, 'Personal');
  });

  test('creating a tag keeps the defaults', () async {
    await db.saveTag(const Tag(id: 'mine', name: 'Mine', color: 0));
    expect(db.getAllTags().any((t) => t.name == 'Mine'), isTrue);
    expect(db.getAllTags().any((t) => t.id == 'personal'), isTrue);
  });

  test('a deleted default stays gone and leaves the entries', () async {
    await write('a', ['Personal', 'other']);
    DatabaseService.invalidate();

    await db.deleteTag('Personal', 'personal');
    DatabaseService.invalidate();

    expect(db.getAllTags().any((t) => t.id == 'personal'), isFalse);
    expect(db.getAllEntries().single.tags, ['other']);
  });
}
