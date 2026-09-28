import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/tag.dart';
import '../../services/database_service.dart';

class TagsScreen extends ConsumerStatefulWidget {
  const TagsScreen({super.key});

  @override
  ConsumerState<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends ConsumerState<TagsScreen> {
  late AppLocalizations l10n;
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    final tags = _db.getAllTags();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('tags.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(),
          ),
        ],
      ),
      body: tags.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.label_outline,
                    size: 80,
                    color: AppColors.textTertiary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.t('tags.empty')),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _showAddDialog(),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.t('tags.create')),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tags.length,
              itemBuilder: (_, i) {
                final tag = tags[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(tag.color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.label,
                        color: Color(tag.color),
                        size: 18,
                      ),
                    ),
                    title: Text('#${tag.name}'),
                    subtitle: Text('${tag.usageCount} entries'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: AppColors.danger,
                      onPressed: () => _deleteTag(tag),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('tags.newTitle')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.t('tags.name')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.t('dialog.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.t('tags.action.create')),
          ),
        ],
      ),
    );
    controller.dispose();

    if (mounted && result != null && result.isNotEmpty) {
      await _db.saveTag(Tag(
        id: result.toLowerCase().replaceAll(' ', '_'),
        name: result,
        color: 0xFF6C5CE7,
      ));
      if (mounted) setState(() {});
    }
  }

  Future<void> _deleteTag(Tag tag) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('#${tag.name}'),
        content: Text(l10n.t('tags.delete.body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('dialog.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: Text(l10n.t('tags.delete.action')),
          ),
        ],
      ),
    );

    if (mounted && ok == true) {
      await _db.deleteTag(tag.name, tag.id);
      if (mounted) setState(() {});
    }
  }
}
