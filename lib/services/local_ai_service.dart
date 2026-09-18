import 'dart:math' as math;

import '../models/journal_entry.dart';
import '../models/mood.dart';

/// LocalAIService — تحليل محلي للنصوص بدون APIs.
///
/// القدرات:
///   • تحليل المشاعر (sentiment analysis)
///   • اقتراح المزاج التلقائي
///   • توليد ملخص
///   • اقتراح وسوم
///   • كشف الأنماط
class LocalAIService {
  // ═══════════════════════════════════════════════════════════
  // 1. Sentiment Analysis
  // ═══════════════════════════════════════════════════════════

  /// تحليل النص وإرجاع score من -1 إلى 1.
  double analyzeSentiment(String text) {
    if (text.trim().isEmpty) return 0.0;

    final words = _tokenize(text);
    if (words.isEmpty) return 0.0;

    var score = 0.0;
    var matches = 0;

    for (final word in words) {
      final wordScore = _wordSentiment(word);
      if (wordScore != 0) {
        score += wordScore;
        matches++;
      }
    }

    if (matches == 0) return 0.0;

    // Normalize between -1 and 1
    return (score / math.sqrt(matches)).clamp(-1.0, 1.0);
  }

  /// اقتراح مزاج من النص.
  String? suggestMood(String text) {
    final score = analyzeSentiment(text);
    if (score == 0.0) return null;

    // Map score to mood
    if (score > 0.6) return 'joyful';
    if (score > 0.4) return 'happy';
    if (score > 0.2) return 'grateful';
    if (score > 0.05) return 'peaceful';
    if (score > -0.05) return 'okay';
    if (score > -0.2) return 'tired';
    if (score > -0.4) return 'sad';
    if (score > -0.6) return 'frustrated';
    return 'depressed';
  }

  /// تسمية عامة للمشاعر.
  String sentimentLabel(double score) {
    if (score > 0.3) return 'Positive';
    if (score < -0.3) return 'Negative';
    return 'Neutral';
  }

  // ═══════════════════════════════════════════════════════════
  // 2. Summarization
  // ═══════════════════════════════════════════════════════════

  /// توليد ملخص بسيط (3 جمل رئيسية).
  String summarize(String text, {int maxSentences = 3}) {
    final sentences = _splitSentences(text);
    if (sentences.length <= maxSentences) return text;

    // Score each sentence by word frequency
    final wordFreq = <String, int>{};
    for (final sentence in sentences) {
      for (final word in _tokenize(sentence)) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
      }
    }

    final scored = sentences.asMap().entries.map((e) {
      final words = _tokenize(e.value);
      final score = words.fold<int>(
        0,
        (sum, w) => sum + (wordFreq[w] ?? 0),
      );
      return MapEntry(e.key, score / math.max(words.length, 1));
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topIndices = scored
        .take(maxSentences)
        .map((e) => e.key)
        .toList()
      ..sort();

    return topIndices.map((i) => sentences[i]).join(' ');
  }

  // ═══════════════════════════════════════════════════════════
  // 3. Tag Suggestions
  // ═══════════════════════════════════════════════════════════

  /// اقتراح وسوم من النص.
  List<String> suggestTags(String text) {
    final words = _tokenize(text);
    final suggestions = <String>{};

    const tagKeywords = {
      'work': ['work', 'job', 'project', 'meeting', 'office', 'career'],
      'family': ['family', 'mom', 'dad', 'parents', 'sister', 'brother', 'son', 'daughter'],
      'health': ['health', 'exercise', 'gym', 'run', 'doctor', 'sick', 'medicine'],
      'travel': ['travel', 'trip', 'flight', 'hotel', 'vacation', 'journey'],
      'goals': ['goal', 'aim', 'target', 'objective', 'plan', 'future'],
      'gratitude': ['grateful', 'thankful', 'blessed', 'appreciate'],
      'ideas': ['idea', 'thought', 'brainstorm', 'creative', 'inspiration'],
      'personal': ['personal', 'private', 'myself', 'reflection'],
    };

    for (final entry in tagKeywords.entries) {
      for (final keyword in entry.value) {
        if (words.contains(keyword)) {
          suggestions.add(entry.key);
          break;
        }
      }
    }

    return suggestions.take(3).toList();
  }

  // ═══════════════════════════════════════════════════════════
  // 4. Patterns Detection
  // ═══════════════════════════════════════════════════════════

  /// كشف الأنماط في آخر N مذكرة.
  List<AIPattern> detectPatterns(List<JournalEntry> entries) {
    if (entries.length < 5) return [];

    final patterns = <AIPattern>[];

    // ─── 1. Mood patterns ───
    final moodCounts = <String, int>{};
    for (final e in entries) {
      if (e.mood.isNotEmpty) {
        moodCounts[e.mood] = (moodCounts[e.mood] ?? 0) + 1;
      }
    }

    if (moodCounts.isNotEmpty) {
      final topMood = moodCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      final mood = Mood.getById(topMood.key);
      if (mood != null && topMood.value >= entries.length * 0.3) {
        patterns.add(AIPattern(
          type: 'mood',
          title: 'Your dominant mood',
          description:
              'You felt ${mood.labelEn} in ${topMood.value} of your last ${entries.length} entries.',
          icon: '😊',
        ));
      }
    }

    // ─── 2. Writing time patterns ───
    final hourCounts = <int, int>{};
    for (final e in entries) {
      final hour = e.createdAt.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    if (hourCounts.isNotEmpty) {
      final topHour = hourCounts.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      patterns.add(AIPattern(
        type: 'time',
        title: 'Your writing time',
        description:
            'You write most at ${_formatHour(topHour.key)}.',
        icon: '⏰',
      ));
    }

    // ─── 3. Streak ───
    final dates = entries
        .map((e) => DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
        .toSet();
    if (dates.length >= 7) {
      patterns.add(AIPattern(
        type: 'consistency',
        title: 'Great consistency',
        description:
            'You wrote on ${dates.length} different days.',
        icon: '🔥',
      ));
    }

    // ─── 4. Length patterns ───
    final avgLength = entries.fold<int>(
          0,
          (sum, e) => sum + e.content.length,
        ) /
        entries.length;

    if (avgLength > 500) {
      patterns.add(AIPattern(
        type: 'depth',
        title: 'Deep thinker',
        description:
            'Your entries average ${avgLength.round()} characters.',
        icon: '💭',
      ));
    } else if (avgLength < 100) {
      patterns.add(AIPattern(
        type: 'brevity',
        title: 'Quick notes',
        description: 'Try writing longer entries for deeper reflection.',
        icon: '📝',
      ));
    }

    // ─── 5. Sentiment trend ───
    final recent = entries.take(5).toList();
    final older = entries.skip(5).take(5).toList();

    if (recent.isNotEmpty && older.isNotEmpty) {
      final recentSent = recent
              .map((e) => analyzeSentiment(e.content))
              .reduce((a, b) => a + b) /
          recent.length;
      final olderSent = older
              .map((e) => analyzeSentiment(e.content))
              .reduce((a, b) => a + b) /
          older.length;

      final diff = recentSent - olderSent;
      if (diff > 0.2) {
        patterns.add(const AIPattern(
          type: 'improvement',
          title: 'Mood is improving',
          description: 'Your recent entries are more positive. Keep going!',
          icon: '📈',
        ));
      } else if (diff < -0.2) {
        patterns.add(const AIPattern(
          type: 'decline',
          title: 'Mood is declining',
          description:
              'Your recent entries are less positive. Consider talking to someone.',
          icon: '📉',
        ));
      }
    }

    return patterns;
  }

  /// توليد اقتراحات بناءً على المذكرات.
  List<String> generatePrompts(List<JournalEntry> entries) {
    final prompts = <String>[];

    if (entries.isEmpty) {
      prompts.add('Write about your day — 3 things that happened.');
      prompts.add('What are you grateful for today?');
      prompts.add('Describe a moment that made you smile.');
      return prompts;
    }

    // Based on last entry's mood
    final last = entries.first;
    final lastMood = Mood.getById(last.mood);

    if (lastMood != null) {
      if (lastMood.category == 'negative') {
        prompts.add('What would make tomorrow 1% better?');
        prompts.add('Write about something that brought you comfort.');
      } else {
        prompts.add('What contributed to your good mood today?');
        prompts.add('How can you create more moments like this?');
      }
    }

    prompts.add('Describe a small win from this week.');
    prompts.add('What is one thing you want to remember forever?');
    prompts.add('What did you learn about yourself recently?');

    return prompts;
  }

  // ═══════════════════════════════════════════════════════════
  // Internal
  // ═══════════════════════════════════════════════════════════

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty && w.length > 2)
        .toList();
  }

  List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'[.!?؟।]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  double _wordSentiment(String word) {
    const positive = {
      // English
      'happy', 'joy', 'love', 'great', 'amazing', 'wonderful', 'excellent',
      'fantastic', 'beautiful', 'awesome', 'perfect', 'good', 'best', 'success',
      'proud', 'grateful', 'blessed', 'thankful', 'excited', 'peaceful',
      // Arabic
      'سعيد', 'فرح', 'حب', 'رائع', 'جميل', 'ممتاز', 'نجاح', 'فخور',
      'ممتن', 'هادئ', 'متحمس', 'سعادة', 'بهجة', 'خير',
    };

    const negative = {
      // English
      'sad', 'angry', 'hate', 'terrible', 'awful', 'bad', 'worst', 'fail',
      'failure', 'hurt', 'pain', 'depressed', 'anxious', 'worried', 'afraid',
      'scared', 'tired', 'exhausted', 'lonely', 'frustrated',
      // Arabic
      'حزين', 'غاضب', 'كره', 'سيء', 'فظيع', 'فشل', 'ألم', 'قلق',
      'خوف', 'متعب', 'وحيد', 'محبط', 'يائس', 'حزن',
    };

    if (positive.contains(word)) return 1.0;
    if (negative.contains(word)) return -1.0;
    return 0.0;
  }

  String _formatHour(int hour) {
    if (hour == 0) return 'midnight';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return 'noon';
    return '${hour - 12} PM';
  }
}

/// AIPattern — نمط مكتشف.
class AIPattern {
  final String type;
  final String title;
  final String description;
  final String icon;

  const AIPattern({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });
}
