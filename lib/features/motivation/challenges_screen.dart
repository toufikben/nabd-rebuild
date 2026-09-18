import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/theme/app_colors.dart';

/// ChallengesScreen — تحديات أسبوعية/شهرية.
class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final Box _box = Hive.box('settings');

  static const _challenges = [
    _Challenge(
      id: 'gratitude_7',
      title: '7 Days of Gratitude',
      titleAr: '7 أيام من الامتنان',
      description: 'Write 3 gratitude items daily for a week',
      emoji: '🙏',
      days: 7,
    ),
    _Challenge(
      id: 'mood_check',
      title: 'Mood Tracker',
      titleAr: 'متتبع المزاج',
      description: 'Log your mood every day',
      emoji: '😊',
      days: 14,
    ),
    _Challenge(
      id: 'long_writing',
      title: 'Deep Dive',
      titleAr: 'غوص عميق',
      description: 'Write 500+ words daily',
      emoji: '✍️',
      days: 7,
    ),
    _Challenge(
      id: 'dream_journal',
      title: 'Dream Catcher',
      titleAr: 'صائد الأحلام',
      description: 'Record your dreams every morning',
      emoji: '🌙',
      days: 14,
    ),
    _Challenge(
      id: 'breathing',
      title: 'Mindful Start',
      titleAr: 'بداية واعية',
      description: 'Start each entry with breathing',
      emoji: '🧘',
      days: 30,
    ),
  ];

  Set<String> get _joined => Set.from(
        (_box.get('joined_challenges', defaultValue: <dynamic>[]) as List)
            .map((e) => e.toString()),
      );

  Future<void> _toggleJoin(String id) async {
    final joined = _joined;
    if (joined.contains(id)) {
      joined.remove(id);
    } else {
      joined.add(id);
    }
    await _box.put('joined_challenges', joined.toList());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _challenges.length,
        itemBuilder: (_, i) {
          final c = _challenges[i];
          final joined = _joined.contains(c.id);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: joined
                  ? const LinearGradient(
                      colors: [Color(0xFF6C5CE7), Color(0xFF8B7BFF)],
                    )
                  : null,
              color: joined ? null : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: joined
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        c.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: joined
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: joined
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: joined
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${c.days} days',
                              style: TextStyle(
                                fontSize: 10,
                                color: joined
                                    ? Colors.white
                                    : AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: joined
                      ? OutlinedButton.icon(
                          onPressed: () => _toggleJoin(c.id),
                          icon: const Icon(Icons.check),
                          label: const Text('Joined'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white),
                          ),
                        )
                      : FilledButton(
                          onPressed: () => _toggleJoin(c.id),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Text('Join Challenge'),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Challenge {
  final String id;
  final String title;
  final String titleAr;
  final String description;
  final String emoji;
  final int days;

  const _Challenge({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.description,
    required this.emoji,
    required this.days,
  });
}
