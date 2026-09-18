import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';

/// DreamJournalScreen — مذكرة أحلام بألوان حالمة.
class DreamJournalScreen extends StatefulWidget {
  const DreamJournalScreen({super.key});

  @override
  State<DreamJournalScreen> createState() => _DreamJournalScreenState();
}

class _DreamJournalScreenState extends State<DreamJournalScreen> {
  final Box _box = Hive.box('journal_entries');
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  bool _isLucid = false;
  bool _isNightmare = false;
  int _clarity = 3; // 1-5

  List<DreamEntry> get _dreams {
    return _box.values
        .map((e) => Map<dynamic, dynamic>.from(e as Map))
        .where((e) => e['isDream'] == true)
        .map((e) => DreamEntry.fromMap(e))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveDream() async {
    if (_controller.text.trim().isEmpty) return;

    final dream = DreamEntry(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      content: _controller.text.trim(),
      createdAt: DateTime.now(),
      isLucid: _isLucid,
      isNightmare: _isNightmare,
      clarity: _clarity,
    );

    await _box.put(dream.id, dream.toMap());
    _controller.clear();
    _titleController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dreams = _dreams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dream Journal'),
        backgroundColor: const Color(0xFF1A1F3A),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A1F3A),
              Color(0xFF2A1F3A),
              Color(0xFF0A0D14),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Existing dreams
            if (dreams.isNotEmpty)
              Expanded(
                flex: 2,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dreams.length,
                  itemBuilder: (_, i) => _DreamCard(dream: dreams[i]),
                ),
              )
            else
              const Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🌙', style: TextStyle(fontSize: 80)),
                      SizedBox(height: 16),
                      Text(
                        'No dreams recorded',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Compose area
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Record a dream',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Dream title (optional)',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Describe your dream...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Options
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Lucid'),
                        selected: _isLucid,
                        onSelected: (v) => setState(() => _isLucid = v),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Nightmare'),
                        selected: _isNightmare,
                        onSelected: (v) => setState(() => _isNightmare = v),
                      ),
                      const Spacer(),
                      const Text(
                        'Clarity',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(5, (i) {
                        return GestureDetector(
                          onTap: () => setState(() => _clarity = i + 1),
                          child: Container(
                            margin: const EdgeInsets.only(left: 2),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: i < _clarity
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saveDream,
                      icon: const Icon(Icons.nightlight_round),
                      label: const Text('Save Dream'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DreamCard extends StatelessWidget {
  final DreamEntry dream;
  const _DreamCard({required this.dream});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dream.isNightmare ? '😱' : dream.isLucid ? '✨' : '🌙',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dream.title.isEmpty ? 'Untitled Dream' : dream.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${dream.createdAt.day}/${dream.createdAt.month}',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dream.content,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class DreamEntry {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final bool isLucid;
  final bool isNightmare;
  final int clarity;

  const DreamEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.isLucid,
    required this.isNightmare,
    required this.clarity,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'isDream': true,
        'isLucid': isLucid,
        'isNightmare': isNightmare,
        'clarity': clarity,
      };

  factory DreamEntry.fromMap(Map<dynamic, dynamic> m) => DreamEntry(
        id: m['id']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        content: m['content']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
        isLucid: m['isLucid'] == true,
        isNightmare: m['isNightmare'] == true,
        clarity: (m['clarity'] as num?)?.toInt() ?? 3,
      );
}
