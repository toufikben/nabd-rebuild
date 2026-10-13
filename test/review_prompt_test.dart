import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/services/review_prompt.dart';

void main() {
  late Directory directory;
  late Box settings;
  late DateTime now;
  late int asks;

  ReviewPrompt prompt() => ReviewPrompt(
        settings: settings,
        now: () => now,
        request: () async {
          asks++;
          return true;
        },
      );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nabd_review');
    Hive.init(directory.path);
    settings = await Hive.openBox('settings');
    now = DateTime(2026, 10, 13, 20);
    asks = 0;
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('waits for a few good moments before asking', () async {
    await prompt().recordWin();
    await prompt().recordWin();
    expect(asks, 0);
    await prompt().recordWin();
    expect(asks, 1);
  });

  test('does not ask again until the spacing has passed', () async {
    for (var i = 0; i < 3; i++) {
      await prompt().recordWin();
    }
    now = now.add(const Duration(days: 30));
    await prompt().recordWin();
    expect(asks, 1);
    now = now.add(ReviewPrompt.spacing);
    await prompt().recordWin();
    expect(asks, 2);
  });

  test('a sheet Play could not show is not counted as asked', () async {
    final unavailable = ReviewPrompt(
      settings: settings,
      now: () => now,
      request: () async => false,
    );
    for (var i = 0; i < 3; i++) {
      await unavailable.recordWin();
    }
    expect(settings.get(ReviewPrompt.askedAtKey), isNull);
    await prompt().recordWin();
    expect(asks, 1);
  });
}
