import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../services/database_service.dart';

/// WordCloudScreen — سحابة كلمات من مذكراتك.
class WordCloudScreen extends ConsumerStatefulWidget {
  const WordCloudScreen({super.key});

  @override
  ConsumerState<WordCloudScreen> createState() => _WordCloudScreenState();
}

class _WordCloudScreenState extends ConsumerState<WordCloudScreen> {
  final DatabaseService _db = DatabaseService();
  int _period = 30; // days

  // Stop words to exclude
  static const Set<String> _stopWords = {
    'the', 'and', 'for', 'with', 'this', 'that', 'from', 'have', 'has',
    'are', 'was', 'were', 'been', 'be', 'is', 'it', 'its',
    'you', 'your', 'they', 'them', 'their', 'his', 'her',
    'she', 'he', 'we', 'our', 'us', 'me', 'my',
    'في', 'من', 'على', 'عن', 'مع', 'إلى', 'أن', 'إن',
    'كان', 'كانت', 'هو', 'هي', 'هم', 'نحن', 'أنا', 'أنت',
    'هذا', 'هذه', 'ذلك', 'تلك', 'لم', 'لن', 'لا', 'ما',
    'كل', 'بعض', 'قد', 'ثم', 'أو',
  };

  Map<String, int> get _wordFrequencies {
    final entries = _db.getAllEntries();
    final cutoff = DateTime.now().subtract(Duration(days: _period));
    final recent = entries.where((e) => e.createdAt.isAfter(cutoff));

    final freq = <String, int>{};

    for (final entry in recent) {
      final text = '${entry.title} ${entry.content}'.toLowerCase();
      final words = text.split(RegExp(r'[\s\u0600-\u06FF]+|\s+'));

      for (final w in words) {
        final word = w.trim();
        if (word.length < 3) continue;
        if (_stopWords.contains(word)) continue;
        if (RegExp(r'^\d+$').hasMatch(word)) continue;

        freq[word] = (freq[word] ?? 0) + 1;
      }
    }

    return freq;
  }

  @override
  Widget build(BuildContext context) {
    final freq = _wordFrequencies;
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(50).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Word Cloud'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [7, 30, 90, 365].map((d) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(d == 365 ? '1 Year' : '$d Days'),
                    selected: _period == d,
                    onSelected: (_) => setState(() => _period = d),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: top.isEmpty
          ? const Center(
              child: Text(
                'Write more entries to see your cloud',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: top.asMap().entries.map((e) {
                  final word = e.value.key;
                  final count = e.value.value;
                  final maxCount = top.first.value;
                  final ratio = count / maxCount;

                  final fontSize = 12 + ratio * 40;
                  final color = _colorFor(word, e.key);

                  return Text(
                    word,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight:
                          ratio > 0.5 ? FontWeight.w700 : FontWeight.w500,
                      color: color,
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }

  Color _colorFor(String word, int index) {
    const palette = [
      Color(0xFF6C5CE7),
      Color(0xFF00D2A8),
      Color(0xFFF5A623),
      Color(0xFFE84848),
      Color(0xFF3B82F6),
      Color(0xFFEC4899),
      Color(0xFF8B5CF6),
      Color(0xFF10B981),
    ];

    // Deterministic color from word hash
    final hash = word.codeUnits.fold<int>(0, (sum, c) => sum + c);
    return palette[hash % palette.length];
  }
}
