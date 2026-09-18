import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/journal_entry.dart';
import '../../models/mood.dart';
import '../../services/database_service.dart';

class HeatmapScreen extends ConsumerStatefulWidget {
  const HeatmapScreen({super.key});

  @override
  ConsumerState<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends ConsumerState<HeatmapScreen> {
  final DatabaseService _db = DatabaseService();
  int _year = DateTime.now().year;
  String _mode = 'count'; // count, mood

  @override
  Widget build(BuildContext context) {
    final entries = _db.getAllEntries();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Heatmap'),
        actions: [
          // Year picker
          DropdownButton<int>(
            value: _year,
            underline: const SizedBox(),
            items: [2024, 2025, 2026]
                .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                .toList(),
            onChanged: (v) => setState(() => _year = v ?? 2025),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Mode selector ───
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Entries'),
                  selected: _mode == 'count',
                  onSelected: (_) => setState(() => _mode = 'count'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Mood'),
                  selected: _mode == 'mood',
                  onSelected: (_) => setState(() => _mode = 'mood'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── Heatmap ───
            _buildHeatmap(entries),

            const SizedBox(height: 24),

            // ─── Legend ───
            _buildLegend(),

            const SizedBox(height: 24),

            // ─── Stats ───
            _buildStats(entries),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap(List<JournalEntry> entries) {
    final startDate = DateTime(_year, 1, 1);
    final endDate = DateTime(_year, 12, 31);
    final totalDays = endDate.difference(startDate).inDays + 1;

    // Group entries by day
    final dayMap = <String, List<JournalEntry>>{};
    for (final entry in entries) {
      if (entry.createdAt.year != _year) continue;
      final key =
          '${entry.createdAt.year}-${entry.createdAt.month}-${entry.createdAt.day}';
      dayMap.putIfAbsent(key, () => []).add(entry);
    }

    // Calculate weeks
    final weeks = <List<Widget>>[];
    var week = <Widget>[];

    // Fill first week with empty days
    final firstDayOfWeek = startDate.weekday % 7;
    for (var i = 0; i < firstDayOfWeek; i++) {
      week.add(const SizedBox(width: 12, height: 12));
    }

    for (var i = 0; i < totalDays; i++) {
      final date = startDate.add(Duration(days: i));
      final key = '${date.year}-${date.month}-${date.day}';
      final dayEntries = dayMap[key] ?? [];

      week.add(_buildDayCell(date, dayEntries));

      if (date.weekday == DateTime.saturday || i == totalDays - 1) {
        weeks.add(week);
        week = <Widget>[];
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: weeks.map((w) {
          return Column(
            children: w.map((c) => Padding(
              padding: const EdgeInsets.all(1.5),
              child: c,
            )).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDayCell(DateTime date, List<JournalEntry> entries) {
    Color color;

    if (_mode == 'mood') {
      if (entries.isEmpty) {
        color = AppColors.textTertiary.withValues(alpha: 0.15);
      } else {
        final moods = entries
            .map((e) => Mood.getById(e.mood))
            .where((m) => m != null)
            .cast<Mood>()
            .toList();
        if (moods.isEmpty) {
          color = AppColors.primary.withValues(alpha: 0.3);
        } else {
          final avgValue = moods.map((m) => m.value).reduce((a, b) => a + b) /
              moods.length;
          color = _colorForValue(avgValue);
        }
      }
    } else {
      // count mode
      if (entries.isEmpty) {
        color = AppColors.textTertiary.withValues(alpha: 0.15);
      } else if (entries.length == 1) {
        color = AppColors.primary.withValues(alpha: 0.3);
      } else if (entries.length == 2) {
        color = AppColors.primary.withValues(alpha: 0.5);
      } else if (entries.length <= 4) {
        color = AppColors.primary.withValues(alpha: 0.7);
      } else {
        color = AppColors.primary;
      }
    }

    return Tooltip(
      message:
          '${date.day}/${date.month}: ${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        const Text(
          'Less',
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 6),
        ...List.generate(5, (i) {
          final alpha = i * 0.25;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: alpha == 0 ? 0.15 : alpha),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
        const SizedBox(width: 6),
        const Text(
          'More',
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStats(List<JournalEntry> entries) {
    final yearEntries =
        entries.where((e) => e.createdAt.year == _year).toList();

    final totalDays = yearEntries
        .map((e) =>
            '${e.createdAt.year}-${e.createdAt.month}-${e.createdAt.day}')
        .toSet()
        .length;

    final totalWords = yearEntries
        .fold<int>(0, (sum, e) => sum + e.content.split(RegExp(r'\s+')).length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$_year in review',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statItem(
                  Icons.edit,
                  '${yearEntries.length}',
                  'Entries',
                ),
              ),
              Expanded(
                child: _statItem(
                  Icons.calendar_today,
                  '$totalDays',
                  'Active days',
                ),
              ),
              Expanded(
                child: _statItem(
                  Icons.text_fields,
                  '$totalWords',
                  'Words',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _colorForValue(double value) {
    if (value >= 8) return const Color(0xFF00C853);
    if (value >= 6) return const Color(0xFFFFD600);
    if (value >= 4) return const Color(0xFFFF6D00);
    return const Color(0xFFD50000);
  }
}
