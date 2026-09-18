import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/mood.dart';
import '../../../services/database_service.dart';
import '../../../services/local_ai_service.dart';

/// YearReviewScreen — ملخص سنوي بأسلوب Spotify Wrapped.
class YearReviewScreen extends ConsumerStatefulWidget {
  const YearReviewScreen({super.key});

  @override
  ConsumerState<YearReviewScreen> createState() => _YearReviewScreenState();
}

class _YearReviewScreenState extends ConsumerState<YearReviewScreen> {
  final DatabaseService _db = DatabaseService();
  final LocalAIService _ai = LocalAIService();

  int _currentSlide = 0;
  final PageController _controller = PageController();

  late List<_YearSlide> _slides;

  @override
  void initState() {
    super.initState();
    _slides = _buildSlides();
  }

  List<_YearSlide> _buildSlides() {
    final year = DateTime.now().year;
    final entries = _db.getAllEntries()
        .where((e) => e.createdAt.year == year)
        .toList();

    if (entries.isEmpty) {
      return [
        _YearSlide(
          title: 'Your Year',
          subtitle: 'No entries in $year yet',
          background: [AppColors.textTertiary, AppColors.textSecondary],
          emoji: '📅',
        ),
      ];
    }

    final totalWords = entries.fold<int>(
      0,
      (sum, e) => sum + e.content.split(RegExp(r'\s+')).length,
    );

    final moodCounts = <String, int>{};
    for (final e in entries) {
      if (e.mood.isNotEmpty) {
        moodCounts[e.mood] = (moodCounts[e.mood] ?? 0) + 1;
      }
    }

    Mood? topMood;
    if (moodCounts.isNotEmpty) {
      final top = moodCounts.entries.reduce((a, b) =>
          a.value > b.value ? a : b);
      topMood = Mood.getById(top.key);
    }

    final writingDays = entries
        .map((e) =>
            '${e.createdAt.year}-${e.createdAt.month}-${e.createdAt.day}')
        .toSet()
        .length;

    // Average sentiment
    final avgSentiment = entries
            .map((e) => _ai.analyzeSentiment(e.content))
            .reduce((a, b) => a + b) /
        entries.length;

    return [
      _YearSlide(
        title: 'Your Year in Writing',
        subtitle: '$year',
        background: [const Color(0xFF6C5CE7), const Color(0xFF8B7BFF)],
        emoji: '✨',
      ),
      _YearSlide(
        title: 'You wrote',
        subtitle: '${entries.length} entries',
        detail: 'across $writingDays days',
        background: [const Color(0xFF00D2A8), const Color(0xFF00897B)],
        emoji: '📝',
      ),
      _YearSlide(
        title: 'Words written',
        subtitle: '$totalWords words',
        detail: 'That\'s about ${(totalWords / 250).round()} pages',
        background: [const Color(0xFFFFB74D), const Color(0xFFFB8C00)],
        emoji: '✍️',
      ),
      if (topMood != null)
        _YearSlide(
          title: 'Your dominant mood',
          subtitle: topMood.labelEn,
          detail: '${moodCounts[topMood.id]} times',
          background: [topMood.color, topMood.color.withValues(alpha: 0.6)],
          emoji: topMood.emoji,
        ),
      _YearSlide(
        title: 'Overall sentiment',
        subtitle: avgSentiment > 0.2
            ? 'Positive 📈'
            : avgSentiment < -0.2
                ? 'Challenging 📉'
                : 'Balanced ⚖️',
        detail: 'Keep growing!',
        background: avgSentiment > 0
            ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
            : [const Color(0xFF5C6BC0), const Color(0xFF303F9F)],
        emoji: '💫',
      ),
      _YearSlide(
        title: 'Here\'s to next year',
        subtitle: 'Keep writing, keep growing',
        background: [AppColors.primary, AppColors.primaryGlow],
        emoji: '🌱',
        isLast: true,
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Slides
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentSlide = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) => _buildSlide(_slides[i]),
          ),

          // Progress indicator
          Positioned(
            top: 60,
            left: 20,
            right: 20,
            child: Row(
              children: _slides.asMap().entries.map((e) {
                final active = e.key <= _currentSlide;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Close button
          Positioned(
            top: 80,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(_YearSlide slide) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: slide.background,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                slide.emoji,
                style: const TextStyle(fontSize: 120),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 40),
              Text(
                slide.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),
              Text(
                slide.subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.3),
              if (slide.detail != null) ...[
                const SizedBox(height: 16),
                Text(
                  slide.detail!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 700.ms),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _YearSlide {
  final String title;
  final String subtitle;
  final String? detail;
  final List<Color> background;
  final String emoji;
  final bool isLast;

  const _YearSlide({
    required this.title,
    required this.subtitle,
    this.detail,
    required this.background,
    required this.emoji,
    this.isLast = false,
  });
}
