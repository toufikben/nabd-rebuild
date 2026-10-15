import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:path_provider/path_provider.dart';

/// DIAGNOSTIC BUILD ONLY (branch diag/entitlement-launch — never merge).
/// logcat on this OEM rotates the `flutter` tag away within a minute, so the
/// launch path is mirrored to an app-specific external file that adb can read
/// without root.
class _Diag {
  _Diag._();

  static Directory? _dir;

  static Future<void> log(String message) async {
    final line = '[NABDDIAG] pid=${Platform.pid} '
        '${DateTime.now().toIso8601String()} $message';
    debugPrint(line);
    try {
      if (!Platform.isAndroid) return;
      _dir ??= await getExternalStorageDirectory();
      final dir = _dir;
      if (dir == null) return;
      await File('${dir.path}/nabd_diag.txt')
          .writeAsString('$line\n', mode: FileMode.append, flush: true);
    } catch (error) {
      debugPrint('[NABDDIAG] sink failed: $error');
    }
  }
}

/// The app never derives subscription expiry locally. Subscription entitlement
/// stays `subscriptionUnverified` until a trusted backend confirms it;
/// lifetime is granted only after an actual store callback.
enum EntitlementStatus {
  unknown,
  pending,
  lifetime,
  subscriptionActive,
  subscriptionUnverified,
  expired,
  error,
}

/// Result of a server-side entitlement check.
class VerificationResult {
  const VerificationResult({
    required this.status,
    this.errorMessage,
    this.expiryDate,
  });

  final EntitlementStatus status;
  final String? errorMessage;
  final DateTime? expiryDate;

  /// Pro is granted only when the backend explicitly reports an active
  /// subscription or a lifetime entitlement.
  bool get isPro =>
      status == EntitlementStatus.subscriptionActive ||
      status == EntitlementStatus.lifetime;

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    final raw = json['status'] as String?;
    final expiry = json['expiryDate'] == null
        ? null
        : DateTime.tryParse(json['expiryDate'] as String);
    final errorMessage = json['errorMessage'] as String?;

    switch (raw) {
      case 'lifetime':
        return VerificationResult(
          status: EntitlementStatus.lifetime,
          errorMessage: errorMessage,
        );
      case 'active':
        if (expiry != null && expiry.isBefore(DateTime.now())) {
          return VerificationResult(
            status: EntitlementStatus.expired,
            expiryDate: expiry,
            errorMessage: errorMessage,
          );
        }
        return VerificationResult(
          status: EntitlementStatus.subscriptionActive,
          expiryDate: expiry,
          errorMessage: errorMessage,
        );
      case 'expired':
        return VerificationResult(
          status: EntitlementStatus.expired,
          expiryDate: expiry,
          errorMessage: errorMessage,
        );
      case 'unverified':
        return VerificationResult(
          status: EntitlementStatus.subscriptionUnverified,
          errorMessage: errorMessage,
        );
      case 'error':
        return VerificationResult(
          status: EntitlementStatus.error,
          errorMessage: errorMessage,
        );
      default:
        return VerificationResult(
          status: EntitlementStatus.unknown,
          errorMessage: errorMessage,
        );
    }
  }
}

/// Trusted backend that validates store purchases.
class SubscriptionVerificationConfig {
  const SubscriptionVerificationConfig._();

  static const backendUrl = String.fromEnvironment(
    'SUBSCRIPTION_VERIFICATION_BACKEND_URL',
  );

  /// A backend of our own, or RevenueCat acting as one.
  static bool get isConfigured =>
      backendUrl.trim().isNotEmpty || RevenueCatConfig.isConfigured;
}

/// RevenueCat, used only as the subscription verification backend through
/// its REST API: the app keeps buying through `in_app_purchase`, and
/// RevenueCat checks each purchase token with Google and reports whether the
/// entitlement is active and until when. No RevenueCat SDK, so there is one
/// billing client in the app.
class RevenueCatConfig {
  const RevenueCatConfig._();

  /// The project's public Google Play SDK key (`goog_...`). Public by design:
  /// it can only post receipts and read entitlements for an app user id.
  static const apiKey = String.fromEnvironment('REVENUECAT_ANDROID_KEY');

  /// The entitlement that means Pro in the RevenueCat dashboard.
  static const entitlement = String.fromEnvironment(
    'REVENUECAT_ENTITLEMENT',
    defaultValue: 'pro',
  );

  static const receiptsUrl = 'https://api.revenuecat.com/v1/receipts';

  /// A secret key (`sk_`) must never ship in an app; refusing it here keeps a
  /// misconfigured build from leaking one.
  static bool get isConfigured {
    final key = apiKey.trim();
    return key.isNotEmpty && !key.startsWith('sk_');
  }
}

/// Reads RevenueCat's subscriber answer for [entitlement].
///
/// An entitlement that is missing altogether is a configuration problem (the
/// product is not attached to it), not a verdict, so it never takes Pro away.
VerificationResult revenueCatVerdict(
  Map<String, dynamic> body, {
  required String entitlement,
  required DateTime now,
}) {
  final subscriber = body['subscriber'];
  final entitlements = subscriber is Map ? subscriber['entitlements'] : null;
  final granted = entitlements is Map ? entitlements[entitlement] : null;
  if (granted is! Map) {
    return VerificationResult(
      status: EntitlementStatus.error,
      errorMessage:
          'RevenueCat has no "$entitlement" entitlement for this purchase.',
    );
  }
  DateTime? read(String key) {
    final value = granted[key];
    return value is String ? DateTime.tryParse(value)?.toLocal() : null;
  }

  final expires = read('expires_date');
  if (expires == null) {
    // Never expires: a non-consumable attached to the entitlement.
    return const VerificationResult(status: EntitlementStatus.lifetime);
  }
  final grace = read('grace_period_expires_date');
  final until = grace != null && grace.isAfter(expires) ? grace : expires;
  if (until.isAfter(now)) {
    return VerificationResult(
      status: EntitlementStatus.subscriptionActive,
      expiryDate: until,
    );
  }
  return VerificationResult(
    status: EntitlementStatus.expired,
    expiryDate: until,
  );
}

/// Asks the trusted backend whether a purchase grants entitlement.
///
/// The client never trusts the store payload on its own, and it never invents
/// an expiry date. When no backend is configured the subscription stays
/// unverified, so Pro is not granted.
Future<VerificationResult> verifySubscription({
  required String purchaseToken,
  required String productId,
  String? appUserId,
}) async {
  final backendUrl = SubscriptionVerificationConfig.backendUrl.trim();
  if (backendUrl.isEmpty && !RevenueCatConfig.isConfigured) {
    return const VerificationResult(
      status: EntitlementStatus.subscriptionUnverified,
      errorMessage:
          'Subscription verification backend is not configured for this build.',
    );
  }
  if (purchaseToken.isEmpty) {
    return const VerificationResult(
      status: EntitlementStatus.error,
      errorMessage: 'Purchase token is empty; verification was not attempted.',
    );
  }

  try {
    if (backendUrl.isEmpty) {
      return await _postRevenueCatReceipt(
        appUserId: appUserId ?? await RevenueCatUser.id(),
        purchaseToken: purchaseToken,
        productId: productId,
      );
    }
    return await _postVerificationRequest(
      backendUrl: backendUrl,
      purchaseToken: purchaseToken,
      productId: productId,
    );
  } on TimeoutException {
    return const VerificationResult(
      status: EntitlementStatus.subscriptionUnverified,
      errorMessage: 'Verification timed out; entitlement was not granted.',
    );
  } on SocketException {
    return const VerificationResult(
      status: EntitlementStatus.subscriptionUnverified,
      errorMessage: 'No network connection; entitlement was not granted.',
    );
  } on FormatException catch (error) {
    return VerificationResult(
      status: EntitlementStatus.error,
      errorMessage: 'Malformed verification response: ${error.message}',
    );
  } on HttpException catch (error) {
    return VerificationResult(
      status: EntitlementStatus.error,
      errorMessage: 'Verification transport error: ${error.message}',
    );
  } catch (error) {
    return VerificationResult(
      status: EntitlementStatus.error,
      errorMessage: 'Verification error: $error',
    );
  }
}

/// The anonymous id RevenueCat files purchases under. Random, made on this
/// phone, kept in the keystore; it identifies nothing about the person.
class RevenueCatUser {
  const RevenueCatUser._();

  static const _key = 'nabd_revenuecat_user';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<String> id() async {
    final stored = await _storage.read(key: _key);
    if (stored != null && stored.isNotEmpty) return stored;
    final random = Random.secure();
    final fresh = 'nabd_${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    await _storage.write(key: _key, value: fresh);
    return fresh;
  }
}

/// Posts the Google Play purchase token to RevenueCat, which checks it with
/// Google and answers with the subscriber's entitlements.
Future<VerificationResult> _postRevenueCatReceipt({
  required String appUserId,
  required String purchaseToken,
  required String productId,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client
        .postUrl(Uri.parse(RevenueCatConfig.receiptsUrl))
        .timeout(const Duration(seconds: 15));
    request.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.authorizationHeader,
          'Bearer ${RevenueCatConfig.apiKey.trim()}')
      ..set('X-Platform', 'android');
    request.write(jsonEncode({
      'app_user_id': appUserId,
      'fetch_token': purchaseToken,
      'product_id': productId,
    }));
    final response = await request.close().timeout(const Duration(seconds: 20));
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode != 200 && response.statusCode != 201) {
      return VerificationResult(
        status: EntitlementStatus.error,
        errorMessage: 'RevenueCat answered HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return const VerificationResult(
        status: EntitlementStatus.error,
        errorMessage: 'RevenueCat response was not a JSON object.',
      );
    }
    return revenueCatVerdict(
      decoded,
      entitlement: RevenueCatConfig.entitlement,
      now: DateTime.now(),
    );
  } finally {
    client.close(force: true);
  }
}

/// Performs the single HTTPS round trip and always releases the socket.
Future<VerificationResult> _postVerificationRequest({
  required String backendUrl,
  required String purchaseToken,
  required String productId,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client
        .postUrl(Uri.parse(backendUrl))
        .timeout(const Duration(seconds: 15));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({
      'purchaseToken': purchaseToken,
      'productId': productId,
      'platform': defaultTargetPlatform.name,
    }));

    final response = await request.close().timeout(const Duration(seconds: 20));
    final body = await utf8.decoder.bind(response).join();
    if (response.statusCode != 200) {
      return VerificationResult(
        status: EntitlementStatus.error,
        errorMessage: 'Verification failed with HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return const VerificationResult(
        status: EntitlementStatus.error,
        errorMessage: 'Verification response was not a JSON object.',
      );
    }
    return VerificationResult.fromJson(decoded);
  } finally {
    client.close(force: true);
  }
}

class MonetizationConfig {
  const MonetizationConfig._();

  // CI passes these even when the variable is unset, as an empty string,
  // which would otherwise replace the default id.
  static const _monthlyIdEnv = String.fromEnvironment('NABD_PRO_MONTHLY_ID');
  static const _yearlyIdEnv = String.fromEnvironment('NABD_PRO_YEARLY_ID');
  static const _lifetimeIdEnv = String.fromEnvironment('NABD_LIFETIME_ID');

  static const monthlyId =
      _monthlyIdEnv == '' ? 'nabd_pro_monthly' : _monthlyIdEnv;
  static const yearlyId = _yearlyIdEnv == '' ? 'nabd_pro_yearly' : _yearlyIdEnv;
  static const lifetimeId =
      _lifetimeIdEnv == '' ? 'nabd_lifetime' : _lifetimeIdEnv;
  static const productionConfigured = bool.fromEnvironment(
    'NABD_PRODUCTION_CONFIGURED',
    defaultValue: false,
  );

  /// Subscriptions can only grant Pro through the verification backend, so
  /// they are not offered for sale until that backend is configured. Selling
  /// a plan that cannot unlock anything is what the store policies forbid.
  static bool get subscriptionsEnabled =>
      SubscriptionVerificationConfig.isConfigured;

  /// The products the paywall may sell in this build.
  static Set<String> get productIds => {
        if (subscriptionsEnabled) ...{monthlyId, yearlyId},
        lifetimeId,
      };

  /// Every product the app knows, so an older subscription bought before the
  /// plans were hidden is still recognised when the store restores it.
  static Set<String> get allProductIds => {monthlyId, yearlyId, lifetimeId};

  static bool get isReady =>
      monthlyId.isNotEmpty && yearlyId.isNotEmpty && lifetimeId.isNotEmpty;
}

/// The entitlement as last confirmed by the store or the backend, kept so Pro
/// survives an app restart without waiting for the store to answer.
class CachedEntitlement {
  const CachedEntitlement({this.lifetime = false, this.proExpiry});

  final bool lifetime;
  final DateTime? proExpiry;

  bool isActive(DateTime now) =>
      lifetime || (proExpiry != null && proExpiry!.isAfter(now));

  Map<String, dynamic> toJson() => {
        'lifetime': lifetime,
        'proExpiry': proExpiry?.toIso8601String(),
      };

  static CachedEntitlement? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final expiry = decoded['proExpiry'];
      return CachedEntitlement(
        lifetime: decoded['lifetime'] == true,
        proExpiry: expiry is String ? DateTime.tryParse(expiry) : null,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Where the entitlement cache lives. Behind an interface so the policy can be
/// tested without a platform channel.
abstract class EntitlementStore {
  Future<CachedEntitlement?> read();

  Future<void> write(CachedEntitlement entitlement);
}

/// The OS keystore, not Hive: the cache must stay out of `.nabd` backups and
/// survive Delete All, exactly like the entitlement keys the backup filters.
class SecureEntitlementStore implements EntitlementStore {
  const SecureEntitlementStore();

  static const _key = 'nabd_entitlement';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  Future<CachedEntitlement?> read() async {
    final raw = await _storage.read(key: _key);
    // DIAGNOSTIC ONLY: is the cache actually present at launch?
    await _Diag.log('store.read raw=${raw ?? 'NULL'}');
    return CachedEntitlement.tryParse(raw);
  }

  @override
  Future<void> write(CachedEntitlement entitlement) async {
    final value = jsonEncode(entitlement.toJson());
    await _storage.write(key: _key, value: value);
    // DIAGNOSTIC ONLY: does the platform store hand the value back?
    final back = await _storage.read(key: _key);
    await _Diag.log('store.write value=$value '
        'readBack=${back ?? 'NULL'}');
  }
}

class EntitlementService {
  const EntitlementService();

  /// Maps a store callback to an entitlement status. Subscription products are
  /// never marked Pro here; they must pass [verifySubscription] first.
  EntitlementStatus statusFor(PurchaseDetails purchase) {
    if (purchase.status == PurchaseStatus.pending) {
      return EntitlementStatus.pending;
    }
    if (purchase.status == PurchaseStatus.error) {
      return EntitlementStatus.error;
    }
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return EntitlementStatus.unknown;
    }
    if (purchase.productID == MonetizationConfig.lifetimeId) {
      return EntitlementStatus.lifetime;
    }
    if (MonetizationConfig.allProductIds.contains(purchase.productID)) {
      return EntitlementStatus.subscriptionUnverified;
    }
    return EntitlementStatus.error;
  }
}

class MonetizationService extends StateNotifier<MonetizationState> {
  MonetizationService({EntitlementStore store = const SecureEntitlementStore()})
      : _store = store,
        super(const MonetizationState()) {
    _init();
  }

  /// A service frozen at [state] that never talks to the store, for tests.
  @visibleForTesting
  MonetizationService.preset(super.state)
      : _store = const SecureEntitlementStore();

  static final InAppPurchase _iap = InAppPurchase.instance;
  static const String proMonthlyId = MonetizationConfig.monthlyId;
  static const String proYearlyId = MonetizationConfig.yearlyId;
  static const String lifetimeId = MonetizationConfig.lifetimeId;

  /// How long a restore may stay silent before the paywall stops spinning.
  /// The store sends nothing at all when there is nothing to restore.
  static const restoreTimeout = Duration(seconds: 15);

  /// A verified subscription without an expiry from the backend is trusted for
  /// this long, then it has to be confirmed again.
  static const _unknownExpiryGrace = Duration(days: 3);

  final EntitlementStore _store;
  final EntitlementService _entitlements = const EntitlementService();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Timer? _restoreTimer;

  Future<void> _init() async {
    // DIAGNOSTIC ONLY
    await _Diag.log('init.start release=$kReleaseMode '
        'prod=${MonetizationConfig.productionConfigured} '
        'lifetimeId=${MonetizationConfig.lifetimeId} '
        'subs=${MonetizationConfig.subscriptionsEnabled}');
    await _loadCachedEntitlement();
    if (!mounted) return;
    // DIAGNOSTIC ONLY
    await _Diag.log('after.cache isPro=${state.isPro} '
        'isLifetime=${state.isLifetime} status=${state.entitlementStatus}');
    if (kReleaseMode && !MonetizationConfig.productionConfigured) {
      await _Diag.log('init.abort killSwitch'); // DIAGNOSTIC ONLY
      state = state.copyWith(
        error: 'Purchases are not configured for this release.',
        entitlementStatus: state.isPro ? null : EntitlementStatus.error,
      );
      return;
    }
    final available = await _iap.isAvailable();
    // DIAGNOSTIC ONLY
    await _Diag.log('billing.available=$available mounted=$mounted');
    if (!mounted) return;
    if (!available) return;
    state = state.copyWith(storeAvailable: true);
    _purchaseSub = _iap.purchaseStream.listen(_onPurchaseUpdate);
    await _loadProducts();
    // Re-confirm what the store knows without showing a spinner, so a
    // purchase made on another device or a refund is picked up on launch.
    await _Diag.log('silent.restore.calling'); // DIAGNOSTIC ONLY
    try {
      await _iap.restorePurchases();
      await _Diag.log('silent.restore.returned'); // DIAGNOSTIC ONLY
    } catch (error) {
      // DIAGNOSTIC ONLY
      await _Diag.log('silent.restore.threw $error');
      debugPrint('Silent restore failed: $error');
    }
  }

  /// Pro is granted from the cache straight away; the store only ever adds to
  /// it or confirms it, so a slow or offline store never locks a buyer out.
  Future<void> _loadCachedEntitlement() async {
    try {
      final cached = await _store.read();
      // DIAGNOSTIC ONLY
      await _Diag.log('cache.parsed '
          'cached=${cached == null ? 'null' : 'lifetime=${cached.lifetime}'} '
          'active=${cached?.isActive(DateTime.now())} mounted=$mounted');
      if (cached == null || !mounted) return;
      if (!cached.isActive(DateTime.now())) return;
      state = state.copyWith(
        isPro: true,
        isLifetime: cached.lifetime,
        proExpiry: cached.proExpiry,
        entitlementStatus: cached.lifetime
            ? EntitlementStatus.lifetime
            : EntitlementStatus.subscriptionActive,
      );
    } catch (error) {
      // DIAGNOSTIC ONLY
      await _Diag.log('cache.read.threw $error');
      debugPrint('Entitlement cache unreadable: $error');
    }
  }

  Future<void> _saveEntitlement() async {
    // DIAGNOSTIC ONLY
    await _Diag.log('cache.write.requested isPro=${state.isPro} '
        'isLifetime=${state.isLifetime} proExpiry=${state.proExpiry}');
    try {
      await _store.write(CachedEntitlement(
        lifetime: state.isLifetime,
        proExpiry: state.isLifetime ? null : state.proExpiry,
      ));
    } catch (error) {
      // DIAGNOSTIC ONLY
      await _Diag.log('cache.write.threw $error');
      debugPrint('Entitlement cache not written: $error');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _iap
          .queryProductDetails(MonetizationConfig.productIds)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      state = state.copyWith(
        products: response.productDetails,
        productsLoaded: true,
        error: response.error?.message,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        productsLoaded: true,
        error: error is TimeoutException
            ? 'The store did not answer in time.'
            : '$error',
        entitlementStatus: state.isPro ? null : EntitlementStatus.error,
      );
    }
  }

  /// Re-runs the store lookup so the paywall can offer a retry instead of an
  /// endless spinner when the catalog came back empty.
  Future<void> retryLoadProducts() => _loadProducts();

  Future<void> buy(ProductDetails product) async {
    if (kReleaseMode && !MonetizationConfig.productionConfigured) {
      state = state.copyWith(
        error: 'Purchases are not configured for this release.',
        entitlementStatus: EntitlementStatus.error,
      );
      return;
    }
    if (!MonetizationConfig.productIds.contains(product.id)) {
      state = state.copyWith(
        error: 'Unknown product',
        entitlementStatus: EntitlementStatus.error,
      );
      return;
    }
    state = state.copyWith(
      purchasing: true,
      error: null,
      entitlementStatus: EntitlementStatus.pending,
    );
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        purchasing: false,
        error: '$error',
        entitlementStatus: EntitlementStatus.error,
      );
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(
      restoring: true,
      nothingRestored: false,
      error: null,
      entitlementStatus: EntitlementStatus.pending,
    );
    _restoreTimer?.cancel();
    _restoreTimer = Timer(restoreTimeout, () {
      if (!mounted || !state.restoring) return;
      state = state.copyWith(
        restoring: false,
        nothingRestored: true,
        entitlementStatus: state.isPro
            ? (state.isLifetime
                ? EntitlementStatus.lifetime
                : EntitlementStatus.subscriptionActive)
            : EntitlementStatus.unknown,
      );
    });
    try {
      await _iap.restorePurchases();
      await _Diag.log('manual.restore.returned'); // DIAGNOSTIC ONLY
    } catch (error) {
      await _Diag.log('manual.restore.threw $error'); // DIAGNOSTIC ONLY
      _restoreTimer?.cancel();
      if (!mounted) return;
      state = state.copyWith(
        restoring: false,
        error: '$error',
        entitlementStatus: EntitlementStatus.error,
      );
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    // DIAGNOSTIC ONLY
    unawaited(_Diag.log('stream.callback count=${purchases.length} '
        'mounted=$mounted isProBefore=${state.isPro}'));
    if (!mounted) return;
    if (purchases.isNotEmpty) _restoreTimer?.cancel();
    for (final purchase in purchases) {
      final status = _entitlements.statusFor(purchase);
      // DIAGNOSTIC ONLY: ids and states, never the purchase token.
      unawaited(_Diag.log('stream.purchase id=${purchase.productID} '
          'orderId=${purchase.purchaseID} status=${purchase.status} '
          'pendingComplete=${purchase.pendingCompletePurchase} '
          'mapped=$status'));
      if (status == EntitlementStatus.lifetime) {
        state = state.copyWith(
          isPro: true,
          isLifetime: true,
          purchasing: false,
          restoring: false,
          entitlementStatus: status,
          error: null,
        );
        unawaited(_saveEntitlement());
      } else if (status == EntitlementStatus.subscriptionUnverified) {
        unawaited(_verifySubscriptionPurchase(purchase));
      } else {
        state = state.copyWith(
          purchasing: false,
          restoring: false,
          entitlementStatus: status,
          error: status == EntitlementStatus.error
              ? purchase.error?.message
              : null,
        );
      }
      if (purchase.pendingCompletePurchase) {
        // DIAGNOSTIC ONLY: a failed acknowledgement is how Play later
        // auto-refunds a purchase, so surface it instead of dropping it.
        unawaited(_iap.completePurchase(purchase).then((_) {
          unawaited(_Diag.log('ack.ok id=${purchase.productID}'));
        }).catchError((error) {
          unawaited(_Diag.log('ack.failed id=${purchase.productID} '
              'error=$error'));
        }));
      }
    }
  }

  /// Sends the purchase to the trusted backend and applies the verdict.
  Future<void> _verifySubscriptionPurchase(PurchaseDetails purchase) async {
    state = state.copyWith(
      purchasing: false,
      restoring: false,
      entitlementStatus: EntitlementStatus.pending,
      error: null,
    );

    final serverToken = purchase.verificationData.serverVerificationData;
    if (serverToken.isEmpty) {
      if (!mounted) return;
      state = state.copyWith(
        purchasing: false,
        restoring: false,
        entitlementStatus: EntitlementStatus.subscriptionUnverified,
        error: 'The store did not return a server verification token.',
      );
      return;
    }

    final result = await verifySubscription(
      purchaseToken: serverToken,
      productId: purchase.productID,
    );
    if (!mounted) return;

    // Network or backend trouble is not a verdict: Pro that the cache already
    // granted stays, and only the status and the message change.
    final isVerdict = result.status == EntitlementStatus.subscriptionActive ||
        result.status == EntitlementStatus.lifetime ||
        result.status == EntitlementStatus.expired;
    if (!isVerdict) {
      state = state.copyWith(
        entitlementStatus: state.isPro ? null : result.status,
        error: state.isPro ? null : result.errorMessage,
      );
      return;
    }

    // A lifetime purchase already owned is never taken away by the verdict on
    // an unrelated subscription.
    final keepsLifetime = state.isLifetime;
    final verdictExpiry = result.isPro
        ? (result.expiryDate ?? DateTime.now().add(_unknownExpiryGrace))
        : null;
    state = state.copyWith(
      isPro: result.isPro || keepsLifetime,
      isLifetime: keepsLifetime || result.status == EntitlementStatus.lifetime,
      proExpiry: verdictExpiry,
      clearProExpiry: verdictExpiry == null,
      entitlementStatus:
          keepsLifetime ? EntitlementStatus.lifetime : result.status,
      error: result.isPro || keepsLifetime ? null : result.errorMessage,
    );
    await _saveEntitlement();
  }

  bool get isProActive => state.isPro;

  /// What the yearly plan saves against twelve months, in whole percent,
  /// from the store's own prices. Null when either price is missing, the
  /// currencies differ, or there is no saving to speak of.
  int? yearlySavingPercent() =>
      savingPercent(_product(proMonthlyId), _product(proYearlyId));

  @visibleForTesting
  static int? savingPercent(ProductDetails? monthly, ProductDetails? yearly) {
    if (monthly == null || yearly == null) return null;
    if (monthly.currencyCode != yearly.currencyCode) return null;
    if (monthly.rawPrice <= 0 || yearly.rawPrice <= 0) return null;
    final percent = ((1 - yearly.rawPrice / (monthly.rawPrice * 12)) * 100)
        .floor();
    return percent >= 5 ? percent : null;
  }

  ProductDetails? _product(String productId) {
    for (final item in state.products) {
      if (item.id == productId) return item;
    }
    return null;
  }

  String priceFor(String productId) {
    for (final item in state.products) {
      if (item.id == productId) return item.price;
    }
    return '';
  }

  @override
  void dispose() {
    _restoreTimer?.cancel();
    _purchaseSub?.cancel();
    super.dispose();
  }
}

class MonetizationState {
  const MonetizationState({
    this.storeAvailable = false,
    this.productsLoaded = false,
    this.isPro = false,
    this.isLifetime = false,
    this.proExpiry,
    this.purchasing = false,
    this.restoring = false,
    this.nothingRestored = false,
    this.products = const [],
    this.error,
    this.entitlementStatus = EntitlementStatus.unknown,
  });

  final bool storeAvailable;
  final bool productsLoaded;
  final bool isPro;
  final bool isLifetime;
  final DateTime? proExpiry;
  final bool purchasing;
  final bool restoring;

  /// True after a restore that the store answered with nothing to restore.
  final bool nothingRestored;
  final List<ProductDetails> products;
  final String? error;
  final EntitlementStatus entitlementStatus;

  MonetizationState copyWith({
    bool? storeAvailable,
    bool? productsLoaded,
    bool? isPro,
    bool? isLifetime,
    DateTime? proExpiry,
    bool clearProExpiry = false,
    bool? purchasing,
    bool? restoring,
    bool? nothingRestored,
    List<ProductDetails>? products,
    String? error,
    EntitlementStatus? entitlementStatus,
  }) =>
      MonetizationState(
        storeAvailable: storeAvailable ?? this.storeAvailable,
        productsLoaded: productsLoaded ?? this.productsLoaded,
        isPro: isPro ?? this.isPro,
        isLifetime: isLifetime ?? this.isLifetime,
        proExpiry: clearProExpiry ? null : (proExpiry ?? this.proExpiry),
        purchasing: purchasing ?? this.purchasing,
        restoring: restoring ?? this.restoring,
        nothingRestored: nothingRestored ?? this.nothingRestored,
        products: products ?? this.products,
        error: error,
        entitlementStatus: entitlementStatus ?? this.entitlementStatus,
      );
}

final monetizationProvider =
    StateNotifierProvider<MonetizationService, MonetizationState>(
  (_) => MonetizationService(),
);
