import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';

/// FutureLettersScreen — رسائل لمستقبلك.
///
/// الفكرة النفسية: الكتابة لمستقبلك تعزز التفكير طويل المدى
/// وتخلق ارتباطًا عاطفيًا بالذات المستقبلية.
class FutureLettersScreen extends StatefulWidget {
  const FutureLettersScreen({super.key});

  @override
  State<FutureLettersScreen> createState() => _FutureLettersScreenState();
}

class _FutureLettersScreenState extends State<FutureLettersScreen> {
  final Box _box = Hive.box('settings');

  List<FutureLetter> get _letters {
    final raw = _box.get('future_letters', defaultValue: <dynamic>[]) as List;
    return raw
        .map((e) => FutureLetter.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.unlockDate.compareTo(b.unlockDate));
  }

  @override
  Widget build(BuildContext context) {
    final letters = _letters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Letters to Future Me'),
      ),
      body: Column(
        children: [
          if (letters.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💌', style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 20),
                    const Text(
                      'No letters yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Write a letter to your future self',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => _composeLetter(),
                      icon: const Icon(Icons.edit),
                      label: const Text('Write first letter'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: letters.length,
                itemBuilder: (_, i) {
                  final letter = letters[i];
                  final locked = letter.unlockDate.isAfter(DateTime.now());
                  return _LetterCard(
                    letter: letter,
                    locked: locked,
                    onTap: () => locked
                        ? _showLockedMessage(letter)
                        : _openLetter(letter),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: letters.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _composeLetter(),
              icon: const Icon(Icons.edit),
              label: const Text('New Letter'),
            ),
    );
  }

  Future<void> _composeLetter() async {
    final controller = TextEditingController();
    DateTime unlockDate = DateTime.now().add(const Duration(days: 365));

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Write to Future You',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This letter will be locked until you choose',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: controller,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Dear future me...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Unlock after:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _durationChip(
                      '1 Month',
                      Duration(days: 30),
                      unlockDate,
                      (d) => setModalState(() => unlockDate = d),
                    ),
                    _durationChip(
                      '6 Months',
                      Duration(days: 180),
                      unlockDate,
                      (d) => setModalState(() => unlockDate = d),
                    ),
                    _durationChip(
                      '1 Year',
                      Duration(days: 365),
                      unlockDate,
                      (d) => setModalState(() => unlockDate = d),
                    ),
                    _durationChip(
                      '5 Years',
                      Duration(days: 1825),
                      unlockDate,
                      (d) => setModalState(() => unlockDate = d),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (controller.text.trim().isEmpty) return;
                      await _saveLetter(
                        controller.text.trim(),
                        unlockDate,
                      );
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    },
                    icon: const Icon(Icons.lock),
                    label: const Text('Lock Letter'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Letter locked until ${unlockDate.day}/${unlockDate.month}/${unlockDate.year}',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Widget _durationChip(
    String label,
    Duration duration,
    DateTime current,
    ValueChanged<DateTime> onSelected,
  ) {
    final target = DateTime.now().add(duration);
    final selected = current.year == target.year &&
        current.month == target.month &&
        current.day == target.day;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(target),
      ),
    );
  }

  Future<void> _saveLetter(String text, DateTime unlockDate) async {
    final letter = FutureLetter(
      id: const Uuid().v4(),
      text: text,
      createdAt: DateTime.now(),
      unlockDate: unlockDate,
    );
    final list = [..._letters.map((e) => e.toMap()), letter.toMap()];
    await _box.put('future_letters', list);
  }

  void _showLockedMessage(FutureLetter letter) {
    final days = letter.unlockDate.difference(DateTime.now()).inDays;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🔒 Letter Locked'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This letter will unlock on:'),
            const SizedBox(height: 12),
            Text(
              '${letter.unlockDate.day}/${letter.unlockDate.month}/${letter.unlockDate.year}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$days days remaining',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openLetter(FutureLetter letter) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Text('💌', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            const Text('From your past self'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                letter.text,
                style: const TextStyle(fontSize: 15, height: 1.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Written: ${letter.createdAt.day}/${letter.createdAt.month}/${letter.createdAt.year}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  final FutureLetter letter;
  final bool locked;
  final VoidCallback onTap;

  const _LetterCard({
    required this.letter,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: locked
              ? const LinearGradient(
                  colors: [Color(0xFF546E7A), Color(0xFF37474F)],
                )
              : const LinearGradient(
                  colors: [Color(0xFFF48FB1), Color(0xFFE91E63)],
                ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                locked ? '🔒' : '💌',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    locked ? 'Locked Letter' : 'Read Letter',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locked
                        ? 'Unlocks: ${letter.unlockDate.day}/${letter.unlockDate.month}/${letter.unlockDate.year}'
                        : 'Written: ${letter.createdAt.day}/${letter.createdAt.month}/${letter.createdAt.year}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class FutureLetter {
  final String id;
  final String text;
  final DateTime createdAt;
  final DateTime unlockDate;

  const FutureLetter({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.unlockDate,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'unlockDate': unlockDate.toIso8601String(),
      };

  factory FutureLetter.fromMap(Map<dynamic, dynamic> m) => FutureLetter(
        id: m['id']?.toString() ?? '',
        text: m['text']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
        unlockDate:
            DateTime.tryParse(m['unlockDate']?.toString() ?? '') ?? DateTime.now(),
      );
}
