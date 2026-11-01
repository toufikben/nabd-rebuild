import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../services/monetization_service.dart';
import '../../services/store_links.dart';

/// PaywallScreen — شاشة الترقية.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  /// "Save N%" from the real prices, or a plain description when the store
  /// gives no comparable monthly price.
  String _yearlySubtitle(BuildContext context, MonetizationService service) {
    final l10n = AppLocalizations.of(context);
    final percent = service.yearlySavingPercent();
    if (percent == null) return l10n.t('paywall.yearlySub');
    return l10n
        .t('paywall.yearlySave')
        .replaceAll(
          '{p}',
          NumberFormat.decimalPattern(l10n.locale.languageCode).format(percent),
        );
  }

  @override
  Widget build(BuildContext context) {
    final monetization = ref.watch(monetizationProvider);
    final service = ref.read(monetizationProvider.notifier);
    final l10n = AppLocalizations.of(context);

    // A Pro user opening this screen is not a customer to sell to: show the
    // entitlement instead of the plans, and drop the restore action that would
    // only ever answer "nothing to restore".
    final isPro = monetization.isPro;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('paywall.title')),
        actions: [
          if (!isPro)
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
                  : Text(l10n.t('paywall.restore')),
            ),
        ],
      ),
      body: SingleChildScrollView(
        // The renewal note is the last line: keep it above the system
        // navigation bar, which the app draws behind.
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.viewPaddingOf(context).bottom,
        ),
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
                  const Icon(
                    Icons.workspace_premium,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).t('paywall.brand'),
                    style: Theme.of(
                      context,
                    ).textTheme.displayLarge?.copyWith(color: Colors.white),
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

            // A restore must answer next to the button that was tapped: the
            // message used to sit under the plans, off-screen on a small
            // phone, so a working reply looked like a dead button.
            if (!isPro && monetization.nothingRestored) ...[
              Text(
                l10n.t('paywall.restoreNothing'),
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            // A restore the store refused used to leave the screen unchanged:
            // the raw store sentence is hidden below when there are no plans,
            // so the button looked dead. Say what happened in the user's own
            // words instead of printing the platform message.
            if (!isPro && monetization.restoreFailed) ...[
              Text(
                l10n.t('paywall.unavailableHint'),
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],

            if (isPro) ...[
              _ProActiveCard(
                lifetime: monetization.isLifetime,
                expiry: monetization.proExpiry,
              ),
              // Only the store can cancel or change a subscription, and a
              // lifetime purchase has nothing to manage.
              if (!monetization.isLifetime) ...[
                const SizedBox(height: 12),
                const _ManageSubscriptionButton(),
              ],
              const SizedBox(height: 28),
            ],

            // Features
            // Only what Pro really unlocks in this build. Everything else in
            // the app is free, so it is not listed as a paid feature.
            _featureRow('🧘', AppLocalizations.of(context).t('paywall.f1')),
            _featureRow('🔭', AppLocalizations.of(context).t('paywall.f2')),
            _featureRow('📄', AppLocalizations.of(context).t('paywall.f3')),
            _featureRow('💜', AppLocalizations.of(context).t('paywall.f4')),

            const SizedBox(height: 32),

            // Plans — nothing to sell once the store confirmed Pro.
            if (!isPro) _plans(monetization, service),

            // The load-failure card already carries the store's message, so
            // repeating it underneath only doubles the text on screen.
            if (!isPro &&
                !monetization.restoreFailed &&
                monetization.error != null &&
                monetization.products.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                monetization.error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            if (!isPro && MonetizationConfig.subscriptionsEnabled)
              Text(
                l10n.t('paywall.renewNote'),
                style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  /// The three plans, or the card that explains why there are none.
  Widget _plans(MonetizationState monetization, MonetizationService service) {
    final l10n = AppLocalizations.of(context);

    if (!monetization.storeAvailable) return const _StoreUnavailableCard();
    if (!monetization.productsLoaded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.t('paywall.loading'),
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }
    if (monetization.products.isEmpty) {
      return _LoadFailedCard(
        message: monetization.error ?? l10n.t('paywall.loadFailed'),
        onRetry: () => service.retryLoadProducts(),
      );
    }

    return Column(
      children: [
        if (MonetizationConfig.subscriptionsEnabled) ...[
          _PlanCard(
            title: l10n.t('paywall.monthly'),
            price: service.priceFor(MonetizationService.proMonthlyId),
            subtitle: l10n.t('paywall.monthlySub'),
            onTap: () => _buy(MonetizationService.proMonthlyId),
          ),
          const SizedBox(height: 12),
          _PlanCard(
            title: l10n.t('paywall.yearly'),
            price: service.priceFor(MonetizationService.proYearlyId),
            subtitle: _yearlySubtitle(context, service),
            badge: l10n.t('paywall.bestValue'),
            highlighted: true,
            onTap: () => _buy(MonetizationService.proYearlyId),
          ),
          const SizedBox(height: 12),
        ],
        _PlanCard(
          title: l10n.t('paywall.lifetime'),
          price: service.priceFor(MonetizationService.lifetimeId),
          subtitle: l10n.t('paywall.lifetimeSub'),
          badge: l10n.t('paywall.best'),
          highlighted: !MonetizationConfig.subscriptionsEnabled,
          onTap: () => _buy(MonetizationService.lifetimeId),
        ),
      ],
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
    // Ink, not Container: a ripple painted on the Material behind an opaque
    // Container is invisible, so the tap would have no feedback at all.
    return Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
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
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (badge != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
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
                          const SizedBox(height: 8),
                        ],
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: highlighted ? Colors.white : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: highlighted
                                ? Colors.white70
                                : AppColors.textSecondary,
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
          ),
        ),
      ),
    );
  }
}

/// The receipt shown instead of the plans when Pro is already active: what
/// was bought, and — for a subscription — when it runs out.
class _ProActiveCard extends StatelessWidget {
  final bool lifetime;
  final DateTime? expiry;

  const _ProActiveCard({required this.lifetime, required this.expiry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final code = l10n.locale.languageCode;

    final String detail;
    if (lifetime) {
      detail = l10n.t('paywall.activeLifetime');
    } else if (expiry != null) {
      detail = l10n
          .t('paywall.activeUntil')
          .replaceAll('{date}', DateFormat.yMMMMd(code).format(expiry!));
    } else {
      detail = l10n.t('settings.pro.activeHint');
    }

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.verified_rounded,
              color: AppColors.success,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('settings.pro.active'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the store's own subscription page — the only place a plan can be
/// cancelled, switched or refunded. The app can sell a subscription, but it can
/// never end one on its own.
class _ManageSubscriptionButton extends StatefulWidget {
  const _ManageSubscriptionButton();

  @override
  State<_ManageSubscriptionButton> createState() =>
      _ManageSubscriptionButtonState();
}

class _ManageSubscriptionButtonState extends State<_ManageSubscriptionButton> {
  bool _opening = false;

  Future<void> _open() async {
    setState(() => _opening = true);
    final opened = await const StoreLinks().openManageSubscriptions();
    if (!mounted) return;
    setState(() => _opening = false);
    if (!opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('paywall.manageFailed')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _opening ? null : _open,
        icon: _opening
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.credit_card_outlined, size: 18),
        label: Text(AppLocalizations.of(context).t('paywall.manage')),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
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
    // The store often reports the same sentence the card already shows as its
    // title; printing it twice says nothing and looks broken.
    final title = AppLocalizations.of(context).t('paywall.loadFailed');
    final detail = message == title ? null : message;

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
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (detail != null) ...[
            const SizedBox(height: 8),
            Text(
              detail,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
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
          Icon(
            Icons.store_mall_directory_outlined,
            size: 40,
            color: AppColors.textTertiary,
          ),
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
