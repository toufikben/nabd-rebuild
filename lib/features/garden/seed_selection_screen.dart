import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/seed.dart';
import '../../services/garden_service.dart';
import '../../services/motivation_service.dart';
import '../../widgets/nabd_ui.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// SeedSelectionScreen — اختيار البذرة الأولى.
class SeedSelectionScreen extends ConsumerStatefulWidget {
  const SeedSelectionScreen({super.key});

  @override
  ConsumerState<SeedSelectionScreen> createState() =>
      _SeedSelectionScreenState();
}

class _SeedSelectionScreenState extends ConsumerState<SeedSelectionScreen> {
  int _step = 0; // 0: intro, 1: selection, 2: confirmation
  Seed? _selectedSeed;
  bool _isPlanting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildIntro();
      case 1:
        return _buildSelection();
      case 2:
        return _buildConfirmation();
      default:
        return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // Step 0: Intro
  // ═══════════════════════════════════════════════════════════
  Widget _buildIntro() {
    return Container(
      key: const ValueKey('intro'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A0D14), Color(0xFF1A2A1E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: _FillOrScroll(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D2A8), Color(0xFF00897B)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00D2A8).withValues(alpha: 0.4),
                        blurRadius: 40,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🌱', style: TextStyle(fontSize: 80)),
                  ),
                )
                    .animate()
                    .scale(duration: 800.ms, curve: Curves.easeOutBack)
                    .fadeIn(),
                const SizedBox(height: 40),
                Text(
                  AppLocalizations.of(context).t(
                      ref.read(gardenProvider).seeds.isEmpty
                          ? 'garden.emptyHint'
                          : 'garden.plantNew'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).t('garden.seedHelp'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 600.ms),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => setState(() => _step = 1),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00D2A8),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)
                          .t('garden.seedSelection.title'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Step 1: Selection
  // ═══════════════════════════════════════════════════════════
  Widget _buildSelection() {
    final unlocked = _unlockedAchievements();
    final planted = ref.watch(gardenProvider).seeds.length;
    final full = planted >= GardenService.maxSeeds;

    return Container(
      key: const ValueKey('selection'),
      color: const Color(0xFF0A0D14),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).t('garden.seedSelection.subtitle'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).t('garden.seedSelection.hint'),
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            if (full) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  AppLocalizations.of(context)
                      .t('garden.seedSelection.full')
                      .replaceAll('{count}', '$planted'),
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 24),
            // Rows as tall as their tallest card: a fixed cell height clipped
            // the "Hope" card by 2 px on a real phone, and more at large text.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: EqualHeightGrid(
                  columns: 2,
                  spacing: 14,
                  children: [
                    for (var i = 0; i < Seed.all.length; i++)
                      Builder(builder: (context) {
                        final seed = Seed.all[i];
                        final selected = _selectedSeed?.id == seed.id;
                        final locked = !seed.isUnlocked(unlocked);
                        return Semantics(
                          button: true,
                          enabled: !locked && !full,
                          child: GestureDetector(
                            onTap: () {
                              if (locked) {
                                _showLockedHint(seed);
                              } else if (full) {
                                _showFullHint(planted);
                              } else {
                                setState(() => _selectedSeed = seed);
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: seed.colors
                                      .map((c) => selected
                                          ? c
                                          : c.withValues(
                                              alpha: locked ? 0.12 : 0.3))
                                      .toList(),
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: selected
                                    ? Border.all(
                                        color: Colors.white, width: 2)
                                    : null,
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    seed.emoji,
                                    style: const TextStyle(fontSize: 44),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    seed.nameFor(AppLocalizations.of(context)
                                        .locale
                                        .languageCode),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    seed.descriptionFor(
                                        AppLocalizations.of(context)
                                            .locale
                                            .languageCode),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (locked) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.lock_outline,
                                          color: Colors.white70,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            AppLocalizations.of(context)
                                                .t('seed.locked'),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _selectedSeed == null
                      ? null
                      : () => setState(() => _step = 2),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        _selectedSeed?.colors.first ?? AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _selectedSeed == null
                        ? AppLocalizations.of(context)
                            .t('garden.seedSelection.select')
                        : AppLocalizations.of(context)
                            .t('garden.seedSelection.action'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Step 2: Confirmation
  // ═══════════════════════════════════════════════════════════
  Widget _buildConfirmation() {
    if (_selectedSeed == null) return const SizedBox.shrink();

    if (_isPlanting) {
      return Container(
        key: const ValueKey('planting'),
        color: const Color(0xFF0A0D14),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedSeed!.emoji,
                style: const TextStyle(fontSize: 120),
              ).animate().scale(duration: 1500.ms).fadeIn(),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).t('garden.seedSelection.planting'),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ).animate().fadeIn(delay: 500.ms),
            ],
          ),
        ),
      );
    }

    return Container(
      key: const ValueKey('confirmation'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _selectedSeed!.colors.first.withValues(alpha: 0.2),
            const Color(0xFF0A0D14),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: _FillOrScroll(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Spacer(),
                Text(
                  _selectedSeed!.emoji,
                  style: const TextStyle(fontSize: 100),
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 24),
                Text(
                  _selectedSeed!.nameFor(AppLocalizations.of(context).locale.languageCode),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).t('garden.seedGrowHint'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _plant,
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedSeed!.colors.first,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)
                          .t('garden.seedSelection.action'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Achievements already earned. An unreadable achievements box must never
  /// hide the garden, so a failure falls back to "everything unlocked".
  Set<String> _unlockedAchievements() {
    try {
      return AchievementService().unlockedIds;
    } catch (_) {
      return Seed.all
          .map((seed) => seed.unlockAchievement)
          .whereType<String>()
          .toSet();
    }
  }

  void _showLockedHint(Seed seed) {
    final l10n = AppLocalizations.of(context);
    final code = l10n.locale.languageCode;
    final achievement = seed.unlockAchievement == null
        ? null
        : Achievement.getById(seed.unlockAchievement!);
    final title = achievement?.titleFor(code) ?? '';
    _snack(l10n.t('seed.unlockHint').replaceAll('{achievement}', title));
  }

  void _showFullHint(int planted) {
    final l10n = AppLocalizations.of(context);
    _snack(
      l10n.t('garden.seedSelection.full').replaceAll('{count}', '$planted'),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  Future<void> _plant() async {
    if (_selectedSeed == null) return;
    setState(() => _isPlanting = true);

    try {
      await ref.read(gardenProvider.notifier).plantSeed(_selectedSeed!);
      await Hive.box('settings').put('onboarding_completed', true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.go('/today');
    } catch (e) {
      if (mounted) {
        setState(() => _isPlanting = false);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError
                  ? l10n.t('garden.error.plant')
                  : '${l10n.t('common.error')}: $e',
            ),
          ),
        );
      }
    }
  }
}

/// Fills the screen so Spacers can centre the content, but scrolls instead
/// of overflowing when the text is large or the phone is short.
class _FillOrScroll extends StatelessWidget {
  const _FillOrScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }
}
