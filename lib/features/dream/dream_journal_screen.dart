import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../services/database_service.dart';

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

  /// The dream being edited, or null while writing a new one.
  DreamEntry? _editing;

  List<DreamEntry> get _dreams {
    return _box.values
        // A box is not a schema: a value written by an older build or by a
        // restore can be anything, and `e as Map` threw on it, taking the whole
        // dream list down with it.
        .whereType<Map>()
        .map((e) => Map<dynamic, dynamic>.from(e))
        .where((e) => e['isDream'] == true)
        .map((e) => DreamEntry.fromMap(e))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> _saveDream() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('dream.needText')),
        ),
      );
      return;
    }

    final editing = _editing;
    final dream = DreamEntry(
      id: editing?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      content: _controller.text.trim(),
      createdAt: editing?.createdAt ?? DateTime.now(),
      isLucid: _isLucid,
      isNightmare: _isNightmare,
      clarity: _clarity,
    );

    await _box.put(dream.id, dream.toMap());
    DatabaseService.invalidate();
    if (!mounted) return;
    _resetForm();
  }

  void _resetForm() {
    _controller.clear();
    _titleController.clear();
    setState(() {
      _editing = null;
      _isLucid = false;
      _isNightmare = false;
      _clarity = 3;
    });
  }

  void _edit(DreamEntry dream) {
    _titleController.text = dream.title;
    _controller.text = dream.content;
    setState(() {
      _editing = dream;
      _isLucid = dream.isLucid;
      _isNightmare = dream.isNightmare;
      _clarity = dream.clarity;
    });
  }

  Future<void> _delete(DreamEntry dream) async {
    final l10n = AppLocalizations.of(context);
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: Text(l10n.t('dream.deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.t('dialog.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.t('dialog.delete.action')),
          ),
        ],
      ),
    );
    if (sure != true) return;
    await _box.delete(dream.id);
    DatabaseService.invalidate();
    if (!mounted) return;
    if (_editing?.id == dream.id) {
      _resetForm();
    } else {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dreams = _dreams;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).t('dream.title')),
        backgroundColor: const Color(0xFF1A1F3A),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1F3A), Color(0xFF2A1F3A), Color(0xFF0A0D14)],
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
                  itemBuilder: (_, i) => _DreamCard(
                    dream: dreams[i],
                    onEdit: () => _edit(dreams[i]),
                    onDelete: () => _delete(dreams[i]),
                  ),
                ),
              )
            else
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🌙', style: TextStyle(fontSize: 80)),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).t('dream.empty'),
                        style: const TextStyle(
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
                // Above the keyboard when it is up, above the system
                // navigation bar otherwise.
                bottom:
                    math.max(
                      MediaQuery.viewInsetsOf(context).bottom,
                      MediaQuery.viewPaddingOf(context).bottom,
                    ) +
                    16,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).t(
                            _editing == null ? 'dream.record' : 'dream.editing',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (_editing != null)
                        IconButton(
                          tooltip: AppLocalizations.of(
                            context,
                          ).t('dialog.cancel'),
                          onPressed: _resetForm,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(
                        context,
                      ).t('dream.titleHint'),
                      labelStyle: const TextStyle(color: Colors.white54),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      hintText: AppLocalizations.of(
                        context,
                      ).t('dream.titleHint'),
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
                      labelText: AppLocalizations.of(context).t('dream.hint'),
                      labelStyle: const TextStyle(color: Colors.white54),
                      floatingLabelBehavior: FloatingLabelBehavior.never,
                      hintText: AppLocalizations.of(context).t('dream.hint'),
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
                        label: Text(
                          AppLocalizations.of(context).t('dream.lucid'),
                        ),
                        selected: _isLucid,
                        onSelected: (v) => setState(() => _isLucid = v),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(
                          AppLocalizations.of(context).t('dream.nightmare'),
                        ),
                        selected: _isNightmare,
                        onSelected: (v) => setState(() => _isNightmare = v),
                      ),
                      const Spacer(),
                      Text(
                        AppLocalizations.of(context).t('dream.clarity'),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...List.generate(5, (i) {
                        return Semantics(
                          button: true,
                          selected: i < _clarity,
                          label:
                              '${AppLocalizations.of(context).t('dream.clarity')} ${i + 1}/5',
                          child: GestureDetector(
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
                      label: Text(AppLocalizations.of(context).t('dream.save')),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _DreamCard({
    required this.dream,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onEdit,
          onLongPress: onDelete,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 4, 14),
            child: _content(context, l10n),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              dream.isNightmare
                  ? '😱'
                  : dream.isLucid
                  ? '✨'
                  : '🌙',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                dream.title.isEmpty
                    ? AppLocalizations.of(context).t('dream.untitled')
                    : dream.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${dream.createdAt.day}/${dream.createdAt.month}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            IconButton(
              tooltip: l10n.t('dream.delete'),
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white54,
                size: 20,
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
