import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/monthly_summary.dart';
import '../../core/text_direction.dart';
import '../../core/theme/app_colors.dart';
import '../../models/mood.dart';
import '../../services/database_service.dart';
import '../../widgets/nabd_ui.dart';

/// A calm look back at one month. Opens on the current month, or on the
/// month given as `?month=yyyy-mm`.
class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key, this.initialMonth});

  final DateTime? initialMonth;

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  late DateTime _month;
  final _entries = DatabaseService().getAllEntries();

  @override
  void initState() {
    super.initState();
    final start = widget.initialMonth ?? DateTime.now();
    _month = DateTime(start.year, start.month);
  }

  DateTime get _firstMonth {
    if (_entries.isEmpty) return _month;
    final oldest = _entries.last.createdAt;
    return DateTime(oldest.year, oldest.month);
  }

  bool get _canGoBack => _month.isAfter(_firstMonth);

  bool get _canGoForward {
    final now = DateTime.now();
    return _month.isBefore(DateTime(now.year, now.month));
  }

  void _shift(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final code = l10n.locale.languageCode;
    final summary = MonthlySummary.compute(_entries, _month);
    final number = NumberFormat.decimalPattern(code);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('hub.feature.monthly.title'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.t('monthly.previous'),
                onPressed: _canGoBack ? () => _shift(-1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM(code).format(_month),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: l10n.t('monthly.next'),
                onPressed: _canGoForward ? () => _shift(1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (summary.isEmpty)
            EmptyState(emoji: '🌱', title: l10n.t('monthly.empty'))
          else ...[
            EqualHeightGrid(
              columns: 2,
              children: [
                _Metric(
                  icon: Icons.menu_book_rounded,
                  label: l10n.t('monthly.entries'),
                  value: number.format(summary.entries),
                ),
                _Metric(
                  icon: Icons.edit_note_rounded,
                  label: l10n.t('monthly.words'),
                  value: number.format(summary.words),
                ),
                _Metric(
                  icon: Icons.event_available_rounded,
                  label: l10n.t('monthly.days'),
                  value: l10n
                      .t('monthly.daysOf')
                      .replaceAll('{n}', number.format(summary.daysWritten))
                      .replaceAll('{d}', number.format(summary.daysInMonth)),
                ),
                _Metric(
                  icon: Icons.local_fire_department_rounded,
                  label: l10n.t('monthly.streak'),
                  value: number.format(summary.longestStreak),
                  color: AppColors.pulse,
                ),
              ],
            ),
            if (summary.averageMood case final average?) ...[
              SectionHeader(l10n.t('monthly.mood'),
                  padding: const EdgeInsets.fromLTRB(4, 24, 4, 10)),
              NabdCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('monthly.moodAverage').replaceAll(
                          '{n}',
                          NumberFormat('0.0', code).format(average)),
                      style: theme.textTheme.titleMedium,
                    ),
                    if (_trendKey(summary.moodChange) case final key?) ...[
                      const SizedBox(height: 4),
                      Text(l10n.t(key), style: theme.textTheme.bodySmall),
                    ],
                    const SizedBox(height: 14),
                    Text(l10n.t('monthly.curve'),
                        style: theme.textTheme.labelMedium),
                    const SizedBox(height: 8),
                    _MoodCurve(daily: summary.dailyMood),
                  ],
                ),
              ),
            ],
            if (summary.topMoods.isNotEmpty) ...[
              SectionHeader(l10n.t('monthly.topMoods'),
                  padding: const EdgeInsets.fromLTRB(4, 24, 4, 10)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (mood, count) in summary.topMoods)
                    Chip(
                      avatar: Text(mood.emoji),
                      label: Text(
                          '${mood.label(code)} · ${number.format(count)}'),
                      backgroundColor: mood.color.withValues(alpha: 0.15),
                    ),
                ],
              ),
            ],
            if (summary.topTags.isNotEmpty) ...[
              SectionHeader(l10n.t('monthly.topTags'),
                  padding: const EdgeInsets.fromLTRB(4, 24, 4, 10)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (tag, count) in summary.topTags)
                    Chip(label: Text('#$tag · ${number.format(count)}')),
                ],
              ),
            ],
            if (summary.brightest case final entry?) ...[
              SectionHeader(l10n.t('monthly.brightest'),
                  padding: const EdgeInsets.fromLTRB(4, 24, 4, 10)),
              NabdCard(
                onTap: () => context.push('/editor', extra: entry.id),
                child: Builder(builder: (context) {
                  final fallback = Directionality.of(context);
                  final title = entry.title.trim();
                  final excerpt =
                      entry.content.trim().replaceAll(RegExp(r'\s+'), ' ');
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${Mood.getById(entry.mood)?.emoji ?? ''}  '
                        '${DateFormat.MMMMEEEEd(code).format(entry.createdAt)}',
                        style: theme.textTheme.labelMedium,
                      ),
                      if (title.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(title,
                            textDirection: textDirectionOf(title, fallback),
                            style: theme.textTheme.titleSmall),
                      ],
                      if (excerpt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          excerpt,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          textDirection: textDirectionOf(excerpt, fallback),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  );
                }),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              l10n.t('monthly.closing'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  static String? _trendKey(double? change) {
    if (change == null) return null;
    if (change >= 0.5) return 'monthly.lighter';
    if (change <= -0.5) return 'monthly.heavier';
    return 'monthly.steady';
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NabdCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color ?? theme.colorScheme.primary),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// One small bar per day; empty days stay as a faint dot.
class _MoodCurve extends StatelessWidget {
  const _MoodCurve({required this.daily});

  final List<double?> daily;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final value in daily)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: value == null
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: scheme.outlineVariant,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      )
                    : FractionallySizedBox(
                        heightFactor: (value / 10).clamp(0.08, 1.0),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color.lerp(AppColors.warning,
                                AppColors.success, (value - 1) / 9),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
