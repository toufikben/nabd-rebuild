import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/journal_entry.dart';
import '../../models/mood.dart';
import '../../models/mood_weather.dart';
import '../../services/database_service.dart';
import '../../widgets/weather_widget.dart';
import '../../core/l10n/app_localizations.dart';

/// WeatherScreen — عرض الطقس المزاجي.
class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = DatabaseService();
    final entries = db.getAllEntries();

    final now = DateTime.now();
    final weekWeather = <MoodWeather>[];
    final dayLabels = <String>[];

    // 7-day forecast
    for (var i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayEntries = entries.where((e) =>
          e.createdAt.year == day.year &&
          e.createdAt.month == day.month &&
          e.createdAt.day == day.day).toList();

      if (dayEntries.isEmpty) {
        weekWeather.add(MoodWeather.fromMoodValue(0));
      } else {
        final values = dayEntries
            .map((e) => Mood.getById(e.mood)?.value ?? 5)
            .toList();
        final avg = values.reduce((a, b) => a + b) / values.length;
        weekWeather.add(MoodWeather.fromMoodValue(avg.toDouble()));
      }

      dayLabels.add(_dayLabel(day.weekday, context));
    }

    // Today's weather
    final todayEntries = entries.where((e) =>
        e.createdAt.year == now.year &&
        e.createdAt.month == now.month &&
        e.createdAt.day == now.day).toList();

    MoodWeather todayWeather;
    if (todayEntries.isEmpty) {
      todayWeather = MoodWeather.fromMoodValue(0);
    } else {
      final values = todayEntries
          .map((e) => Mood.getById(e.mood)?.value ?? 5)
          .toList();
      final avg = values.reduce((a, b) => a + b) / values.length;
      todayWeather = MoodWeather.fromMoodValue(avg.toDouble());
    }

    // Monthly average
    final monthlyWeather = _calculateMonthlyWeather(entries);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).moodWeather)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── Today ───
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: todayWeather.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context).today,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                WeatherWidget(
                  weather: todayWeather,
                  size: 100,
                ),
                const SizedBox(height: 16),
                Text(
                  todayWeather.labelEn,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Week forecast ───
          WeatherForecastCard(
            weekWeather: weekWeather,
            dayLabels: dayLabels,
          ),
          SizedBox(height: 24),

          // ─── Monthly average ───
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context).thisMonth,
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),
                WeatherWidget(
                  weather: monthlyWeather,
                  size: 80,
                ),
                SizedBox(height: 12),
                Text(
                  monthlyWeather.labelEn,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  MoodWeather _calculateMonthlyWeather(List<JournalEntry> entries) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final recent = entries
        .where((e) => e.createdAt.isAfter(cutoff))
        .map((e) => Mood.getById(e.mood)?.value ?? 5)
        .toList();

    if (recent.isEmpty) return MoodWeather.fromMoodValue(0);
    final avg = recent.reduce((a, b) => a + b) / recent.length;
    return MoodWeather.fromMoodValue(avg.toDouble());
  }

  String _dayLabel(int weekday, BuildContext context) {
    final locale = AppLocalizations.of(context).locale;
    // Use ARB files based on locale
    if (locale.languageCode == 'ar') {
      const arLabels = [
        'الأحد',
        'الإثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
      ];
      return arLabels[(weekday - 1) % 7];
    } else {
      const enLabels = [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
      ];
      return enLabels[(weekday - 1) % 7];
    }
  }
}
