import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/services/encryption_service.dart';

const _masterAlias = 'nabd_master_key_v1';
const _pendingAlias = 'nabd_master_key_pending';

/// The real service with the keystore swapped for a map.
class _MemoryKeystore extends EncryptionService {
  final Map<String, String> secrets = {};
  bool failCommit = false;

  @override
  Future<String?> readSecret(String key) async => secrets[key];

  @override
  Future<void> writeSecret(String key, String value) async {
    if (failCommit && key == _masterAlias && value != secrets[key]) {
      throw StateError('keystore refused the write');
    }
    secrets[key] = value;
  }

  @override
  Future<void> deleteSecret(String key) async {
    secrets.remove(key);
  }
}

List<int> _key(int seed) => List<int>.generate(32, (i) => (i + seed) % 256);

final _journal = <String, dynamic>{
  'a': {
    'id': 'a',
    'title': 'private',
    'tags': ['one', 'two'],
  },
  'b': {'id': 'b', 'title': 'also private', 'tags': <String>[]},
};
final _settings = <String, dynamic>{
  'language': 'ar',
  'unsent_letters': [
    {'id': 'l1', 'body': 'dear me'},
  ],
};

void main() {
  late Directory directory;
  late _MemoryKeystore keystore;
  final oldKey = _key(1);

  Future<void> seed() async {
    final cipher = HiveAesCipher(oldKey);
    final journal = await Hive.openBox<dynamic>(
      'journal_entries',
      encryptionCipher: cipher,
    );
    await journal.putAll(_journal);
    final settings = await Hive.openBox<dynamic>(
      'settings',
      encryptionCipher: cipher,
    );
    await settings.putAll(_settings);
  }

  Future<Map<dynamic, dynamic>> readBack(String name, List<int> key) async {
    if (Hive.isBoxOpen(name)) await Hive.box(name).close();
    final box = await Hive.openBox<dynamic>(
      name,
      encryptionCipher: HiveAesCipher(key),
      crashRecovery: false,
    );
    return box.toMap();
  }

  List<String> leftovers() => directory
      .listSync()
      .map((entity) => entity.path)
      .where((path) => path.contains('.rotating'))
      .toList();

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nabd_rotation');
    await Hive.close();
    Hive.init(directory.path);
    EncryptionService.resetCachedKey();
    keystore = _MemoryKeystore()..secrets[_masterAlias] = base64Encode(oldKey);
  });

  tearDown(() async {
    await Hive.close();
    EncryptionService.resetCachedKey();
    await directory.delete(recursive: true);
  });

  test('a rotation re-encrypts every record under a new key', () async {
    await seed();

    await keystore.rotateKey();

    final newKey = base64Decode(keystore.secrets[_masterAlias]!);
    expect(newKey, isNot(equals(oldKey)));
    expect(keystore.secrets.containsKey(_pendingAlias), isFalse);
    expect(leftovers(), isEmpty);
    // The boxes stay open for the running app.
    expect(Hive.isBoxOpen('journal_entries'), isTrue);

    final journal = await readBack('journal_entries', newKey);
    expect(journal['a']['title'], 'private');
    expect(journal['a']['tags'], ['one', 'two']);
    expect(journal.length, 2);
    final settings = await readBack('settings', newKey);
    expect(settings['unsent_letters'][0]['body'], 'dear me');
  });

  test('a failed commit rolls back to the old key with data intact', () async {
    await seed();
    keystore.failCommit = true;

    await expectLater(keystore.rotateKey(), throwsStateError);

    expect(base64Decode(keystore.secrets[_masterAlias]!), oldKey);
    expect(keystore.secrets.containsKey(_pendingAlias), isFalse);
    expect(leftovers(), isEmpty);
    final journal = await readBack('journal_entries', oldKey);
    expect(journal['b']['title'], 'also private');
  });

  File journalFile() =>
      File('${directory.path}/${EncryptionService.rotationJournalName}');

  /// Runs a real rotation up to the point a kill would cut it at, by
  /// reproducing what is on disk at that moment from a finished rotation.
  Future<List<int>> rotateAndForgetKeystoreWrite() async {
    await seed();
    await keystore.rotateKey();
    final newKey = base64Decode(keystore.secrets[_masterAlias]!);
    // The keystore saves asynchronously: a kill right after the rotation
    // can lose the new key while the boxes are already rewritten.
    keystore.secrets[_masterAlias] = base64Encode(oldKey);
    await Hive.close();
    EncryptionService.resetCachedKey();
    return newKey;
  }

  test(
    'a rotation leaves its journal until a launch reads the key back',
    () async {
      await seed();
      await keystore.rotateKey();
      expect(journalFile().existsSync(), isTrue);
      await Hive.close();

      await keystore.recoverInterruptedRotation(directory);

      expect(journalFile().existsSync(), isFalse);
      expect(leftovers(), isEmpty);
    },
  );

  test(
    'a keystore write lost after the commit is put back from the journal',
    () async {
      final newKey = await rotateAndForgetKeystoreWrite();

      await keystore.recoverInterruptedRotation(directory);

      expect(base64Decode(keystore.secrets[_masterAlias]!), newKey);
      final journal = await readBack('journal_entries', newKey);
      expect(journal['a']['title'], 'private');
      expect(journal.length, 2);
      // Kept until a launch proves the keystore holds the key.
      expect(journalFile().existsSync(), isTrue);

      await Hive.close();
      await keystore.recoverInterruptedRotation(directory);
      expect(journalFile().existsSync(), isFalse);
    },
  );

  test('a crash before the commit is undone on the next launch', () async {
    await seed();
    await Hive.close();
    // What a rotation killed mid-rewrite leaves: the journal step still
    // staging, every box backed up, one box half rewritten under a new key.
    // Building it needs a real staging step, so record one by rotating and
    // turning its step back to staging.
    final boxFile = File('${directory.path}/journal_entries.hive');
    final backup = boxFile.readAsBytesSync();
    final settingsBackup = File(
      '${directory.path}/settings.hive',
    ).readAsBytesSync();
    final cipher = HiveAesCipher(oldKey);
    await Hive.openBox<dynamic>('journal_entries', encryptionCipher: cipher);
    await Hive.openBox<dynamic>('settings', encryptionCipher: cipher);
    await keystore.rotateKey();
    final newKey = base64Decode(keystore.secrets[_masterAlias]!);
    await Hive.close();
    keystore.secrets[_masterAlias] = base64Encode(oldKey);
    final raw = jsonDecode(journalFile().readAsStringSync());
    raw['steps'].last['state'] = 'staging';
    journalFile().writeAsStringSync(jsonEncode(raw));
    File('${boxFile.path}.rotating').writeAsBytesSync(backup);
    File(
      '${directory.path}/settings.hive.rotating',
    ).writeAsBytesSync(settingsBackup);
    await Hive.deleteBoxFromDisk('journal_entries');
    final half = await Hive.openBox<dynamic>(
      'journal_entries',
      encryptionCipher: HiveAesCipher(newKey),
    );
    await half.put('a', 'half written');
    await Hive.close();
    EncryptionService.resetCachedKey();

    await keystore.recoverInterruptedRotation(directory);

    expect(base64Decode(keystore.secrets[_masterAlias]!), oldKey);
    expect(leftovers(), isEmpty);
    expect(journalFile().existsSync(), isFalse);
    final journal = await readBack('journal_entries', oldKey);
    expect(journal['a']['title'], 'private');
    expect(journal.length, 2);
    final settings = await readBack('settings', oldKey);
    expect(settings['language'], 'ar');
  });

  test(
    'two rotations with both keystore writes lost end on the last key',
    () async {
      await seed();
      await keystore.rotateKey();
      await keystore.rotateKey();
      final lastKey = base64Decode(keystore.secrets[_masterAlias]!);
      await Hive.close();
      keystore.secrets[_masterAlias] = base64Encode(oldKey);
      EncryptionService.resetCachedKey();

      await keystore.recoverInterruptedRotation(directory);

      expect(base64Decode(keystore.secrets[_masterAlias]!), lastKey);
      final journal = await readBack('journal_entries', lastKey);
      expect(journal.length, 2);
    },
  );

  test(
    'a keystore holding a key the journal does not know is left alone',
    () async {
      await rotateAndForgetKeystoreWrite();
      final stranger = base64Encode(_key(200));
      keystore.secrets[_masterAlias] = stranger;

      await keystore.recoverInterruptedRotation(directory);

      expect(keystore.secrets[_masterAlias], stranger);
      expect(journalFile().existsSync(), isTrue);
    },
  );

  test('a leftover pending key from the old design is cleaned up', () async {
    await seed();
    await Hive.close();
    keystore.secrets[_pendingAlias] = base64Encode(_key(77));

    await keystore.recoverInterruptedRotation(directory);

    expect(keystore.secrets.containsKey(_pendingAlias), isFalse);
    final journal = await readBack('journal_entries', oldKey);
    expect(journal['a']['title'], 'private');
  });

  test('a half-written backup copy is discarded, not restored', () async {
    await seed();
    await Hive.close();
    final boxFile = File('${directory.path}/journal_entries.hive');
    File('${boxFile.path}.rotating.partial').writeAsBytesSync([1, 2, 3]);
    keystore.secrets[_pendingAlias] = base64Encode(_key(77));

    await keystore.recoverInterruptedRotation(directory);

    expect(leftovers(), isEmpty);
    final journal = await readBack('journal_entries', oldKey);
    expect(journal['a']['title'], 'private');
  });

  test('nothing happens when no rotation was interrupted', () async {
    await seed();
    await Hive.close();

    await keystore.recoverInterruptedRotation(directory);

    expect(base64Decode(keystore.secrets[_masterAlias]!), oldKey);
    final journal = await readBack('journal_entries', oldKey);
    expect(journal.length, 2);
  });
}
