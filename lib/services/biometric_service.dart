import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';

/// BiometricService — قفل بالبصمة/الوجه.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// هل الجهاز يدعم المصادقة الحيوية؟
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// عرض نافذة المصادقة.
  Future<bool> authenticate({
    String reason = 'Unlock your journal',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  /// هل القفل مُفعّل؟
  bool isLockEnabled() {
    return Hive.box('settings').get('lock_enabled', defaultValue: false)
        as bool;
  }

  /// تفعيل/تعطيل القفل.
  Future<void> setLockEnabled(bool enabled) async {
    await Hive.box('settings').put('lock_enabled', enabled);
  }

  /// قفل بعد فترة عدم استخدام (بالدقائق).
  int getLockTimeout() {
    return Hive.box('settings').get('lock_timeout_minutes', defaultValue: 5)
        as int;
  }

  Future<void> setLockTimeout(int minutes) async {
    await Hive.box('settings').put('lock_timeout_minutes', minutes);
  }

  /// آخر نشاط.
  DateTime? getLastActivity() {
    final s = Hive.box('settings').get('last_activity') as String?;
    return s == null ? null : DateTime.tryParse(s);
  }

  Future<void> updateLastActivity() async {
    await Hive.box('settings')
        .put('last_activity', DateTime.now().toIso8601String());
  }

  /// هل يجب عرض شاشة القفل؟
  bool shouldShowLock() {
    if (!isLockEnabled()) return false;
    final last = getLastActivity();
    if (last == null) return true;
    return DateTime.now().difference(last).inMinutes >= getLockTimeout();
  }
}
