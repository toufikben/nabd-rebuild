import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nabd/services/store_links.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('Android opens the Play page for this package', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final uri = const StoreLinks().manageSubscriptionsUri;
    expect(uri.host, 'play.google.com');
    expect(uri.queryParameters['package'], 'com.nabd.journal');
  });

  test('iOS opens the App Store subscription page', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final uri = const StoreLinks().manageSubscriptionsUri;
    expect(uri.host, 'apps.apple.com');
    expect(uri.path, '/account/subscriptions');
  });

  test('the link is https in every case', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      debugDefaultTargetPlatformOverride = platform;
      expect(const StoreLinks().manageSubscriptionsUri.scheme, 'https');
    }
  });
}
