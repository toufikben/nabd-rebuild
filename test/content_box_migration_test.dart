import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/core/storage.dart';

void main() {
  late Directory directory;
  late Box settings;
  late Box content;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nabd_content');
    Hive.init(directory.path);
    settings = await Hive.openBox<dynamic>(HiveBoxes.settings);
    content = await Hive.openBox<dynamic>(HiveBoxes.content);
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('user content leaves settings, preferences stay', () async {
    await settings.putAll({
      'language': 'ar',
      'lock_enabled': true,
      'unsent_letters': [
        {'id': '1', 'content': 'dear you'},
      ],
      'gratitude_2026_10_1': ['tea'],
      'weekly_pulse_2026-W40': {'entryCount': 3},
      'unlocked_achievements': ['first_entry'],
    });

    final moved = await ContentBoxMigration.run(
      settings: settings,
      content: content,
    );

    expect(moved, 4);
    expect(settings.keys.toSet(), {'language', 'lock_enabled'});
    expect(content.get('unsent_letters')[0]['content'], 'dear you');
    expect(content.get('gratitude_2026_10_1'), ['tea']);
    expect(content.get('weekly_pulse_2026-W40')['entryCount'], 3);
  });

  test('a second run is a no-op', () async {
    await settings.put('worry_box', [
      {'id': 'w'},
    ]);
    await ContentBoxMigration.run(settings: settings, content: content);
    expect(
      await ContentBoxMigration.run(settings: settings, content: content),
      0,
    );
    expect(content.get('worry_box'), hasLength(1));
  });

  test('content written after an interrupted move is not overwritten',
      () async {
    await content.put('worry_box', [
      {'id': 'new'},
    ]);
    await settings.put('worry_box', [
      {'id': 'old'},
    ]);
    await ContentBoxMigration.run(settings: settings, content: content);
    expect(content.get('worry_box')[0]['id'], 'new');
    expect(settings.containsKey('worry_box'), isFalse);
  });

  test('time capsules become letters to the future', () async {
    await content.put('future_letters', [
      {'id': 'f1', 'text': 'hello', 'unlockDate': '2027-01-01T00:00:00.000'},
    ]);
    await content.put('time_capsules', [
      {
        'id': 'c1',
        'title': 'Open me',
        'content': 'remember today',
        'createdAt': '2026-10-01T00:00:00.000',
        'unlockAt': '2027-10-01T00:00:00.000',
      },
    ]);

    expect(await ContentBoxMigration.foldTimeCapsules(content), 1);
    expect(content.containsKey('time_capsules'), isFalse);
    final letters = content.get('future_letters') as List;
    expect(letters, hasLength(2));
    expect(letters.last['text'], 'Open me\n\nremember today');
    expect(letters.last['unlockDate'], '2027-10-01T00:00:00.000');
    expect(await ContentBoxMigration.foldTimeCapsules(content), 0);
  });
}
