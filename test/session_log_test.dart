import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/core/session_log.dart';
import 'package:nabd/core/storage.dart';

void main() {
  late Directory directory;
  late Box box;

  setUp(() async {
    await Hive.close();
    directory = await Directory.systemTemp.createTemp('nabd_session_log');
    Hive.init(directory.path);
    box = await Hive.openBox<dynamic>(HiveBoxes.content);
  });

  tearDown(() async {
    await Hive.close();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('a fresh journal has finished no sessions', () {
    expect(SessionLog.completed(box), 0);
  });

  test('every finished session is counted once', () async {
    await SessionLog.record(box);
    await SessionLog.record(box);

    expect(SessionLog.completed(box), 2);
  });

  test('a value that is not a number reads as zero', () async {
    // A restore from an older build could leave something else under the key;
    // the counter must not throw on it.
    await box.put(ContentKeys.sessionsCompleted, 'twelve');

    expect(SessionLog.completed(box), 0);
    expect(await SessionLog.record(box), 1);
  });

  test('the breathing screen and the runner share one counter', () {
    // They used to keep a copy of this code each; a change in one would have
    // silently diverged from the other.
    final sources = [
      'lib/features/breathing/breathing_screen.dart',
      'lib/features/sessions/screens/session_runner_screen.dart',
      'lib/features/stats/stats_screen.dart',
    ];
    for (final path in sources) {
      final source = File(path).readAsStringSync();
      expect(source, contains('core/session_log.dart'), reason: path);
      expect(source, isNot(contains('ContentKeys.sessionsCompleted')),
          reason: path);
    }
  });
}
