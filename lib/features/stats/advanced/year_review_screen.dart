import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
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

  List<_YearSlide> _slides = const [];

  List<_YearSlide> _buildSlides(AppLocalizations l10n) {
    String t(String key) => l10n.t(key);
    final year = DateTime.now().year;
    final entries = _db.getAllEntries()
        .where((e) => e.createdAt.year == year)
        .toList();

    if (entries.isEmpty) {
      return [
        _YearSlide(
          title: t('year.empty'),
          subtitle: '${t('year.emptySub')} ($year)',
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
        title: t('year.title'),
        subtitle: '$year',
        background: [const Color(0xFF6C5CE7), const Color(0xFF8B7BFF)],
        emoji: '✨',
      ),
      _YearSlide(
        title: t('year.wrote'),
        subtitle: '${entries.length} ${t('year.entries')}',
        detail: '${t('year.across')} $writingDays ${t('year.daysUnit')}',
        background: [const Color(0xFF00D2A8), const Color(0xFF00897B)],
        emoji: '📝',
      ),
      _YearSlide(
        title: t('year.words'),
        subtitle: '$totalWords ${t('year.wordsUnit')}',
        detail: '${t('year.pages')}: ${(totalWords / 250).round()}',
        background: [const Color(0xFFFFB74D), const Color(0xFFFB8C00)],
        emoji: '✍️',
      ),
      if (topMood != null)
        _YearSlide(
          title: t('year.mood'),
          subtitle: topMood.label(l10n.locale.languageCode),
          detail: '${moodCounts[topMood.id]} ${t('year.times')}',
          background: [topMood.color, topMood.color.withValues(alpha: 0.6)],
          emoji: topMood.emoji,
        ),
      _YearSlide(
        title: t('year.sentiment'),
        subtitle: avgSentiment > 0.2
            ? '${t('year.positive')} 📈'
            : avgSentiment < -0.2
                ? '${t('year.negative')} 📉'
                : '${t('year.balanced')} ⚖️',
        detail: t('year.keep'),
        background: avgSentiment > 0
            ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
            : [const Color(0xFF5C6BC0), const Color(0xFF303F9F)],
        emoji: '💫',
      ),
      _YearSlide(
        title: t('year.next'),
        subtitle: t('year.nextSub'),
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
    // Rebuilt every frame on purpose: the copy follows the app locale and the
    // entries the user has written since the screen was opened.
    _slides = _buildSlides(AppLocalizations.of(context));
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
