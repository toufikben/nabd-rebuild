import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'encryption_service.dart';

/// BackupService — نسخ احتياطي محلي مع تشفير AES-256-GCM حقيقي.
///
/// التنسيق:
///   • بدون كلمة مرور → ZIP عادي
///   • مع كلمة مرور → ZIP + AES-256-GCM
///
/// البنية داخل ZIP:
///   entries.json     — المذكرات
///   settings.json    — الإعدادات
///   garden.json      — الحديقة
///   achievements.json — الإنجازات
///   metadata.json    — معلومات الإصدار
///   images/          — الصور
///   audio/           — التسجيلات
class BackupService {
  final _encryption = EncryptionService();
  static const maxBackupBytes = 50 * 1024 * 1024;
  static const maxExtractedBytes = 200 * 1024 * 1024;
  static const maxFileBytes = 25 * 1024 * 1024;
  static const maxFileCount = 500;

  /// إنشاء نسخة احتياطية.
  Future<File> createBackup({
    String? password,
    void Function(double progress)? onProgress,
  }) async {
    final docs = await getApplicationDocumentsDirectory();
    final tempDir = await getTemporaryDirectory();
    final archive = Archive();

    var step = 0;
    const totalSteps = 6;

    void reportProgress() {
      step++;
      onProgress?.call(step / totalSteps);
    }

    // 1. Journal entries
    final entriesBox = Hive.box('journal_entries');
    final entriesJson = entriesBox.values.toList();
    _addJson(archive, 'entries.json', entriesJson);
    reportProgress();

    // 2. Settings
    final settingsBox = Hive.box('settings');
    final settingsJson = <String, dynamic>{};
    for (final key in settingsBox.keys) {
      settingsJson[key.toString()] = settingsBox.get(key);
    }
    _addJson(archive, 'settings.json', settingsJson);
    reportProgress();

    // 3. Garden
    final gardenBox = Hive.box('garden');
    final gardenJson = <String, dynamic>{};
    for (final key in gardenBox.keys) {
      gardenJson[key.toString()] = gardenBox.get(key);
    }
    _addJson(archive, 'garden.json', gardenJson);
    reportProgress();

    // 4. Achievements + Challenges
    final achievementsJson = <String, dynamic>{
      'unlocked': settingsBox.get('unlocked_achievements', defaultValue: []),
      'joined_challenges':
          settingsBox.get('joined_challenges', defaultValue: []),
      'legacy_entries': settingsBox.get('legacy_entries', defaultValue: []),
      'unsent_letters': settingsBox.get('unsent_letters', defaultValue: []),
      'time_capsules': settingsBox.get('time_capsules', defaultValue: []),
      'gratitude_items': settingsBox.get('gratitude_items', defaultValue: []),
      'future_letters': settingsBox.get('future_letters', defaultValue: []),
      'worry_box': settingsBox.get('worry_box', defaultValue: []),
    };
    _addJson(archive, 'achievements.json', achievementsJson);
    reportProgress();

    // 5. Media files
    for (final dirName in ['images', 'audio']) {
      final dir = Directory('${docs.path}/$dirName');
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            final name = p.basename(entity.path);
            final bytes = await entity.readAsBytes();
            archive.addFile(
              ArchiveFile('$dirName/$name', bytes.length, bytes),
            );
          }
        }
      }
    }
    reportProgress();

    // 6. Metadata
    final metadata = {
      'version': 2,
      'app': 'nabd',
      'exportedAt': DateTime.now().toIso8601String(),
      'encrypted': password != null && password.isNotEmpty,
      'entryCount': entriesBox.length,
      'gardenCount': gardenBox.length,
    };
    _addJson(archive, 'metadata.json', metadata);
    reportProgress();

    // 7. Encode ZIP
    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to encode ZIP');
    }

    // 8. Encrypt if password provided (using real AES-256-GCM)
    final outputBytes = (password != null && password.isNotEmpty)
        ? await _encryptZip(Uint8List.fromList(zipBytes), password)
        : Uint8List.fromList(zipBytes);

    // 9. Save
    final extension =
        (password != null && password.isNotEmpty) ? 'nabd' : 'zip';
    final filename =
        'nabd_backup_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final backupFile = File('${tempDir.path}/$filename');
    await backupFile.writeAsBytes(outputBytes);

    return backupFile;
  }

  /// استيراد نسخة احتياطية.
  Future<ImportResult> restoreBackup(
    String backupPath, {
    String? password,
    RestoreMode mode = RestoreMode.merge,
  }) async {
    try {
      final input = File(backupPath);
      if (!await input.exists() || await input.length() > maxBackupBytes) {
        return const ImportResult(
            ok: false, error: 'Backup is missing or too large');
      }
      var bytes = await input.readAsBytes();

      // 1. Decrypt if needed
      if (password != null && password.isNotEmpty) {
        try {
          bytes = await _decryptZip(Uint8List.fromList(bytes), password);
        } catch (e) {
          return ImportResult(
            ok: false,
            error: 'فشل فك التشفير: كلمة المرور خاطئة أو الملف تالف',
          );
        }
      }

      // 2. Decode ZIP
      final archive = ZipDecoder().decodeBytes(bytes);
      if (archive.length > maxFileCount) {
        return const ImportResult(
            ok: false, error: 'Backup contains too many files');
      }
      if (!archive.any((file) => file.isFile && file.name == 'metadata.json')) {
        return const ImportResult(
            ok: false, error: 'Backup metadata is missing');
      }
      var extractedBytes = 0;
      for (final file in archive) {
        if (!isSafeArchivePath(file.name) || file.size > maxFileBytes) {
          return const ImportResult(
              ok: false, error: 'Backup contains an unsafe file');
        }
        extractedBytes += file.size;
        if (extractedBytes > maxExtractedBytes) {
          return const ImportResult(
              ok: false, error: 'Backup expands beyond the limit');
        }
      }

      if (mode == RestoreMode.replace) {
        await Hive.box('journal_entries').clear();
        await Hive.box('settings').clear();
        await Hive.box('garden').clear();
      }

      var imported = 0;
      var imagesRestored = 0;
      var audioRestored = 0;

      final docs = await getApplicationDocumentsDirectory();

      // 3. Restore files
      for (final file in archive) {
        if (!file.isFile) continue;

        final name = file.name;
        final content = file.content as List<int>;

        if (name == 'metadata.json') {
          final metadata = jsonDecode(utf8.decode(content));
          if (metadata is! Map ||
              metadata['version'] is! num ||
              metadata['version'] > 2) {
            return const ImportResult(
              ok: false,
              error: 'Unsupported backup schema',
            );
          }
        } else if (name == 'entries.json') {
          final decoded = jsonDecode(utf8.decode(content));
          if (decoded is! List || !validateEntriesPayload(decoded)) {
            return const ImportResult(ok: false, error: 'Invalid entries data');
          }
          final entries = decoded;
          final box = Hive.box('journal_entries');
          for (final entry in entries) {
            final map = Map<String, dynamic>.from(entry as Map);
            final id = map['id']?.toString() ?? '';
            if (id.isNotEmpty) {
              await box.put(id, map);
              imported++;
            }
          }
        } else if (name == 'settings.json') {
          final settings = jsonDecode(utf8.decode(content)) as Map;
          final box = Hive.box('settings');
          for (final e in filterRestoredSettings(settings).entries) {
            await box.put(e.key.toString(), e.value);
          }
        } else if (name == 'garden.json') {
          final garden = jsonDecode(utf8.decode(content)) as Map;
          final box = Hive.box('garden');
          for (final e in garden.entries) {
            await box.put(e.key.toString(), e.value);
          }
        } else if (name == 'achievements.json') {
          final data = jsonDecode(utf8.decode(content)) as Map;
          final box = Hive.box('settings');
          for (final e in filterRestoredSettings(data).entries) {
            await box.put(e.key.toString(), e.value);
          }
        } else if (name.startsWith('images/')) {
          final filename = p.basename(name.substring(7));
          final imagesDir = Directory('${docs.path}/images');
          if (!await imagesDir.exists()) {
            await imagesDir.create(recursive: true);
          }
          await File('${imagesDir.path}/$filename').writeAsBytes(content);
          imagesRestored++;
        } else if (name.startsWith('audio/')) {
          final filename = p.basename(name.substring(6));
          final audioDir = Directory('${docs.path}/audio');
          if (!await audioDir.exists()) {
            await audioDir.create(recursive: true);
          }
          await File('${audioDir.path}/$filename').writeAsBytes(content);
          audioRestored++;
        }
      }

      return ImportResult(
        ok: true,
        entriesImported: imported,
        imagesRestored: imagesRestored,
        audioRestored: audioRestored,
      );
    } catch (e) {
      return ImportResult(ok: false, error: '$e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Internal — AES-256-GCM for ZIP files
  // ═══════════════════════════════════════════════════════════════

  /// تشفير ZIP بـ AES-256-GCM باستخدام مفتاح مشتق من كلمة المرور.
  ///
  /// التنسيق:
  ///   [salt:16][nonce:12][ciphertext...][mac:16]
  Future<Uint8List> _encryptZip(Uint8List zipBytes, String password) async {
    final algorithm = AesGcm.with256bits();

    // 1. Generate salt
    final salt = _encryption.generateSalt(16);

    // 2. Derive key from password
    final key = await _encryption.deriveKeyFromPassword(
      password: password,
      salt: salt,
    );

    // 3. Encrypt
    final nonce = algorithm.newNonce();
    final secretBox = await algorithm.encrypt(
      zipBytes,
      secretKey: key,
      nonce: nonce,
    );

    // 4. Combine: salt + nonce + ciphertext + mac
    return Uint8List.fromList([
      ...salt,
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  /// فك تشفير ZIP.
  Future<Uint8List> _decryptZip(Uint8List encrypted, String password) async {
    final algorithm = AesGcm.with256bits();

    const saltLength = 16;
    const nonceLength = 12;
    const macLength = 16;

    if (encrypted.length < saltLength + nonceLength + macLength) {
      throw const FormatException('Encrypted backup too short');
    }

    // 1. Extract parts
    final salt = encrypted.sublist(0, saltLength);
    final nonce = encrypted.sublist(saltLength, saltLength + nonceLength);
    final macBytes = encrypted.sublist(encrypted.length - macLength);
    final cipherText = encrypted.sublist(
      saltLength + nonceLength,
      encrypted.length - macLength,
    );

    // 2. Derive key
    final key = await _encryption.deriveKeyFromPassword(
      password: password,
      salt: salt,
    );

    // 3. Decrypt (throws if MAC verification fails)
    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final plaintext = await algorithm.decrypt(
      secretBox,
      secretKey: key,
    );

    return Uint8List.fromList(plaintext);
  }

  void _addJson(Archive archive, String name, dynamic data) {
    final bytes = utf8.encode(jsonEncode(data));
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  static const _entitlementKeys = {'is_pro', 'is_lifetime', 'pro_expiry'};

  static Map<Object?, Object?> filterRestoredSettings(Map source) => {
        for (final entry in source.entries)
          if (!_entitlementKeys.contains(entry.key.toString()))
            entry.key: entry.value,
      };

  static bool validateEntriesPayload(List entries) {
    final ids = <String>{};
    for (final entry in entries) {
      if (entry is! Map) return false;
      final id = entry['id']?.toString() ?? '';
      if (id.isEmpty || !ids.add(id)) return false;
      if (entry['title'] != null && entry['title'] is! String) return false;
      if (entry['content'] != null && entry['content'] is! String) return false;
    }
    return true;
  }

  static bool isSafeArchivePath(String name) {
    if (name.isEmpty || name.startsWith('/') || p.isAbsolute(name)) {
      return false;
    }
    final decoded = Uri.decodeFull(name).replaceAll('\\', '/');
    if (decoded.split('/').contains('..')) return false;
    return decoded == 'entries.json' ||
        decoded == 'settings.json' ||
        decoded == 'garden.json' ||
        decoded == 'achievements.json' ||
        decoded.startsWith('images/') ||
        decoded.startsWith('audio/');
  }
}

enum RestoreMode { merge, replace }

class ImportResult {
  final bool ok;
  final int entriesImported;
  final int imagesRestored;
  final int audioRestored;
  final String? error;

  const ImportResult({
    required this.ok,
    this.entriesImported = 0,
    this.imagesRestored = 0,
    this.audioRestored = 0,
    this.error,
  });
}
