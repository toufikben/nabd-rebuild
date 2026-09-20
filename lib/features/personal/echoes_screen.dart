import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../models/mood.dart';
import '../../services/r_personal_service.dart';

class EchoesScreen extends StatefulWidget {
  const EchoesScreen({super.key});
  @override
  State<EchoesScreen> createState() => _EchoesScreenState();
}

class _EchoesScreenState extends State<EchoesScreen> {
  final _service = RPersonalService();
  List<EchoRecord>? _echoes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final echoes = await _service.loadEchoes();
    if (mounted) setState(() => _echoes = echoes);
  }

  @override
  Widget build(BuildContext context) {
    final echoes = _echoes;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.echoes)),
      body: echoes == null
          ? const Center(child: CircularProgressIndicator())
          : echoes.isEmpty
              ? _EmptyEchoes(message: l10n.echoesEmpty)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: echoes.length,
                  itemBuilder: (_, index) => _EchoCard(record: echoes[index]),
                ),
    );
  }
}

class _EchoCard extends StatelessWidget {
  const _EchoCard({required this.record});
  final EchoRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mood = Mood.getById(record.original.mood);
    final resolved = record.resolution != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  resolved
                      ? Icons.wb_sunny_outlined
                      : Icons.nightlight_outlined,
                  color: resolved ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    resolved ? l10n.resolvedEcho : l10n.awaitingEcho,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(mood?.emoji ?? '❔',
                        style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 4),
                    Text(
                      mood?.label(l10n.isArabic ? 'ar' : 'en') ??
                          l10n.unknownMood,
                      style: const TextStyle(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              record.original.content,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              '${l10n.original}: ${_date(record.original.createdAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            if (record.resolution case final resolution?) ...[
              const Divider(height: 24),
              Text(
                l10n.laterPositiveEntry,
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                resolution.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.resolved}: ${_date(resolution.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _date(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}

class _EmptyEchoes extends StatelessWidget {
  const _EmptyEchoes({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
}
