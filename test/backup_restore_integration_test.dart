import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:nabd/services/backup_service.dart';

Future<void> _openBoxes() async {
  for (final name in [
    'journal_entries',
    'settings',
    'moods',
    'tags',
    'garden',
  ]) {
    await Hive.openBox<dynamic>(name);
  }
}

void main() {
  test('creates encrypted nabd and restores replace/merge atomically',
      () async {
    final root = await Directory.systemTemp.createTemp('nabd_backup');
    final docs = Directory('${root.path}/docs')..createSync(recursive: true);
    final temp = Directory('${root.path}/temp')..createSync(recursive: true);
    addTearDown(() async {
      await Hive.close();
      await root.delete(recursive: true);
    });
    Hive.init('${root.path}/hive');
    await _openBoxes();

    await Hive.box('journal_entries').put('a', {
      'id': 'a',
      'title': 'A',
      'content': 'saved',
    });
    await Hive.box('settings').put('theme_mode', 'dark');
    await Hive.box('garden').put('seed', 'rose');
    final images = Directory('${docs.path}/images')..createSync();
    File('${images.path}/saved.jpg').writeAsBytesSync([1, 2, 3]);

    final service = BackupService(
      documentsDirectory: () async => docs,
      temporaryDirectory: () async => temp,
    );
    final backup = await service.createBackup(password: 'correct-password');
    expect(backup.path, endsWith('.nabd'));
    expect(await backup.length(), greaterThan(0));

    await Hive.box('journal_entries').clear();
    await Hive.box('journal_entries').put('c', {
      'id': 'c',
      'title': 'C',
      'content': 'current',
    });
    await File('${images.path}/current.jpg').writeAsBytes([4, 5, 6]);

    final wrong = await service.restoreBackup(
      backup.path,
      password: 'wrong-password',
      mode: RestoreMode.replace,
    );
    expect(wrong.ok, isFalse);
    expect(Hive.box('journal_entries').get('c')['content'], 'current');

    final replaced = await service.restoreBackup(
      backup.path,
      password: 'correct-password',
      mode: RestoreMode.replace,
    );
    expect(replaced.ok, isTrue);
    expect(Hive.box('journal_entries').containsKey('a'), isTrue);
    expect(Hive.box('journal_entries').containsKey('c'), isFalse);
    expect(await File('${images.path}/saved.jpg').exists(), isTrue);
    expect(await File('${images.path}/current.jpg').exists(), isFalse);

    await Hive.box('journal_entries').put('c', {
      'id': 'c',
      'title': 'C',
      'content': 'current',
    });
    final merged = await service.restoreBackup(
      backup.path,
      password: 'correct-password',
      mode: RestoreMode.merge,
    );
    expect(merged.ok, isTrue);
    expect(Hive.box('journal_entries').containsKey('a'), isTrue);
    expect(Hive.box('journal_entries').containsKey('c'), isTrue);
  });

  test('corrupt backup does not modify current Hive data', () async {
    final root = await Directory.systemTemp.createTemp('nabd_corrupt_backup');
    final docs = Directory('${root.path}/docs')..createSync(recursive: true);
    final temp = Directory('${root.path}/temp')..createSync(recursive: true);
    addTearDown(() async {
      await Hive.close();
      await root.delete(recursive: true);
    });
    Hive.init('${root.path}/hive');
    await _openBoxes();
    await Hive.box('journal_entries').put('current', {'id': 'current'});

    final service = BackupService(
      documentsDirectory: () async => docs,
      temporaryDirectory: () async => temp,
    );
    final backup = await service.createBackup(password: 'password');
    final bytes = await backup.readAsBytes();
    bytes[bytes.length - 1] ^= 1;
    final corrupt = File('${temp.path}/corrupt.nabd')..writeAsBytesSync(bytes);

    final result = await service.restoreBackup(
      corrupt.path,
      password: 'password',
      mode: RestoreMode.replace,
    );
    expect(result.ok, isFalse);
    expect(Hive.box('journal_entries').containsKey('current'), isTrue);
  });
}
