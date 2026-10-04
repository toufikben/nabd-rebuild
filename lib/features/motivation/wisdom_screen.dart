import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../services/motivation_service.dart';
import '../../core/storage.dart';

class WisdomScreen extends StatefulWidget {
  const WisdomScreen({super.key});

  @override
  State<WisdomScreen> createState() => _WisdomScreenState();
}

class _WisdomScreenState extends State<WisdomScreen> {
  late AppLocalizations l10n;
  static const _wisdomStorageKey = 'wisdom_state';

  final Box _settings = contentBox();
  (String, String)? _wisdom;
  bool _pendingDefault = false;

  @override
  void initState() {
    super.initState();
    final raw = _settings.get(_wisdomStorageKey);
    if (raw is Map && raw['deleted'] == true) return;

    final quote = raw is Map ? raw['quote']?.toString() : null;
    final author = raw is Map ? raw['author']?.toString() : null;
    if (quote != null &&
        quote.isNotEmpty &&
        author != null &&
        author.isNotEmpty) {
      _wisdom = (quote, author);
    } else {
      _pendingDefault = true;
    }
  }

  void _createWisdom() {
    final wisdom = MotivationService.getRandomQuoteFor(l10n.locale.languageCode);
    setState(() => _wisdom = wisdom);
    _persistWisdom(wisdom, deleted: false);
  }

  void _changeWisdom() {
    final wisdom = MotivationService.getRandomQuoteFor(l10n.locale.languageCode,
        excludingQuote: _wisdom?.$1);
    setState(() => _wisdom = wisdom);
    _persistWisdom(wisdom, deleted: false);
  }

  void _deleteWisdom() {
    setState(() => _wisdom = null);
    _persistWisdom(null, deleted: true);
  }

  void _persistWisdom((String, String)? wisdom, {required bool deleted}) {
    unawaited(
      _settings.put(_wisdomStorageKey, {
        'deleted': deleted,
        'quote': wisdom?.$1,
        'author': wisdom?.$2,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    if (_pendingDefault) {
      _pendingDefault = false;
      _wisdom = MotivationService.getTodayQuoteFor(l10n.locale.languageCode);
      _persistWisdom(_wisdom, deleted: false);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('wisdom.title'))),
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
                          label: Text(l10n.t('wisdom.another')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: _deleteWisdom,
                        tooltip: l10n.t('wisdom.deleteTooltip'),
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
                  Text(
                    l10n.t('wisdom.readonlyNote'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
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
            SizedBox(height: 16),
            Text(
              '— ${wisdom.$2}',
              style: TextStyle(color: AppColors.textSecondary),
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
          Text(
            AppLocalizations.of(context).t('wisdom.empty'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).t('wisdom.createHint'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _createWisdom,
            icon: const Icon(Icons.add),
            label: Text(l10n.t('wisdom.generate')),
          ),
        ],
      ),
    );
  }
}
