import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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

  static bool get isConfigured => backendUrl.trim().isNotEmpty;
}

/// Asks the trusted backend whether a purchase grants entitlement.
///
/// The client never trusts the store payload on its own, and it never invents
/// an expiry date. When no backend is configured the subscription stays
/// unverified, so Pro is not granted.
Future<VerificationResult> verifySubscription({
  required String purchaseToken,
  required String productId,
}) async {
  final backendUrl = SubscriptionVerificationConfig.backendUrl.trim();
  if (backendUrl.isEmpty) {
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

  static const monthlyId = String.fromEnvironment(
    'NABD_PRO_MONTHLY_ID',
    defaultValue: 'nabd_pro_monthly',
  );
  static const yearlyId = String.fromEnvironment(
    'NABD_PRO_YEARLY_ID',
    defaultValue: 'nabd_pro_yearly',
  );
  static const lifetimeId = String.fromEnvironment(
    'NABD_LIFETIME_ID',
    defaultValue: 'nabd_lifetime',
  );
  static const productionConfigured = bool.fromEnvironment(
    'NABD_PRODUCTION_CONFIGURED',
    defaultValue: false,
  );

  static Set<String> get productIds => {monthlyId, yearlyId, lifetimeId};

  static bool get isReady =>
      monthlyId.isNotEmpty && yearlyId.isNotEmpty && lifetimeId.isNotEmpty;
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
    if (MonetizationConfig.productIds.contains(purchase.productID)) {
      return EntitlementStatus.subscriptionUnverified;
    }
    return EntitlementStatus.error;
  }
}

class MonetizationService extends StateNotifier<MonetizationState> {
  MonetizationService() : super(const MonetizationState()) {
    _init();
  }

  static final InAppPurchase _iap = InAppPurchase.instance;
  static const String proMonthlyId = MonetizationConfig.monthlyId;
  static const String proYearlyId = MonetizationConfig.yearlyId;
  static const String lifetimeId = MonetizationConfig.lifetimeId;

  final EntitlementService _entitlements = const EntitlementService();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  Future<void> _init() async {
    if (kReleaseMode && !MonetizationConfig.productionConfigured) {
      if (mounted) {
        state = state.copyWith(
          error: 'Purchases are not configured for this release.',
          entitlementStatus: EntitlementStatus.error,
        );
      }
      return;
    }
    final available = await _iap.isAvailable();
    if (!mounted) return;
    if (!available) return;
    state = state.copyWith(storeAvailable: true);
    _purchaseSub = _iap.purchaseStream.listen(_onPurchaseUpdate);
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response =
          await _iap.queryProductDetails(MonetizationConfig.productIds);
      if (!mounted) return;
      state = state.copyWith(
        products: response.productDetails,
        error: response.error?.message,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        error: '$error',
        entitlementStatus: EntitlementStatus.error,
      );
    }
  }

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
      error: null,
      entitlementStatus: EntitlementStatus.pending,
    );
    try {
      await _iap.restorePurchases();
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(
        restoring: false,
        error: '$error',
        entitlementStatus: EntitlementStatus.error,
      );
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    if (!mounted) return;
    for (final purchase in purchases) {
      final status = _entitlements.statusFor(purchase);
      if (status == EntitlementStatus.lifetime) {
        state = state.copyWith(
          isPro: true,
          isLifetime: true,
          purchasing: false,
          restoring: false,
          entitlementStatus: status,
          error: null,
        );
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
        unawaited(_iap.completePurchase(purchase));
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

    final result = await verifySubscription(
      purchaseToken: purchase.verificationData ?? '',
      productId: purchase.productID,
    );
    if (!mounted) return;

    state = state.copyWith(
      isPro: result.isPro,
      isLifetime: result.status == EntitlementStatus.lifetime,
      proExpiry: result.expiryDate,
      entitlementStatus: result.status,
      error: result.isPro ? null : result.errorMessage,
    );
  }

  bool get isProActive => state.isPro;

  bool canWriteEntry({required int currentMonthEntries}) =>
      isProActive || currentMonthEntries < 7;

  int remainingEntries({required int currentMonthEntries}) =>
      isProActive ? -1 : (7 - currentMonthEntries).clamp(0, 7);

  String priceFor(String productId) {
    for (final item in state.products) {
      if (item.id == productId) return item.price;
    }
    return '';
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}

class MonetizationState {
  const MonetizationState({
    this.storeAvailable = false,
    this.isPro = false,
    this.isLifetime = false,
    this.proExpiry,
    this.purchasing = false,
    this.restoring = false,
    this.products = const [],
    this.error,
    this.entitlementStatus = EntitlementStatus.unknown,
  });

  final bool storeAvailable;
  final bool isPro;
  final bool isLifetime;
  final DateTime? proExpiry;
  final bool purchasing;
  final bool restoring;
  final List<ProductDetails> products;
  final String? error;
  final EntitlementStatus entitlementStatus;

  MonetizationState copyWith({
    bool? storeAvailable,
    bool? isPro,
    bool? isLifetime,
    DateTime? proExpiry,
    bool? purchasing,
    bool? restoring,
    List<ProductDetails>? products,
    String? error,
    EntitlementStatus? entitlementStatus,
  }) =>
      MonetizationState(
        storeAvailable: storeAvailable ?? this.storeAvailable,
        isPro: isPro ?? this.isPro,
        isLifetime: isLifetime ?? this.isLifetime,
        proExpiry: proExpiry ?? this.proExpiry,
        purchasing: purchasing ?? this.purchasing,
        restoring: restoring ?? this.restoring,
        products: products ?? this.products,
        error: error,
        entitlementStatus: entitlementStatus ?? this.entitlementStatus,
      );
}

final monetizationProvider =
    StateNotifierProvider<MonetizationService, MonetizationState>(
  (_) => MonetizationService(),
);
