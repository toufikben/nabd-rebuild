import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// The app never derives subscription expiry locally. Subscription entitlement
/// is `unknown` until a trusted verifier is connected; lifetime is granted only
/// for the current process after an actual store callback.
enum EntitlementStatus {
  unknown,
  pending,
  lifetime,
  subscriptionUnverified,
  expired,
  error
}

class EntitlementService {
  EntitlementStatus statusFor(PurchaseDetails purchase) {
    if (purchase.status == PurchaseStatus.pending) {
      return EntitlementStatus.pending;
    }
    if (purchase.status == PurchaseStatus.error) return EntitlementStatus.error;
    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return EntitlementStatus.unknown;
    }
    if (purchase.productID == MonetizationService.lifetimeId) {
      return EntitlementStatus.lifetime;
    }
    if (purchase.productID == MonetizationService.proMonthlyId ||
        purchase.productID == MonetizationService.proYearlyId) {
      return EntitlementStatus.subscriptionUnverified;
    }
    return EntitlementStatus.error;
  }
}

class MonetizationService extends StateNotifier<MonetizationState> {
  MonetizationService() : super(const MonetizationState()) {
    _init();
  }

  static final _iap = InAppPurchase.instance;
  static const String proMonthlyId = 'nabd_pro_monthly';
  static const String proYearlyId = 'nabd_pro_yearly';
  static const String lifetimeId = 'nabd_lifetime';
  static const Set<String> productIds = {proMonthlyId, proYearlyId, lifetimeId};

  final _entitlements = EntitlementService();
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  Future<void> _init() async {
    final available = await _iap.isAvailable();
    if (!available) return;
    state = state.copyWith(storeAvailable: true);
    _purchaseSub = _iap.purchaseStream.listen(_onPurchaseUpdate);
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final response = await _iap.queryProductDetails(productIds);
      state = state.copyWith(
        products: response.productDetails,
        error: response.error?.message,
      );
    } catch (error) {
      state = state.copyWith(
          error: '$error', entitlementStatus: EntitlementStatus.error);
    }
  }

  Future<void> buy(ProductDetails product) async {
    if (!productIds.contains(product.id)) {
      state = state.copyWith(
          error: 'Unknown product', entitlementStatus: EntitlementStatus.error);
      return;
    }
    state = state.copyWith(
        purchasing: true,
        error: null,
        entitlementStatus: EntitlementStatus.pending);
    try {
      await _iap.buyNonConsumable(
          purchaseParam: PurchaseParam(productDetails: product));
    } catch (error) {
      state = state.copyWith(
          purchasing: false,
          error: '$error',
          entitlementStatus: EntitlementStatus.error);
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(
        restoring: true,
        error: null,
        entitlementStatus: EntitlementStatus.pending);
    try {
      await _iap.restorePurchases();
    } catch (error) {
      state = state.copyWith(
          restoring: false,
          error: '$error',
          entitlementStatus: EntitlementStatus.error);
    }
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      final status = _entitlements.statusFor(purchase);
      if (status == EntitlementStatus.lifetime) {
        state = state.copyWith(
          isPro: true,
          isLifetime: true,
          purchasing: false,
          restoring: false,
          entitlementStatus: status,
        );
      } else {
        state = state.copyWith(
          purchasing: false,
          restoring: false,
          entitlementStatus: status,
          error: status == EntitlementStatus.subscriptionUnverified
              ? 'Subscription requires server-side entitlement verification.'
              : purchase.error?.message,
        );
      }
      if (purchase.pendingCompletePurchase) {
        unawaited(_iap.completePurchase(purchase));
      }
    }
  }

  bool get isProActive => state.isLifetime;

  bool canWriteEntry({required int currentMonthEntries}) =>
      isProActive || currentMonthEntries < 7;

  int remainingEntries({required int currentMonthEntries}) =>
      isProActive ? -1 : (7 - currentMonthEntries).clamp(0, 7);

  String priceFor(String productId) {
    final matches = state.products.where((item) => item.id == productId);
    if (matches.isNotEmpty) return matches.first.price;
    return '';
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}

class MonetizationState {
  final bool storeAvailable;
  final bool isPro;
  final bool isLifetime;
  final DateTime? proExpiry;
  final bool purchasing;
  final bool restoring;
  final List<ProductDetails> products;
  final String? error;
  final EntitlementStatus entitlementStatus;

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
