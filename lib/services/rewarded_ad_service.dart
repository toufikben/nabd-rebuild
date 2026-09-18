import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/admob_config.dart';

/// RewardedAdService — إعلانات مكافأة مع إدارة آمنة للمعرفات.
class RewardedAdService {
  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  /// تحميل إعلان مكافأة.
  Future<void> loadAd() async {
    if (_isLoading || _rewardedAd != null) return;

    // تحقق من جاهزية الإعدادات في Release
    if (!kDebugMode && !AdMobConfig.isProductionReady) {
      debugPrint('[RewardedAd] Production IDs missing — skipping load');
      return;
    }

    _isLoading = true;

    try {
      await RewardedAd.load(
        adUnitId: AdMobConfig.rewardedAdUnitId,
        request: const AdRequest(nonPersonalizedAds: false),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isLoading = false;
            _retryCount = 0;
            debugPrint('[RewardedAd] Loaded');
          },
          onAdFailedToLoad: (error) {
            _isLoading = false;
            _retryCount++;
            debugPrint('[RewardedAd] Failed: ${error.code} ${error.message}');

            if (_retryCount < _maxRetries) {
              final delay = Duration(seconds: 1 << _retryCount); // 2, 4, 8
              Future.delayed(delay, loadAd);
            }
          },
        ),
      );
    } catch (e) {
      _isLoading = false;
      debugPrint('[RewardedAd] Exception: $e');
    }
  }

  /// عرض إعلان.
  Future<bool> showAd({
    required VoidCallback onReward,
    VoidCallback? onDismiss,
    VoidCallback? onFailed,
  }) async {
    final ad = _rewardedAd;
    if (ad == null) {
      await loadAd();
      for (var i = 0; i < 20 && _rewardedAd == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
    final loadedAd = _rewardedAd;
    if (loadedAd == null) {
      onFailed?.call();
      return false;
    }

    var rewardDelivered = false;

    loadedAd.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        unawaited(loadAd());
        onDismiss?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onFailed?.call();
        unawaited(loadAd());
      },
    );

    loadedAd.show(onUserEarnedReward: (_, __) {
      if (rewardDelivered) return;
      rewardDelivered = true;
      onReward();
    });

    return true;
  }

  bool get isReady => _rewardedAd != null;

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
