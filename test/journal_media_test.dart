import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/models/journal_entry.dart';
import 'package:nabd/services/database_service.dart';
import 'package:nabd/services/encryption_service.dart';
import 'package:nabd/services/media_vault.dart';

class _MemoryKeystore extends EncryptionService {
  final Map<String, String> secrets = {};

  @override
  Future<String?> readSecret(String key) async => secrets[key];

  @override
  Future<void> writeSecret(String key, String value) async =>
      secrets[key] = value;

  @override
  Future<void> deleteSecret(String key) async => secrets.remove(key);
}

void main() {
  late Directory docs;
  late MediaVault vault;
  late DatabaseService db;

  setUp(() async {
    EncryptionService.resetCachedKey();
    docs = await Directory.systemTemp.createTemp('nabd_journal_media');
    Hive.init(docs.path);
    await Hive.openBox<dynamic>('journal_entries');
    await Hive.openBox<dynamic>('tags');
    vault = MediaVault(
      encryption: _MemoryKeystore(),
      documentsDirectory: () async => docs,
      temporaryDirectory: () async => docs,
    );
    db = DatabaseService(media: vault);
  });

  tearDown(() async {
    await Hive.close();
    DatabaseService.invalidate();
    EncryptionService.resetCachedKey();
    await docs.delete(recursive: true);
  });

  JournalEntry entry({List<String> images = const [], String? audio}) =>
      JournalEntry(
        id: 'e1',
        title: 't',
        content: 'c',
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
        imagePaths: images,
        audioPath: audio,
      );

  test('legacy plain media moves into the vault with relative paths',
      () async {
    final plain = File('${docs.path}/images/old.jpg')
      ..createSync(recursive: true)
      ..writeAsBytesSync([1, 2, 3, 4]);
    await db.addEntry(entry(images: [plain.path]), isPro: true);

    expect(await db.encryptLegacyMedia(), 1);

    final saved = db.findEntry('e1')!;
    expect(saved.imagePaths.single, startsWith('images/'));
    expect(MediaVault.isEncrypted(saved.imagePaths.single), isTrue);
    expect(plain.existsSync(), isFalse);
    expect(await vault.read(saved.imagePaths.single), [1, 2, 3, 4]);
    expect(await db.encryptLegacyMedia(), 0);
  });

  test('deleting an entry deletes its encrypted media', () async {
    final stored = await vault.store(
      Uint8List.fromList([9, 9]),
      folder: 'images',
    );
    await db.addEntry(entry(images: [stored]), isPro: true);

    await db.deleteEntry('e1');

    expect(File('${docs.path}/$stored').existsSync(), isFalse);
  });

  test('the cache sees a write made straight to the box', () async {
    await db.addEntry(entry(), isPro: true);
    expect(db.getAllEntries(), hasLength(1));

    await Hive.box('journal_entries').delete('e1');
    DatabaseService.invalidate();

    expect(db.getAllEntries(), isEmpty);
  });
}
