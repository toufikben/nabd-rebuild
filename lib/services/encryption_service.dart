import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  /// تدوير المفتاح غير متاح حتى يتم تنفيذ عملية إعادة تشفير ذرية.
  ///
  /// استبدال المفتاح مباشرة يترك صناديق Hive مشفرة بالمفتاح القديم، ولذلك
  /// كان يؤدي إلى فقدان قابلية قراءة البيانات. يجب على المستدعي استخدام
  /// مسار تدوير يتحقق من staging قبل تبديل المفتاح.
  Future<void> rotateKey() async {
    throw const UnsupportedError(
      'Unsafe key rotation is disabled until an atomic re-encryption flow exists',
    );
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
