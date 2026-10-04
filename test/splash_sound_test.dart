import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/app_settings.dart';
import 'package:nabd/core/l10n/app_strings.dart';
import 'package:nabd/features/sessions/data/sessions_data.dart';
import 'package:nabd/services/splash_service.dart';
import 'package:nabd/services/ui_sounds.dart';

void main() {
  test('the default launch cue is the warm breath the owner chose', () {
    expect(SplashService.signatureSound, 'splash_breath');
    expect(SplashService.choices.first, SplashService.signatureSound);
  });

  test('every launch sound offered in Settings is bundled and named', () {
    for (final id in SplashService.choices) {
      expect(AppSettings.resolveSoundFile(id), '$id.m4a', reason: id);
      expect(S.ar['sound.$id'], isNotNull, reason: id);
      expect(S.en['sound.$id'], isNotNull, reason: id);
    }
  });

  test('every declared sound really is bundled on disk', () {
    for (final file in AppSettings.availableSounds) {
      expect(
        File('assets/sounds/$file').existsSync(),
        isTrue,
        reason: '$file is listed in AppSettings.availableSounds but missing',
      );
    }
  });

  test('no sound ships without being declared', () {
    final bundled = Directory('assets/sounds')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .where((name) => !name.startsWith('.'))
        .toSet();
    expect(bundled.difference(AppSettings.availableSounds), isEmpty);
  });

  test('every session and moment sound exists', () {
    for (final session in SessionsData.all) {
      final asset = session.ambientSound;
      expect(asset, isNotNull, reason: session.id);
      expect(File(asset!).existsSync(), isTrue, reason: asset);
    }
    for (final sound in UiSound.values) {
      expect(File('assets/sounds/${sound.file}').existsSync(), isTrue,
          reason: sound.file);
    }
  });

  test('the splash always has a playable fallback', () {
    expect(AppSettings.resolveSoundFile('tibetan_bowl'), isNotNull);
  });
}
