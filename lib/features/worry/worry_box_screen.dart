import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';

class WorryBoxScreen extends StatefulWidget {
  const WorryBoxScreen({super.key});

  @override
  State<WorryBoxScreen> createState() => _WorryBoxScreenState();
}

class _WorryBoxScreenState extends State<WorryBoxScreen> {
  final Box _box = Hive.box('settings');
  final TextEditingController _controller = TextEditingController();

  List<WorryItem> get _worries {
    final raw = _box.get('worry_box', defaultValue: <dynamic>[]) as List;
    return raw
        .whereType<Map>()
        .map((item) => WorryItem.fromMap(Map<dynamic, dynamic>.from(item)))
        .where((item) => item.text.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.reviewDate.compareTo(b.reviewDate));
  }

  Future<void> _addWorry() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final item = WorryItem(
      id: const Uuid().v4(),
      text: text,
      createdAt: now,
      reviewDate: now.add(const Duration(days: 1)),
    );
    await _box
        .put('worry_box', [..._worries.map((e) => e.toMap()), item.toMap()]);
    if (!mounted) return;
    _controller.clear();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حفظ القلق. يمكنك مراجعته غدًا.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _removeWorry(WorryItem item) async {
    final remaining = _worries
        .where((entry) => entry.id != item.id)
        .map((entry) => entry.toMap())
        .toList();
    await _box.put('worry_box', remaining);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final worries = _worries;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('صندوق القلق')),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ضع ما يقلقك هنا. راجعه غدًا؛ غالبًا سيبدو أصغر.',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: worries.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('📦', style: TextStyle(fontSize: 80)),
                          SizedBox(height: 16),
                          Text(
                            'صندوق القلق فارغ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'وهذا أمر جيد ✨',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: worries.length,
                      itemBuilder: (_, index) => _WorryCard(
                        item: worries[index],
                        onRemove: () => _removeWorry(worries[index]),
                      ),
                    ),
            ),
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'ما الذي يقلقك؟',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _addWorry(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _addWorry,
                      icon: const Icon(Icons.archive_outlined),
                      tooltip: 'حفظ القلق',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorryCard extends StatelessWidget {
  final WorryItem item;
  final VoidCallback onRemove;

  const _WorryCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final canReview = !now.isBefore(item.reviewDate);
    final daysLeft = item.reviewDate.difference(now).inDays.clamp(0, 999);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canReview
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.textTertiary.withValues(alpha: 0.2),
          width: canReview ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(canReview ? '🔓' : '📦',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  canReview
                      ? 'حان وقت المراجعة'
                      : 'متبقٍ $daysLeft ${daysLeft == 1 ? 'يوم' : 'أيام'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        canReview ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: 'حذف',
                icon: const Icon(Icons.delete_outline, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class WorryItem {
  final String id;
  final String text;
  final DateTime createdAt;
  final DateTime reviewDate;

  const WorryItem({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.reviewDate,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'reviewDate': reviewDate.toIso8601String(),
      };

  factory WorryItem.fromMap(Map<dynamic, dynamic> map) => WorryItem(
        id: map['id']?.toString() ?? '',
        text: map['text']?.toString() ?? '',
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        reviewDate: DateTime.tryParse(map['reviewDate']?.toString() ?? '') ??
            DateTime.now(),
      );
}
