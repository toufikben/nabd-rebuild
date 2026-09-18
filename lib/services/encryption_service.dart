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

  SecretKey? _cachedKey;

  /// تهيئة المفتاح — يُستدعى مرة واحدة عند بدء التطبيق.
  Future<void> initialize() async {
    final stored = await _storage.read(key: _keyAlias);
    if (stored != null) {
      try {
        final bytes = base64Decode(stored);
        if (bytes.length == 32) {
          _cachedKey = SecretKey(bytes);
          return;
        }
      } catch (_) {
        // مفتاح تالف → أنشئ جديد
      }
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
    await initialize();
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

  /// إعادة إنشاء المفتاح الرئيسي — **يُفقد كل البيانات المشفرة**.
  Future<void> rotateKey() async {
    await _storage.delete(key: _keyAlias);
    _cachedKey = null;
    await initialize();
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
