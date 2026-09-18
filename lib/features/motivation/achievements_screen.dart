import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../services/database_service.dart';
import '../../services/motivation_service.dart';

/// AchievementsScreen — عرض الإنجازات.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = DatabaseService();
    final service = AchievementService();

    final entries = db.getAllEntries();
    final unlocked = service.unlockedIds;

    final userStats = {
      'entries': entries.length,
      'streak': _calculateStreak(),
      'words': entries.fold<int>(
          0, (sum, e) => sum + e.content.split(RegExp(r'\s+')).length),
      'moods': entries.map((e) => e.mood).where((m) => m.isNotEmpty).toSet().length,
      'gratitude': 0, // TODO: hook gratitude
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFF8B6914)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 12),
                Text(
                  '${unlocked.length} / ${Achievement.all.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Achievements Unlocked',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Grid of achievements
          ...Achievement.all.map((a) {
            final isUnlocked = unlocked.contains(a.id);
            final progress = _progressFor(a, userStats);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUnlocked
                      ? const Color(0xFFD4AF37)
                      : Colors.transparent,
                  width: isUnlocked ? 2 : 0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: isUnlocked
                          ? const LinearGradient(
                              colors: [Color(0xFFD4AF37), Color(0xFF8B6914)],
                            )
                          : null,
                      color: isUnlocked
                          ? null
                          : AppColors.textTertiary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      a.emoji,
                      style: TextStyle(
                        fontSize: 26,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.titleEn,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isUnlocked
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          a.description,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (!isUnlocked && progress > 0) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 4,
                              backgroundColor: AppColors.textTertiary
                                  .withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isUnlocked)
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFFD4AF37),
                    )
                      .animate(onPlay: (c) => c.repeat())
                      .shimmer(duration: 2000.ms),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  double _progressFor(Achievement a, Map<String, int> stats) {
    final current = stats[a.requirementType] ?? 0;
    return (current / a.requirement).clamp(0.0, 1.0);
  }

  int _calculateStreak() {
    final db = DatabaseService();
    final entries = db.getAllEntries();
    if (entries.isEmpty) return 0;

    final dates = entries
        .map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
        .toSet();

    var streak = 0;
    var date = DateTime.now();
    while (dates.contains(DateTime(date.year, date.month, date.day))) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
