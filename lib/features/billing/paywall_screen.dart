import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        title: const Text('Upgrade to Pro'),
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
                : const Text('Restore'),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF8B7BFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  const Icon(Icons.workspace_premium,
                      size: 64, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    'نبض Pro',
                    style: Theme.of(context)
                        .textTheme
                        .displayLarge
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'افتح كل الميزات',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Features
            _featureRow('📝', 'مدخلات غير محدودة'),
            _featureRow('🌱', '10 بذور في الحديقة'),
            _featureRow('🔒', 'قفل بيومتري'),
            _featureRow('📊', 'كل الإحصائيات المتقدمة'),
            _featureRow('💌', 'رسائل المستقبل والكبسولات'),
            _featureRow('📤', 'تصدير PDF + JSON'),
            _featureRow('🚫', 'بدون إعلانات'),

            const SizedBox(height: 32),

            // Plans
            if (!monetization.storeAvailable)
              const _StoreUnavailableCard()
            else if (monetization.products.isEmpty)
              const Center(child: CircularProgressIndicator())
            else ...[
              _PlanCard(
                title: 'Monthly',
                price: service.priceFor(MonetizationService.proMonthlyId),
                subtitle: 'يُجدّد شهرياً',
                onTap: () => _buy(MonetizationService.proMonthlyId),
              ),
              const SizedBox(height: 12),
              _PlanCard(
                title: 'Yearly',
                price: service.priceFor(MonetizationService.proYearlyId),
                subtitle: 'وفّر 50%',
                badge: 'الأكثر توفيراً',
                highlighted: true,
                onTap: () => _buy(MonetizationService.proYearlyId),
              ),
              const SizedBox(height: 12),
              _PlanCard(
                title: 'Lifetime',
                price: service.priceFor(MonetizationService.lifetimeId),
                subtitle: 'دفعة واحدة، للأبد',
                badge: '⭐ الأفضل',
                onTap: () => _buy(MonetizationService.lifetimeId),
              ),
            ],

            if (monetization.error != null) ...[
              const SizedBox(height: 16),
              Text(
                monetization.error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            const Text(
              'سيتم تجديد الاشتراك تلقائياً. يمكنك الإلغاء في أي وقت من إعدادات المتجر.',
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
          SnackBar(content: Text('Error: $e')),
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
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
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
                  colors: [Color(0xFF6C5CE7), Color(0xFF8B7BFF)],
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
      child: const Column(
        children: [
          Icon(Icons.store_mall_directory_outlined,
              size: 40, color: AppColors.textTertiary),
          SizedBox(height: 12),
          Text(
            'متجر التطبيقات غير متاح',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'حاول لاحقاً أو تحقق من اتصالك بالإنترنت',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
