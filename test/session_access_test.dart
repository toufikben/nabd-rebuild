import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/features/sessions/data/sessions_data.dart';
import 'package:nabd/features/sessions/session_access.dart';

void main() {
  group('session access', () {
    test('a paid session is locked for a free user', () {
      expect(sessionIsLocked(isFree: false, isPro: false), isTrue);
    });

    test('a paid session opens for a Pro user', () {
      expect(sessionIsLocked(isFree: false, isPro: true), isFalse);
    });

    test('a free session opens for everyone', () {
      expect(sessionIsLocked(isFree: true, isPro: false), isFalse);
      expect(sessionIsLocked(isFree: true, isPro: true), isFalse);
    });

    test('the Pro buyer reaches every session in the catalogue', () {
      final paid = SessionsData.all.where((s) => !s.isFree).toList();
      expect(paid, isNotEmpty);
      for (final session in paid) {
        expect(sessionIsLocked(isFree: session.isFree, isPro: true), isFalse,
            reason: '${session.id} stayed locked for a Pro user');
      }
    });
  });
}
