import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../services/database_service.dart';
import '../../services/habit_service.dart';
import '../../widgets/nabd_ui.dart';

/// Small daily habits that tend to lift the mood, ticked once a day, with a
/// gentle look at how each one goes together with the journal's mood.
class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key, this.service});

  final HabitService? service;

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  late final HabitService _habits = widget.service ?? HabitService();
  final _entries = DatabaseService().getAllEntries();

  String _name(Habit habit, AppLocalizations l10n) =>
      habit.presetId == null ? habit.name : l10n.t(habit.nameKey());

  Future<void> _toggle(Habit habit, DateTime day) async {
    await _habits.toggle(habit.id, day);
    if (mounted) setState(() {});
  }

  Future<void> _add(AppLocalizations l10n) async {
    final taken = {for (final h in _habits.active()) h.presetId};
    final controller = TextEditingController();
    final habit = await showModalBottomSheet<Habit>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.t('habits.suggestions'),
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (id, emoji) in Habit.presets)
                        if (!taken.contains(id))
                          ActionChip(
                            avatar: Text(emoji),
                            label: Text(l10n.t('habit.preset.$id')),
                            onPressed: () => Navigator.of(sheetContext)
                                .pop(Habit(presetId: id, emoji: emoji)),
                          ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.t('habits.custom'),
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.sentences,
                    decoration:
                        InputDecoration(hintText: l10n.t('habits.customHint')),
                    onSubmitted: (value) {
                      if (value.trim().isEmpty) return;
                      Navigator.of(sheetContext)
                          .pop(Habit(name: value.trim(), emoji: '✨'));
                    },
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton(
                      onPressed: () {
                        final value = controller.text.trim();
                        if (value.isEmpty) return;
                        Navigator.of(sheetContext)
                            .pop(Habit(name: value, emoji: '✨'));
                      },
                      child: Text(l10n.t('habits.create')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    controller.dispose();
    if (habit == null) return;
    await _habits.add(habit);
    if (mounted) setState(() {});
  }

  Future<void> _manage(Habit habit, AppLocalizations l10n) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bedtime_outlined),
              title: Text(l10n.t('habits.archive')),
              onTap: () => Navigator.of(sheetContext).pop('archive'),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(sheetContext).colorScheme.error),
              title: Text(l10n.t('habits.delete')),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'archive') {
      await _habits.archive(habit.id);
    } else if (action == 'delete') {
      final sure = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          content: Text(l10n.t('habits.deleteConfirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.t('dialog.cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.t('habits.delete')),
            ),
          ],
        ),
      );
      if (sure == true) await _habits.delete(habit.id);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final habits = _habits.active();
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('habits.title'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(l10n),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.t('habits.add')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          Text(
            l10n.t('habits.intro'),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          if (habits.isEmpty)
            EmptyState(
              emoji: '🌱',
              title: l10n.t('habits.empty'),
              actionLabel: l10n.t('habits.add'),
              onAction: () => _add(l10n),
            ),
          for (final habit in habits) ...[
            _HabitCard(
              name: _name(habit, l10n),
              emoji: habit.emoji,
              doneDays: _habits.doneDays(habit.id),
              today: today,
              link: HabitService.moodLink(_habits.doneDays(habit.id), _entries),
              onToggle: (day) => _toggle(habit, day),
              onManage: () => _manage(habit, l10n),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({
    required this.name,
    required this.emoji,
    required this.doneDays,
    required this.today,
    required this.link,
    required this.onToggle,
    required this.onManage,
  });

  final String name;
  final String emoji;
  final Set<String> doneDays;
  final DateTime today;
  final HabitMoodLink? link;
  final void Function(DateTime day) onToggle;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final code = l10n.locale.languageCode;
    final doneToday = doneDays.contains(HabitService.dayKey(today));
    final streak = HabitService.streak(doneDays, today);
    final week = [
      for (var i = 6; i >= 0; i--)
        DateTime(today.year, today.month, today.day - i),
    ];

    final insight = switch (link) {
      null => l10n.t('habits.moodLearning'),
      final l when l.difference >= 0.5 => l10n.t('habits.moodLift').replaceAll(
          '{n}', NumberFormat('0.0', code).format(l.difference)),
      _ => l10n.t('habits.moodSame'),
    };

    return NabdCard(
      onTap: () => onToggle(today),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: theme.textTheme.titleSmall),
                    if (streak > 0)
                      Text(
                        l10n.t('habits.streak').replaceAll('{n}', '$streak'),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: AppColors.pulse),
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: doneToday
                    ? l10n.t('habits.doneToday')
                    : l10n.t('habits.notYet'),
                onPressed: () => onToggle(today),
                icon: Icon(
                  doneToday
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 32,
                  color: doneToday ? AppColors.success : scheme.outline,
                ),
              ),
              IconButton(
                tooltip: l10n.t('habits.archive'),
                onPressed: onManage,
                icon: const Icon(Icons.more_vert_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final day in week)
                Expanded(
                  child: InkResponse(
                    onTap: () => onToggle(day),
                    child: Column(
                      children: [
                        Text(
                          DateFormat.E(code).format(day),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: doneDays.contains(HabitService.dayKey(day))
                                ? AppColors.success
                                : scheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(insight,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
