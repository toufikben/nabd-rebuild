import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/data_revision.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/streak.dart';
import '../../core/theme/app_colors.dart';
import '../../core/writing_prompts.dart';
import '../../models/mood.dart';
import '../../services/database_service.dart';
import '../../services/garden_service.dart';
import '../../services/motivation_service.dart';
import '../../widgets/entry_card.dart';
import '../../widgets/nabd_ui.dart';

/// The first tab: a calm start to the day. Today's question, the streak,
/// a one-tap mood check-in, a few calming tools and the latest entries.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final DatabaseService _db = DatabaseService();
  (String, String)? _quote;

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return l10n.t('today.morning');
    if (hour >= 12 && hour < 17) return l10n.t('today.afternoon');
    if (hour >= 17 && hour < 22) return l10n.t('today.evening');
    return l10n.t('today.night');
  }

  Future<void> _open(String route) async {
    await context.push(route);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    ref.watch(dataRevisionProvider);
    final garden = ref.watch(gardenProvider);
    final locale = l10n.locale.languageCode;

    final entries = _db.getAllEntries();
    final moments = entries.map((e) => e.createdAt);
    final streak = StreakCalculator.current(moments);
    final wroteToday = StreakCalculator.wroteToday(moments);
    final now = DateTime.now();
    final thisMonth = entries
        .where((e) => e.createdAt.year == now.year && e.createdAt.month == now.month)
        .length;
    final growth = garden.seeds.isEmpty
        ? 0
        : garden.seeds.map((s) => s.growthPoints).reduce((a, b) => a > b ? a : b);
    _quote ??= MotivationService.getTodayQuoteFor(l10n.isArabic);
    final quote = _quote!;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat.MMMMEEEEd(locale).format(now),
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          Text(
                            _greeting(l10n),
                            style: theme.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.t('menu.search'),
                      onPressed: () => _open('/search'),
                      icon: const Icon(Icons.search_rounded),
                    ),
                    IconButton(
                      tooltip: l10n.t('settings.title'),
                      onPressed: () => _open('/settings'),
                      icon: const Icon(Icons.tune_rounded),
                    ),
                  ],
                ),
              ),
            ),

            // ── Today's question ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: NabdCard(
                  gradient: AppColors.brandGradient,
                  padding: const EdgeInsets.all(22),
                  onTap: () => _open('/editor'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Colors.white70, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            wroteToday
                                ? l10n.t('today.wrote')
                                : l10n.t('today.promptLabel'),
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        WritingPrompts.today(l10n),
                        style: theme.textTheme.titleLarge
                            ?.copyWith(color: Colors.white, height: 1.45),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryDark,
                            iconColor: AppColors.primaryDark,
                          ),
                          onPressed: () => _open('/editor'),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: Text(wroteToday
                              ? l10n.t('today.writeMore')
                              : l10n.t('today.write')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Numbers ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    StatPill(
                      icon: Icons.local_fire_department_rounded,
                      value: '$streak',
                      label: l10n.t('today.streak'),
                      color: AppColors.pulse,
                    ),
                    const SizedBox(width: 10),
                    StatPill(
                      icon: Icons.edit_calendar_rounded,
                      value: '$thisMonth',
                      label: l10n.t('today.month'),
                    ),
                    const SizedBox(width: 10),
                    StatPill(
                      icon: Icons.local_florist_rounded,
                      value: '$growth%',
                      label: l10n.t('today.garden'),
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ),

            // ── Mood check-in ─────────────────────────────────────────
            SliverToBoxAdapter(child: SectionHeader(l10n.t('today.feel'))),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: Mood.journalMoods.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final mood = Mood.journalMoods[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _open('/editor?mood=${mood.id}'),
                      child: Container(
                        width: 70,
                        decoration: BoxDecoration(
                          color: mood.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(mood.emoji,
                                style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 4),
                            Text(
                              mood.label(locale),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ── Calming tools ─────────────────────────────────────────
            SliverToBoxAdapter(child: SectionHeader(l10n.t('today.tools'))),
            SliverToBoxAdapter(
              child: FeatureGrid(children: [
                FeatureTile(
                  icon: Icons.air_rounded,
                  title: l10n.t('hub.feature.breathing.title'),
                  subtitle: l10n.t('hub.feature.breathing.subtitle'),
                  color: AppColors.secondary,
                  onTap: () => _open('/breathing'),
                ),
                FeatureTile(
                  icon: Icons.favorite_rounded,
                  title: l10n.t('hub.feature.gratitudeJournal.title'),
                  subtitle: l10n.t('hub.feature.gratitudeJournal.subtitle'),
                  color: AppColors.pulse,
                  onTap: () => _open('/gratitude-journal'),
                ),
                FeatureTile(
                  icon: Icons.inventory_2_outlined,
                  title: l10n.t('hub.feature.worryBox.title'),
                  subtitle: l10n.t('hub.feature.worryBox.subtitle'),
                  color: AppColors.primary,
                  onTap: () => _open('/worry-box'),
                ),
                FeatureTile(
                  icon: Icons.nights_stay_outlined,
                  title: l10n.t('hub.feature.silent.title'),
                  subtitle: l10n.t('hub.feature.silent.subtitle'),
                  color: AppColors.masculinePrimary,
                  onTap: () => _open('/silent'),
                ),
              ]),
            ),

            // ── Wisdom ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(
                l10n.t('today.quote'),
                actionLabel: l10n.t('today.anotherQuote'),
                onAction: () => setState(() => _quote =
                    MotivationService.getRandomQuoteFor(l10n.isArabic,
                        excludingQuote: quote.$1)),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: NabdCard(
                  color: scheme.secondaryContainer.withValues(alpha: 0.55),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.format_quote_rounded,
                          color: scheme.secondary, size: 28),
                      Text(quote.$1, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text(
                        '— ${quote.$2}',
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Recent ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: SectionHeader(
                l10n.t('today.recent'),
                actionLabel: entries.isEmpty ? null : l10n.t('today.seeAll'),
                onAction: () => context.go('/journal'),
              ),
            ),
            if (entries.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  emoji: '📖',
                  title: l10n.t('today.noRecent'),
                  actionLabel: l10n.t('today.write'),
                  onAction: () => _open('/editor'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.list(children: [
                  for (final entry in entries.take(3))
                    EntryCard(
                      entry: entry,
                      onTap: () => _open('/editor?id=${entry.id}'),
                    ),
                ]),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}
