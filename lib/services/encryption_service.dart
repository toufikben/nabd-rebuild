import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_value_equality.dart';
import '../core/storage.dart';

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

  /// Photos and voice notes have their own key, so rotating the journal key
  /// never has to rewrite every media file.
  static const _mediaKeyAlias = 'nabd_media_key_v1';
  static SecretKey? _cachedMediaKey;
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

  /// Shared by every instance: after a rotation or a fresh key, a service
  /// created earlier must not keep using the key it cached before.
  static SecretKey? _cachedKey;

  /// Forgets the cached keys so each test starts from what storage holds.
  @visibleForTesting
  static void resetCachedKey() {
    _cachedKey = null;
    _cachedMediaKey = null;
  }

  /// The media key, created on first use. Losing it only costs media that
  /// was encrypted with it, which is why Delete All removes both together.
  Future<SecretKey> mediaKey() async {
    final cached = _cachedMediaKey;
    if (cached != null) return cached;
    final stored = await readSecret(_mediaKeyAlias);
    if (stored != null) {
      final bytes = base64Decode(stored);
      if (bytes.length != 32) throw const InvalidEncryptionKeyException();
      return _cachedMediaKey = SecretKey(bytes);
    }
    final fresh = await _algorithm.newSecretKey();
    await writeSecret(_mediaKeyAlias, base64Encode(await fresh.extractBytes()));
    return _cachedMediaKey = fresh;
  }

  /// Forgets the media key after every media file was deleted.
  Future<void> deleteMediaKey() async {
    await deleteSecret(_mediaKeyAlias);
    _cachedMediaKey = null;
  }

  /// تهيئة المفتاح — يُستدعى مرة واحدة عند بدء التطبيق.
  ///
  /// لا يُنشأ مفتاح جديد إذا كانت بيانات Hive موجودة؛ في هذه الحالة يجب
  /// إظهار مسار استعادة آمن بدل الكتابة فوق البيانات القديمة.
  Future<void> initialize({bool hasExistingData = false}) async {
    final stored = await readSecret(_keyAlias);
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
    await writeSecret(_keyAlias, base64Encode(bytes));
    _cachedKey = newKey;
  }

  Future<List<int>> hiveKeyBytes() async {
    final bytes = await (await _getKey()).extractBytes();
    if (bytes.length != 32) {
      throw const FormatException('Invalid Hive encryption key length');
    }
    return bytes;
  }

  Future<String?> readMetadata(String key) => readSecret('meta_$key');

  Future<void> writeMetadata(String key, String value) =>
      writeSecret('meta_$key', value);

  /// The OS keystore. Overridable so key handling can be tested without a
  /// platform channel.
  Future<String?> readSecret(String key) => _storage.read(key: key);

  Future<void> writeSecret(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> deleteSecret(String key) => _storage.delete(key: key);

  Future<SecretKey> _getKey() async {
    if (_cachedKey != null) return _cachedKey!;
    final stored = await readSecret(_keyAlias);
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
    return await readSecret(_keyAlias) != null;
  }

  static const _boxNames = HiveBoxes.all;

  /// The key a rotation is moving to. It is stored before any box is
  /// rewritten, so a crash at any point leaves enough on disk to finish or to
  /// undo the rotation on the next launch.
  static const _pendingKeyAlias = 'nabd_master_key_pending';
  static const _backupSuffix = '.rotating';
  static const _partialSuffix = '.rotating.partial';

  /// Rotates the master key and re-encrypts every open Hive box, so that it
  /// survives being interrupted at any step.
  ///
  /// Sequence:
  ///  1. Snapshot every open box, then close Hive.
  ///  2. Store the new key under a pending alias (the old key stays current).
  ///  3. Copy every box file aside as `.rotating` (written as `.partial` and
  ///     renamed, so a half-written copy is never mistaken for a backup).
  ///  4. Rewrite each box from the snapshot under the new key.
  ///  5. Close and reopen every box from disk and compare it with the snapshot.
  ///  6. Commit: make the new key current, delete the backups, then the
  ///     pending key.
  /// Any failure restores the backups and the old key. Backups are only ever
  /// deleted once the data they protect is known to be readable.
  /// [recoverInterruptedRotation] finishes or undoes a rotation the process
  /// did not survive.
  Future<void> rotateKey() async {
    final snapshot = <String, Map<dynamic, dynamic>>{};
    final boxFiles = <String, File>{};
    for (final name in _boxNames) {
      if (!Hive.isBoxOpen(name)) continue;
      final box = Hive.box<dynamic>(name);
      snapshot[name] = {for (final key in box.keys) key: box.get(key)};
      await box.flush();
      final boxPath = box.path;
      if (boxPath != null) boxFiles[name] = File(boxPath);
    }

    if (snapshot.isEmpty) {
      throw const KeyRotationException(
        'No encrypted Hive box is open, so there is nothing to rotate.',
      );
    }

    final previousKey = await currentKeyBytes();
    final newKey = await _algorithm.newSecretKey();
    final newKeyBytes = await newKey.extractBytes();
    if (newKeyBytes.length != 32) {
      throw const FormatException('Invalid Hive encryption key length');
    }

    await Hive.close();
    await writeSecret(_pendingKeyAlias, base64Encode(newKeyBytes));

    final backups = <File>[];
    try {
      for (final file in boxFiles.values) {
        if (!file.existsSync()) continue;
        backups.add(await _stageBackup(file));
      }

      final newCipher = HiveAesCipher(newKeyBytes);
      for (final entry in snapshot.entries) {
        await Hive.deleteBoxFromDisk(entry.key);
        final box = await Hive.openBox<dynamic>(
          entry.key,
          encryptionCipher: newCipher,
        );
        await box.putAll(entry.value);
        await box.flush();
        await box.close();
      }

      // Read every box back from disk, not from Hive's memory cache.
      for (final entry in snapshot.entries) {
        final box = await Hive.openBox<dynamic>(
          entry.key,
          encryptionCipher: newCipher,
          crashRecovery: false,
        );
        _verifySnapshot(entry.key, box, entry.value);
      }
    } catch (_) {
      await _rollbackRotation(previousKey, snapshot.keys, backups);
      rethrow;
    }

    try {
      await writeSecret(_keyAlias, base64Encode(newKeyBytes));
    } catch (_) {
      await _rollbackRotation(previousKey, snapshot.keys, backups);
      rethrow;
    }
    _cachedKey = newKey;
    // Backups first, pending key last: recovery relies on that order.
    await _deleteFiles(backups);
    await deleteSecret(_pendingKeyAlias);
  }

  void _verifySnapshot(
    String name,
    Box<dynamic> box,
    Map<dynamic, dynamic> expected,
  ) {
    if (box.length != expected.length) {
      throw KeyRotationException(
        'Box "$name" holds ${box.length} records after rotation, '
        'expected ${expected.length}.',
      );
    }
    for (final entry in expected.entries) {
      if (!box.containsKey(entry.key) ||
          !hiveValuesEqual(box.get(entry.key), entry.value)) {
        throw KeyRotationException('Box "$name" changed the record '
            '"${entry.key}" during rotation.');
      }
    }
  }

  Future<File> _stageBackup(File boxFile) async {
    final partial = File('${boxFile.path}$_partialSuffix');
    await boxFile.copy(partial.path);
    return partial.rename('${boxFile.path}$_backupSuffix');
  }

  /// Undoes a failed rotation: puts the staged files back under the previous
  /// key and reopens the boxes. If that fails as well, the backups and the
  /// pending key stay where they are for [recoverInterruptedRotation].
  Future<void> _rollbackRotation(
    List<int> previousKey,
    Iterable<String> boxNames,
    List<File> backups,
  ) async {
    try {
      await Hive.close();
      for (final backup in backups) {
        await _restoreBackup(backup);
      }
      await writeSecret(_keyAlias, base64Encode(previousKey));
      _cachedKey = SecretKey(previousKey);
      final restoredCipher = HiveAesCipher(previousKey);
      for (final name in boxNames) {
        await Hive.openBox<dynamic>(name, encryptionCipher: restoredCipher);
      }
      await _deleteFiles(backups);
      await deleteSecret(_pendingKeyAlias);
    } catch (_) {
      // The original failure is the one reported. Next launch recovers from
      // the backups, which are deliberately left on disk.
      _cachedKey = null;
      await Hive.close();
    }
  }

  /// Run at startup before any box is opened. Finishes a rotation whose new
  /// key was already committed, or undoes one that was not, using the files
  /// in [hiveDirectory]. Does nothing when no rotation was interrupted.
  Future<void> recoverInterruptedRotation(Directory hiveDirectory) async {
    if (!hiveDirectory.existsSync()) return;
    final entries = hiveDirectory.listSync().whereType<File>().toList();
    // A partial copy was never a complete backup: the box it was copied from
    // had not been touched yet, so the copy is simply discarded.
    for (final file in entries.where((f) => f.path.endsWith(_partialSuffix))) {
      await file.delete();
    }
    final backups =
        entries.where((f) => f.path.endsWith(_backupSuffix)).toList();
    final pending = await readSecret(_pendingKeyAlias);

    if (pending == null) {
      // Backups are deleted before the pending key, so without it any backup
      // left over belongs to a rotation that already finished.
      await _deleteFiles(backups);
      return;
    }

    final current = await readSecret(_keyAlias);
    if (current == pending) {
      // The new key was committed; only the cleanup was cut short.
      await _deleteFiles(backups);
      await deleteSecret(_pendingKeyAlias);
      return;
    }

    // The new key never became current, so the boxes on disk may be half
    // rewritten. The backups hold them as they were under the current key.
    for (final backup in backups) {
      await _restoreBackup(backup);
    }
    _cachedKey = null;
    await _deleteFiles(backups);
    await deleteSecret(_pendingKeyAlias);
  }

  /// Puts a `.rotating` copy back in place of its box file. Written to a
  /// sibling and renamed, so the box file is never half restored.
  Future<void> _restoreBackup(File backup) async {
    final original =
        backup.path.substring(0, backup.path.length - _backupSuffix.length);
    final restoring = File('$original.restoring');
    await backup.copy(restoring.path);
    await restoring.rename(original);
  }

  Future<void> _deleteFiles(Iterable<File> files) async {
    for (final file in files) {
      try {
        if (file.existsSync()) await file.delete();
      } on FileSystemException {
        // A leftover file is harmless; recovery or the next rotation removes it.
      }
    }
  }

  /// إنشاء مفتاح جديد بعد اكتمال حذف جميع البيانات القديمة.
  /// لا يجوز استخدام هذا المسار مع صناديق Hive تحتوي على بيانات.
  Future<void> createFreshKeyAfterDataDeletion() async {
    final newKey = await _algorithm.newSecretKey();
    final bytes = await newKey.extractBytes();
    await writeSecret(_keyAlias, base64Encode(bytes));
    _cachedKey = newKey;
  }

  Future<List<int>> currentKeyBytes() async => hiveKeyBytes();

  Future<void> restoreKeyBytes(List<int> bytes) async {
    if (bytes.length != 32) {
      throw const FormatException('Invalid encryption key length');
    }
    await writeSecret(_keyAlias, base64Encode(bytes));
    _cachedKey = SecretKey(bytes);
  }

  /// حذف المفتاح (عند حذف كل البيانات).
  Future<void> deleteKey() async {
    await deleteSecret(_keyAlias);
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
