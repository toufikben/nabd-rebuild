import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_colors.dart';
import '../../models/journal_entry.dart';
import '../../models/mood.dart';
import '../../services/database_service.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Mood Pulse'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverview(),
          _buildMoodPulse(),
          _buildActivity(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Tab 1: Overview
  // ═══════════════════════════════════════════════════════════
  Widget _buildOverview() {
    final entries = _db.getAllEntries();
    final totalEntries = entries.length;
    final totalWords = _db.getWordCount();
    final streak = _calculateStreak();
    final longestStreak = _calculateLongestStreak();
    final avgWords = totalEntries == 0 ? 0 : totalWords ~/ totalEntries;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Top stats grid ───
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.4,
          children: [
            _statCard(
              icon: Icons.book_outlined,
              value: '$totalEntries',
              label: 'Total Entries',
              color: AppColors.primary,
            ),
            _statCard(
              icon: Icons.text_fields,
              value: '$totalWords',
              label: 'Total Words',
              color: AppColors.success,
            ),
            _statCard(
              icon: Icons.local_fire_department,
              value: '$streak',
              label: 'Current Streak',
              color: AppColors.warning,
            ),
            _statCard(
              icon: Icons.emoji_events,
              value: '$longestStreak',
              label: 'Longest Streak',
              color: AppColors.danger,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ─── Average words ───
        _sectionTitle('Writing Habits'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Average words per entry',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$avgWords',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (avgWords / 500).clamp(0.0, 1.0),
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.1),
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Text(
                avgWords < 100
                    ? 'Try writing more detailed entries'
                    : avgWords < 300
                        ? 'Good progress!'
                        : 'Amazing depth!',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Tab 2: Mood Pulse
  // ═══════════════════════════════════════════════════════════
  Widget _buildMoodPulse() {
    final entries = _db.getAllEntries();
    final distribution = _db.getMoodDistribution();

    // ─── Weekly pulse ───
    final weeklyPulse = _calculateWeeklyPulse(entries);

    // ─── Monthly pulse ───
    final monthlyPulse = _calculateMonthlyPulse(entries);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ─── Weekly Pulse Chart ───
        _sectionTitle('Weekly Pulse'),
        Container(
          height: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: weeklyPulse.isEmpty
              ? const Center(
                  child: Text(
                    'Write entries to see your mood pulse',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            const days = [
                              'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'
                            ];
                            final i = value.toInt();
                            if (i < 0 || i >= days.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                days[i],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minY: 0,
                    maxY: 10,
                    lineBarsData: [
                      LineChartBarData(
                        spots: weeklyPulse.asMap().entries.map((e) {
                          return FlSpot(e.key.toDouble(), e.value);
                        }).toList(),
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: _moodColorForValue(spot.y),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 20),

        // ─── Monthly mood average ───
        _sectionTitle('Monthly Mood Average'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _moodColorForValue(monthlyPulse)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _emojiForValue(monthlyPulse),
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your average mood',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${monthlyPulse.toStringAsFixed(1)} / 10',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _moodDescription(monthlyPulse),
                          style: TextStyle(
                            fontSize: 12,
                            color: _moodColorForValue(monthlyPulse),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ─── Mood distribution ───
        _sectionTitle('Mood Distribution'),
        if (distribution.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No moods recorded yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ...distribution.entries.map((e) {
            final mood = Mood.getById(e.key);
            if (mood == null) return const SizedBox.shrink();
            final total = distribution.values.reduce((a, b) => a + b);
            final percent = (e.value / total * 100).round();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: mood.color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              mood.label('en'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$percent%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: mood.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: e.value / total,
                            minHeight: 6,
                            backgroundColor:
                                mood.color.withValues(alpha: 0.1),
                            valueColor:
                                AlwaysStoppedAnimation(mood.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Tab 3: Activity
  // ═══════════════════════════════════════════════════════════
  Widget _buildActivity() {
    final entries = _db.getAllEntries();
    final last30 = _last30DaysData(entries);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Last 30 Days'),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 5,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: last30.asMap().entries.map((e) {
                return BarChartGroupData(
                  x: e.key,
                  barRods: [
                    BarChartRodData(
                      toY: e.value.toDouble(),
                      color: AppColors.primary,
                      width: 6,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
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
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textTertiary,
            letterSpacing: 1,
          ),
        ),
      );

  int _calculateStreak() {
    final entries = _db.getAllEntries();
    if (entries.isEmpty) return 0;

    final dates = entries.map((e) => DateTime(
          e.createdAt.year,
          e.createdAt.month,
          e.createdAt.day,
        )).toSet();

    var streak = 0;
    var date = DateTime.now();
    while (dates.contains(DateTime(date.year, date.month, date.day))) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _calculateLongestStreak() {
    final entries = _db.getAllEntries();
    if (entries.isEmpty) return 0;

    final dates = entries
        .map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
        .toSet()
        .toList()
      ..sort();

    var longest = 1;
    var current = 1;

    for (var i = 1; i < dates.length; i++) {
      final diff = dates[i].difference(dates[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  /// نبض أسبوعي: متوسط المزاج لكل يوم في آخر 7 أيام.
  List<double> _calculateWeeklyPulse(List<JournalEntry> entries) {
    final now = DateTime.now();
    final result = <double>[];

    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayEntries = entries.where((e) =>
          e.createdAt.year == day.year &&
          e.createdAt.month == day.month &&
          e.createdAt.day == day.day);

      if (dayEntries.isEmpty) {
        result.add(0);
        continue;
      }

      final values = dayEntries
          .map((e) => Mood.getById(e.mood)?.value ?? 0)
          .where((v) => v > 0)
          .toList();

      if (values.isEmpty) {
        result.add(0);
      } else {
        result.add(values.reduce((a, b) => a + b) / values.length);
      }
    }

    return result;
  }

  /// متوسط المزاج في آخر 30 يوم.
  double _calculateMonthlyPulse(List<JournalEntry> entries) {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 30));
    final recent = entries.where((e) => e.createdAt.isAfter(cutoff));

    final values = recent
        .map((e) => Mood.getById(e.mood)?.value ?? 0)
        .where((v) => v > 0)
        .toList();

    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// بيانات آخر 30 يوم (عدد المذكرات).
  List<int> _last30DaysData(List<JournalEntry> entries) {
    final now = DateTime.now();
    final result = <int>[];

    for (var i = 29; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final count = entries.where((e) =>
          e.createdAt.year == day.year &&
          e.createdAt.month == day.month &&
          e.createdAt.day == day.day).length;
      result.add(count);
    }

    return result;
  }

  Color _moodColorForValue(double value) {
    if (value >= 8) return const Color(0xFF00C853);
    if (value >= 6) return const Color(0xFFFFD600);
    if (value >= 4) return const Color(0xFFFF6D00);
    if (value > 0) return const Color(0xFFD50000);
    return AppColors.textTertiary;
  }

  String _emojiForValue(double value) {
    if (value == 0) return '😐';
    if (value >= 9) return '😁';
    if (value >= 7) return '😊';
    if (value >= 5) return '😐';
    if (value >= 3) return '😢';
    return '😭';
  }

  String _moodDescription(double value) {
    if (value == 0) return 'Not enough data';
    if (value >= 8) return 'Great month!';
    if (value >= 6) return 'Doing well';
    if (value >= 4) return 'Average month';
    if (value >= 2) return 'Tough month';
    return 'Consider talking to someone';
  }
}
