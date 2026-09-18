import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';

/// UnsentLettersScreen — رسائل لن تُرسل أبدًا.
///
/// الفكرة النفسية:
///   كتابة رسالة لشخص لن تستطيع/تريد إرسالها لها
///   تُعطي تفريغًا عاطفيًا هائلًا.
class UnsentLettersScreen extends StatefulWidget {
  const UnsentLettersScreen({super.key});

  @override
  State<UnsentLettersScreen> createState() => _UnsentLettersScreenState();
}

class _UnsentLettersScreenState extends State<UnsentLettersScreen> {
  final Box _box = Hive.box('settings');

  List<UnsentLetter> get _letters {
    final raw = _box.get('unsent_letters', defaultValue: <dynamic>[]) as List;
    return raw
        .map((e) => UnsentLetter.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    final letters = _letters;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unsent Letters'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _composeLetter(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    color: Color(0xFF9C27B0), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Letters you write but never send. '
                    'A powerful way to process emotions.',
                    style: TextStyle(
                      color: Color(0xFF9C27B0),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: letters.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💌', style: TextStyle(fontSize: 80)),
                        const SizedBox(height: 16),
                        const Text(
                          'No unsent letters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Write to someone you can\'t reach',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => _composeLetter(),
                          icon: const Icon(Icons.edit),
                          label: const Text('Write first letter'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF9C27B0),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: letters.length,
                    itemBuilder: (_, i) => _LetterCard(
                      letter: letters[i],
                      onDelete: () => _deleteLetter(letters[i]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: letters.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => _composeLetter(),
              backgroundColor: const Color(0xFF9C27B0),
              child: const Icon(Icons.edit, color: Colors.white),
            ),
    );
  }

  Future<void> _composeLetter() async {
    final toController = TextEditingController();
    final contentController = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Write an unsent letter',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'To whom?',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: toController,
                decoration: InputDecoration(
                  hintText: 'To: someone I miss...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: 'Dear..., I wanted to tell you...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    if (contentController.text.trim().isEmpty) return;
                    await _saveLetter(
                      toController.text.trim().isEmpty
                          ? 'Someone'
                          : toController.text.trim(),
                      contentController.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  },
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Keep it unsent'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF9C27B0),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (saved == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💌 Letter kept in your heart'),
          backgroundColor: Color(0xFF9C27B0),
        ),
      );
    }
  }

  Future<void> _saveLetter(String to, String content) async {
    final letter = UnsentLetter(
      id: const Uuid().v4(),
      to: to,
      content: content,
      createdAt: DateTime.now(),
    );
    final list = [..._letters.map((e) => e.toMap()), letter.toMap()];
    await _box.put('unsent_letters', list);
  }

  Future<void> _deleteLetter(UnsentLetter letter) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Let it go?'),
        content: const Text(
          'This letter will be released. You cannot get it back.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Release'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final list = _letters
          .where((l) => l.id != letter.id)
          .map((l) => l.toMap())
          .toList();
      await _box.put('unsent_letters', list);
      setState(() {});
    }
  }
}

class _LetterCard extends StatelessWidget {
  final UnsentLetter letter;
  final VoidCallback onDelete;

  const _LetterCard({required this.letter, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF9C27B0).withValues(alpha: 0.1),
            const Color(0xFF6A1B9A).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF9C27B0).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('💌', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'To: ${letter.to}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            letter.content,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${letter.createdAt.day}/${letter.createdAt.month}/${letter.createdAt.year}',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class UnsentLetter {
  final String id;
  final String to;
  final String content;
  final DateTime createdAt;

  const UnsentLetter({
    required this.id,
    required this.to,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'to': to,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UnsentLetter.fromMap(Map<dynamic, dynamic> m) => UnsentLetter(
        id: m['id']?.toString() ?? '',
        to: m['to']?.toString() ?? '',
        content: m['content']?.toString() ?? '',
        createdAt: DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
            DateTime.now(),
      );
}
