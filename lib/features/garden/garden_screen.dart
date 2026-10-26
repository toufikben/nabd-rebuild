import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data_revision.dart';
import '../../models/seed.dart';
import '../../services/audio_service.dart';
import '../../services/garden_service.dart';
import 'bloom_celebration.dart';

/// GardenScreen — عرض الحديقة والبذور.
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(dataRevisionProvider);
    ref.listen<int>(dataRevisionProvider, (_, __) {
      ref.read(gardenProvider.notifier).refresh();
    });
    final state = ref.watch(gardenProvider);
    final garden = ref.read(gardenProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final archived = garden.archivedSeeds;

    if (state.seeds.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.t('garden.title')),
          actions: [
            if (archived.isNotEmpty)
              IconButton(
                tooltip: l10n.t('garden.showcase.button'),
                onPressed: () => context.push('/garden-showcase'),
                icon: const Icon(Icons.local_florist_outlined),
              ),
          ],
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGardenAudioControl(context),
                const SizedBox(height: 20),
                const Text('🌱', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 20),
                Text(
                  l10n.t('garden.empty'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.t('garden.emptyHint'),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/seed-selection'),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.t('garden.plant')),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push('/sound-garden'),
                  icon: const Icon(Icons.library_music_outlined),
                  label: Text(l10n.t('garden.soundGarden')),
                ),
                if (archived.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/garden-showcase'),
                    icon: const Icon(Icons.local_florist_outlined),
                    label: Text(l10n.t('garden.showcase.button')),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final primary = garden.primarySeed;
    final stats = garden.getStats();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).t('garden.title')),
        actions: [
          if (archived.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.local_florist_outlined),
              onPressed: () => context.push('/garden-showcase'),
              tooltip: l10n.t('garden.showcase.button'),
            ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/seed-selection'),
            tooltip: l10n.t('garden.plantNew'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildGardenAudioControl(context),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/sound-garden'),
              icon: const Icon(Icons.library_music_outlined),
              label: Text(AppLocalizations.of(context).t('garden.soundGarden')),
            ),
          ),
          const SizedBox(height: 20),
          // ─── Stats ───
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.spa,
                  value: '${stats.totalSeeds}',
                  label: AppLocalizations.of(context).t('garden.stat.seeds'),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  icon: Icons.emoji_events,
                  value: '${stats.completedSeeds}',
                  label:
                      AppLocalizations.of(context).t('garden.stat.completed'),
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  icon: Icons.trending_up,
                  value: '${stats.averageGrowth.round()}%',
                  label:
                      AppLocalizations.of(context).t('garden.stat.avgGrowth'),
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (stats.totalSeeds > 0 &&
              stats.completedSeeds == stats.totalSeeds) ...[
            _buildAllCompleteCard(context, garden, stats),
            const SizedBox(height: 20),
          ],

          // ─── Primary tree ───
          if (primary != null) _buildPrimaryTree(context, primary),
          const SizedBox(height: 24),

          // ─── All seeds ───
          Text(
            AppLocalizations.of(context).t('garden.allSeeds'),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...state.seeds.map((s) => _buildSeedRow(context, s, garden)),
        ],
      ),
    );
  }

  Widget _buildAllCompleteCard(
    BuildContext context,
    GardenService garden,
    GardenStats stats,
  ) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            l10n.t('garden.watering.congrats'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.t('garden.watering.bloom'),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/garden-showcase'),
                icon: const Icon(Icons.local_florist_outlined),
                label: Text(l10n.t('garden.showcase.button')),
              ),
              FilledButton.icon(
                onPressed: () =>
                    _confirmNewSeason(context, garden, stats.totalSeeds),
                icon: const Icon(Icons.autorenew),
                label: Text(l10n.t('garden.newSeason')),
              ),
            ],
          ),
          if (stats.totalSeeds < GardenService.maxSeeds) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.push('/seed-selection'),
              icon: const Icon(Icons.add),
              label: Text(l10n.t('garden.plantNew')),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmNewSeason(
    BuildContext context,
    GardenService garden,
    int count,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.t('garden.newSeason.title')),
        content: Text(
          l10n.t('garden.newSeason.body').replaceAll('{count}', '$count'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.t('dialog.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.t('garden.newSeason')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await garden.startNewSeason();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('garden.newSeason.done'))),
      );
    } catch (error) {
      debugPrint('Could not start a new garden season: $error');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('garden.error.plant'))),
      );
    }
  }

  Widget _buildGardenAudioControl(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final audio = AudioService.instance;

    return ValueListenableBuilder<AmbientPlaybackState>(
      valueListenable: audio.ambientState,
      builder: (context, state, _) {
        final isGarden = state.source == AmbientSource.garden;
        final isPlaying =
            isGarden && state.status == AmbientPlaybackStatus.playing;
        final isLoading =
            isGarden && state.status == AmbientPlaybackStatus.loading;
        final hasError =
            isGarden && state.status == AmbientPlaybackStatus.error;
        final anotherAmbientIsActive = state.source != null &&
            !isGarden &&
            state.status != AmbientPlaybackStatus.idle;

        return Card(
          child: ListTile(
            leading: Icon(Icons.nature, color: colors.primary),
            title: Text(l10n.t('garden.ambience')),
            subtitle: Text(
              hasError
                  ? l10n.t('garden.ambienceFailed')
                  : anotherAmbientIsActive
                      ? l10n.t('garden.ambienceBusy')
                      : isLoading
                          ? l10n.t('garden.ambienceLoading')
                          : isPlaying
                              ? l10n.t('garden.ambiencePlaying')
                              : l10n.t('garden.ambienceIdle'),
            ),
            trailing: IconButton(
              tooltip: isPlaying
                  ? l10n.t('garden.ambienceStop')
                  : l10n.t('garden.ambiencePlay'),
              onPressed: anotherAmbientIsActive || isLoading
                  ? null
                  : () async {
                      if (isPlaying) {
                        await audio.stop();
                      } else {
                        await audio.playAmbient(AmbientSource.garden);
                      }
                    },
              icon: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(isPlaying ? Icons.stop_circle : Icons.play_circle),
            ),
          ),
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 6),
          // "100%" must stay on one line: at 1.5x the card is narrow enough
          // for the percent sign to wrap onto a line of its own.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryTree(BuildContext context, PlantedSeed seed) {
    final s = seed.seed;
    if (s == null) return const SizedBox.shrink();

    final stage = seed.growthStage;
    final emoji = s.emojiForStage(stage);
    final thirsty = seed.isThirsty(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            s.colors.first.withValues(alpha: 0.3),
            s.colors.last.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: s.colors.first.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context).t('garden.mainTree'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),

          // Tree emoji
          Opacity(
            opacity: thirsty ? 0.65 : 1.0,
            child: Transform.rotate(
              angle: thirsty ? -0.08 : 0.0,
              child: Text(
                emoji,
                style: TextStyle(fontSize: stage >= 3 ? 120 : 80),
              ),
            ),
          ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 12),
          Text(
            s.nameFor(AppLocalizations.of(context).locale.languageCode),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _stageName(AppLocalizations.of(context), stage),
            style: TextStyle(
              fontSize: 13,
              color: s.colors.last,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (thirsty) ...[
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).t('garden.needsWater'),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Progress bar
          Column(
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).t('garden.growth'),
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    '${seed.growthPoints}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: seed.progress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation(s.colors.first),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today,
                  size: 14, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text(
                '${seed.daysCared} ${AppLocalizations.of(context).t('garden.daysOfCare')}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          if (seed.isComplete) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events, size: 16, color: AppColors.warning),
                  SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).t('garden.fullBloom'),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => showBloomCelebration(context, seed),
              icon: const Icon(Icons.workspace_premium, size: 18),
              label: Text(
                AppLocalizations.of(context).t('garden.completed'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeedRow(
    BuildContext context,
    PlantedSeed seed,
    GardenService garden,
  ) {
    final s = seed.seed;
    if (s == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final needsWater = seed.needsWater(now);
    final thirsty = seed.isThirsty(now);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: s.colors),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: thirsty ? 0.6 : 1.0,
              child: Transform.rotate(
                angle: thirsty ? -0.1 : 0.0,
                child: Text(
                  s.emojiForStage(seed.growthStage),
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.nameFor(
                            AppLocalizations.of(context).locale.languageCode),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (needsWater) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppLocalizations.of(context).t('garden.needsWater'),
                          style: const TextStyle(
                            fontSize: 9,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: seed.progress,
                      minHeight: 6,
                      backgroundColor: s.colors.first.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation(s.colors.first),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${seed.growthPoints}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: s.colors.last,
            ),
          ),
          if (seed.isComplete)
            IconButton(
              tooltip: AppLocalizations.of(context).t('garden.completed'),
              visualDensity: VisualDensity.compact,
              onPressed: () => showBloomCelebration(context, seed),
              icon: const Icon(
                Icons.workspace_premium,
                size: 18,
                color: AppColors.warning,
              ),
            ),
          IconButton(
            tooltip: AppLocalizations.of(context).t('dialog.delete.action'),
            visualDensity: VisualDensity.compact,
            onPressed: () => _confirmRemoveSeed(context, garden, seed),
            icon: Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveSeed(
    BuildContext context,
    GardenService garden,
    PlantedSeed seed,
  ) async {
    final l10n = AppLocalizations.of(context);
    final plant = seed.seed;
    if (plant == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          plant.nameFor(l10n.locale.languageCode),
        ),
        content: Text(l10n.t('editor.delete.body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.t('dialog.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.t('dialog.delete.action')),
          ),
        ],
      ),
    );
    if (confirmed == true) await garden.removeSeed(seed.id);
  }

  String _stageName(AppLocalizations l10n, int stage) {
    switch (stage) {
      case 0:
        return l10n.t('garden.stage.seed');
      case 1:
        return l10n.t('garden.stage.sprout');
      case 2:
        return l10n.t('garden.stage.sapling');
      case 3:
        return l10n.t('garden.stage.youngTree');
      case 4:
        return l10n.t('garden.stage.strongTree');
      default:
        return l10n.t('garden.stage.fullBloom');
    }
  }
}
