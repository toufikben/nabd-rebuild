import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../services/motivation_service.dart';
import '../../core/l10n/app_localizations.dart';

class MotivationScreen extends StatefulWidget {
  const MotivationScreen({super.key});

  @override
  State<MotivationScreen> createState() => _MotivationScreenState();
}

class _MotivationScreenState extends State<MotivationScreen> {
  (String, String)? _quote;

  String get _language => AppLocalizations.of(context).locale.languageCode;

  void _refresh() => setState(
        () => _quote = MotivationService.getRandomQuoteFor(_language),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _quote ??= MotivationService.getTodayQuoteFor(_language);
    final quote = _quote!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('hub.feature.motivation.title')),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: l10n.t('motivation.another'),
            icon: const Icon(Icons.refresh),
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
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.primaryGlow.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      l10n.t('motivation.todayMessage'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  '«${quote.$1}»',
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.65,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  '— ${quote.$2}',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.t('motivation.another')),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.t('motivation.localNote'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
