import 'dart:async';

import 'package:hive/hive.dart';

/// Opens a box without Hive's crash recovery, so a checksum failure throws
/// instead of truncating the file.
///
/// Hive also completes an internal future with that error which nothing
/// listens to, so every caught failure would still surface as an unhandled
/// exception. The open runs in its own error zone to keep that echo out of
/// the app's error reporting; the caller still gets the error.
Future<Box<dynamic>> openBoxStrict(String name, {HiveCipher? cipher}) {
  final result = Completer<Box<dynamic>>();
  runZonedGuarded(
    () async {
      final box = await Hive.openBox<dynamic>(
        name,
        encryptionCipher: cipher,
        crashRecovery: false,
      );
      if (!result.isCompleted) result.complete(box);
    },
    (error, stackTrace) {
      if (!result.isCompleted) result.completeError(error, stackTrace);
    },
  );
  return result.future;
}
