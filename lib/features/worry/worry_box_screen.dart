import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/storage.dart';

class WorryBoxScreen extends StatefulWidget {
  const WorryBoxScreen({super.key});

  @override
  State<WorryBoxScreen> createState() => _WorryBoxScreenState();
}

class _WorryBoxScreenState extends State<WorryBoxScreen> {
  final Box _box = contentBox();
  final TextEditingController _controller = TextEditingController();

  List<WorryItem> get _worries {
    final raw = _box.get(ContentKeys.worryBox);
    // A restore from another build can leave a non-list here; the old `as List`
    // threw and the screen stayed blank with no way to recover.
    final items = raw is Iterable ? raw.whereType<Map>() : const <Map>[];
    return items
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
      // The next calendar day, so "review it tomorrow" is true at midnight
      // rather than at the same hour tomorrow night.
      reviewDate: DateTime(now.year, now.month, now.day + 1),
    );
    await _box.put(
      ContentKeys.worryBox,
      [..._worries.map((e) => e.toMap()), item.toMap()],
    );
    if (!mounted) return;
    _controller.clear();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).t('worryBox.savedNote')),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _removeWorry(WorryItem item) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.t('worryBox.deleteTitle')),
        content: Text(l10n.t('worryBox.deleteBody')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.t('dialog.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.t('dialog.delete.action')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final remaining = _worries
        .where((entry) => entry.id != item.id)
        .map((entry) => entry.toMap())
        .toList();
    await _box.put(ContentKeys.worryBox, remaining);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final worries = _worries;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('hub.feature.worryBox.title'))),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.t('worryBox.hint'),
                    style: const TextStyle(
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
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📦', style: TextStyle(fontSize: 80)),
                        SizedBox(height: 16),
                        Text(
                          l10n.t('worryBox.empty'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          l10n.t('worryBox.emptyGood'),
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
                        hintText: l10n.t('worryBox.fieldHint'),
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
                  SizedBox(width: 10),
                  IconButton(
                    onPressed: _addWorry,
                    icon: const Icon(Icons.archive_outlined),
                    tooltip: l10n.t('worryBox.save'),
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
    );
  }
}

/// Whole calendar days until [reviewDate], counted by date and not by elapsed
/// hours.
///
/// A worry saved at 23:00 for review "tomorrow" is 1 day away, not 0: the old
/// `difference().inDays` truncated 23h59m to 0, so the card read "0 days left"
/// and the worry looked reviewable on the day it was written.
int worryDaysUntil(DateTime reviewDate, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(reviewDate.year, reviewDate.month, reviewDate.day);
  return due.difference(today).inDays;
}

class _WorryCard extends StatelessWidget {
  final WorryItem item;
  final VoidCallback onRemove;

  const _WorryCard({required this.item, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // "Read it tomorrow" means the next calendar day, not 24 hours later: a
    // worry written at 23:00 used to stay sealed until 23:00 the next night.
    final daysLeft = worryDaysUntil(item.reviewDate, now).clamp(0, 999);
    final canReview = daysLeft == 0;

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
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  canReview
                      ? AppLocalizations.of(context).t('worryBox.reviewTime')
                      : daysLeft == 1
                          ? AppLocalizations.of(context).t('worryBox.dayLeft')
                          : AppLocalizations.of(context)
                              .t('worryBox.daysLeft')
                              .replaceAll('{n}', '$daysLeft'),
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
                tooltip:
                    AppLocalizations.of(context).t('worryBox.deleteTooltip'),
                icon: const Icon(Icons.delete_outline, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            item.text,
            style: TextStyle(
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
