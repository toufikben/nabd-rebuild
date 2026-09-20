import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/motivation_service.dart';

class WisdomScreen extends StatefulWidget {
  const WisdomScreen({super.key});

  @override
  State<WisdomScreen> createState() => _WisdomScreenState();
}

class _WisdomScreenState extends State<WisdomScreen> {
  (String, String)? _wisdom;

  @override
  void initState() {
    super.initState();
    _wisdom = MotivationService.getTodayQuoteArabic();
  }

  void _createWisdom() {
    setState(() => _wisdom = MotivationService.getTodayQuoteArabic());
  }

  void _changeWisdom() {
    setState(() => _wisdom = MotivationService.getRandomQuoteArabic());
  }

  void _deleteWisdom() {
    setState(() => _wisdom = null);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('حكمة')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: _wisdom == null
              ? _emptyState()
              : ListView(
                  children: [
                    _wisdomCard(context),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _changeWisdom,
                            icon: const Icon(Icons.swap_horiz),
                            label: const Text('حكمة أخرى'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: _deleteWisdom,
                          tooltip: 'حذف الحكمة',
                          icon: const Icon(Icons.delete_outline),
                          style: IconButton.styleFrom(
                            foregroundColor: AppColors.danger,
                            backgroundColor:
                                AppColors.danger.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'لا يمكن تعديل نص الحكمة. احذفها ثم أنشئ حكمة جديدة إذا رغبت.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _wisdomCard(BuildContext context) {
    final wisdom = _wisdom!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.format_quote, color: AppColors.primary, size: 32),
            const SizedBox(height: 16),
            Text(
              '«${wisdom.$1}»',
              style: const TextStyle(
                fontSize: 22,
                height: 1.7,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '— ${wisdom.$2}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_outline,
              size: 64, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'لا توجد حكمة معروضة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'أنشئ حكمة جديدة من البيانات المحلية.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _createWisdom,
            icon: const Icon(Icons.add),
            label: const Text('إنشاء حكمة'),
          ),
        ],
      ),
    );
  }
}
