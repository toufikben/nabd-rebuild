import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../services/database_service.dart';
import '../../services/motivation_service.dart';
import '../../core/storage.dart';

/// AchievementsScreen — عرض الإنجازات.
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() =>
      _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncProgress());
  }

  /// Opening an achievement is the screen's job: nothing else calls `unlock`,
  /// so without this the list would stay empty forever.
  Future<void> _syncProgress() async {
    final fresh = await AchievementService().unlockFromJournal(
      DatabaseService().getAllEntries(),
      contentBox(),
    );
    if (fresh.isNotEmpty && mounted) setState(() {});
  }

  Map<String, int> _userStats() => AchievementService.progressFor(
        DatabaseService().getAllEntries(),
        contentBox(),
      );

  @override
  Widget build(BuildContext context) {
    final service = AchievementService();

    final unlocked = service.unlockedIds;
    final userStats = _userStats();

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).t('achievements.title'))),
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
                Text(
                  AppLocalizations.of(context).t('achievements.unlocked'),
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

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
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.titleFor(AppLocalizations.of(context).isArabic),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isUnlocked
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          a.descriptionFor(AppLocalizations.of(context).isArabic),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (!isUnlocked && progress > 0) ...[
                          SizedBox(height: 6),
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
}
