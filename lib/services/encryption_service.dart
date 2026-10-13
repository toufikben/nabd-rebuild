import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'hive_strict_open.dart';
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
    switch (keyAction(storedValue: stored, hasExistingData: hasExistingData)) {
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
    final cipherText = combined.sublist(
      nonceLength,
      combined.length - macLength,
    );
    final macBytes = combined.sublist(combined.length - macLength);

    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes));

    final plaintext = await _algorithm.decrypt(secretBox, secretKey: key);

    return utf8.decode(plaintext);
  }

  /// هل التشفير مُفعّل؟
  Future<bool> isEnabled() async {
    return await readSecret(_keyAlias) != null;
  }

  static const _boxNames = HiveBoxes.all;

  /// Left by the rotation design before the journal. Only ever cleaned up.
  static const _legacyPendingKeyAlias = 'nabd_master_key_pending';
  static const _backupSuffix = '.rotating';
  static const _partialSuffix = '.rotating.partial';

  /// The rotation journal, next to the box files. The keystore cannot be
  /// trusted to order writes: on Android it saves with `apply()`, which
  /// returns before the value reaches the disk, so a process killed a moment
  /// later can lose it while the box files it describes were already
  /// rewritten. The journal is written and flushed by the app itself, before
  /// the step it describes, and the keystore is only ever brought in line
  /// with it.
  static const rotationJournalName = 'nabd_key_rotation.json';

  /// Rotates the master key and re-encrypts every open Hive box, so that it
  /// survives being interrupted at any step.
  ///
  /// Sequence:
  ///  1. Snapshot every open box, then close Hive.
  ///  2. Add a `staging` step to the journal: the new key sealed with the
  ///     current one, and the fingerprints of both.
  ///  3. Copy every box file aside as `.rotating` (written as `.partial` and
  ///     renamed, so a half-written copy is never mistaken for a backup).
  ///  4. Rewrite each box from the snapshot under the new key.
  ///  5. Close and reopen every box from disk and compare it with the snapshot.
  ///  6. Commit: mark the step `committed` in the journal, store the new key
  ///     in the keystore, delete the backups.
  /// Any failure before the keystore holds the new key restores the backups.
  /// The journal stays until a later launch reads the new key back from the
  /// keystore, which proves the keystore write reached the disk.
  /// [recoverInterruptedRotation] finishes or undoes whatever was cut short.
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

    if (snapshot.isEmpty || boxFiles.isEmpty) {
      throw const KeyRotationException(
        'No encrypted Hive box is open, so there is nothing to rotate.',
      );
    }

    final journal = _RotationJournal(
      File('${boxFiles.values.first.parent.path}/$rotationJournalName'),
    );
    final previousKey = await currentKeyBytes();
    final newKey = await _algorithm.newSecretKey();
    final newKeyBytes = await newKey.extractBytes();
    if (newKeyBytes.length != 32) {
      throw const FormatException('Invalid Hive encryption key length');
    }

    await Hive.close();
    final steps = journal.read();
    steps.add({
      'from': await _fingerprint(previousKey),
      'to': await _fingerprint(newKeyBytes),
      'sealed': await _seal(previousKey, newKeyBytes),
      'state': _staging,
    });
    await journal.write(steps);

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
        final box = await openBoxStrict(entry.key, cipher: newCipher);
        _verifySnapshot(entry.key, box, entry.value);
      }

      steps.last['state'] = _committed;
      await journal.write(steps);
    } catch (_) {
      await _rollbackRotation(previousKey, snapshot.keys, backups, journal);
      rethrow;
    }

    try {
      await writeSecret(_keyAlias, base64Encode(newKeyBytes));
    } catch (_) {
      // Back to staging first, so a crash during the rollback is undone by
      // recovery instead of being finished half way.
      steps.last['state'] = _staging;
      await journal.write(steps);
      await _rollbackRotation(previousKey, snapshot.keys, backups, journal);
      rethrow;
    }
    _cachedKey = newKey;
    await _deleteFiles(backups);
  }

  static const _staging = 'staging';
  static const _committed = 'committed';

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
        throw KeyRotationException(
          'Box "$name" changed the record '
          '"${entry.key}" during rotation.',
        );
      }
    }
  }

  Future<File> _stageBackup(File boxFile) async {
    final partial = File('${boxFile.path}$_partialSuffix');
    await partial.writeAsBytes(await boxFile.readAsBytes(), flush: true);
    return partial.rename('${boxFile.path}$_backupSuffix');
  }

  /// Undoes a rotation that never reached the keystore: puts the staged
  /// files back, drops the step from the journal and reopens the boxes under
  /// the previous key. If that fails as well, the backups and the journal
  /// stay where they are for [recoverInterruptedRotation].
  Future<void> _rollbackRotation(
    List<int> previousKey,
    Iterable<String> boxNames,
    List<File> backups,
    _RotationJournal journal,
  ) async {
    try {
      await Hive.close();
      for (final backup in backups) {
        await _restoreBackup(backup);
      }
      final steps = journal.read()..removeLast();
      await journal.write(steps);
      _cachedKey = SecretKey(previousKey);
      final restoredCipher = HiveAesCipher(previousKey);
      for (final name in boxNames) {
        await Hive.openBox<dynamic>(name, encryptionCipher: restoredCipher);
      }
      await _deleteFiles(backups);
    } catch (_) {
      // The original failure is the one reported. Next launch recovers from
      // the backups, which are deliberately left on disk.
      _cachedKey = null;
      await Hive.close();
    }
  }

  /// Run at startup before any box is opened. Follows the journal from the
  /// key the keystore holds: committed steps lead to the key the boxes are
  /// encrypted with, and a step still staging is undone from its backups.
  /// Does nothing when no rotation is on record.
  Future<void> recoverInterruptedRotation(Directory hiveDirectory) async {
    if (!hiveDirectory.existsSync()) return;
    final files = hiveDirectory.listSync().whereType<File>().toList();
    // A partial copy was never a complete backup: the box it was copied from
    // had not been touched yet, so the copy is simply discarded.
    await _deleteFiles(files.where((f) => f.path.endsWith(_partialSuffix)));
    final backups = files.where((f) => f.path.endsWith(_backupSuffix)).toList();
    if (await readSecret(_legacyPendingKeyAlias) != null) {
      await deleteSecret(_legacyPendingKeyAlias);
    }

    final journal = _RotationJournal(
      File('${hiveDirectory.path}/$rotationJournalName'),
    );
    final steps = journal.read();
    if (steps.isEmpty) {
      // Backups are deleted before a journal is, so a backup without one
      // belongs to a rotation that already finished.
      await _deleteFiles(backups);
      journal.delete();
      return;
    }

    final stored = await readSecret(_keyAlias);
    if (stored == null) return; // Nothing to follow; startup reports it.
    List<int> key = base64Decode(stored);
    var fingerprint = await _fingerprint(key);
    // Steps before the keystore's key are history from rotations whose key
    // write did reach the disk.
    var position = steps.indexWhere((step) => step['from'] == fingerprint);
    if (position < 0) position = steps.length;
    while (position < steps.length && steps[position]['from'] == fingerprint) {
      final step = steps[position];
      if (step['state'] != _committed) {
        // Cut short before the commit: every box was staged before any was
        // rewritten, so the backups hold the data under [key].
        for (final backup in backups) {
          await _restoreBackup(backup);
        }
        steps.removeRange(position, steps.length);
        break;
      }
      key = await _unseal(key, step['sealed'] as String);
      fingerprint = await _fingerprint(key);
      position++;
    }

    final lastKnown = steps.isEmpty ? null : steps.last['to'];
    if (base64Encode(key) == stored) {
      // The keystore already holds the key the boxes use. If that is where
      // the journal ends, the rotation is settled and its record can go.
      if (steps.isEmpty || lastKnown == fingerprint) {
        await _deleteFiles(backups);
        journal.delete();
        _cachedKey = null;
      }
      // Otherwise the keystore holds a key the journal does not lead from;
      // leave everything for the storage failure screen.
      return;
    }

    // The keystore lost the write of a committed key. Put it back; the
    // journal stays until a launch reads it back from the keystore.
    await _deleteFiles(backups);
    await journal.write(steps);
    await writeSecret(_keyAlias, base64Encode(key));
    _cachedKey = SecretKey(key);
  }

  /// Forgets every rotation on record, once the boxes it describes were
  /// deleted with all the data.
  static void forgetRotations(Directory hiveDirectory) => _RotationJournal(
    File('${hiveDirectory.path}/$rotationJournalName'),
  ).delete();

  /// Puts a `.rotating` copy back in place of its box file. Written to a
  /// sibling and renamed, so the box file is never half restored.
  Future<void> _restoreBackup(File backup) async {
    final original = backup.path.substring(
      0,
      backup.path.length - _backupSuffix.length,
    );
    final restoring = File('$original.restoring');
    await restoring.writeAsBytes(await backup.readAsBytes(), flush: true);
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

  static Future<String> _fingerprint(List<int> key) async =>
      base64Encode((await Sha256().hash(key)).bytes);

  /// The next key, sealed with the one before it, so the journal never holds
  /// a key in the clear.
  static Future<String> _seal(List<int> key, List<int> secret) async {
    final box = await _algorithm.encrypt(secret, secretKey: SecretKey(key));
    return base64Encode(box.concatenation());
  }

  static Future<List<int>> _unseal(List<int> key, String sealed) async {
    final box = SecretBox.fromConcatenation(
      base64Decode(sealed),
      nonceLength: _algorithm.nonceLength,
      macLength: _algorithm.macAlgorithm.macLength,
    );
    return _algorithm.decrypt(box, secretKey: SecretKey(key));
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
    // 100k rounds of pure-Dart PBKDF2 take a second or more on a modest
    // phone; run them on a worker isolate so the UI keeps animating.
    final bytes = await Isolate.run(() => _pbkdf2(password, salt));
    return SecretKey(bytes);
  }

  static Future<List<int>> _pbkdf2(String password, Uint8List salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: 256,
    );
    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return key.extractBytes();
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

/// The ordered rotation steps, as a JSON file the app writes and flushes
/// itself. Replaced through a sibling file, so it is never half written.
class _RotationJournal {
  _RotationJournal(this.file);

  final File file;

  List<Map<String, dynamic>> read() {
    if (!file.existsSync()) return [];
    final decoded = jsonDecode(file.readAsStringSync());
    return [
      for (final step in decoded['steps'] as List)
        Map<String, dynamic>.from(step as Map),
    ];
  }

  Future<void> write(List<Map<String, dynamic>> steps) async {
    if (steps.isEmpty) {
      delete();
      return;
    }
    final next = File('${file.path}.next');
    await next.writeAsString(jsonEncode({'v': 1, 'steps': steps}), flush: true);
    await next.rename(file.path);
  }

  void delete() {
    if (file.existsSync()) file.deleteSync();
  }
}

class KeyRotationException implements Exception {
  const KeyRotationException(this.message);

  final String message;

  @override
  String toString() => 'Key rotation failed: $message';
}
