import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/seed.dart';
import '../../services/garden_service.dart';

/// GardenScreen — عرض الحديقة والبذور.
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gardenProvider);
    final garden = ref.read(gardenProvider.notifier);

    if (state.seeds.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Garden')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌱', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 20),
              const Text(
                'No seeds yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Plant your first seed',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/seed-selection'),
                icon: const Icon(Icons.add),
                label: const Text('Plant a seed'),
              ),
            ],
          ),
        ),
      );
    }

    final primary = garden.primarySeed;
    final stats = garden.getStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Garden'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => context.push('/seed-selection'),
            tooltip: 'Plant new seed',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── Stats ───
          Row(
            children: [
              Expanded(
                child: _statCard(
                  icon: Icons.spa,
                  value: '${stats.totalSeeds}',
                  label: 'Seeds',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  icon: Icons.emoji_events,
                  value: '${stats.completedSeeds}',
                  label: 'Completed',
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statCard(
                  icon: Icons.trending_up,
                  value: '${stats.averageGrowth.round()}%',
                  label: 'Avg Growth',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Primary tree ───
          if (primary != null)
            _buildPrimaryTree(context, primary),
          const SizedBox(height: 24),

          // ─── All seeds ───
          const Text(
            'ALL SEEDS',
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
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
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
          const Text(
            'YOUR MAIN TREE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),

          // Tree emoji
          Text(
            emoji,
            style: TextStyle(fontSize: stage >= 3 ? 120 : 80),
          ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 12),
          Text(
            s.nameAr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _stageName(stage),
            style: TextStyle(
              fontSize: 13,
              color: s.colors.last,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Progress bar
          Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Growth',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: seed.progress,
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation(s.colors.first),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                '${seed.daysCared} days of care',
                style: const TextStyle(
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
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.emoji_events,
                      size: 16, color: AppColors.warning),
                  SizedBox(width: 6),
                  Text(
                    'Full bloom! 🌸',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
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

    final needsWater = seed.needsWater(DateTime.now());

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
            child: Text(
              s.emojiForStage(seed.growthStage),
              style: const TextStyle(fontSize: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      s.nameAr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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
                        child: const Text(
                          '💧 Needs water',
                          style: TextStyle(
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: seed.progress,
                    minHeight: 6,
                    backgroundColor:
                        s.colors.first.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(s.colors.first),
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
        ],
      ),
    );
  }

  String _stageName(int stage) {
    switch (stage) {
      case 0:
        return 'Seed';
      case 1:
        return 'Sprout';
      case 2:
        return 'Sapling';
      case 3:
        return 'Young Tree';
      case 4:
        return 'Strong Tree';
      default:
        return 'Full Bloom 🌸';
    }
  }
}
