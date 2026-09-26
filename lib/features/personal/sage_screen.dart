import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
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

  void _refresh() => setState(
        () => _sage = MotivationService.getRandomQuoteArabic(
          excludingQuote: _sage.$1,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.sage),
          actions: [
            IconButton(
                onPressed: _refresh,
                tooltip: l10n.refresh,
                icon: const Icon(Icons.refresh_rounded)),
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
                  Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        l10n.quietThought,
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
                  SizedBox(height: 16),
                  Text(
                    '— ${_sage.$2}',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              l10n.sageLocalNote,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
