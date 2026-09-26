import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../models/journal_entry.dart';
import '../../models/mood.dart';
import '../../services/database_service.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final entries = _db.getAllEntries();
    final summary = _StatsSummary.fromEntries(entries);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإحصائيات')),
        body: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _buildOverview(context, summary),
              const SizedBox(height: 24),
              _buildTimeline(context, summary),
              const SizedBox(height: 24),
              _buildMoodDistribution(context, summary),
              const SizedBox(height: 24),
              _buildWordCloud(context, summary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverview(BuildContext context, _StatsSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('نظرة عامة'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.55,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _statCard(
              icon: Icons.menu_book_outlined,
              value: '${summary.totalEntries}',
              label: 'إجمالي الإدخالات',
              color: AppColors.primary,
            ),
            _statCard(
              icon: Icons.calendar_month_outlined,
              value: '${summary.activeDays}',
              label: 'أيام الكتابة',
              color: AppColors.success,
            ),
            _statCard(
              icon: Icons.local_fire_department_outlined,
              value: '${summary.currentStreak}',
              label: 'التتابع الحالي',
              color: AppColors.warning,
            ),
            _statCard(
              icon: Icons.emoji_events_outlined,
              value: '${summary.longestStreak}',
              label: 'أطول تتابع',
              color: AppColors.danger,
            ),
            _statCard(
              icon: Icons.self_improvement_outlined,
              value: '${summary.completedSessions}',
              label: 'جلسات مكتملة',
              color: const Color(0xFF26A69A),
            ),
            _statCard(
              icon: Icons.text_fields_outlined,
              value: '${summary.totalWords}',
              label: 'إجمالي الكلمات',
              color: const Color(0xFF7E57C2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context, _StatsSummary summary) {
    final maxCount = summary.lastSevenDays
        .map((day) => day.count)
        .fold<int>(0, (max, count) => count > max ? count : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('ملخص آخر 7 أيام'),
        const SizedBox(height: 12),
        _panel(
          context,
          child: Column(
            children: [
              for (final day in summary.lastSevenDays) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 72,
                      child: Text(
                        day.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: maxCount == 0 ? 0 : day.count / maxCount,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${day.count}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                if (day != summary.lastSevenDays.last)
                  const SizedBox(height: 14),
              ],
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'هذا الشهر: ${summary.thisMonthEntries} إدخال',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMoodDistribution(
    BuildContext context,
    _StatsSummary summary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('توزيع المشاعر'),
        const SizedBox(height: 12),
        if (summary.totalMoodEntries == 0)
          _emptyPanel(context, 'لا توجد مشاعر مسجلة بعد')
        else
          _panel(
            context,
            child: Column(
              children: [
                for (final mood in Mood.journalMoods)
                  _moodRow(context, mood, summary.moodCounts[mood.id] ?? 0,
                      summary.totalMoodEntries),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWordCloud(BuildContext context, _StatsSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('أكثر الكلمات استخدامًا'),
        const SizedBox(height: 12),
        summary.topWords.isEmpty
            ? _emptyPanel(
                context, 'اكتب في Journal لعرض الكلمات الأكثر تكرارًا')
            : _panel(
                context,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < summary.topWords.length; i++)
                      Chip(
                        avatar: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          child: Text('${i + 1}'),
                        ),
                        label: Text(
                          '${summary.topWords[i].word}  ${summary.topWords[i].count}',
                          style: TextStyle(
                            fontSize:
                                12 + (summary.topWords[i].count > 2 ? 3 : 0),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _moodRow(
    BuildContext context,
    Mood mood,
    int count,
    int total,
  ) {
    final ratio = total == 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(mood.emoji, style: const TextStyle(fontSize: 21)),
          ),
          SizedBox(
            width: 64,
            child: Text(mood.labelAr),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: ratio,
                backgroundColor: mood.color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(mood.color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            child: Text(
              '$count (${(ratio * 100).round()}%)',
              textAlign: TextAlign.left,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 21),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
      );

  Widget _panel(BuildContext context, {required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: child,
      );

  Widget _emptyPanel(BuildContext context, String message) => _panel(
        context,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
}

class _StatsSummary {
  final int totalEntries;
  final int totalWords;
  final int activeDays;
  final int currentStreak;
  final int longestStreak;
  final int completedSessions;
  final int thisMonthEntries;
  final Map<String, int> moodCounts;
  final int totalMoodEntries;
  final List<_DaySummary> lastSevenDays;
  final List<_WordSummary> topWords;

  const _StatsSummary({
    required this.totalEntries,
    required this.totalWords,
    required this.activeDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.completedSessions,
    required this.thisMonthEntries,
    required this.moodCounts,
    required this.totalMoodEntries,
    required this.lastSevenDays,
    required this.topWords,
  });

  factory _StatsSummary.fromEntries(List<JournalEntry> entries) {
    final dates = entries
        .map((entry) => _dateOnly(entry.createdAt))
        .toSet()
        .toList()
      ..sort();
    final dateCounts = <DateTime, int>{};
    for (final entry in entries) {
      final date = _dateOnly(entry.createdAt);
      dateCounts[date] = (dateCounts[date] ?? 0) + 1;
    }

    final now = DateTime.now();
    final today = _dateOnly(now);
    final currentStreak =
        dates.contains(today) ? _streakEndingAt(dates, today) : 0;
    final longestStreak = _longestStreak(dates);
    final moodCounts = <String, int>{};
    for (final entry in entries) {
      if (Mood.journalMoods.any((mood) => mood.id == entry.mood)) {
        moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
      }
    }

    final wordCounts = _countWords(entries);
    final lastSevenDays = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return _DaySummary(
        label: _arabicDayLabel(date.weekday),
        count: dateCounts[date] ?? 0,
      );
    });

    return _StatsSummary(
      totalEntries: entries.length,
      totalWords:
          entries.fold(0, (sum, entry) => sum + _wordCount(entry.content)),
      activeDays: dates.length,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      completedSessions: _completedSessions(),
      thisMonthEntries: entries
          .where((entry) =>
              entry.createdAt.year == now.year &&
              entry.createdAt.month == now.month)
          .length,
      moodCounts: moodCounts,
      totalMoodEntries: moodCounts.values.fold(0, (sum, count) => sum + count),
      lastSevenDays: lastSevenDays,
      topWords: wordCounts.entries
          .map((entry) => _WordSummary(word: entry.key, count: entry.value))
          .toList()
        ..sort((a, b) => b.count.compareTo(a.count)),
    );
  }

  static int _completedSessions() {
    final raw = Hive.box('settings').get('sessions_completed_total');
    return raw is int ? raw : 0;
  }

  static int _streakEndingAt(List<DateTime> dates, DateTime end) {
    final available = dates.toSet();
    var length = 0;
    var date = end;
    while (available.contains(date)) {
      length++;
      date = date.subtract(const Duration(days: 1));
    }
    return length;
  }

  static int _longestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    var longest = 1;
    var current = 1;
    for (var i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  static Map<String, int> _countWords(List<JournalEntry> entries) {
    const ignored = {
      'من',
      'في',
      'على',
      'إلى',
      'عن',
      'مع',
      'هذا',
      'هذه',
      'ذلك',
      'التي',
      'الذي',
      'أنا',
      'أنت',
      'هو',
      'هي',
      'نحن',
      'هم',
      'و',
      'أو',
      'ثم',
      'لا',
      'ما',
      'لم',
      'لن',
      'كان',
      'كانت',
      'كل',
      'قد',
      'لقد',
      'إن',
      'أن',
      'يا',
      'the',
      'and',
      'or',
      'to',
      'of',
      'in',
      'on',
      'is',
      'a',
      'i',
      'it',
      'my',
    };
    final counts = <String, int>{};
    final splitter = RegExp(r'[\s\n\r،؛,.!?؟:;()\[\]{}"“”]+');
    for (final entry in entries) {
      for (final raw in entry.content.toLowerCase().split(splitter)) {
        final word = raw.trim();
        if (word.length < 2 || ignored.contains(word)) continue;
        counts[word] = (counts[word] ?? 0) + 1;
      }
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(12));
  }

  static int _wordCount(String content) =>
      content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _arabicDayLabel(int weekday) {
    const labels = [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد'
    ];
    return labels[weekday - 1];
  }
}

class _DaySummary {
  final String label;
  final int count;

  const _DaySummary({required this.label, required this.count});
}

class _WordSummary {
  final String word;
  final int count;

  const _WordSummary({required this.word, required this.count});
}
