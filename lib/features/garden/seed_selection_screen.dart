import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/seed.dart';
import '../../services/garden_service.dart';
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
              const Text(
                'Plant your first seed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),
              const Text(
                'Every journal entry helps your seed grow.\n'
                'Positive feelings make it bloom.',
                style: TextStyle(
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
                  child: const Text(
                    'Choose a Seed',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Step 1: Selection
  // ═══════════════════════════════════════════════════════════
  Widget _buildSelection() {
    return Container(
      key: const ValueKey('selection'),
      color: const Color(0xFF0A0D14),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            const Text(
              'Choose what you want to grow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pick the feeling you want to nurture most',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1,
                ),
                itemCount: Seed.all.length,
                itemBuilder: (_, i) {
                  final seed = Seed.all[i];
                  final selected = _selectedSeed?.id == seed.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSeed = seed),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: seed.colors
                              .map((c) =>
                                  selected ? c : c.withValues(alpha: 0.3))
                              .toList(),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: selected
                            ? Border.all(color: Colors.white, width: 2)
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
                            seed.nameAr,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            seed.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                        ? 'Select a seed'
                        : 'Plant ${_selectedSeed!.nameAr}',
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
              const Text(
                'Planting...',
                style: TextStyle(color: Colors.white70, fontSize: 14),
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
                'A ${_selectedSeed!.nameAr} seed',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Write in your journal every day.\nYour seed will grow with every word.',
                style: TextStyle(
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
                  child: const Text(
                    'Plant Now',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _plant() async {
    if (_selectedSeed == null) return;
    setState(() => _isPlanting = true);

    try {
      await ref.read(gardenProvider.notifier).plantSeed(_selectedSeed!);
      await Hive.box('settings').put('onboarding_completed', true);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() => _isPlanting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
