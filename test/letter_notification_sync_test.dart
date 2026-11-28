import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/notification_service.dart';

void main() {
  group('letter announcements', () {
    test('one notification id per letter, stable across launches', () {
      final first = NotificationService.letterNotificationId('letter-42');
      final second = NotificationService.letterNotificationId('letter-42');
      final other = NotificationService.letterNotificationId('letter-43');

      expect(first, second);
      expect(first, isNot(other));
      expect(first, greaterThanOrEqualTo(1000));
    });

    test('the boot path reconciles letter notifications', () {
      // A letter can be deleted or restored from a backup without going
      // through its screen. The screen alone syncing the OS schedule meant a
      // deleted letter kept announcing itself, and a restored one never did.
      final main = File('lib/main.dart').readAsStringSync();
      expect(main, contains('NotificationService.syncLetterUnlocks'));
    });
  });
}
