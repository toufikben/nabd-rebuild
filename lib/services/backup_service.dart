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
  final EncryptionService _encryption;
  final Future<Directory> Function() _documentsDirectory;
  final Future<Directory> Function() _temporaryDirectory;
  static const _backupMagic = <int>[0x4E, 0x41, 0x42, 0x44]; // NABD
  static const _backupFormatVersion = 1;
  static const maxBackupBytes = 50 * 1024 * 1024;
  static const maxExtractedBytes = 200 * 1024 * 1024;
  static const maxFileBytes = 25 * 1024 * 1024;
  static const maxFileCount = 500;

  BackupService({
    EncryptionService? encryption,
    Future<Directory> Function()? documentsDirectory,
    Future<Directory> Function()? temporaryDirectory,
  })  : _encryption = encryption ?? EncryptionService(),
        _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory,
        _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  /// إنشاء نسخة احتياطية.
  Future<File> createBackup({
    required String password,
    void Function(double progress)? onProgress,
  }) async {
    if (password.isEmpty) {
      throw const FormatException('Backup password is required');
    }
    final docs = await _documentsDirectory();
    final tempDir = await _temporaryDirectory();
    final archive = Archive();

    var step = 0;
    const totalSteps = 8;

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
    _addJson(archive, 'settings.json', filterRestoredSettings(settingsJson));
    reportProgress();

    // 3. Garden
    final gardenBox = Hive.box('garden');
    final gardenJson = <String, dynamic>{};
    for (final key in gardenBox.keys) {
      gardenJson[key.toString()] = gardenBox.get(key);
    }
    _addJson(archive, 'garden.json', gardenJson);
    reportProgress();

    // 4. Moods and tags
    for (final name in ['moods', 'tags']) {
      final box = Hive.box(name);
      _addJson(archive, '$name.json', box.toMap());
      reportProgress();
    }

    // 5. Achievements + Challenges
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

    // 6. Media files
    for (final dirName in ['images', 'audio']) {
      final dir = Directory('${docs.path}/$dirName');
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            final name = p.basename(entity.path);
            final bytes = await entity.readAsBytes();
            if (bytes.length > maxFileBytes || archive.length >= maxFileCount) {
              throw const FormatException('Backup exceeds file limits');
            }
            archive.addFile(
              ArchiveFile('$dirName/$name', bytes.length, bytes),
            );
          }
        }
      }
    }
    reportProgress();

    // 7. Metadata
    final metadata = {
      'version': 3,
      'formatVersion': _backupFormatVersion,
      'app': 'nabd',
      'exportedAt': DateTime.now().toIso8601String(),
      'encrypted': true,
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

    // 8. Always encrypt backups (using real AES-256-GCM).
    final outputBytes =
        await _encryptZip(Uint8List.fromList(zipBytes), password);
    if (outputBytes.length > maxBackupBytes) {
      throw const FormatException('Backup exceeds size limit');
    }

    // 9. Save
    final filename =
        'nabd_backup_${DateTime.now().millisecondsSinceEpoch}.nabd';
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
      if (password == null || password.isEmpty) {
        return const ImportResult(
          ok: false,
          error: 'Backup password is required',
        );
      }
      final input = File(backupPath);
      if (!await input.exists() || await input.length() > maxBackupBytes) {
        return const ImportResult(
            ok: false, error: 'Backup is missing or too large');
      }
      var bytes = await input.readAsBytes();

      // 1. Decrypt the mandatory authenticated envelope.
      try {
        bytes = await _decryptZip(Uint8List.fromList(bytes), password);
      } catch (_) {
        return const ImportResult(
          ok: false,
          error: 'فشل فك التشفير: كلمة المرور خاطئة أو الملف تالف',
        );
      }

      // 2. Decode ZIP
      final archive = ZipDecoder().decodeBytes(bytes);
      if (archive.length > maxFileCount) {
        return const ImportResult(
            ok: false, error: 'Backup contains too many files');
      }
      final metadataFile = archive.whereType<ArchiveFile>().firstWhere(
            (file) => file.isFile && file.name == 'metadata.json',
            orElse: () =>
                throw const FormatException('Backup metadata is missing'),
          );
      final metadata = jsonDecode(
        utf8.decode(metadataFile.content as List<int>),
      );
      if (metadata is! Map ||
          metadata['formatVersion'] != _backupFormatVersion ||
          metadata['version'] is! num ||
          metadata['version'] > 3 ||
          metadata['app'] != 'nabd' ||
          metadata['encrypted'] != true) {
        return const ImportResult(
          ok: false,
          error: 'Unsupported backup schema',
        );
      }
      if (metadata['entryCount'] is! num || metadata['entryCount'] < 0) {
        return const ImportResult(ok: false, error: 'Invalid backup metadata');
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

      final stagedEntries = <String, Map<String, dynamic>>{};
      final stagedSettings = <Object?, Object?>{};
      final stagedGarden = <Object?, Object?>{};
      final stagedMoods = <Object?, Object?>{};
      final stagedTags = <Object?, Object?>{};
      final stagedFiles = <String, List<int>>{};
      final seenPayloads = <String>{};

      // 3. Decode and validate everything before touching current data.
      for (final file in archive) {
        if (!file.isFile) continue;

        final name = file.name;
        final content = file.content as List<int>;

        if (name == 'metadata.json') {
          if (!seenPayloads.add(name)) {
            return const ImportResult(
                ok: false, error: 'Duplicate backup payload');
          }
          continue;
        } else if (name == 'entries.json') {
          if (!seenPayloads.add(name)) {
            return const ImportResult(
                ok: false, error: 'Duplicate backup payload');
          }
          final decoded = jsonDecode(utf8.decode(content));
          if (decoded is! List || !validateEntriesPayload(decoded)) {
            return const ImportResult(ok: false, error: 'Invalid entries data');
          }
          for (final entry in decoded) {
            final map = Map<String, dynamic>.from(entry as Map);
            final id = map['id']?.toString() ?? '';
            stagedEntries[id] = map;
          }
        } else if (name == 'settings.json') {
          if (!seenPayloads.add(name)) {
            return const ImportResult(
                ok: false, error: 'Duplicate backup payload');
          }
          final settings = jsonDecode(utf8.decode(content));
          if (settings is! Map) {
            return const ImportResult(
                ok: false, error: 'Invalid settings data');
          }
          stagedSettings.addAll(filterRestoredSettings(settings));
        } else if (name == 'garden.json') {
          if (!seenPayloads.add(name)) {
            return const ImportResult(
                ok: false, error: 'Duplicate backup payload');
          }
          final garden = jsonDecode(utf8.decode(content));
          if (garden is! Map) {
            return const ImportResult(ok: false, error: 'Invalid garden data');
          }
          stagedGarden.addAll(garden);
        } else if (name == 'moods.json' || name == 'tags.json') {
          if (!seenPayloads.add(name)) {
            return const ImportResult(
                ok: false, error: 'Duplicate backup payload');
          }
          final values = jsonDecode(utf8.decode(content));
          if (values is! Map) {
            return const ImportResult(ok: false, error: 'Invalid box data');
          }
          (name == 'moods.json' ? stagedMoods : stagedTags).addAll(values);
        } else if (name == 'achievements.json') {
          if (!seenPayloads.add(name)) {
            return const ImportResult(
                ok: false, error: 'Duplicate backup payload');
          }
          final data = jsonDecode(utf8.decode(content));
          if (data is! Map) {
            return const ImportResult(
                ok: false, error: 'Invalid achievements data');
          }
          stagedSettings.addAll(filterRestoredSettings(data));
        } else if (name.startsWith('images/')) {
          final safeName = 'images/${p.basename(name.substring(7))}';
          if (!seenPayloads.add(safeName) ||
              p.basename(name.substring(7)).isEmpty ||
              content.isEmpty) {
            return const ImportResult(
                ok: false, error: 'Duplicate or malformed media');
          }
          stagedFiles[safeName] = content;
        } else if (name.startsWith('audio/')) {
          final safeName = 'audio/${p.basename(name.substring(6))}';
          if (!seenPayloads.add(safeName) ||
              p.basename(name.substring(6)).isEmpty ||
              content.isEmpty) {
            return const ImportResult(
                ok: false, error: 'Duplicate or malformed media');
          }
          stagedFiles[safeName] = content;
        }
      }

      const requiredPayloads = {
        'metadata.json',
        'entries.json',
        'settings.json',
        'garden.json',
        'moods.json',
        'tags.json',
        'achievements.json',
      };
      if (!requiredPayloads.every(seenPayloads.contains) ||
          metadata['entryCount'] != stagedEntries.length) {
        return const ImportResult(
          ok: false,
          error: 'Backup payload is incomplete',
        );
      }

      final tempRoot = Directory(
        '${(await _temporaryDirectory()).path}/nabd_restore_${DateTime.now().microsecondsSinceEpoch}',
      );
      final mediaStage = Directory('${tempRoot.path}/media');
      final mediaRollback = Directory('${tempRoot.path}/rollback');
      await mediaStage.create(recursive: true);
      for (final entry in stagedFiles.entries) {
        final stagedFile = File('${mediaStage.path}/${entry.key}');
        await stagedFile.parent.create(recursive: true);
        await stagedFile.writeAsBytes(entry.value, flush: true);
      }

      final entriesBox = Hive.box('journal_entries');
      final settingsBox = Hive.box('settings');
      final gardenBox = Hive.box('garden');
      final moodsBox = Hive.box('moods');
      final tagsBox = Hive.box('tags');
      final docs = await _documentsDirectory();
      final snapshots = {
        entriesBox: Map<dynamic, dynamic>.from(entriesBox.toMap()),
        settingsBox: Map<dynamic, dynamic>.from(settingsBox.toMap()),
        gardenBox: Map<dynamic, dynamic>.from(gardenBox.toMap()),
        moodsBox: Map<dynamic, dynamic>.from(moodsBox.toMap()),
        tagsBox: Map<dynamic, dynamic>.from(tagsBox.toMap()),
      };
      var imported = 0;
      var imagesRestored = 0;
      var audioRestored = 0;
      try {
        for (final directoryName in ['images', 'audio']) {
          final current = Directory('${docs.path}/$directoryName');
          if (await current.exists()) {
            await _copyDirectory(
                current, Directory('${mediaRollback.path}/$directoryName'));
          }
        }
        if (mode == RestoreMode.replace) {
          await entriesBox.clear();
          await settingsBox.clear();
          await gardenBox.clear();
          await moodsBox.clear();
          await tagsBox.clear();
        }
        await entriesBox.putAll(stagedEntries);
        await settingsBox.putAll(stagedSettings);
        await gardenBox.putAll(stagedGarden);
        await moodsBox.putAll(stagedMoods);
        await tagsBox.putAll(stagedTags);
        imported = stagedEntries.length;

        if (mode == RestoreMode.replace) {
          for (final directoryName in ['images', 'audio']) {
            final current = Directory('${docs.path}/$directoryName');
            if (await current.exists()) await current.delete(recursive: true);
          }
        }
        for (final entry in stagedFiles.entries) {
          final file = File('${docs.path}/${entry.key}');
          await file.parent.create(recursive: true);
          await File('${mediaStage.path}/${entry.key}').copy(file.path);
          if (entry.key.startsWith('images/')) {
            imagesRestored++;
          } else {
            audioRestored++;
          }
        }
      } catch (_) {
        await entriesBox.clear();
        await settingsBox.clear();
        await gardenBox.clear();
        await moodsBox.clear();
        await tagsBox.clear();
        await entriesBox.putAll(snapshots[entriesBox]!);
        await settingsBox.putAll(snapshots[settingsBox]!);
        await gardenBox.putAll(snapshots[gardenBox]!);
        await moodsBox.putAll(snapshots[moodsBox]!);
        await tagsBox.putAll(snapshots[tagsBox]!);
        for (final directoryName in ['images', 'audio']) {
          final current = Directory('${docs.path}/$directoryName');
          if (await current.exists()) await current.delete(recursive: true);
          final rollback = Directory('${mediaRollback.path}/$directoryName');
          if (await rollback.exists()) {
            await _copyDirectory(rollback, current);
          }
        }
        if (await tempRoot.exists()) await tempRoot.delete(recursive: true);
        return const ImportResult(ok: false, error: 'Restore failed safely');
      }

      if (await tempRoot.exists()) await tempRoot.delete(recursive: true);

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

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list()) {
      final destination = '${target.path}/${p.basename(entity.path)}';
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(destination));
      } else if (entity is File) {
        await entity.copy(destination);
      }
    }
  }

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
      ..._backupMagic,
      _backupFormatVersion,
      ...salt,
      ...secretBox.nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  /// فك تشفير ZIP.
  Future<Uint8List> _decryptZip(Uint8List encrypted, String password) async {
    final algorithm = AesGcm.with256bits();

    const headerLength = 5;
    const saltLength = 16;
    const nonceLength = 12;
    const macLength = 16;

    if (encrypted.length <
        headerLength + saltLength + nonceLength + macLength) {
      throw const FormatException('Encrypted backup too short');
    }

    for (var index = 0; index < _backupMagic.length; index++) {
      if (encrypted[index] != _backupMagic[index]) {
        throw const FormatException('Unsupported backup format');
      }
    }
    if (encrypted[4] != _backupFormatVersion) {
      throw const FormatException('Unsupported backup format version');
    }

    // 1. Extract parts
    final salt = encrypted.sublist(headerLength, headerLength + saltLength);
    final nonceStart = headerLength + saltLength;
    final nonce = encrypted.sublist(nonceStart, nonceStart + nonceLength);
    final macBytes = encrypted.sublist(encrypted.length - macLength);
    final cipherText = encrypted.sublist(
      nonceStart + nonceLength,
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
    return decoded == 'metadata.json' ||
        decoded == 'entries.json' ||
        decoded == 'settings.json' ||
        decoded == 'garden.json' ||
        decoded == 'moods.json' ||
        decoded == 'tags.json' ||
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
