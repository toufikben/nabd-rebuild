import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../services/monetization_service.dart';

/// PaywallScreen — شاشة الترقية.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  @override
  Widget build(BuildContext context) {
    final monetization = ref.watch(monetizationProvider);
    final service = ref.read(monetizationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).t('paywall.title')),
        actions: [
          TextButton(
            onPressed: monetization.restoring
                ? null
                : () => service.restorePurchases(),
            child: monetization.restoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppLocalizations.of(context).t('paywall.restore')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium,
                      size: 64, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).t('paywall.brand'),
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).t('paywall.tagline'),
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Features
            // Only what Pro really unlocks in this build. Everything else in
            // the app is free, so it is not listed as a paid feature.
            _featureRow('🧘', AppLocalizations.of(context).t('paywall.f1')),
            _featureRow('🔭', AppLocalizations.of(context).t('paywall.f2')),
            _featureRow('📄', AppLocalizations.of(context).t('paywall.f3')),
            _featureRow('💜', AppLocalizations.of(context).t('paywall.f4')),

            const SizedBox(height: 32),

            // Plans
            if (!monetization.storeAvailable)
              const _StoreUnavailableCard()
            else if (!monetization.productsLoaded)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).t('paywall.loading'),
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else if (monetization.products.isEmpty)
              _LoadFailedCard(
                message: monetization.error ??
                    AppLocalizations.of(context).t('paywall.loadFailed'),
                onRetry: () => service.retryLoadProducts(),
              )
            else ...[
              if (MonetizationConfig.subscriptionsEnabled) ...[
              _PlanCard(
                title: AppLocalizations.of(context).t('paywall.monthly'),
                price: service.priceFor(MonetizationService.proMonthlyId),
                subtitle: AppLocalizations.of(context).t('paywall.monthlySub'),
                onTap: () => _buy(MonetizationService.proMonthlyId),
              ),
              const SizedBox(height: 12),
              _PlanCard(
                title: AppLocalizations.of(context).t('paywall.yearly'),
                price: service.priceFor(MonetizationService.proYearlyId),
                subtitle: AppLocalizations.of(context).t('paywall.yearlySub'),
                badge: AppLocalizations.of(context).t('paywall.bestValue'),
                highlighted: true,
                onTap: () => _buy(MonetizationService.proYearlyId),
              ),
              const SizedBox(height: 12),
              ],
              _PlanCard(
                title: AppLocalizations.of(context).t('paywall.lifetime'),
                price: service.priceFor(MonetizationService.lifetimeId),
                subtitle: AppLocalizations.of(context).t('paywall.lifetimeSub'),
                badge: AppLocalizations.of(context).t('paywall.best'),
                highlighted: !MonetizationConfig.subscriptionsEnabled,
                onTap: () => _buy(MonetizationService.lifetimeId),
              ),
            ],

            if (monetization.nothingRestored) ...[
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).t('paywall.restoreNothing'),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],

            if (monetization.error != null) ...[
              SizedBox(height: 16),
              Text(
                monetization.error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],

            SizedBox(height: 24),

            if (MonetizationConfig.subscriptionsEnabled)
            Text(
              AppLocalizations.of(context).t('paywall.renewNote'),
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _buy(String productId) async {
    final service = ref.read(monetizationProvider.notifier);
    final products = ref.read(monetizationProvider).products;

    try {
      final product = products.firstWhere((p) => p.id == productId);
      await service.buy(product);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text(
            '${AppLocalizations.of(context).t('common.error')}: $e',
          ),
        ),
        );
      }
    }
  }

  Widget _featureRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Icon(Icons.check_circle, color: AppColors.success, size: 20),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String subtitle;
  final String? badge;
  final bool highlighted;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    this.badge,
    this.highlighted = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: highlighted
              ? const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primaryGlow],
                )
              : null,
          color: highlighted ? null : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: highlighted
              ? null
              : Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: highlighted
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: highlighted
                              ? Colors.white
                              : AppColors.warning,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: highlighted ? Colors.white : null,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: highlighted ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: highlighted ? Colors.white : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadFailedCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadFailedCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).t('paywall.loadFailed'),
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context).t('paywall.retry')),
          ),
        ],
      ),
    );
  }
}

class _StoreUnavailableCard extends StatelessWidget {
  const _StoreUnavailableCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.store_mall_directory_outlined,
              size: 40, color: AppColors.textTertiary),
          SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).t('paywall.unavailable'),
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).t('paywall.unavailableHint'),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
