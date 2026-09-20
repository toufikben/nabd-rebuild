import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/motivation_service.dart';

class SageScreen extends StatefulWidget {
  const SageScreen({super.key});
  @override
  State<SageScreen> createState() => _SageScreenState();
}

class _SageScreenState extends State<SageScreen> {
  late (String, String) _sage;

  @override
  void initState() {
    super.initState();
    _sage = MotivationService.getTodayQuoteArabic();
  }

  void _refresh() =>
      setState(() => _sage = MotivationService.getRandomQuoteArabic());

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Sage'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: .18),
                  AppColors.secondary.withValues(alpha: .10),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'A quiet thought',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  '«${_sage.$1}»',
                  style: const TextStyle(
                    fontSize: 23,
                    height: 1.7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '— ${_sage.$2}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sage uses the app’s local library. It changes only when you press Refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
