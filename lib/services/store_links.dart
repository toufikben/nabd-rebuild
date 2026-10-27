import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where the store itself lets a subscriber cancel, change or restore the plan
/// they bought. Nothing in the app can cancel a purchase — only the store can —
/// so the Pro screen hands the user straight to that page instead of leaving
/// them to find it in the Play/App Store settings.
class StoreLinks {
  const StoreLinks();

  static const packageId = 'com.nabd.journal';

  /// The subscription page of the store this build came from.
  Uri get manageSubscriptionsUri {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Uri.parse('https://apps.apple.com/account/subscriptions');
    }
    return Uri.parse(
      'https://play.google.com/store/account/subscriptions?package=$packageId',
    );
  }

  /// Opens the page. Returns false when there is no browser to open it in, so
  /// the caller can say so instead of doing nothing.
  Future<bool> openManageSubscriptions() async {
    try {
      return await launchUrl(
        manageSubscriptionsUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
