import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/mood_patterns.dart';
import '../../core/streak.dart';
import '../../services/monetization_service.dart';
import '../../widgets/nabd_ui.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data_revision.dart';
import '../../models/journal_entry.dart';
import '../../models/mood.dart';
import '../../services/database_service.dart';
import '../../core/storage.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    ref.watch(dataRevisionProvider);
    final entries = _db.getAllEntries();
    final summary = _StatsSummary.fromEntries(entries);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).t('insights.title'))),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _buildOverview(context, summary),
            const SizedBox(height: 24),
            _buildExplore(context),
            const SizedBox(height: 24),
            _buildTimeline(context, summary),
            const SizedBox(height: 24),
            _buildMoodDistribution(context, summary),
            const SizedBox(height: 24),
            _buildPatterns(context, MoodPatterns.compute(entries)),
            const SizedBox(height: 24),
            _buildWordCloud(context, summary),
          ],
        ),
      ),
    );
  }

  /// The other insight screens, which used to hide behind a menu.
  Widget _buildExplore(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isPro = ref.watch(monetizationProvider.select((s) => s.isPro));
    final pro = isPro ? null : l10n.t('pro.badge');
    final tiles = <(IconData, String, String, String, Color, String?)>[
      (Icons.wb_cloudy_outlined, 'hub.feature.weather.title',
          'hub.feature.weather.subtitle', '/weather', AppColors.secondary, null),
      (Icons.calendar_month_rounded, 'hub.feature.monthly.title',
          'hub.feature.monthly.subtitle', '/monthly', AppColors.primary, null),
      (Icons.calendar_view_week_rounded, 'hub.feature.weeklyPulse.title',
          'hub.feature.weeklyPulse.subtitle', '/weekly-pulse', AppColors.pulse,
          null),
      (Icons.grid_view_rounded, 'hub.feature.heatmap.title',
          'hub.feature.heatmap.subtitle', '/heatmap', AppColors.success, null),
      (Icons.wb_sunny_outlined, 'hub.feature.echoes.title',
          'hub.feature.echoes.subtitle', '/echoes', AppColors.warning, null),
      (Icons.auto_awesome, 'hub.feature.yearReview.title',
          'hub.feature.yearReview.subtitle', '/year-review', AppColors.primary,
          pro),
      (Icons.radar_rounded, 'hub.feature.emotionRadar.title',
          'hub.feature.emotionRadar.subtitle', '/emotion-radar',
          AppColors.femininePrimary, pro),
      (Icons.cloud_queue_rounded, 'hub.feature.wordCloud.title',
          'hub.feature.wordCloud.subtitle', '/word-cloud',
          AppColors.masculinePrimary, pro),
      (Icons.sell_outlined, 'hub.feature.tags.title',
          'hub.feature.tags.subtitle', '/tags', AppColors.primaryGlow, null),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.t('insights.explore')),
        const SizedBox(height: 12),
        EqualHeightGrid(
          columns: MediaQuery.sizeOf(context).width >= 600 ? 4 : 2,
          children: [
            for (final (icon, title, subtitle, route, color, badge) in tiles)
              FeatureTile(
                icon: icon,
                title: l10n.t(title),
                subtitle: l10n.t(subtitle),
                color: color,
                badge: badge,
                onTap: () async {
                  await context.push(route);
                  if (mounted) setState(() {});
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverview(BuildContext context, _StatsSummary summary) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.t('stats.overview')),
        const SizedBox(height: 12),
        EqualHeightGrid(
          columns: 2,
          spacing: 10,
          children: [
            _statCard(
              icon: Icons.menu_book_outlined,
              value: '${summary.totalEntries}',
              label: l10n.t('stats.totalEntries'),
              color: AppColors.primary,
            ),
            _statCard(
              icon: Icons.calendar_month_outlined,
              value: '${summary.activeDays}',
              label: l10n.t('stats.writingDays'),
              color: AppColors.success,
            ),
            _statCard(
              icon: Icons.local_fire_department_outlined,
              value: '${summary.currentStreak}',
              label: l10n.t('stats.currentStreak'),
              color: AppColors.warning,
            ),
            _statCard(
              icon: Icons.emoji_events_outlined,
              value: '${summary.longestStreak}',
              label: l10n.t('stats.longestStreak'),
              color: AppColors.danger,
            ),
            _statCard(
              icon: Icons.self_improvement_outlined,
              value: '${summary.completedSessions}',
              label: l10n.t('stats.completedSessions'),
              color: const Color(0xFF26A69A),
            ),
            _statCard(
              icon: Icons.text_fields_outlined,
              value: '${summary.totalWords}',
              label: l10n.t('stats.totalWords'),
              color: const Color(0xFF7E57C2),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeline(BuildContext context, _StatsSummary summary) {
    final l10n = AppLocalizations.of(context);
    final weekdayFormat =
        DateFormat.EEEE(Localizations.localeOf(context).toString());
    final maxCount = summary.lastSevenDays
        .map((day) => day.count)
        .fold<int>(0, (max, count) => count > max ? count : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.t('stats.weekSummary')),
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
                        weekdayFormat.format(DateTime(2024, 1, day.weekday)),
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
              SizedBox(height: 14),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  l10n.t('stats.monthSummary').replaceAll(
                        '{n}',
                        '${summary.thisMonthEntries}',
                      ),
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
        _sectionTitle(AppLocalizations.of(context).t('stats.moodDistribution')),
        const SizedBox(height: 12),
        if (summary.totalMoodEntries == 0)
          _emptyPanel(context, AppLocalizations.of(context).t('stats.noMoods'))
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

  Widget _buildPatterns(BuildContext context, MoodPatterns patterns) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = l10n.locale.languageCode;
    String weekdayName(int weekday) =>
        DateFormat.EEEE(locale).format(DateTime(2026, 10, 4 + weekday));
    String weekdayShort(int weekday) =>
        DateFormat.E(locale).format(DateTime(2026, 10, 4 + weekday));
    // Start the week where the locale's calendar does (Saturday in Arabic,
    // Monday in most of Europe, Sunday in English).
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final first = firstDay == 0 ? 7 : firstDay;
    final order = [for (var i = 0; i < 7; i++) (first - 1 + i) % 7 + 1];

    final insights = <String>[
      if (patterns.calmestWeekday case final day?)
        l10n.t('stats.patterns.calmDay').replaceAll('{day}', weekdayName(day)),
      if (patterns.hardestWeekday case final day?)
        l10n.t('stats.patterns.hardDay').replaceAll('{day}', weekdayName(day)),
      if (patterns.calmestDayPart case final part?)
        l10n.t('stats.patterns.calmPart')
            .replaceAll('{part}', l10n.t('daypart.${part.name}')),
      if (patterns.hardestDayPart case final part?)
        l10n.t('stats.patterns.hardPart')
            .replaceAll('{part}', l10n.t('daypart.${part.name}')),
      for (final tag in patterns.tags)
        l10n
            .t(tag.difference > 0 ? 'stats.patterns.tagUp' : 'stats.patterns.tagDown')
            .replaceAll('{tag}', tag.tag),
    ];

    Color colorFor(double average) => Color.lerp(
        AppColors.primary, AppColors.secondary, ((average - 2) / 7).clamp(0, 1))!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.t('stats.patterns')),
        const SizedBox(height: 12),
        if (!patterns.hasEnough)
          _emptyPanel(
            context,
            l10n.t('stats.patterns.needMore').replaceAll(
                '{n}', '${MoodPatterns.minEntries - patterns.overall.count}'),
          )
        else
          _panel(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in insights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.insights_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(line, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(l10n.t('stats.patterns.weekday'),
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: 10),
                SizedBox(
                  height: 96,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final day in order)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                height: 6 +
                                    58 * ((patterns.byWeekday[day]?.average ?? 0) / 10),
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: patterns.byWeekday[day] == null
                                      ? theme.colorScheme.surfaceContainerHighest
                                      : colorFor(patterns.byWeekday[day]!.average),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                weekdayShort(day),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: theme.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.t('stats.patterns.daypart'),
                    style: theme.textTheme.labelLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final part in DayPart.values)
                      if (patterns.byDayPart[part] case final avg?)
                        Chip(
                          avatar: CircleAvatar(
                            backgroundColor: colorFor(avg.average),
                            radius: 6,
                          ),
                          label: Text(
                            '${l10n.t('daypart.short.${part.name}')}  '
                            '${avg.average.toStringAsFixed(1)}',
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.t('stats.patterns.note'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWordCloud(BuildContext context, _StatsSummary summary) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(l10n.t('stats.topWords')),
        const SizedBox(height: 12),
        summary.topWords.isEmpty
            ? _emptyPanel(context, l10n.t('stats.topWordsEmpty'))
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
            width: 84,
            child: Text(
              mood.label(AppLocalizations.of(context).locale.languageCode),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
          SizedBox(width: 8),
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
    final moments = entries.map((entry) => entry.createdAt);
    final currentStreak = StreakCalculator.current(moments, now: now);
    final longestStreak = StreakCalculator.longest(moments);
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
        weekday: date.weekday,
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
    final raw = contentBox().get(ContentKeys.sessionsCompleted);
    return raw is int ? raw : 0;
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
}

class _DaySummary {
  final int weekday;
  final int count;

  const _DaySummary({required this.weekday, required this.count});
}

class _WordSummary {
  final String word;
  final int count;

  const _WordSummary({required this.word, required this.count});
}
