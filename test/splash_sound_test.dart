import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/core/app_settings.dart';
import 'package:nabd/services/splash_service.dart';

void main() {
  test('the launch cue is the dawn chirp, not the old synthetic bell', () {
    expect(SplashService.signatureSound, 'splash_dawn');
    expect(AppSettings.resolveSoundFile('splash_dawn'), 'splash_dawn.wav');
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

  test('the splash always has a playable fallback', () {
    for (final id in const ['splash_dawn', 'splash_drop', 'tibetan_bowl']) {
      expect(AppSettings.resolveSoundFile(id), isNotNull, reason: id);
    }
  });
}
