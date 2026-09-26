import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// EncryptionService — تشفير AES-256-GCM حقيقي مع مصادقة.
///
/// الميزات:
///   • AES-256-GCM (Authenticated Encryption)
///   • Nonce عشوائي لكل عملية (12 bytes)
///   • MAC مدمج (16 bytes) لمنع التلاعب
///   • مفتاح محفوظ في Secure Storage (Keychain/Keystore)
///
/// Contract:
///   • encrypt() → base64(nonce + ciphertext + mac)
///   • decrypt() → plaintext (throws إذا فُشّل MAC)
class EncryptionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyAlias = 'nabd_master_key_v1';
  static const _iterations = 100000;

  static final _algorithm = AesGcm.with256bits();

  static EncryptionKeyAction keyAction({
    required String? storedValue,
    required bool hasExistingData,
  }) {
    if (storedValue == null) {
      return hasExistingData
          ? EncryptionKeyAction.failMissing
          : EncryptionKeyAction.create;
    }
    try {
      return base64Decode(storedValue).length == 32
          ? EncryptionKeyAction.useStored
          : EncryptionKeyAction.failInvalid;
    } catch (_) {
      return EncryptionKeyAction.failInvalid;
    }
  }

  SecretKey? _cachedKey;

  /// تهيئة المفتاح — يُستدعى مرة واحدة عند بدء التطبيق.
  ///
  /// لا يُنشأ مفتاح جديد إذا كانت بيانات Hive موجودة؛ في هذه الحالة يجب
  /// إظهار مسار استعادة آمن بدل الكتابة فوق البيانات القديمة.
  Future<void> initialize({bool hasExistingData = false}) async {
    final stored = await _storage.read(key: _keyAlias);
    switch (keyAction(
      storedValue: stored,
      hasExistingData: hasExistingData,
    )) {
      case EncryptionKeyAction.useStored:
        _cachedKey = SecretKey(base64Decode(stored!));
        return;
      case EncryptionKeyAction.failMissing:
        throw const MissingEncryptionKeyException();
      case EncryptionKeyAction.failInvalid:
        throw const InvalidEncryptionKeyException();
      case EncryptionKeyAction.create:
        break;
    }

    // إنشاء مفتاح جديد
    final newKey = await _algorithm.newSecretKey();
    final bytes = await newKey.extractBytes();
    await _storage.write(key: _keyAlias, value: base64Encode(bytes));
    _cachedKey = newKey;
  }

  Future<List<int>> hiveKeyBytes() async {
    final bytes = await (await _getKey()).extractBytes();
    if (bytes.length != 32) {
      throw const FormatException('Invalid Hive encryption key length');
    }
    return bytes;
  }

  Future<String?> readMetadata(String key) => _storage.read(key: 'meta_$key');

  Future<void> writeMetadata(String key, String value) =>
      _storage.write(key: 'meta_$key', value: value);

  Future<SecretKey> _getKey() async {
    if (_cachedKey != null) return _cachedKey!;
    final stored = await _storage.read(key: _keyAlias);
    if (stored == null) throw const MissingEncryptionKeyException();
    final bytes = base64Decode(stored);
    if (bytes.length != 32) throw const InvalidEncryptionKeyException();
    _cachedKey = SecretKey(bytes);
    return _cachedKey!;
  }

  /// تشفير نص بـ AES-256-GCM.
  ///
  /// التنسيق المُعاد:
  ///   base64( nonce[12] || ciphertext || mac[16] )
  Future<String> encrypt(String plaintext) async {
    if (plaintext.isEmpty) return '';

    final key = await _getKey();
    final nonce = _algorithm.newNonce();

    final secretBox = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );

    // Combine: nonce + ciphertext + mac
    final combined = Uint8List.fromList([
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return base64Encode(combined);
  }

  /// فك تشفير نص.
  ///
  /// يرمي `SecretBoxAuthenticationError` إذا تم التلاعب.
  Future<String> decrypt(String encoded) async {
    if (encoded.isEmpty) return '';

    final key = await _getKey();
    final combined = base64Decode(encoded);

    const nonceLength = 12; // AES-GCM standard
    const macLength = 16; // AES-GCM standard

    if (combined.length < nonceLength + macLength) {
      throw const FormatException('Ciphertext too short');
    }

    final nonce = combined.sublist(0, nonceLength);
    final cipherText =
        combined.sublist(nonceLength, combined.length - macLength);
    final macBytes = combined.sublist(combined.length - macLength);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final plaintext = await _algorithm.decrypt(
      secretBox,
      secretKey: key,
    );

    return utf8.decode(plaintext);
  }

  /// هل التشفير مُفعّل؟
  Future<bool> isEnabled() async {
    return await _storage.containsKey(key: _keyAlias);
  }

  /// Atomically rotates the master key and re-encrypts every open Hive box.
  ///
  /// Sequence:
  ///  1. Snapshot every open box after it is decrypted with the current key.
  ///  2. Copy the box files aside as `.rotating` backups.
  ///  3. Generate a fresh AES-256-GCM key.
  ///  4. Close Hive, reopen each box with the new cipher, write the snapshot back.
  ///  5. Verify every record reads back under the new key.
  ///  6. Only on success: persist the new key and drop the backups.
  ///  7. On any failure: delete the new files, restore the backups and the old key.
  Future<void> rotateKey() async {
    const boxNames = <String>[
      'journal_entries',
      'settings',
      'moods',
      'tags',
      'garden',
    ];

    // 1) Snapshot each open box and stage on-disk backups.
    final snapshot = <String, Map<dynamic, dynamic>>{};
    final stagedBackups = <File>[];

    for (final name in boxNames) {
      if (!Hive.isBoxOpen(name)) continue;
      final box = Hive.box<dynamic>(name);
      snapshot[name] = {for (final key in box.keys) key: box.get(key)};

      final boxPath = box.path;
      if (boxPath == null) continue;
      final boxFile = File(boxPath);
      if (!boxFile.existsSync()) continue;

      final backup = File('$boxPath.rotating');
      if (backup.existsSync()) backup.deleteSync();
      boxFile.copySync(backup.path);
      stagedBackups.add(backup);

      final lockFile = File('$boxPath.lock');
      if (lockFile.existsSync()) {
        final lockBackup = File('$boxPath.lock.rotating');
        if (lockBackup.existsSync()) lockBackup.deleteSync();
        lockFile.copySync(lockBackup.path);
        stagedBackups.add(lockBackup);
      }
    }

    if (snapshot.isEmpty) {
      throw const KeyRotationException(
        'No encrypted Hive box is open, so there is nothing to rotate.',
      );
    }

    final previousKey = await currentKeyBytes();
    await Hive.close();

    // 2) Re-encrypt under the new key.
    try {
      final newKey = await _algorithm.newSecretKey();
      final newKeyBytes = await newKey.extractBytes();
      if (newKeyBytes.length != 32) {
        throw const FormatException('Invalid Hive encryption key length');
      }
      final newCipher = HiveAesCipher(newKeyBytes);

      for (final name in boxNames) {
        final values = snapshot[name];
        if (values == null) continue;
        final box =
            await Hive.openBox<dynamic>(name, encryptionCipher: newCipher);
        await box.putAll(values);
        await box.flush();
      }

      // 3) Verify every record is readable under the new key.
      for (final name in boxNames) {
        final expected = snapshot[name];
        if (expected == null) continue;
        final box = Hive.box<dynamic>(name);
        if (box.length != expected.length) {
          throw KeyRotationException(
            'Box "$name" holds ${box.length} records after rotation, '
            'expected ${expected.length}.',
          );
        }
        for (final key in expected.keys) {
          if (!box.containsKey(key)) {
            throw KeyRotationException('Box "$name" lost the record "$key".');
          }
          box.get(key);
        }
      }

      // 4) Commit only after full verification.
      await _storage.write(key: _keyAlias, value: base64Encode(newKeyBytes));
      _cachedKey = newKey;
    } catch (_) {
      await _rollbackRotation(previousKey, boxNames, stagedBackups);
      rethrow;
    } finally {
      for (final backup in stagedBackups) {
        if (backup.existsSync()) {
          try {
            backup.deleteSync();
          } on FileSystemException {
            // A leftover backup is harmless; the next rotation replaces it.
          }
        }
      }
    }
  }

  /// Undoes a failed rotation: removes the new files, restores the staged
  /// backups together with the previous key, and reopens the boxes.
  Future<void> _rollbackRotation(
    List<int> previousKey,
    List<String> boxNames,
    List<File> stagedBackups,
  ) async {
    try {
      await Hive.close();
      for (final name in boxNames) {
        if (await Hive.boxExists(name)) {
          await Hive.deleteBoxFromDisk(name);
        }
      }
      for (final backup in stagedBackups) {
        if (!backup.existsSync()) continue;
        final original = backup.path.replaceFirst(RegExp(r'\.rotating$'), '');
        File(original).writeAsBytesSync(backup.readAsBytesSync(), flush: true);
      }
      await _storage.write(key: _keyAlias, value: base64Encode(previousKey));
      _cachedKey = SecretKey(previousKey);
      final restoredCipher = HiveAesCipher(previousKey);
      for (final name in boxNames) {
        if (await Hive.boxExists(name)) {
          await Hive.openBox<dynamic>(name, encryptionCipher: restoredCipher);
        }
      }
    } catch (_) {
      // Automatic recovery failed. The previous key stays in secure storage so
      // the store is never left encrypted under a key that is not on disk.
      _cachedKey = null;
      await Hive.close();
    }
  }

  /// إنشاء مفتاح جديد بعد اكتمال حذف جميع البيانات القديمة.
  /// لا يجوز استخدام هذا المسار مع صناديق Hive تحتوي على بيانات.
  Future<void> createFreshKeyAfterDataDeletion() async {
    final newKey = await _algorithm.newSecretKey();
    final bytes = await newKey.extractBytes();
    await _storage.write(key: _keyAlias, value: base64Encode(bytes));
    _cachedKey = newKey;
  }

  Future<List<int>> currentKeyBytes() async => hiveKeyBytes();

  Future<void> restoreKeyBytes(List<int> bytes) async {
    if (bytes.length != 32) {
      throw const FormatException('Invalid encryption key length');
    }
    await _storage.write(key: _keyAlias, value: base64Encode(bytes));
    _cachedKey = SecretKey(bytes);
  }

  /// حذف المفتاح (عند حذف كل البيانات).
  Future<void> deleteKey() async {
    await _storage.delete(key: _keyAlias);
    _cachedKey = null;
  }

  /// توليد مفتاح مشتق من كلمة مرور (PBKDF2).
  ///
  /// يُستخدم لتشفير النسخ الاحتياطي.
  Future<SecretKey> deriveKeyFromPassword({
    required String password,
    required Uint8List salt,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    );

    return await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  /// توليد salt عشوائي.
  Uint8List generateSalt([int length = 16]) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}

enum EncryptionKeyAction { useStored, create, failMissing, failInvalid }

class MissingEncryptionKeyException implements Exception {
  const MissingEncryptionKeyException();

  @override
  String toString() => 'Encryption key is unavailable';
}

class InvalidEncryptionKeyException implements Exception {
  const InvalidEncryptionKeyException();

  @override
  String toString() => 'Encryption key is invalid';
}

class KeyRotationException implements Exception {
  const KeyRotationException(this.message);

  final String message;

  @override
  String toString() => 'Key rotation failed: $message';
}
