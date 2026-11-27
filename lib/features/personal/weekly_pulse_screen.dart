import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../services/r_personal_service.dart';

class WeeklyPulseScreen extends StatefulWidget {
  const WeeklyPulseScreen({super.key});
  @override
  State<WeeklyPulseScreen> createState() => _WeeklyPulseScreenState();
}

class _WeeklyPulseScreenState extends State<WeeklyPulseScreen> {
  final _service = RPersonalService();
  WeeklyPulse? _pulse;
  late final DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    final pulse = await _service.loadWeeklyPulse(_now);
    if (mounted) setState(() => _pulse = pulse);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pulse = _pulse;
    if (pulse == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.t('weekly.title'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('weekly.title'))),
      body: pulse.insufficientData
          ? const _InsufficientState()
          : _PulseBody(pulse: pulse, title: 'weekly.yourWeek'),
    );
  }
}

class _PulseBody extends StatelessWidget {
  const _PulseBody({required this.pulse, required this.title});

  final WeeklyPulse pulse;
  final String title;

  String? _weekRange(BuildContext context) {
    final end = DateTime.tryParse(pulse.weekKey);
    if (end == null) return null;
    final start = end.subtract(const Duration(days: 6));
    final locale = AppLocalizations.of(context).locale.toString();
    final format = DateFormat.MMMd(locale);
    return '${format.format(start)} – ${format.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final range = _weekRange(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l10n.t(title),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (range != null) ...[
          const SizedBox(height: 4),
          Text(
            range,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _Metric(
                label: l10n.t('weekly.entries'),
                value: '${pulse.entryCount}',
                icon: Icons.menu_book_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Metric(
                label: l10n.t('weekly.words'),
                value: '${pulse.wordCount}',
                icon: Icons.edit_note_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Metric(
                label: l10n.t('weekly.positive'),
                value: '${pulse.positiveCount}',
                icon: Icons.wb_sunny_outlined,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Metric(
                label: l10n.t('weekly.negative'),
                value: '${pulse.negativeCount}',
                icon: Icons.cloud_outlined,
                color: AppColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _Metric(
          label: l10n.t('weekly.avgMood'),
          value: pulse.averageMood.toStringAsFixed(1),
          icon: Icons.insights_outlined,
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color ?? AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _InsufficientState extends StatelessWidget {
  const _InsufficientState();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        AppLocalizations.of(context).t('weekly.insufficient'),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
