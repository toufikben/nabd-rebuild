import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/services/encryption_service.dart';
import 'package:nabd/services/privacy_service.dart';

class _RotatingEncryption extends EncryptionService {
  _RotatingEncryption(this.key);

  List<int> key;

  @override
  Future<List<int>> currentKeyBytes() async => key;

  @override
  Future<void> rotateKey() async {
    key = List<int>.generate(32, (index) => index + 101);
  }

  @override
  Future<void> restoreKeyBytes(List<int> bytes) async {
    key = List<int>.from(bytes);
  }
}

void main() {
  test('Delete All rotates key and reopens empty encrypted boxes', () async {
    final directory = await Directory.systemTemp.createTemp('nabd_delete_all');
    addTearDown(() async {
      await Hive.close();
      await directory.delete(recursive: true);
    });
    Hive.init(directory.path);

    final oldKey = List<int>.generate(32, (index) => index + 1);
    final oldCipher = HiveAesCipher(oldKey);
    for (final name in [
      'journal_entries',
      'settings',
      'moods',
      'tags',
      'garden',
    ]) {
      await Hive.openBox<dynamic>(name, encryptionCipher: oldCipher);
    }
    await Hive.box('journal_entries').put('entry', 'private');
    final media = Directory('${directory.path}/images')..createSync();
    File('${media.path}/photo.jpg').writeAsBytesSync([1, 2, 3]);

    final encryption = _RotatingEncryption(oldKey);
    await PrivacyService(
      encryption: encryption,
      documentsDirectory: () async => directory,
    ).deleteEverything();

    expect(encryption.key, isNot(equals(oldKey)));
    final newCipher = HiveAesCipher(encryption.key);
    for (final name in [
      'journal_entries',
      'settings',
      'moods',
      'tags',
      'garden',
    ]) {
      final box = Hive.box(name);
      expect(box.isEmpty, isTrue);
      await box.close();
      final reopened = await Hive.openBox<dynamic>(
        name,
        encryptionCipher: newCipher,
      );
      expect(reopened.isEmpty, isTrue);
    }
    expect(await media.exists(), isFalse);
  });
}
