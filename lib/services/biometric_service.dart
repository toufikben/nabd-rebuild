import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';

class AppLockPolicy {
  AppLockPolicy({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  bool _coldStartPending = true;
  DateTime? _backgroundedAt;

  void setLockEnabled(bool enabled) {
    if (!enabled) {
      _backgroundedAt = null;
    } else {
      markColdStartComplete();
    }
  }

  void updateLastActivity() {
    markColdStartComplete();
    _backgroundedAt = null;
  }

  void markBackgrounded() {
    _backgroundedAt ??= _now();
  }

  void clearBackgrounded() {
    _backgroundedAt = null;
  }

  void markColdStartComplete() {
    _coldStartPending = false;
  }

  bool shouldShowLock({
    required bool enabled,
    required int timeoutMinutes,
    bool coldStart = false,
  }) {
    if (!enabled) return false;
    if (coldStart) return _coldStartPending;

    final backgroundedAt = _backgroundedAt;
    if (backgroundedAt == null || timeoutMinutes <= 0) return false;
    return _now().difference(backgroundedAt) >=
        Duration(minutes: timeoutMinutes);
  }
}

/// BiometricService — قفل بالبصمة/الوجه.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  static final AppLockPolicy _policy = AppLockPolicy();

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
  Future<bool> authenticate({String reason = 'Unlock your journal'}) async {
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
    _policy.setLockEnabled(enabled);
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
    _policy.updateLastActivity();
  }

  /// يسجل بداية فترة الخلفية مرة واحدة حتى لا يتأثر القرار بإعادة البناء.
  void markBackgrounded() {
    _policy.markBackgrounded();
  }

  void clearBackgrounded() {
    _policy.clearBackgrounded();
  }

  /// ينهي شرط القفل الخاص بالتشغيل البارد بعد دخول المستخدم للتطبيق.
  void markColdStartComplete() {
    _policy.markColdStartComplete();
  }

  /// هل يجب عرض شاشة القفل؟
  bool shouldShowLock({bool coldStart = false}) {
    return _policy.shouldShowLock(
      enabled: isLockEnabled(),
      timeoutMinutes: getLockTimeout(),
      coldStart: coldStart,
    );
  }
}
