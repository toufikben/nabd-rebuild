import 'package:flutter/foundation.dart';

/// AdMobConfig — إدارة معرفات AdMob بأمان.
///
/// الاستراتيجية:
///   • Debug → Test IDs (آمنة دائماً)
///   • Release → إنتاجية عبر --dart-define
///
/// للبناء الإنتاجي:
///   flutter build appbundle --release \
///     --dart-define=ADMOB_ANDROID_APP_ID=ca-app-pub-...~... \
///     --dart-define=ADMOB_ANDROID_REWARDED_ID=ca-app-pub-.../... \
///     --dart-define=ADMOB_IOS_REWARDED_ID=ca-app-pub-.../...
///
/// ⚠️ AdMob IDs ليست أسراراً — تظهر في التطبيق النهائي بطبيعتها.
///    الحماية الحقيقية: عدم وضع Server Keys أو Verification Secrets في الكود.
class AdMobConfig {
  // ═══════════════════════════════════════════════════════════════
  // Test IDs الرسمية من Google (آمنة للنشر أثناء التطوير)
  // المرجع: https://developers.google.com/admob/flutter/test-ads
  // ═══════════════════════════════════════════════════════════════
  static const String _androidTestRewarded =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _iosTestRewarded =
      'ca-app-pub-3940256099942544/1712485313';

  // ═══════════════════════════════════════════════════════════════
  // Production IDs (تُحقَن وقت البناء)
  // ═══════════════════════════════════════════════════════════════
  static const String _androidProdRewarded =
      String.fromEnvironment('ADMOB_ANDROID_REWARDED_ID');
  static const String _iosProdRewarded =
      String.fromEnvironment('ADMOB_IOS_REWARDED_ID');

  /// AdMob App ID — يوضع في AndroidManifest.xml و Info.plist.
  /// المرجع منفصل تماماً عن Ad Unit IDs (يستخدم `~` بدل `/`).
  static const String _androidAppId =
      String.fromEnvironment('ADMOB_ANDROID_APP_ID');
  static const String _iosAppId =
      String.fromEnvironment('ADMOB_IOS_APP_ID');

  /// الحصول على Rewarded Ad Unit ID المناسب.
  static String get rewardedAdUnitId {
    if (kDebugMode) {
      return defaultTargetPlatform == TargetPlatform.iOS
          ? _iosTestRewarded
          : _androidTestRewarded;
    }

    // في Release: استخدم الإنتاجي أو عطّل تحميل الإعلان
    final prod = defaultTargetPlatform == TargetPlatform.iOS
        ? _iosProdRewarded
        : _androidProdRewarded;

    if (!_isValidId(prod)) return '';
    return prod;
  }

  static bool _isValidId(String value) =>
      value.isNotEmpty && !value.contains('XXXX');

  /// AdMob App ID للاستخدام في Native config (مرجع فقط).
  static String get androidAppId => _androidAppId;
  static String get iosAppId => _iosAppId;

  /// هل الإعدادات الإنتاجية جاهزة؟
  static bool get isProductionReady {
    if (kDebugMode) return true;
    final rewarded = defaultTargetPlatform == TargetPlatform.iOS
        ? _iosProdRewarded
        : _androidProdRewarded;
    final appId = defaultTargetPlatform == TargetPlatform.iOS
        ? _iosAppId
        : _androidAppId;
    return _isValidId(rewarded) && _isValidId(appId);
  }
}
