import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_bottom_navigation.dart';

enum NabdSection { writing, journey, analytics }

class SectionHubScreen extends StatelessWidget {
  final NabdSection section;
  const SectionHubScreen({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final c = _config(section);
    final index = section == NabdSection.writing
        ? 1
        : section == NabdSection.journey
            ? 2
            : 3;

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
                    Icon(c.icon,
                        size: 34, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(c.subtitle),
                      ],
                    )),
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
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(f.icon,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                            const Spacer(),
                            Text(f.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Text(f.subtitle,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
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
      bottomNavigationBar: AppBottomNavigation(currentIndex: index),
    );
  }

  _Config _config(NabdSection s) {
    switch (s) {
      case NabdSection.writing:
        return const _Config(
            'Writing',
            'Everything you need to capture your thoughts.',
            Icons.edit_note_rounded, [
          _Feature('New Entry', 'Write something new',
              Icons.add_circle_outline_rounded, '/editor'),
          _Feature(
              'Search', 'Find an old entry', Icons.search_rounded, '/search'),
          _Feature('Calendar', 'Browse by date', Icons.calendar_month_rounded,
              '/calendar'),
          _Feature('Dream Journal', 'Record your dreams',
              Icons.nightlight_round, '/dream-journal'),
          _Feature('Gratitude Journal', 'Keep the good moments',
              Icons.favorite_rounded, '/gratitude-journal'),
          _Feature('Worry Box', 'Put worries somewhere safe',
              Icons.inventory_2_outlined, '/worry-box'),
          _Feature('Future Letters', 'Write to your future self',
              Icons.mark_email_unread_outlined, '/future-letters'),
          _Feature('Unsent Letters', 'Words you never sent',
              Icons.mail_outline_rounded, '/unsent-letters'),
          _Feature('Legacy Journal', 'Preserve your story',
              Icons.auto_stories_rounded, '/legacy-journal'),
          _Feature('Time Capsule', 'Save memories for later',
              Icons.schedule_rounded, '/time-capsule'),
        ]);
      case NabdSection.journey:
        return const _Config('My Journey',
            'Small practices that help you move forward.', Icons.spa_rounded, [
          _Feature('Garden', 'Grow your personal garden',
              Icons.local_florist_rounded, '/garden'),
          _Feature('Gratitude Garden', 'Grow gratitude', Icons.eco_rounded,
              '/gratitude-garden'),
          _Feature('Breathing', 'Take a mindful pause', Icons.air_rounded,
              '/breathing'),
          _Feature('Worry Release', 'Let thoughts go',
              Icons.self_improvement_rounded, '/worry-release'),
          _Feature('Challenges', 'Build positive habits', Icons.flag_rounded,
              '/challenges'),
          _Feature('Achievements', 'See your progress',
              Icons.emoji_events_rounded, '/achievements'),
        ]);
      case NabdSection.analytics:
        return const _Config(
            'Insights',
            'Understand your journal and your patterns.',
            Icons.insights_rounded, [
          _Feature('Statistics', 'Your journal numbers',
              Icons.bar_chart_rounded, '/stats'),
          _Feature('Heatmap', 'Your writing activity', Icons.grid_view_rounded,
              '/heatmap'),
          _Feature('Mood Weather', 'Your emotional climate',
              Icons.cloud_rounded, '/weather'),
          _Feature('Word Cloud', 'Words that appear most',
              Icons.cloud_queue_rounded, '/word-cloud'),
          _Feature('Emotion Radar', 'Explore emotional patterns',
              Icons.radar_rounded, '/emotion-radar'),
          _Feature('Year Review', 'Look back at your year',
              Icons.calendar_view_month_rounded, '/year-review'),
          _Feature(
              'Tags', 'Organize your entries', Icons.sell_outlined, '/tags'),
        ]);
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
