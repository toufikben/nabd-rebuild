import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:cryptography/cryptography.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/storage.dart';
import 'database_service.dart';
import 'encryption_service.dart';
import 'media_vault.dart';

/// Encrypted `.nabd` backups.
///
/// Format 2 (written now):
///   `NABD` · 0x02 · salt[16] · chunkSize[u32] · chunk*
///   chunk = length[u32] · nonce[12] · ciphertext · mac[16]
/// Each chunk is AES-256-GCM with the chunk index and a "last chunk" flag as
/// associated data, so chunks cannot be reordered, dropped or cut off. The
/// key is PBKDF2-SHA256 of the password. Because it streams, a backup is no
/// longer limited by memory: photos and voice notes of any amount fit.
///
/// Format 1 (one GCM block over the whole ZIP) is still read.
///
/// Inside, a ZIP holds one JSON file per box plus `media/<stored path>` with
/// the plain bytes of every photo and voice note, so a backup opens on any
/// phone and is re-encrypted there with that phone's media key.
class BackupService {
  BackupService({
    EncryptionService? encryption,
    MediaVault? media,
    Future<Directory> Function()? documentsDirectory,
    Future<Directory> Function()? temporaryDirectory,
  })  : _encryption = encryption ?? EncryptionService(),
        _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory,
        _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory,
        _mediaOverride = media;

  final EncryptionService _encryption;
  final Future<Directory> Function() _documentsDirectory;
  final Future<Directory> Function() _temporaryDirectory;
  final MediaVault? _mediaOverride;

  MediaVault get _media =>
      _mediaOverride ??
      MediaVault(
        encryption: _encryption,
        documentsDirectory: _documentsDirectory,
        temporaryDirectory: _temporaryDirectory,
      );

  static const _magic = <int>[0x4E, 0x41, 0x42, 0x44]; // NABD
  static const formatVersion = 2;
  static const _legacyFormatVersion = 1;
  static const chunkSize = 1024 * 1024;
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _macLength = 16;

  /// Format 1 was decrypted in memory, so it keeps its old ceiling.
  static const maxLegacyBackupBytes = 50 * 1024 * 1024;
  static const maxExtractedBytes = 4 * 1024 * 1024 * 1024;
  static const maxFileBytes = 200 * 1024 * 1024;
  static const maxFileCount = 20000;

  static final _algorithm = AesGcm.with256bits();

  // ═══════════════════════════════════════════════════════════════════
  // Create
  // ═══════════════════════════════════════════════════════════════════

  Future<File> createBackup({
    required String password,
    void Function(double progress)? onProgress,
  }) async {
    if (password.isEmpty) {
      throw const FormatException('Backup password is required');
    }
    final temp = await _temporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final zipFile = File(p.join(temp.path, 'nabd_backup_$stamp.zip'));
    final output = File(p.join(temp.path, 'nabd_backup_$stamp.nabd'));

    try {
      final entries = Hive.box(HiveBoxes.journal);
      final encoder = ZipFileEncoder()..create(zipFile.path);
      void addJson(String name, Object? data) {
        final bytes = utf8.encode(jsonEncode(data));
        encoder.addArchiveFile(ArchiveFile(name, bytes.length, bytes));
      }

      addJson('entries.json', entries.values.toList());
      addJson('settings.json', exportableSettings(Hive.box(HiveBoxes.settings)));
      addJson('content.json', _stringKeys(Hive.box(HiveBoxes.content)));
      addJson('garden.json', _stringKeys(Hive.box(HiveBoxes.garden)));
      addJson('moods.json', _stringKeys(Hive.box(HiveBoxes.moods)));
      addJson('tags.json', _stringKeys(Hive.box(HiveBoxes.tags)));
      onProgress?.call(0.1);

      final mediaPaths = _mediaPathsOf(entries.values);
      var done = 0;
      for (final stored in mediaPaths) {
        try {
          final bytes = await _media.read(stored);
          encoder.addArchiveFile(
            ArchiveFile('media/${_archiveName(stored)}', bytes.length, bytes),
          );
        } catch (_) {
          // A photo that is already gone is not a reason to lose the journal.
        }
        done++;
        onProgress?.call(0.1 + 0.6 * done / mediaPaths.length);
      }

      addJson('metadata.json', {
        'app': 'nabd',
        'formatVersion': formatVersion,
        'encrypted': true,
        'exportedAt': DateTime.now().toIso8601String(),
        'entryCount': entries.length,
        'mediaCount': mediaPaths.length,
      });
      await encoder.close();

      await _encryptFile(zipFile, output, password, (fraction) {
        onProgress?.call(0.7 + 0.3 * fraction);
      });
      return output;
    } catch (_) {
      if (await output.exists()) await output.delete();
      rethrow;
    } finally {
      if (await zipFile.exists()) await zipFile.delete();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Restore
  // ═══════════════════════════════════════════════════════════════════

  Future<ImportResult> restoreBackup(
    String backupPath, {
    String? password,
    RestoreMode mode = RestoreMode.merge,
    void Function(double progress)? onProgress,
  }) async {
    if (password == null || password.isEmpty) {
      return const ImportResult.failed(BackupError.passwordRequired);
    }
    final input = File(backupPath);
    if (!await input.exists()) {
      return const ImportResult.failed(BackupError.unreadable);
    }
    // A file that is not even a Nabd backup is refused before anything else.
    try {
      await _checkHeader(input);
    } on BackupException catch (error) {
      return ImportResult.failed(error.error);
    } catch (_) {
      return const ImportResult.failed(BackupError.unreadable);
    }

    final Directory temp;
    try {
      temp = await _temporaryDirectory();
    } catch (_) {
      return const ImportResult.failed(BackupError.failed);
    }
    final zipFile = File(p.join(
      temp.path,
      'nabd_restore_${DateTime.now().microsecondsSinceEpoch}.zip',
    ));
    final storedMedia = <String>[];
    try {
      try {
        await _decryptFile(input, zipFile, password);
      } on BackupException catch (error) {
        return ImportResult.failed(error.error);
      } catch (_) {
        return const ImportResult.failed(BackupError.wrongPasswordOrCorrupt);
      }
      onProgress?.call(0.3);

      final payload = await _readPayload(zipFile);
      if (payload.error != null) return ImportResult.failed(payload.error!);
      onProgress?.call(0.5);

      return await _apply(payload, mode, storedMedia, onProgress);
    } catch (_) {
      await _deleteStored(storedMedia);
      return const ImportResult.failed(BackupError.failed);
    } finally {
      if (await zipFile.exists()) await zipFile.delete();
    }
  }

  /// Reads and validates every part before anything current is touched.
  Future<_Payload> _readPayload(File zipFile) async {
    final stream = InputFileStream(zipFile.path);
    try {
      final archive = ZipDecoder().decodeBuffer(stream);
      if (archive.length > maxFileCount) {
        return const _Payload.error(BackupError.tooLarge);
      }
      var extracted = 0;
      for (final file in archive) {
        if (!isSafeArchivePath(file.name) || file.size > maxFileBytes) {
          return const _Payload.error(BackupError.unsafe);
        }
        extracted += file.size;
        if (extracted > maxExtractedBytes) {
          return const _Payload.error(BackupError.tooLarge);
        }
      }

      final json = <String, Object?>{};
      final media = <String, ArchiveFile>{};
      for (final file in archive) {
        if (!file.isFile) continue;
        final name = Uri.decodeFull(file.name).replaceAll('\\', '/');
        if (_jsonParts.contains(name)) {
          if (json.containsKey(name)) {
            return const _Payload.error(BackupError.corrupt);
          }
          json[name] = jsonDecode(utf8.decode(file.content as List<int>));
        } else if (name.startsWith('media/') ||
            name.startsWith('images/') ||
            name.startsWith('audio/')) {
          if (media.containsKey(name)) {
            return const _Payload.error(BackupError.corrupt);
          }
          media[name] = file;
        }
      }

      final metadata = json['metadata.json'];
      if (metadata is! Map ||
          metadata['app'] != 'nabd' ||
          metadata['encrypted'] != true ||
          metadata['formatVersion'] is! num ||
          (metadata['formatVersion'] as num) > formatVersion) {
        return const _Payload.error(BackupError.unsupported);
      }
      final legacy = metadata['formatVersion'] == _legacyFormatVersion;
      final required = legacy ? _legacyRequired : _requiredParts;
      if (!required.every(json.containsKey)) {
        return const _Payload.error(BackupError.incomplete);
      }

      final entries = json['entries.json'];
      if (entries is! List || !validateEntriesPayload(entries)) {
        return const _Payload.error(BackupError.corrupt);
      }
      if (metadata['entryCount'] != entries.length) {
        return const _Payload.error(BackupError.incomplete);
      }
      for (final part in [
        'settings.json',
        'garden.json',
        'moods.json',
        'tags.json',
        if (!legacy) 'content.json',
        if (legacy) 'achievements.json',
      ]) {
        if (json[part] is! Map) return const _Payload.error(BackupError.corrupt);
      }

      // Format 1 kept user content inside the settings dump and a second
      // copy in achievements.json; split it the way format 2 stores it.
      final settings = Map<Object?, Object?>.from(json['settings.json'] as Map);
      final content = <Object?, Object?>{
        if (!legacy) ...(json['content.json'] as Map),
      };
      if (legacy) {
        for (final source in [settings, json['achievements.json'] as Map]) {
          for (final entry in source.entries) {
            final key = entry.key.toString();
            if (key == 'unlocked') {
              content[ContentKeys.unlockedAchievements] = entry.value;
            } else if (ContentKeys.isContentKey(key)) {
              content[key] = entry.value;
            }
          }
        }
        settings.removeWhere((key, _) => ContentKeys.isContentKey('$key'));
      }

      return _Payload(
        entries: [
          for (final entry in entries) Map<String, dynamic>.from(entry as Map),
        ],
        settings: filterRestoredSettings(settings),
        content: content,
        garden: Map<Object?, Object?>.from(json['garden.json'] as Map),
        moods: Map<Object?, Object?>.from(json['moods.json'] as Map),
        tags: Map<Object?, Object?>.from(json['tags.json'] as Map),
        media: media,
        legacy: legacy,
      );
    } on FormatException {
      return const _Payload.error(BackupError.corrupt);
    } finally {
      await stream.close();
    }
  }

  Future<ImportResult> _apply(
    _Payload payload,
    RestoreMode mode,
    List<String> storedMedia,
    void Function(double progress)? onProgress,
  ) async {
    final boxes = {for (final name in HiveBoxes.all) name: Hive.box(name)};
    final snapshots = {
      for (final entry in boxes.entries)
        entry.key: Map<dynamic, dynamic>.from(entry.value.toMap()),
    };
    final journal = boxes[HiveBoxes.journal]!;
    final previousMedia = _mediaPathsOf(journal.values);

    // Decide which backup entries land, then move only their media.
    final incoming = <String, Map<String, dynamic>>{};
    for (final entry in payload.entries) {
      final id = entry['id'].toString();
      final current = journal.get(id);
      if (mode == RestoreMode.merge && current is Map) {
        final currentAt = DateTime.tryParse('${current['updatedAt']}');
        final backupAt = DateTime.tryParse('${entry['updatedAt']}');
        if (currentAt != null &&
            (backupAt == null || !backupAt.isAfter(currentAt))) {
          continue;
        }
      }
      incoming[id] = entry;
    }

    var imagesRestored = 0;
    var audioRestored = 0;
    try {
      final total = incoming.length;
      var done = 0;
      for (final entry in incoming.values) {
        final images = <String>[];
        for (final path in _stringList(entry['imagePaths'])) {
          final stored = await _restoreMedia(
              payload, path, MediaVault.imagesDir, storedMedia);
          if (stored != null) {
            images.add(stored);
            imagesRestored++;
          }
        }
        entry['imagePaths'] = images;
        final audio = entry['audioPath'];
        if (audio is String) {
          final stored = await _restoreMedia(
              payload, audio, MediaVault.audioDir, storedMedia);
          entry['audioPath'] = stored;
          if (stored != null) audioRestored++;
        }
        done++;
        onProgress?.call(0.5 + 0.4 * done / (total == 0 ? 1 : total));
      }

      if (mode == RestoreMode.replace) {
        for (final name in HiveBoxes.all) {
          if (name == HiveBoxes.settings) continue;
          await boxes[name]!.clear();
        }
        await journal.putAll(incoming);
        await boxes[HiveBoxes.settings]!.putAll(payload.settings);
        await boxes[HiveBoxes.content]!.putAll(payload.content);
        await boxes[HiveBoxes.garden]!.putAll(payload.garden);
        await boxes[HiveBoxes.moods]!.putAll(payload.moods);
        await boxes[HiveBoxes.tags]!.putAll(payload.tags);
      } else {
        await journal.putAll(incoming);
        await _mergeInto(boxes[HiveBoxes.settings]!, payload.settings,
            keepCurrent: true);
        await _mergeContent(boxes[HiveBoxes.content]!, payload.content);
        await _mergeInto(boxes[HiveBoxes.garden]!, payload.garden,
            keepCurrent: true);
        await _mergeInto(boxes[HiveBoxes.moods]!, payload.moods,
            keepCurrent: true);
        await _mergeInto(boxes[HiveBoxes.tags]!, payload.tags,
            keepCurrent: true);
      }
      for (final box in boxes.values) {
        await box.flush();
      }
    } catch (_) {
      for (final entry in boxes.entries) {
        await entry.value.clear();
        await entry.value.putAll(snapshots[entry.key]!);
      }
      DatabaseService.invalidate();
      await _deleteStored(storedMedia);
      return const ImportResult.failed(BackupError.failed);
    }
    DatabaseService.invalidate();

    // Only after the commit: media no entry points at any more goes away.
    final stillUsed = _mediaPathsOf(journal.values);
    await _deleteStored(previousMedia.where((path) => !stillUsed.contains(path)));
    onProgress?.call(1);

    return ImportResult(
      ok: true,
      entriesImported: incoming.length,
      imagesRestored: imagesRestored,
      audioRestored: audioRestored,
    );
  }

  /// Puts one photo or voice note from the backup into this phone's vault and
  /// returns the path to store, or null when the backup did not carry it.
  Future<String?> _restoreMedia(
    _Payload payload,
    String storedPath,
    String folder,
    List<String> storedMedia,
  ) async {
    final file = payload.legacy
        ? payload.media['$folder/${p.basename(storedPath)}']
        : payload.media['media/${_archiveName(storedPath)}'];
    if (file == null) return null;
    final bytes = file.content as List<int>;
    if (bytes.isEmpty) return null;
    var extension = p.extension(
      MediaVault.isEncrypted(storedPath)
          ? storedPath.substring(
              0, storedPath.length - MediaVault.encryptedExtension.length)
          : storedPath,
    );
    if (extension.length > 6) extension = '';
    final stored = await _media.store(
      Uint8List.fromList(bytes),
      folder: folder,
      extension: extension,
    );
    storedMedia.add(stored);
    return stored;
  }

  Future<void> _mergeInto(
    Box box,
    Map<Object?, Object?> incoming, {
    required bool keepCurrent,
  }) async {
    final additions = <dynamic, dynamic>{
      for (final entry in incoming.entries)
        if (!keepCurrent || !box.containsKey(entry.key)) entry.key: entry.value,
    };
    if (additions.isNotEmpty) await box.putAll(additions);
  }

  Future<void> _mergeContent(Box box, Map<Object?, Object?> incoming) async {
    final merged = <dynamic, dynamic>{};
    for (final entry in incoming.entries) {
      final key = entry.key;
      if (!box.containsKey(key)) {
        merged[key] = entry.value;
        continue;
      }
      final value = mergeContentValue(box.get(key), entry.value);
      if (value != null) merged[key] = value;
    }
    if (merged.isNotEmpty) await box.putAll(merged);
  }

  /// How a backup value joins the one already on the phone:
  ///  • lists of records with an `id` are joined by id (the phone's copy of a
  ///    record wins),
  ///  • lists of plain values become their union,
  ///  • counters keep the larger number,
  ///  • anything else keeps what the phone has.
  /// Returns null when nothing changes.
  static Object? mergeContentValue(Object? current, Object? incoming) {
    if (current is List && incoming is List) {
      final hasIds = current.every((item) => item is Map && item['id'] != null) &&
          incoming.every((item) => item is Map && item['id'] != null);
      if (hasIds) {
        final ids = current.map((item) => '${(item as Map)['id']}').toSet();
        final added = incoming
            .where((item) => !ids.contains('${(item as Map)['id']}'))
            .toList();
        return added.isEmpty ? null : [...current, ...added];
      }
      final seen = current.map(jsonEncode).toSet();
      final added =
          incoming.where((item) => !seen.contains(jsonEncode(item))).toList();
      return added.isEmpty ? null : [...current, ...added];
    }
    if (current is num && incoming is num) {
      return incoming > current ? incoming : null;
    }
    return null;
  }

  Future<void> _deleteStored(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        await _media.delete(path);
      } catch (_) {}
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // Streaming encryption
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _encryptFile(
    File plain,
    File output,
    String password,
    void Function(double fraction) onProgress,
  ) async {
    final salt = _encryption.generateSalt(_saltLength);
    final key = await _encryption.deriveKeyFromPassword(
      password: password,
      salt: salt,
    );
    final total = await plain.length();
    final reader = await plain.open();
    final sink = output.openWrite();
    try {
      sink.add([..._magic, formatVersion, ...salt, ..._u32(chunkSize)]);
      var index = 0;
      var position = 0;
      do {
        final chunk = await reader.read(chunkSize);
        position += chunk.length;
        final last = position >= total;
        final box = await _algorithm.encrypt(
          chunk,
          secretKey: key,
          nonce: _algorithm.newNonce(),
          aad: _chunkAad(index, last),
        );
        sink.add(_u32(box.cipherText.length));
        sink.add(box.nonce);
        sink.add(box.cipherText);
        sink.add(box.mac.bytes);
        index++;
        onProgress(total == 0 ? 1 : position / total);
        if (last) break;
      } while (true);
      await sink.flush();
    } finally {
      await sink.close();
      await reader.close();
    }
  }

  /// Returns the format version after checking the magic bytes.
  Future<int> _checkHeader(File input) async {
    final header = <int>[
      for (final part in await input.openRead(0, _magic.length + 1).toList())
        ...part,
    ];
    if (header.length < _magic.length + 1) {
      throw const BackupException(BackupError.corrupt);
    }
    for (var i = 0; i < _magic.length; i++) {
      if (header[i] != _magic[i]) {
        throw const BackupException(BackupError.unsupported);
      }
    }
    final version = header[_magic.length];
    if (version != _legacyFormatVersion && version != formatVersion) {
      throw const BackupException(BackupError.unsupported);
    }
    return version;
  }

  Future<void> _decryptFile(File input, File output, String password) async {
    if (await _checkHeader(input) == _legacyFormatVersion) {
      return _decryptLegacy(input, output, password);
    }

    final reader = await input.open();
    final sink = output.openWrite();
    try {
      await reader.setPosition(_magic.length + 1);
      final salt = await reader.read(_saltLength);
      final declaredChunk = _readU32(await reader.read(4));
      if (salt.length != _saltLength ||
          declaredChunk <= 0 ||
          declaredChunk > 16 * chunkSize) {
        throw const BackupException(BackupError.corrupt);
      }
      final key = await _encryption.deriveKeyFromPassword(
        password: password,
        salt: Uint8List.fromList(salt),
      );
      final size = await reader.length();
      var index = 0;
      var sawLast = false;
      while (await reader.position() < size) {
        if (sawLast) throw const BackupException(BackupError.corrupt);
        final length = _readU32(await reader.read(4));
        if (length > declaredChunk) {
          throw const BackupException(BackupError.corrupt);
        }
        final nonce = await reader.read(_nonceLength);
        final cipherText = await reader.read(length);
        final mac = await reader.read(_macLength);
        if (nonce.length != _nonceLength ||
            cipherText.length != length ||
            mac.length != _macLength) {
          throw const BackupException(BackupError.corrupt);
        }
        final last = await reader.position() >= size;
        final plain = await _algorithm.decrypt(
          SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
          secretKey: key,
          aad: _chunkAad(index, last),
        );
        sink.add(plain);
        sawLast = last;
        index++;
      }
      if (!sawLast) throw const BackupException(BackupError.corrupt);
      await sink.flush();
    } finally {
      await sink.close();
      await reader.close();
    }
  }

  /// Format 1: `NABD` · 0x01 · salt · nonce · ciphertext · mac, in memory.
  Future<void> _decryptLegacy(File input, File output, String password) async {
    if (await input.length() > maxLegacyBackupBytes) {
      throw const BackupException(BackupError.tooLarge);
    }
    final bytes = await input.readAsBytes();
    const headerLength = 5;
    if (bytes.length < headerLength + _saltLength + _nonceLength + _macLength) {
      throw const BackupException(BackupError.corrupt);
    }
    final salt = bytes.sublist(headerLength, headerLength + _saltLength);
    final nonceStart = headerLength + _saltLength;
    final key = await _encryption.deriveKeyFromPassword(
      password: password,
      salt: Uint8List.fromList(salt),
    );
    final plain = await _algorithm.decrypt(
      SecretBox(
        bytes.sublist(nonceStart + _nonceLength, bytes.length - _macLength),
        nonce: bytes.sublist(nonceStart, nonceStart + _nonceLength),
        mac: Mac(bytes.sublist(bytes.length - _macLength)),
      ),
      secretKey: key,
    );
    await output.writeAsBytes(plain, flush: true);
  }

  static List<int> _chunkAad(int index, bool last) {
    final data = ByteData(9)
      ..setUint64(0, index)
      ..setUint8(8, last ? 1 : 0);
    return data.buffer.asUint8List();
  }

  static List<int> _u32(int value) =>
      (ByteData(4)..setUint32(0, value)).buffer.asUint8List();

  static int _readU32(List<int> bytes) {
    if (bytes.length != 4) throw const BackupException(BackupError.corrupt);
    return ByteData.sublistView(Uint8List.fromList(bytes)).getUint32(0);
  }

  // ═══════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════

  static const _jsonParts = {
    'metadata.json',
    'entries.json',
    'settings.json',
    'content.json',
    'garden.json',
    'moods.json',
    'tags.json',
    'achievements.json',
  };

  static const _requiredParts = {
    'metadata.json',
    'entries.json',
    'settings.json',
    'content.json',
    'garden.json',
    'moods.json',
    'tags.json',
  };

  static const _legacyRequired = {
    'metadata.json',
    'entries.json',
    'settings.json',
    'garden.json',
    'moods.json',
    'tags.json',
    'achievements.json',
  };

  /// Never travels in a backup: purchases are restored from the store, and
  /// the lock, reminder and onboarding state belong to the phone they were
  /// set on (the passcode itself lives in that phone's keystore).
  static const _deviceKeys = {
    'is_pro',
    'is_lifetime',
    'pro_expiry',
    'lock_enabled',
    'lock_timeout_minutes',
    'last_activity',
    'onboarding_completed',
    'last_splash_id',
    'reminder_enabled',
    'reminder_hour',
    'reminder_minute',
    'reminder_title',
    'reminder_body',
    'weekly_review_enabled',
    'weekly_review_title',
    'weekly_review_body',
    'garden_growth_day',
    'garden_growth_today',
    // Consent to the phone's speech service is given per device.
    'dictation_notice_seen',
  };

  static bool isEntitlementKey(String key) =>
      const {'is_pro', 'is_lifetime', 'pro_expiry'}.contains(key.toLowerCase());

  static bool isDeviceKey(String key) =>
      _deviceKeys.contains(key.toLowerCase());

  static Map<String, Object?> exportableSettings(Box settings) => {
        for (final key in settings.keys)
          if (!isDeviceKey('$key') && !ContentKeys.isContentKey('$key'))
            '$key': settings.get(key),
      };

  static Map<Object?, Object?> filterRestoredSettings(Map source) => {
        for (final entry in source.entries)
          if (!isDeviceKey(entry.key.toString())) entry.key: entry.value,
      };

  static Map<String, Object?> _stringKeys(Box box) => {
        for (final key in box.keys) '$key': box.get(key),
      };

  static List<String> _stringList(Object? value) => value is Iterable
      ? value.map((item) => item.toString()).toList()
      : <String>[];

  static List<String> _mediaPathsOf(Iterable<dynamic> entries) {
    final paths = <String>{};
    for (final entry in entries) {
      if (entry is! Map) continue;
      paths.addAll(_stringList(entry['imagePaths']));
      final audio = entry['audioPath'];
      if (audio is String) paths.add(audio);
    }
    return paths.toList();
  }

  /// A stored path as an archive name: relative paths are kept, absolute
  /// legacy paths keep their folder and file name.
  static String _archiveName(String stored) => p.isAbsolute(stored)
      ? '${p.basename(p.dirname(stored))}/${p.basename(stored)}'
      : stored.replaceAll('\\', '/');

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
    if (decoded.startsWith('/')) return false;
    if (decoded.split('/').contains('..')) return false;
    return _jsonParts.contains(decoded) ||
        decoded.startsWith('media/') ||
        decoded.startsWith('images/') ||
        decoded.startsWith('audio/');
  }
}

enum RestoreMode { merge, replace }

/// Why a restore failed, as a string-table key for the screen.
enum BackupError {
  passwordRequired('backup.error.password'),
  unreadable('backup.error.unreadable'),
  wrongPasswordOrCorrupt('backup.error.wrongPassword'),
  unsupported('backup.error.unsupported'),
  corrupt('backup.error.corrupt'),
  incomplete('backup.error.incomplete'),
  unsafe('backup.error.unsafe'),
  tooLarge('backup.error.tooLarge'),
  failed('backup.error.failed');

  const BackupError(this.messageKey);

  final String messageKey;
}

class BackupException implements Exception {
  const BackupException(this.error);

  final BackupError error;

  @override
  String toString() => 'BackupException(${error.name})';
}

class ImportResult {
  final bool ok;
  final int entriesImported;
  final int imagesRestored;
  final int audioRestored;
  final BackupError? failure;

  const ImportResult({
    required this.ok,
    this.entriesImported = 0,
    this.imagesRestored = 0,
    this.audioRestored = 0,
    this.failure,
  });

  const ImportResult.failed(BackupError this.failure)
      : ok = false,
        entriesImported = 0,
        imagesRestored = 0,
        audioRestored = 0;

  /// The string-table key describing the failure, if any.
  String? get error => failure?.messageKey;
}

class _Payload {
  const _Payload({
    required this.entries,
    required this.settings,
    required this.content,
    required this.garden,
    required this.moods,
    required this.tags,
    required this.media,
    required this.legacy,
  }) : error = null;

  const _Payload.error(BackupError this.error)
      : entries = const [],
        settings = const {},
        content = const {},
        garden = const {},
        moods = const {},
        tags = const {},
        media = const {},
        legacy = false;

  final BackupError? error;
  final List<Map<String, dynamic>> entries;
  final Map<Object?, Object?> settings;
  final Map<Object?, Object?> content;
  final Map<Object?, Object?> garden;
  final Map<Object?, Object?> moods;
  final Map<Object?, Object?> tags;
  final Map<String, ArchiveFile> media;
  final bool legacy;
}
