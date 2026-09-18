import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';

/// TimeCapsuleScreen — كبسولة زمنية تُفتح بعد سنوات.
class TimeCapsuleScreen extends StatefulWidget {
  const TimeCapsuleScreen({super.key});

  @override
  State<TimeCapsuleScreen> createState() => _TimeCapsuleScreenState();
}

class _TimeCapsuleScreenState extends State<TimeCapsuleScreen> {
  final Box _box = Hive.box('settings');

  List<TimeCapsule> get _capsules {
    final raw = _box.get('time_capsules', defaultValue: <dynamic>[]) as List;
    return raw
        .map((e) => TimeCapsule.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.unlockAt.compareTo(b.unlockAt));
  }

  @override
  Widget build(BuildContext context) {
    final capsules = _capsules;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Capsules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _composeCapsule,
          ),
        ],
      ),
      body: capsules.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⏳', style: TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),
                  const Text(
                    'No time capsules',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bury a message for your future self',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _composeCapsule,
                    icon: const Icon(Icons.add),
                    label: const Text('Create capsule'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: capsules.length,
              itemBuilder: (_, i) => _CapsuleCard(
                capsule: capsules[i],
                onOpen: () => _openCapsule(capsules[i]),
              ),
            ),
    );
  }

  Future<void> _composeCapsule() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    Duration selectedDuration = const Duration(days: 365);

    await showModalBottomSheet(
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Time Capsule',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Capsule title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Message to future you...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
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
                Wrap(
                  spacing: 8,
                  children: [
                    _chip('1 Month', 30, selectedDuration,
                        (d) => setModalState(() => selectedDuration = d)),
                    _chip('6 Months', 180, selectedDuration,
                        (d) => setModalState(() => selectedDuration = d)),
                    _chip('1 Year', 365, selectedDuration,
                        (d) => setModalState(() => selectedDuration = d)),
                    _chip('5 Years', 1825, selectedDuration,
                        (d) => setModalState(() => selectedDuration = d)),
                    _chip('10 Years', 3650, selectedDuration,
                        (d) => setModalState(() => selectedDuration = d)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (contentController.text.trim().isEmpty) return;
                      await _saveCapsule(
                        titleController.text.trim(),
                        contentController.text.trim(),
                        DateTime.now().add(selectedDuration),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.lock),
                    label: const Text('Bury Capsule'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    setState(() {});
  }

  Widget _chip(
    String label,
    int days,
    Duration selected,
    ValueChanged<Duration> onSelected,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: selected.inDays == days,
      onSelected: (_) => onSelected(Duration(days: days)),
    );
  }

  Future<void> _saveCapsule(
    String title,
    String content,
    DateTime unlockAt,
  ) async {
    final capsule = TimeCapsule(
      id: const Uuid().v4(),
      title: title,
      content: content,
      createdAt: DateTime.now(),
      unlockAt: unlockAt,
    );
    final list = [..._capsules.map((e) => e.toMap()), capsule.toMap()];
    await _box.put('time_capsules', list);
  }

  void _openCapsule(TimeCapsule capsule) {
    final unlocked = capsule.unlockAt.isBefore(DateTime.now());

    if (!unlocked) {
      final days = capsule.unlockAt.difference(DateTime.now()).inDays;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('🔒 Capsule Locked'),
          content: Text(
            'Unlocks on ${capsule.unlockAt.day}/${capsule.unlockAt.month}/${capsule.unlockAt.year}\n\n$days days remaining',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(capsule.title.isEmpty ? 'Time Capsule' : capsule.title),
        content: SingleChildScrollView(
          child: Text(capsule.content),
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

class _CapsuleCard extends StatelessWidget {
  final TimeCapsule capsule;
  final VoidCallback onOpen;

  const _CapsuleCard({required this.capsule, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final unlocked = capsule.unlockAt.isBefore(DateTime.now());

    return GestureDetector(
      onTap: onOpen,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: unlocked
                ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                : [const Color(0xFF546E7A), const Color(0xFF37474F)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                unlocked ? '💌' : '⏳',
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    capsule.title.isEmpty ? 'Untitled Capsule' : capsule.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    unlocked
                        ? 'Tap to open!'
                        : 'Unlocks ${capsule.unlockAt.day}/${capsule.unlockAt.month}/${capsule.unlockAt.year}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              unlocked ? Icons.lock_open : Icons.lock,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }
}

class TimeCapsule {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime unlockAt;

  const TimeCapsule({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.unlockAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'unlockAt': unlockAt.toIso8601String(),
      };

  factory TimeCapsule.fromMap(Map<dynamic, dynamic> m) => TimeCapsule(
        id: m['id']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        content: m['content']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(m['createdAt']?.toString() ?? '') ?? DateTime.now(),
        unlockAt:
            DateTime.tryParse(m['unlockAt']?.toString() ?? '') ?? DateTime.now(),
      );
}
