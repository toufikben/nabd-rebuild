import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/core/storage.dart';

void main() {
  late Directory directory;
  late Box box;

  setUp(() async {
    await Hive.close();
    directory = await Directory.systemTemp.createTemp('nabd_storage_readers');
    Hive.init(directory.path);
    box = await Hive.openBox<dynamic>(HiveBoxes.settings);
  });

  tearDown(() async {
    await Hive.close();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  group('a setting is read, not trusted', () {
    test('a bool survives its own type', () {
      expect(readBool(box, 'flag', fallback: true), isTrue);
      expect(readBool(box, 'flag', fallback: false), isFalse);
    });

    test('a bool stored as text or a number still reads', () async {
      await box.put('flag', 'false');
      expect(readBool(box, 'flag', fallback: true), isFalse);
      await box.put('flag', 0);
      expect(readBool(box, 'flag', fallback: true), isFalse);
      await box.put('flag', 1);
      expect(readBool(box, 'flag', fallback: false), isTrue);
    });

    test('a bool stored as something else falls back instead of throwing',
        () async {
      await box.put('flag', <String>['true']);
      expect(readBool(box, 'flag', fallback: true), isTrue);
      expect(readBool(box, 'flag', fallback: false), isFalse);
    });

    test('a string reads whether it is stored as text or not', () async {
      expect(readString(box, 'sound'), isNull);
      await box.put('sound', 'chime');
      expect(readString(box, 'sound'), 'chime');
      await box.put('sound', 42);
      expect(readString(box, 'sound'), '42');
    });

    test('an int reads from a number or a string, with a fallback', () async {
      expect(readInt(box, 'timeout', fallback: 5), 5);
      await box.put('timeout', 12);
      expect(readInt(box, 'timeout', fallback: 5), 12);
      await box.put('timeout', '7');
      expect(readInt(box, 'timeout', fallback: 5), 7);
      await box.put('timeout', 'not a number');
      expect(readInt(box, 'timeout', fallback: 5), 5);
      await box.put('timeout', <int>[1]);
      expect(readInt(box, 'timeout', fallback: 5), 5);
    });
  });

  group('a list is read only when it is a list', () {
    test('a string list drops non-list values without throwing', () async {
      expect(readStringList(box, 'items'), isEmpty);
      await box.put('items', 'not a list');
      expect(readStringList(box, 'items'), isEmpty);
      await box.put('items', [1, 'two', null]);
      expect(readStringList(box, 'items'), ['1', 'two']);
    });

    test('a raw list keeps its items for the caller to check', () async {
      expect(readList(box, 'items'), isEmpty);
      await box.put('items', {'not': 'a list'});
      expect(readList(box, 'items'), isEmpty);
      await box.put('items', [1, 'two']);
      expect(readList(box, 'items'), [1, 'two']);
    });
  });
}
