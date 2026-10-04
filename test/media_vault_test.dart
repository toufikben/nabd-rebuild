import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
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
  late Directory temp;
  late MediaVault vault;

  setUp(() async {
    EncryptionService.resetCachedKey();
    docs = await Directory.systemTemp.createTemp('nabd_docs');
    temp = await Directory.systemTemp.createTemp('nabd_tmp');
    vault = MediaVault(
      encryption: _MemoryKeystore(),
      documentsDirectory: () async => docs,
      temporaryDirectory: () async => temp,
    );
  });

  tearDown(() async {
    EncryptionService.resetCachedKey();
    await docs.delete(recursive: true);
    await temp.delete(recursive: true);
  });

  final photo = Uint8List.fromList(List<int>.generate(4096, (i) => i % 251));

  test('stored media is relative, encrypted and reads back', () async {
    final stored = await vault.store(photo, folder: 'images', extension: '.jpg');

    expect(stored, startsWith('images/'));
    expect(stored, endsWith('.jpg.nenc'));
    final onDisk = await File('${docs.path}/$stored').readAsBytes();
    expect(onDisk, isNot(contains(photo.sublist(0, 64))));
    expect(await vault.read(stored), photo);
  });

  test('a tampered file is refused', () async {
    final stored = await vault.store(photo, folder: 'images');
    final file = File('${docs.path}/$stored');
    final bytes = await file.readAsBytes();
    bytes[bytes.length - 20] ^= 0xFF;
    await file.writeAsBytes(bytes);

    await expectLater(vault.read(stored), throwsA(anything));
  });

  test('a legacy absolute plain file is served and then converted', () async {
    final legacy = File('${docs.path}/images/old.jpg')
      ..createSync(recursive: true)
      ..writeAsBytesSync(photo);

    expect(await vault.read(legacy.path), photo);
    final converted = await vault.encryptLegacy(legacy.path, folder: 'images');

    expect(converted, isNotNull);
    expect(MediaVault.isEncrypted(converted!), isTrue);
    expect(legacy.existsSync(), isFalse);
    expect(await vault.read(converted), photo);
  });

  test('audio is decrypted to a temporary file for the player', () async {
    final stored = await vault.store(photo, folder: 'audio', extension: '.m4a');
    final playable = await vault.decryptToTemp(stored);

    expect(playable.path, startsWith(temp.path));
    expect(await playable.readAsBytes(), photo);
  });
}
