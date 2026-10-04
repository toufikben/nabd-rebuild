import 'package:hive_flutter/hive_flutter.dart';

import '../core/streak.dart';
import '../models/journal_entry.dart';
import '../core/storage.dart';

/// MotivationService — الاقتباسات + الإنجازات + التحديات.
class MotivationService {
  /// اقتباسات محلية.
  static const _quotes = [
    ('The unexamined life is not worth living.', 'Socrates'),
    (
      'We are what we repeatedly do. Excellence, then, is not an act, but a habit.',
      'Aristotle'
    ),
    (
      'The best time to plant a tree was 20 years ago. The second best time is now.',
      'Chinese Proverb'
    ),
    ('Write hard and clear about what hurts.', 'Ernest Hemingway'),
    (
      'You don\'t have to be great to start, but you have to start to be great.',
      'Zig Ziglar'
    ),
    (
      'Almost everything will work again if you unplug it for a few minutes, including you.',
      'Anne Lamott'
    ),
    (
      'Feelings are much like waves. We can\'t stop them from coming, but we can choose which one to surf.',
      'Jonatan Mårtensson'
    ),
    ('The wound is the place where the light enters you.', 'Rumi'),
    (
      'Nothing is impossible. The word itself says "I\'m possible!"',
      'Audrey Hepburn'
    ),
    (
      'You are allowed to be both a masterpiece and a work in progress.',
      'Sophia Bush'
    ),
    ('The only way out is through.', 'Robert Frost'),
    ('Wherever you are, be there totally.', 'Eckhart Tolle'),
    ('The journey of a thousand miles begins with a single step.', 'Lao Tzu'),
    ('What you seek is seeking you.', 'Rumi'),
    ('Be gentle with yourself. You are a child of the universe.', 'Desiderata'),
  ];

  static const _arabicQuotes = [
    ('الحياة التي لا نفحصها لا تستحق أن نعيشها.', 'سقراط'),
    ('نحن ما نكرره باستمرار؛ فالتميّز ليس فعلًا بل عادة.', 'أرسطو'),
    (
      'أفضل وقت لزرع شجرة كان قبل عشرين عامًا، وثاني أفضل وقت هو الآن.',
      'مثل صيني'
    ),
    ('اكتب بصدق ووضوح عمّا يؤلمك.', 'إرنست همنغواي'),
    (
      'لست بحاجة إلى أن تكون عظيمًا كي تبدأ، لكن عليك أن تبدأ كي تصبح عظيمًا.',
      'زيغ زيغلر'
    ),
    (
      'كل شيء تقريبًا سيعمل مجددًا إذا منحته بضع دقائق من الراحة، بما في ذلك أنت.',
      'آن لاموت'
    ),
    (
      'المشاعر تشبه الأمواج؛ لا نستطيع منعها من الوصول، لكن يمكننا اختيار الموجة التي نركبها.',
      'جوناثان مارتنسون'
    ),
    ('الجرح هو المكان الذي يدخل منه النور إليك.', 'الرومي'),
    ('لا شيء مستحيل؛ فالكلمة نفسها تقول: أنا ممكن.', 'أودري هيبورن'),
    ('يسمح لك أن تكون تحفة فنية وعملًا قيد التطور في الوقت نفسه.', 'صوفيا بوش'),
    ('الطريق الوحيد للخروج هو العبور من خلاله.', 'روبرت فروست'),
    ('أينما كنت، كن حاضرًا بكل كيانك.', 'إيكهارت تول'),
    ('رحلة الألف ميل تبدأ بخطوة واحدة.', 'لاو تزو'),
    ('ما تبحث عنه يبحث عنك أيضًا.', 'الرومي'),
    ('كن لطيفًا مع نفسك؛ فأنت ابن هذا الكون.', 'ديسيديراتا'),
  ];

  /// مكتبة الاقتباسات حسب اللغة.
  static List<(String, String)> _library(bool arabic) =>
      arabic ? _arabicQuotes : _quotes;

  /// اقتباس اليوم (ثابت خلال اليوم) حسب لغة الواجهة.
  static (String, String) getTodayQuoteFor(bool arabic) {
    final list = _library(arabic);
    final day = DateTime.now().difference(DateTime(2025)).inDays;
    return list[day % list.length];
  }

  /// اقتباس عشوائي حسب لغة الواجهة، مع استبعاد الاقتباس المعروض إن طُلب.
  static (String, String) getRandomQuoteFor(bool arabic,
      {String? excludingQuote}) {
    final list = _library(arabic);
    final start = DateTime.now().microsecondsSinceEpoch % list.length;
    if (excludingQuote == null || list.length < 2) {
      return list[start];
    }
    for (var offset = 0; offset < list.length; offset++) {
      final candidate = list[(start + offset) % list.length];
      if (candidate.$1 != excludingQuote) return candidate;
    }
    return list[start];
  }

  static (String, String) getTodayQuote() => getTodayQuoteFor(false);

  static (String, String) getRandomQuote() => getRandomQuoteFor(false);

  static (String, String) getTodayQuoteArabic() => getTodayQuoteFor(true);

  static (String, String) getRandomQuoteArabic({String? excludingQuote}) =>
      getRandomQuoteFor(true, excludingQuote: excludingQuote);
}

/// Achievement — إنجاز يفتحه المستخدم.
class Achievement {
  final String id;
  final String emoji;
  final String titleEn;
  final String titleAr;
  final String description;
  final String descriptionAr;
  final int requirement;
  final String requirementType;

  String titleFor(bool arabic) => arabic ? titleAr : titleEn;
  String descriptionFor(bool arabic) => arabic ? descriptionAr : description;

  const Achievement({
    required this.id,
    required this.emoji,
    required this.titleEn,
    required this.titleAr,
    required this.description,
    required this.descriptionAr,
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
      descriptionAr: 'اكتب أول مدخلة',
      requirement: 1,
      requirementType: 'entries',
    ),
    Achievement(
      id: 'seven_entries',
      emoji: '🌿',
      titleEn: 'Growing',
      titleAr: 'تنمو',
      description: 'Write 7 entries',
      descriptionAr: 'اكتب 7 مدخلات',
      requirement: 7,
      requirementType: 'entries',
    ),
    Achievement(
      id: 'thirty_entries',
      emoji: '🌳',
      titleEn: 'Strong Writer',
      titleAr: 'كاتب قوي',
      description: 'Write 30 entries',
      descriptionAr: 'اكتب 30 مدخلة',
      requirement: 30,
      requirementType: 'entries',
    ),
    Achievement(
      id: 'streak_3',
      emoji: '🔥',
      titleEn: 'On Fire',
      titleAr: 'ملتهب',
      description: '3-day streak',
      descriptionAr: '٣ أيام متتالية',
      requirement: 3,
      requirementType: 'streak',
    ),
    Achievement(
      id: 'streak_7',
      emoji: '⭐',
      titleEn: 'Week Warrior',
      titleAr: 'محارب الأسبوع',
      description: '7-day streak',
      descriptionAr: '٧ أيام متتالية',
      requirement: 7,
      requirementType: 'streak',
    ),
    Achievement(
      id: 'streak_30',
      emoji: '🏆',
      titleEn: 'Month Master',
      titleAr: 'سيد الشهر',
      description: '30-day streak',
      descriptionAr: '٣٠ يوماً متتالية',
      requirement: 30,
      requirementType: 'streak',
    ),
    Achievement(
      id: 'words_1000',
      emoji: '✍️',
      titleEn: 'Storyteller',
      titleAr: 'راوي',
      description: 'Write 1,000 words',
      descriptionAr: 'اكتب ١٠٠٠ كلمة',
      requirement: 1000,
      requirementType: 'words',
    ),
    Achievement(
      id: 'words_10000',
      emoji: '📚',
      titleEn: 'Author',
      titleAr: 'مؤلف',
      description: 'Write 10,000 words',
      descriptionAr: 'اكتب ١٠٠٠٠ كلمة',
      requirement: 10000,
      requirementType: 'words',
    ),
    Achievement(
      id: 'moods_variety',
      emoji: '🎨',
      titleEn: 'Emotional Rainbow',
      titleAr: 'قوس قزح عاطفي',
      description: 'Use 10 different moods',
      descriptionAr: 'استعمل ١٠ مزاجات مختلفة',
      requirement: 10,
      requirementType: 'moods',
    ),
    Achievement(
      id: 'gratitude_7',
      emoji: '🙏',
      titleEn: 'Grateful Heart',
      titleAr: 'قلب ممتن',
      description: '7 days of gratitude',
      descriptionAr: '٧ أيام من الامتنان',
      requirement: 7,
      requirementType: 'gratitude',
    ),
  ];
}

/// AchievementService — فحص الإنجازات المفتوحة.
class AchievementService {
  Box get _box => contentBox();

  Set<String> get unlockedIds {
    final raw =
        _box.get('unlocked_achievements', defaultValue: <dynamic>[]) as List;
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

  /// Distinct gratitude journal days saved in [box]. The garden stores its
  /// flowers under the same `gratitude_` prefix, so only day-shaped keys with
  /// at least one non-empty line count.
  static int gratitudeDayCount(Box box) {
    var days = 0;
    for (final key in box.keys) {
      final name = key.toString();
      if (!name.startsWith('gratitude_')) continue;
      final date = _journalDateFromKey(name);
      if (date == null) continue;
      final raw = box.get(key);
      if (raw is! Iterable) continue;
      final hasText = raw.any((item) => item?.toString().trim().isNotEmpty ?? false);
      if (hasText) days++;
    }
    return days;
  }

  /// `gratitude_<y>_<m>_<d>` stands for a journal day; anything else in the
  /// same prefix belongs to the garden or to an older writer. The parts are
  /// checked against the date they build because `DateTime.parse` happily
  /// rolls an impossible day like `2026-9-31` into the next month.
  static DateTime? _journalDateFromKey(String key) {
    final parts = key.split('_');
    if (parts.length != 4) return null;
    final year = int.tryParse(parts[1]);
    final month = int.tryParse(parts[2]);
    final day = int.tryParse(parts[3]);
    if (year == null || month == null || day == null) return null;
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) return null;
    return date;
  }

  /// The progress numbers every achievement is judged on, from the journal as
  /// it is now. The streak is the longest run ever, so a past week of writing
  /// is never "un-earned" by a missed day.
  static Map<String, int> progressFor(List<JournalEntry> entries, Box settings) {
    return {
      'entries': entries.length,
      'streak': StreakCalculator.longest(entries.map((e) => e.createdAt)),
      'words': entries.fold<int>(
        0,
        (sum, e) => sum +
            (e.content.trim().isEmpty
                ? 0
                : e.content.trim().split(RegExp(r'\s+')).length),
      ),
      'moods': entries
          .map((e) => e.mood)
          .where((m) => m.isNotEmpty)
          .toSet()
          .length,
      'gratitude': gratitudeDayCount(settings),
    };
  }

  /// Unlocks whatever the journal now qualifies for. The single caller-facing
  /// entry point, used after a save and when the achievements screen opens.
  Future<List<Achievement>> unlockFromJournal(
    List<JournalEntry> entries,
    Box settings,
  ) {
    final progress = progressFor(entries, settings);
    return unlockEligible(
      entries: progress['entries']!,
      streak: progress['streak']!,
      words: progress['words']!,
      moods: progress['moods']!,
      gratitudeDays: progress['gratitude']!,
    );
  }

  /// Unlocks every achievement the stats qualify for and returns the new ones.
  Future<List<Achievement>> unlockEligible({
    required int entries,
    required int streak,
    required int words,
    required int moods,
    required int gratitudeDays,
  }) async {
    final fresh = checkNew(
      entries: entries,
      streak: streak,
      words: words,
      moods: moods,
      gratitudeDays: gratitudeDays,
    );
    for (final achievement in fresh) {
      await unlock(achievement);
    }
    return fresh;
  }
}
