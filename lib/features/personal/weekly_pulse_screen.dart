import 'package:flutter/material.dart';

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
    if (_now.weekday != DateTime.sunday) {
      return Scaffold(
        appBar: AppBar(title: const Text('Weekly Pulse')),
        body: const _NextSundayState(),
      );
    }
    final pulse = _pulse;
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Pulse')),
      body:
          pulse == null
              ? const Center(child: CircularProgressIndicator())
              : pulse.insufficientData
              ? const _InsufficientState()
              : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Your week',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('A stable snapshot saved for this Sunday.'),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: 'Entries',
                          value: '${pulse.entryCount}',
                          icon: Icons.menu_book_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Metric(
                          label: 'Words',
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
                          label: 'Positive',
                          value: '${pulse.positiveCount}',
                          icon: Icons.wb_sunny_outlined,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Metric(
                          label: 'Negative',
                          value: '${pulse.negativeCount}',
                          icon: Icons.cloud_outlined,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _Metric(
                    label: 'Average mood score',
                    value: pulse.averageMood.toStringAsFixed(1),
                    icon: Icons.insights_outlined,
                  ),
                ],
              ),
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

class _NextSundayState extends StatelessWidget {
  const _NextSundayState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 52,
            color: AppColors.primary,
          ),
          SizedBox(height: 16),
          Text(
            'Your next Pulse arrives on Sunday.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'No new Pulse is created before Sunday.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

class _InsufficientState extends StatelessWidget {
  const _InsufficientState();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        'There is not enough Journal data for this week yet. Your Pulse will remain empty until you have entries.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}
