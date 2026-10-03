import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/nabd_ui.dart';
import '../sessions/data/sessions_data.dart';
import '../sessions/widgets/session_card.dart';

/// The practice tab: guided sessions by feeling, the calming tools, and the
/// motivation corner, in one place instead of three separate hubs.
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sessions = SessionsData.all;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('practice.title'))),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.t('sessions.howDoYouFeel'),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.t('sessions.chooseFeeling'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(l10n.t('practice.sessions')),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.count(
              crossAxisCount:
                  MediaQuery.sizeOf(context).width >= 600 ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                for (final session in sessions)
                  SessionCard(
                    session: session,
                    onTap: () =>
                        context.push('/sessions/run?id=${session.id}'),
                  ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: SectionHeader(l10n.t('practice.tools'))),
          SliverToBoxAdapter(
            child: FeatureGrid(children: [
              FeatureTile(
                icon: Icons.air_rounded,
                title: l10n.t('hub.feature.breathing.title'),
                subtitle: l10n.t('hub.feature.breathing.subtitle'),
                color: AppColors.secondary,
                onTap: () => context.push('/breathing'),
              ),
              FeatureTile(
                icon: Icons.self_improvement_rounded,
                title: l10n.t('hub.feature.worryRelease.title'),
                subtitle: l10n.t('hub.feature.worryRelease.subtitle'),
                color: AppColors.primary,
                onTap: () => context.push('/worry-release'),
              ),
              FeatureTile(
                icon: Icons.nights_stay_outlined,
                title: l10n.t('hub.feature.silent.title'),
                subtitle: l10n.t('hub.feature.silent.subtitle'),
                color: AppColors.masculinePrimary,
                onTap: () => context.push('/silent'),
              ),
              FeatureTile(
                icon: Icons.graphic_eq_rounded,
                title: l10n.t('hub.feature.soundGarden.title'),
                subtitle: l10n.t('hub.feature.soundGarden.subtitle'),
                color: AppColors.success,
                onTap: () => context.push('/sound-garden'),
              ),
              FeatureTile(
                icon: Icons.eco_rounded,
                title: l10n.t('hub.feature.gratitudeGarden.title'),
                subtitle: l10n.t('hub.feature.gratitudeGarden.subtitle'),
                color: AppColors.femininePrimary,
                onTap: () => context.push('/gratitude-garden'),
              ),
              FeatureTile(
                icon: Icons.inventory_2_outlined,
                title: l10n.t('hub.feature.worryBox.title'),
                subtitle: l10n.t('hub.feature.worryBox.subtitle'),
                color: AppColors.warning,
                onTap: () => context.push('/worry-box'),
              ),
            ]),
          ),
          SliverToBoxAdapter(child: SectionHeader(l10n.t('practice.growth'))),
          SliverToBoxAdapter(
            child: FeatureGrid(children: [
              FeatureTile(
                icon: Icons.auto_awesome_rounded,
                title: l10n.t('hub.feature.motivation.title'),
                subtitle: l10n.t('hub.feature.motivation.subtitle'),
                color: AppColors.pulse,
                onTap: () => context.push('/motivation'),
              ),
              FeatureTile(
                icon: Icons.lightbulb_outline_rounded,
                title: l10n.t('hub.feature.wisdom.title'),
                subtitle: l10n.t('hub.feature.wisdom.subtitle'),
                color: AppColors.warning,
                onTap: () => context.push('/wisdom'),
              ),
              FeatureTile(
                icon: Icons.flag_rounded,
                title: l10n.t('hub.feature.challenges.title'),
                subtitle: l10n.t('hub.feature.challenges.subtitle'),
                color: AppColors.secondary,
                onTap: () => context.push('/challenges'),
              ),
              FeatureTile(
                icon: Icons.emoji_events_rounded,
                title: l10n.t('hub.feature.achievements.title'),
                subtitle: l10n.t('hub.feature.achievements.subtitle'),
                color: AppColors.primary,
                onTap: () => context.push('/achievements'),
              ),
            ]),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}
