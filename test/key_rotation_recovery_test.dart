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
    final journal =
        await Hive.openBox<dynamic>('journal_entries', encryptionCipher: cipher);
    await journal.putAll(_journal);
    final settings =
        await Hive.openBox<dynamic>('settings', encryptionCipher: cipher);
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

  test('a crash before the commit is undone on the next launch', () async {
    await seed();
    await Hive.close();
    // State a killed rotation leaves behind: backups staged, the new key
    // pending, and the box half rewritten under the new key.
    final boxFile = File('${directory.path}/journal_entries.hive');
    boxFile.copySync('${boxFile.path}.rotating');
    final newKey = _key(77);
    keystore.secrets[_pendingAlias] = base64Encode(newKey);
    await Hive.deleteBoxFromDisk('journal_entries');
    final half = await Hive.openBox<dynamic>(
      'journal_entries',
      encryptionCipher: HiveAesCipher(newKey),
    );
    await half.put('a', 'half written');
    await Hive.close();

    await keystore.recoverInterruptedRotation(directory);

    expect(base64Decode(keystore.secrets[_masterAlias]!), oldKey);
    expect(keystore.secrets.containsKey(_pendingAlias), isFalse);
    expect(leftovers(), isEmpty);
    final journal = await readBack('journal_entries', oldKey);
    expect(journal['a']['title'], 'private');
    expect(journal.length, 2);
  });

  test('a crash after the commit only finishes the cleanup', () async {
    await seed();
    await Hive.close();
    final boxFile = File('${directory.path}/journal_entries.hive');
    boxFile.copySync('${boxFile.path}.rotating');
    keystore.secrets[_pendingAlias] = keystore.secrets[_masterAlias]!;

    await keystore.recoverInterruptedRotation(directory);

    expect(keystore.secrets.containsKey(_pendingAlias), isFalse);
    expect(leftovers(), isEmpty);
    final journal = await readBack('journal_entries', oldKey);
    expect(journal.length, 2);
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
