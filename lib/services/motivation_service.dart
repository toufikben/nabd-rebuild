import 'package:hive_flutter/hive_flutter.dart';

/// MotivationService — الاقتباسات + الإنجازات + التحديات.
class MotivationService {
  /// اقتباسات محلية.
  static const _quotes = [
    ('The unexamined life is not worth living.', 'Socrates'),
    ('We are what we repeatedly do. Excellence, then, is not an act, but a habit.', 'Aristotle'),
    ('The best time to plant a tree was 20 years ago. The second best time is now.', 'Chinese Proverb'),
    ('Write hard and clear about what hurts.', 'Ernest Hemingway'),
    ('You don\'t have to be great to start, but you have to start to be great.', 'Zig Ziglar'),
    ('Almost everything will work again if you unplug it for a few minutes, including you.', 'Anne Lamott'),
    ('Feelings are much like waves. We can\'t stop them from coming, but we can choose which one to surf.', 'Jonatan Mårtensson'),
    ('The wound is the place where the light enters you.', 'Rumi'),
    ('Nothing is impossible. The word itself says "I\'m possible!"', 'Audrey Hepburn'),
    ('You are allowed to be both a masterpiece and a work in progress.', 'Sophia Bush'),
    ('The only way out is through.', 'Robert Frost'),
    ('Wherever you are, be there totally.', 'Eckhart Tolle'),
    ('The journey of a thousand miles begins with a single step.', 'Lao Tzu'),
    ('What you seek is seeking you.', 'Rumi'),
    ('Be gentle with yourself. You are a child of the universe.', 'Desiderata'),
  ];

  /// اقتباس اليوم (ثابت خلال اليوم).
  static (String, String) getTodayQuote() {
    final day = DateTime.now().difference(DateTime(2025)).inDays;
    return _quotes[day % _quotes.length];
  }

  /// اقتباس عشوائي.
  static (String, String) getRandomQuote() {
    final idx = DateTime.now().microsecondsSinceEpoch % _quotes.length;
    return _quotes[idx];
  }
}

/// Achievement — إنجاز يفتحه المستخدم.
class Achievement {
  final String id;
  final String emoji;
  final String titleEn;
  final String titleAr;
  final String description;
  final int requirement;
  final String requirementType;

  const Achievement({
    required this.id,
    required this.emoji,
    required this.titleEn,
    required this.titleAr,
    required this.description,
    required this.requirement,
    required this.requirementType,
  });

  static const all = [
    Achievement(
      id: 'first_entry',
      emoji: '🌱',
      titleEn: 'First Seed',
      titleAr: 'أول بذرة',
      description: 'Write your first entry',
      requirement: 1,
      requirementType: 'entries',
    ),
    Achievement(
      id: 'seven_entries',
      emoji: '🌿',
      titleEn: 'Growing',
      titleAr: 'تنمو',
      description: 'Write 7 entries',
      requirement: 7,
      requirementType: 'entries',
    ),
    Achievement(
      id: 'thirty_entries',
      emoji: '🌳',
      titleEn: 'Strong Writer',
      titleAr: 'كاتب قوي',
      description: 'Write 30 entries',
      requirement: 30,
      requirementType: 'entries',
    ),
    Achievement(
      id: 'streak_3',
      emoji: '🔥',
      titleEn: 'On Fire',
      titleAr: 'ملتهب',
      description: '3-day streak',
      requirement: 3,
      requirementType: 'streak',
    ),
    Achievement(
      id: 'streak_7',
      emoji: '⭐',
      titleEn: 'Week Warrior',
      titleAr: 'محارب الأسبوع',
      description: '7-day streak',
      requirement: 7,
      requirementType: 'streak',
    ),
    Achievement(
      id: 'streak_30',
      emoji: '🏆',
      titleEn: 'Month Master',
      titleAr: 'سيد الشهر',
      description: '30-day streak',
      requirement: 30,
      requirementType: 'streak',
    ),
    Achievement(
      id: 'words_1000',
      emoji: '✍️',
      titleEn: 'Storyteller',
      titleAr: 'راوي',
      description: 'Write 1,000 words',
      requirement: 1000,
      requirementType: 'words',
    ),
    Achievement(
      id: 'words_10000',
      emoji: '📚',
      titleEn: 'Author',
      titleAr: 'مؤلف',
      description: 'Write 10,000 words',
      requirement: 10000,
      requirementType: 'words',
    ),
    Achievement(
      id: 'moods_variety',
      emoji: '🎨',
      titleEn: 'Emotional Rainbow',
      titleAr: 'قوس قزح عاطفي',
      description: 'Use 10 different moods',
      requirement: 10,
      requirementType: 'moods',
    ),
    Achievement(
      id: 'gratitude_7',
      emoji: '🙏',
      titleEn: 'Grateful Heart',
      titleAr: 'قلب ممتن',
      description: '7 days of gratitude',
      requirement: 7,
      requirementType: 'gratitude',
    ),
  ];
}

/// AchievementService — فحص الإنجازات المفتوحة.
class AchievementService {
  Box get _box => Hive.box('settings');

  Set<String> get unlockedIds {
    final raw = _box.get('unlocked_achievements', defaultValue: <dynamic>[]) as List;
    return raw.map((e) => e.toString()).toSet();
  }

  /// فحص الإنجازات الجديدة.
  List<Achievement> checkNew({
    required int entries,
    required int streak,
    required int words,
    required int moods,
    required int gratitudeDays,
  }) {
    final unlocked = unlockedIds;
    final newOnes = <Achievement>[];

    for (final a in Achievement.all) {
      if (unlocked.contains(a.id)) continue;

      bool ok = false;
      switch (a.requirementType) {
        case 'entries':
          ok = entries >= a.requirement;
          break;
        case 'streak':
          ok = streak >= a.requirement;
          break;
        case 'words':
          ok = words >= a.requirement;
          break;
        case 'moods':
          ok = moods >= a.requirement;
          break;
        case 'gratitude':
          ok = gratitudeDays >= a.requirement;
          break;
      }

      if (ok) newOnes.add(a);
    }

    return newOnes;
  }

  Future<void> unlock(Achievement a) async {
    final ids = unlockedIds..add(a.id);
    await _box.put('unlocked_achievements', ids.toList());
  }
}
