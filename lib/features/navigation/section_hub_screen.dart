import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';

enum NabdSection { writing, journey, analytics }

class SectionHubScreen extends StatelessWidget {
  final NabdSection section;
  const SectionHubScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final c = _config(section, AppLocalizations.of(context));
    return Scaffold(
      appBar: AppBar(title: Text(c.title)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 600 ? 3 : 2;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer,
                      Theme.of(context).colorScheme.secondaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(
                      c.icon,
                      size: 34,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(c.subtitle),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: c.features.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 2 ? 1.05 : 1.15,
                ),
                itemBuilder: (_, i) {
                  final f = c.features[i];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => context.push(f.route),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                f.icon,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              f.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              f.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  _Config _config(NabdSection s, AppLocalizations l10n) {
    String t(String key) => l10n.t(key);
    switch (s) {
      case NabdSection.writing:
        return _Config(
          t('hub.writing.title'),
          t('hub.writing.subtitle'),
          Icons.edit_note_rounded,
          [
            _Feature(
              t('hub.feature.editor.title'),
              t('hub.feature.editor.subtitle'),
              Icons.add_circle_outline_rounded,
              '/editor',
            ),
            _Feature(
              t('hub.feature.search.title'),
              t('hub.feature.search.subtitle'),
              Icons.search_rounded,
              '/search',
            ),
            _Feature(
              t('hub.feature.calendar.title'),
              t('hub.feature.calendar.subtitle'),
              Icons.calendar_month_rounded,
              '/calendar',
            ),
            _Feature(
              t('hub.feature.dream.title'),
              t('hub.feature.dream.subtitle'),
              Icons.nightlight_round,
              '/dream-journal',
            ),
            _Feature(
              t('hub.feature.gratitudeJournal.title'),
              t('hub.feature.gratitudeJournal.subtitle'),
              Icons.favorite_rounded,
              '/gratitude-journal',
            ),
            _Feature(
              t('hub.feature.worryBox.title'),
              t('hub.feature.worryBox.subtitle'),
              Icons.inventory_2_outlined,
              '/worry-box',
            ),
            _Feature(
              t('hub.feature.letters.title'),
              t('hub.feature.letters.subtitle'),
              Icons.mark_email_unread_outlined,
              '/letters',
            ),
            _Feature(
              t('hub.feature.legacy.title'),
              t('hub.feature.legacy.subtitle'),
              Icons.auto_stories_rounded,
              '/legacy-journal',
            ),
            _Feature(
              t('hub.feature.timeCapsule.title'),
              t('hub.feature.timeCapsule.subtitle'),
              Icons.schedule_rounded,
              '/time-capsule',
            ),
          ],
        );
      case NabdSection.journey:
        return _Config(
          t('hub.journey.title'),
          t('hub.journey.subtitle'),
          Icons.spa_rounded,
          [
            _Feature(
              t('hub.feature.garden.title'),
              t('hub.feature.garden.subtitle'),
              Icons.local_florist_rounded,
              '/garden',
            ),
            _Feature(
              t('hub.feature.gratitudeGarden.title'),
              t('hub.feature.gratitudeGarden.subtitle'),
              Icons.eco_rounded,
              '/gratitude-garden',
            ),
            _Feature(
              t('hub.feature.breathing.title'),
              t('hub.feature.breathing.subtitle'),
              Icons.air_rounded,
              '/breathing',
            ),
            _Feature(
              t('hub.feature.worryRelease.title'),
              t('hub.feature.worryRelease.subtitle'),
              Icons.self_improvement_rounded,
              '/worry-release',
            ),
            _Feature(
              t('hub.feature.motivation.title'),
              t('hub.feature.motivation.subtitle'),
              Icons.auto_awesome_rounded,
              '/motivation',
            ),
            _Feature(
              t('hub.feature.wisdom.title'),
              t('hub.feature.wisdom.subtitle'),
              Icons.lightbulb_outline_rounded,
              '/wisdom',
            ),
            _Feature(
              t('hub.feature.sage.title'),
              t('hub.feature.sage.subtitle'),
              Icons.auto_awesome_rounded,
              '/sage',
            ),
            _Feature(
              t('hub.feature.challenges.title'),
              t('hub.feature.challenges.subtitle'),
              Icons.flag_rounded,
              '/challenges',
            ),
            _Feature(
              t('hub.feature.achievements.title'),
              t('hub.feature.achievements.subtitle'),
              Icons.emoji_events_rounded,
              '/achievements',
            ),
          ],
        );
      case NabdSection.analytics:
        return _Config(
          t('hub.analytics.title'),
          t('hub.analytics.subtitle'),
          Icons.insights_rounded,
          [
            _Feature(
              t('hub.feature.stats.title'),
              t('hub.feature.stats.subtitle'),
              Icons.bar_chart_rounded,
              '/stats',
            ),
            _Feature(
              t('hub.feature.heatmap.title'),
              t('hub.feature.heatmap.subtitle'),
              Icons.grid_view_rounded,
              '/heatmap',
            ),
            _Feature(
              t('hub.feature.weather.title'),
              t('hub.feature.weather.subtitle'),
              Icons.cloud_rounded,
              '/weather',
            ),
            _Feature(
              t('hub.feature.wordCloud.title'),
              t('hub.feature.wordCloud.subtitle'),
              Icons.cloud_queue_rounded,
              '/word-cloud',
            ),
            _Feature(
              t('hub.feature.emotionRadar.title'),
              t('hub.feature.emotionRadar.subtitle'),
              Icons.radar_rounded,
              '/emotion-radar',
            ),
            _Feature(
              t('hub.feature.yearReview.title'),
              t('hub.feature.yearReview.subtitle'),
              Icons.calendar_view_month_rounded,
              '/year-review',
            ),
            _Feature(
              t('hub.feature.tags.title'),
              t('hub.feature.tags.subtitle'),
              Icons.sell_outlined,
              '/tags',
            ),
            _Feature(
              t('hub.feature.echoes.title'),
              t('hub.feature.echoes.subtitle'),
              Icons.wb_sunny_outlined,
              '/echoes',
            ),
            _Feature(
              t('hub.feature.weeklyPulse.title'),
              t('hub.feature.weeklyPulse.subtitle'),
              Icons.calendar_today_outlined,
              '/weekly-pulse',
            ),
          ],
        );
    }
  }
}

class _Config {
  final String title, subtitle;
  final IconData icon;
  final List<_Feature> features;
  const _Config(this.title, this.subtitle, this.icon, this.features);
}

class _Feature {
  final String title, subtitle, route;
  final IconData icon;
  const _Feature(this.title, this.subtitle, this.icon, this.route);
}
