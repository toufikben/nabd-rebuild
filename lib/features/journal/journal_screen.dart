import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/data_revision.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/journal_entry.dart';
import '../../models/mood.dart';
import '../../services/database_service.dart';
import '../../widgets/entry_card.dart';
import '../../widgets/nabd_ui.dart';

/// The journal tab: every entry, newest first and grouped by month, with
/// search, a mood filter and the other writing spaces one tap away.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _search = TextEditingController();
  String _query = '';
  String? _mood;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(String route) async {
    await context.push(route);
    if (mounted) setState(() {});
  }

  List<JournalEntry> _filtered(List<JournalEntry> entries) {
    final query = _query.trim().toLowerCase();
    final result = entries.where((entry) {
      if (_mood != null && entry.mood != _mood) return false;
      if (query.isEmpty) return true;
      return entry.title.toLowerCase().contains(query) ||
          entry.content.toLowerCase().contains(query) ||
          entry.tags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
    // Pinned entries lead; the rest stay newest first.
    result.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = l10n.locale.languageCode;
    ref.watch(dataRevisionProvider);
    final all = _db.getAllEntries();
    final entries = _filtered(all);

    // Group by month, keeping pinned entries in their own group at the top.
    final groups = <String, List<JournalEntry>>{};
    for (final entry in entries) {
      final key = entry.isPinned
          ? l10n.t('journal.pinned')
          : DateFormat.yMMMM(locale).format(entry.createdAt);
      groups.putIfAbsent(key, () => []).add(entry);
    }

    final spaces = <(IconData, String, String, Color)>[
      (Icons.nightlight_round, 'hub.feature.dream.title', '/dream-journal',
          AppColors.masculinePrimary),
      (Icons.mark_email_unread_outlined, 'hub.feature.letters.title',
          '/letters', AppColors.pulse),
      (Icons.favorite_rounded, 'hub.feature.gratitudeJournal.title',
          '/gratitude-journal', AppColors.femininePrimary),
      (Icons.inventory_2_outlined, 'hub.feature.worryBox.title', '/worry-box',
          AppColors.primary),
      (Icons.auto_stories_rounded, 'hub.feature.legacy.title',
          '/legacy-journal', AppColors.secondary),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('nav.journal')),
        actions: [
          IconButton(
            tooltip: l10n.t('hub.feature.calendar.title'),
            onPressed: () => _open('/calendar'),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: l10n.t('hub.feature.tags.title'),
            onPressed: () => _open('/tags'),
            icon: const Icon(Icons.sell_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open('/editor'),
        icon: const Icon(Icons.edit_rounded),
        label: Text(l10n.t('journal.new')),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.t('home.searchHint'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ChoiceChip(
                    label: Text(l10n.t('home.filter.all')),
                    selected: _mood == null,
                    onSelected: (_) => setState(() => _mood = null),
                  ),
                  for (final mood in Mood.journalMoods)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 8),
                      child: ChoiceChip(
                        label: Text('${mood.emoji} ${mood.label(locale)}'),
                        selected: _mood == mood.id,
                        onSelected: (_) => setState(
                            () => _mood = _mood == mood.id ? null : mood.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: SectionHeader(l10n.t('journal.spaces'))),
          SliverToBoxAdapter(
            child: SizedBox(
              // Icon and padding, plus two lines that grow with the font size.
              height: 24 + 24 + 6 + MediaQuery.textScalerOf(context).scale(36),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: spaces.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final (icon, title, route, color) = spaces[i];
                  return SizedBox(
                    width: 118,
                    child: NabdCard(
                      onTap: () => _open(route),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: color),
                          const Spacer(),
                          Text(
                            l10n.t(title),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (entries.isEmpty)
            SliverToBoxAdapter(
              child: all.isEmpty
                  ? EmptyState(
                      emoji: '✍️',
                      title: l10n.t('journal.empty.title'),
                      body: l10n.t('journal.empty.body'),
                      actionLabel: l10n.t('journal.new'),
                      onAction: () => _open('/editor'),
                    )
                  : EmptyState(
                      emoji: '🔍',
                      title: l10n.t('journal.noResults'),
                      body: l10n.t('home.empty.hintFilter'),
                    ),
            )
          else
            for (final group in groups.entries) ...[
              SliverToBoxAdapter(child: SectionHeader(group.key)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList.list(children: [
                  for (final entry in group.value)
                    EntryCard(
                      entry: entry,
                      onTap: () => _open('/editor?id=${entry.id}'),
                    ),
                ]),
              ),
            ],
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}
