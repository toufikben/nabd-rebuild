import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

/// WorryReleaseScreen — اكتب همّك، أطلقه.
///
/// الفكرة النفسية: التدوين عن الهم ثم "إطلاقه" بصريًا
/// يعطي إحساسًا حقيقيًا بالتفريغ (مستند إلى تمارين CBT).
class WorryReleaseScreen extends StatefulWidget {
  const WorryReleaseScreen({super.key});

  @override
  State<WorryReleaseScreen> createState() => _WorryReleaseScreenState();
}

class _WorryReleaseScreenState extends State<WorryReleaseScreen> {
  final TextEditingController _controller = TextEditingController();

  int _stage = 0; // 0: write, 1: releasing, 2: released
  bool _saveBeforeRelease = false;

  Future<void> _release() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _stage = 1);

    // Optional: save as entry before releasing
    if (_saveBeforeRelease) {
      // Save as a "released worry" entry
    }

    await Future.delayed(const Duration(seconds: 4));

    if (mounted) setState(() => _stage = 2);
  }

  void _reset() {
    setState(() {
      _stage = 0;
      _controller.clear();
      _saveBeforeRelease = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _stage == 0
          ? null
          : const Color(0xFF0A0D14), // Dark for releasing
      appBar: AppBar(
        title: const Text('Release a Worry'),
        backgroundColor: _stage == 0 ? null : Colors.transparent,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _buildStage(),
      ),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case 0:
        return _buildWriteStage();
      case 1:
        return _buildReleasingStage();
      default:
        return _buildReleasedStage();
    }
  }

  Widget _buildWriteStage() {
    return Padding(
      key: const ValueKey('write'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s weighing on you?',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Write it out. Then let it go.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'I\'m worried about...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 16),
                ),
                style: const TextStyle(fontSize: 16, height: 1.7),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _saveBeforeRelease,
            onChanged: (v) => setState(() => _saveBeforeRelease = v ?? false),
            title: const Text('Save a copy to my journal'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _controller.text.trim().isEmpty ? null : _release,
              icon: const Icon(Icons.air),
              label: const Text('Release It'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReleasingStage() {
    return Container(
      key: const ValueKey('releasing'),
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Particle animations
          ...List.generate(20, (i) {
            final angle = (i / 20) * 2 * math.pi;
            return Animate(
              delay: Duration(milliseconds: i * 50),
              child: Transform.translate(
                offset: Offset(
                  math.cos(angle) * 100,
                  math.sin(angle) * 100,
                ),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ).animate().fadeIn().scale().fadeOut(delay: 2.seconds),
            );
          }),

          // The text floating away
          Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              _controller.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.6,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .then()
              .moveY(begin: 0, end: -400, duration: 3.seconds, curve: Curves.easeIn)
              .fadeOut(duration: 3.seconds),
        ],
      ),
    );
  }

  Widget _buildReleasedStage() {
    return Center(
      key: const ValueKey('released'),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00D2A8), Color(0xFF00B88A)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00D2A8).withValues(alpha: 0.4),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                size: 60,
                color: Colors.white,
              ),
            ).animate().scale(curve: Curves.easeOutBack),
            const SizedBox(height: 32),
            const Text(
              'Released',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 12),
            const Text(
              'You let it go. That took courage.',
              style: TextStyle(color: Colors.white70, fontSize: 15),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 48),
            OutlinedButton(
              onPressed: () {
                _reset();
                context.pop();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Done'),
            ).animate().fadeIn(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
