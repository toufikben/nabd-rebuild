import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'encryption_service.dart';

/// Photos and voice notes, encrypted on disk with AES-256-GCM.
///
/// Entries store a path relative to the documents directory
/// (`images/<name>.nenc`), so a backup restored on another phone, or an iOS
/// container that moved after an update, still finds its media. Older
/// entries may hold an absolute path to a plain file; [read] still serves
/// those and [encryptLegacy] converts them.
///
/// Media has its own key in the keystore, separate from the journal key, so
/// rotating the journal key never has to rewrite every photo.
class MediaVault {
  MediaVault({
    EncryptionService? encryption,
    Future<Directory> Function()? documentsDirectory,
    Future<Directory> Function()? temporaryDirectory,
  })  : _encryption = encryption ?? EncryptionService(),
        _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory,
        _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  static const encryptedExtension = '.nenc';
  static const imagesDir = 'images';
  static const audioDir = 'audio';
  static const _magic = <int>[0x4E, 0x42, 0x4D, 0x31]; // NBM1
  static const _nonceLength = 12;
  static const _macLength = 16;
  static final _algorithm = AesGcm.with256bits();

  final EncryptionService _encryption;
  final Future<Directory> Function() _documentsDirectory;
  final Future<Directory> Function() _temporaryDirectory;

  static bool isEncrypted(String storedPath) =>
      storedPath.endsWith(encryptedExtension);

  /// Resolves what an entry stores to a file on this device.
  Future<File> resolve(String storedPath) async {
    if (p.isAbsolute(storedPath)) return File(storedPath);
    final docs = await _documentsDirectory();
    return File(p.join(docs.path, storedPath));
  }

  /// Encrypts [bytes] into the vault and returns the path to store.
  Future<String> store(
    Uint8List bytes, {
    required String folder,
    String extension = '',
  }) async {
    final docs = await _documentsDirectory();
    final dir = Directory(p.join(docs.path, folder));
    if (!await dir.exists()) await dir.create(recursive: true);
    final name = '${DateTime.now().microsecondsSinceEpoch}_'
        '${Random.secure().nextInt(1 << 32).toRadixString(16)}'
        '$extension$encryptedExtension';
    final relative = p.join(folder, name);
    final target = File(p.join(docs.path, relative));
    final partial = File('${target.path}.partial');
    await partial.writeAsBytes(await _seal(bytes), flush: true);
    await partial.rename(target.path);
    return relative;
  }

  /// Moves a plain file (a picked photo copy or a fresh recording) into the
  /// vault and deletes the plain copy when [deleteSource] is set.
  Future<String> importFile(
    File source, {
    required String folder,
    bool deleteSource = false,
  }) async {
    final bytes = await source.readAsBytes();
    final stored = await store(
      bytes,
      folder: folder,
      extension: p.extension(source.path),
    );
    if (deleteSource && await source.exists()) await source.delete();
    return stored;
  }

  /// The plain bytes behind a stored path, encrypted or legacy.
  Future<Uint8List> read(String storedPath) async {
    final file = await resolve(storedPath);
    final bytes = await file.readAsBytes();
    if (!isEncrypted(storedPath)) return bytes;
    return _open(bytes);
  }

  /// Players need a file, not bytes: writes a short-lived plain copy in the
  /// temporary directory. The caller deletes it when playback ends.
  Future<File> decryptToTemp(String storedPath) async {
    if (!isEncrypted(storedPath)) return resolve(storedPath);
    final temp = await _temporaryDirectory();
    final plainName = p.basenameWithoutExtension(storedPath);
    final file = File(p.join(temp.path, 'play_$plainName'));
    await file.writeAsBytes(await read(storedPath), flush: true);
    return file;
  }

  Future<void> delete(String storedPath) async {
    final file = await resolve(storedPath);
    if (await file.exists()) await file.delete();
  }

  /// Converts a plain or absolute media path into an encrypted, relative one.
  /// Returns null when the file no longer exists.
  Future<String?> encryptLegacy(String storedPath, {required String folder}) async {
    if (isEncrypted(storedPath) && !p.isAbsolute(storedPath)) return storedPath;
    final file = await resolve(storedPath);
    if (!await file.exists()) return null;
    return importFile(file, folder: folder, deleteSource: true);
  }

  Future<Uint8List> _seal(Uint8List plain) async {
    final key = await _encryption.mediaKey();
    final nonce = _algorithm.newNonce();
    final box = await _algorithm.encrypt(plain, secretKey: key, nonce: nonce);
    return Uint8List.fromList([
      ..._magic,
      ...box.nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  Future<Uint8List> _open(Uint8List sealed) async {
    if (sealed.length < _magic.length + _nonceLength + _macLength) {
      throw const FormatException('Encrypted media is too short');
    }
    for (var i = 0; i < _magic.length; i++) {
      if (sealed[i] != _magic[i]) {
        throw const FormatException('Not an encrypted media file');
      }
    }
    final start = _magic.length;
    final box = SecretBox(
      sealed.sublist(start + _nonceLength, sealed.length - _macLength),
      nonce: sealed.sublist(start, start + _nonceLength),
      mac: Mac(sealed.sublist(sealed.length - _macLength)),
    );
    final key = await _encryption.mediaKey();
    return Uint8List.fromList(await _algorithm.decrypt(box, secretKey: key));
  }
}
