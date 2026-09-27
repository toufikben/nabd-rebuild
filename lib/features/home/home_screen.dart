// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/data_revision.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../models/journal_entry.dart';
import '../../models/mood.dart';
import '../../services/database_service.dart';
import '../../widgets/entry_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final DatabaseService _db = DatabaseService();
  String _searchQuery = '';
  String? _selectedMood;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Refetch when a restore replaces the underlying boxes.
    ref.watch(dataRevisionProvider);
    final entries = _db.getAllEntries();
    final filtered = _filterEntries(entries);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('home.title')),
        actions: [
          PopupMenuButton<String>(
            tooltip: l10n.t('home.exploreTooltip'),
            onSelected: (route) => context.push(route),
            itemBuilder: (_) => [
              PopupMenuItem(value: '/search', child: Text(l10n.t('menu.search'))),
              PopupMenuItem(value: '/stats', child: Text(l10n.t('menu.stats'))),
              PopupMenuItem(value: '/heatmap', child: Text(l10n.t('menu.heatmap'))),
              PopupMenuItem(value: '/weather', child: Text(l10n.t('menu.weather'))),
              PopupMenuItem(value: '/word-cloud', child: Text(l10n.t('menu.wordCloud'))),
              PopupMenuItem(
                  value: '/emotion-radar', child: Text(l10n.t('menu.emotionRadar'))),
              PopupMenuItem(value: '/year-review', child: Text(l10n.t('menu.yearReview'))),
              PopupMenuItem(value: '/garden', child: Text(l10n.t('menu.garden'))),
              PopupMenuItem(value: '/worry-box', child: Text(l10n.t('menu.worryBox'))),
              PopupMenuItem(
                  value: '/worry-release', child: Text(l10n.t('menu.worryRelease'))),
              PopupMenuItem(value: '/breathing', child: Text(l10n.t('menu.breathing'))),
              PopupMenuItem(
                  value: '/gratitude-garden', child: Text(l10n.t('menu.gratitudeGarden'))),
              PopupMenuItem(
                  value: '/gratitude-journal',
                  child: Text(l10n.t('menu.gratitudeJournal'))),
              PopupMenuItem(
                  value: '/future-letters', child: Text(l10n.t('menu.futureLetters'))),
              PopupMenuItem(
                  value: '/unsent-letters', child: Text(l10n.t('menu.unsentLetters'))),
              PopupMenuItem(
                  value: '/legacy-journal', child: Text(l10n.t('menu.legacyJournal'))),
              PopupMenuItem(
                  value: '/time-capsule', child: Text(l10n.t('menu.timeCapsule'))),
              PopupMenuItem(
                  value: '/achievements', child: Text(l10n.t('menu.achievements'))),
              PopupMenuItem(value: '/challenges', child: Text(l10n.t('menu.challenges'))),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () async {
              await context.push('/calendar');
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await context.push('/settings');
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.t('home.searchHint'),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Mood Filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 11, // All + 10 moods
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.t('home.filter.all')),
                      selected: _selectedMood == null,
                      onSelected: (_) => setState(() => _selectedMood = null),
                    ),
                  );
                }
                final mood = Mood.journalMoods[i - 1];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(mood.emoji),
                    selected: _selectedMood == mood.id,
                    onSelected: (_) => setState(() => _selectedMood = mood.id),
                  ),
                );
              },
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _statCard(Icons.book, '${_db.getEntryCount()}', l10n.t('home.stat.entries')),
                const SizedBox(width: 12),
                _statCard(Icons.text_fields, '${_db.getWordCount()}', l10n.t('home.stat.words')),
                const SizedBox(width: 12),
                _statCard(Icons.local_fire_department, '${_calculateStreak()}',
                    l10n.t('home.stat.streak')),
              ],
            ),
          ),

          // Entries List
          Expanded(
            child: filtered.isEmpty
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _sessionsCard(context, l10n),
                      const SizedBox(height: 10),
                      _silentCompanionCard(context, l10n),
                      SizedBox(height: 24),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.book_outlined,
                              size: 80,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              entries.isEmpty ? l10n.t('home.empty.noEntries') : l10n.t('home.empty.noMatches'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(height: 8),
                            Text(
                              entries.isEmpty
                                  ? l10n.t('home.empty.hintNew')
                                  : l10n.t('home.empty.hintFilter'),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length + 2,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      if (i == 0) return _sessionsCard(context, l10n);
                      if (i == 1) return _silentCompanionCard(context, l10n);
                      final entry = filtered[i - 2];
                      return EntryCard(
                        entry: entry,
                        onTap: () async {
                          await context.push('/editor', extra: entry.id);
                          if (mounted) setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/editor');
          if (mounted) setState(() {});
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.t('home.action.newEntry')),
      ),
    );
  }

  Widget _sessionsCard(BuildContext context, AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: colors.primaryContainer,
      child: InkWell(
        onTap: () => context.push('/sessions'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.self_improvement, color: colors.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('home.sessions.title'),
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.t('home.sessions.subtitle'),
                      style: TextStyle(
                        color: colors.onPrimaryContainer.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 16, color: colors.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _silentCompanionCard(BuildContext context, AppLocalizations l10n) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: colors.secondaryContainer,
      child: InkWell(
        onTap: () => context.push('/silent'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.water_drop_outlined,
                color: colors.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.t('home.silent.title'),
                      style: TextStyle(
                        color: colors.onSecondaryContainer,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.t('home.silent.subtitle'),
                      style: TextStyle(
                        color:
                            colors.onSecondaryContainer.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colors.onSecondaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<JournalEntry> _filterEntries(List<JournalEntry> entries) {
    var result = entries;
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((e) =>
              e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              e.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              e.tags.any((tag) =>
                  tag.toLowerCase().contains(_searchQuery.toLowerCase())))
          .toList();
    }
    if (_selectedMood != null) {
      result = result.where((e) => e.mood == _selectedMood).toList();
    }
    return [...result]..sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  int _calculateStreak() {
    final entries = _db.getAllEntries();
    if (entries.isEmpty) return 0;

    final dates = entries
        .map((e) =>
            DateTime(e.createdAt.year, e.createdAt.month, e.createdAt.day))
        .toSet();
    var streak = 0;
    var date = DateTime.now();
    while (dates.contains(DateTime(date.year, date.month, date.day))) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(value,
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
