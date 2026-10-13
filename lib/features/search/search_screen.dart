import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/data_revision.dart';
import '../../models/journal_entry.dart';
import '../../models/mood.dart';
import '../../models/tag.dart';
import '../../services/database_service.dart';
import '../../widgets/entry_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialTag});

  /// Opens with this tag already selected, from the Tags screen.
  final String? initialTag;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {

  // Sort keys are stable identifiers; only their labels are localized.
  static const String _sortNewest = 'newest';
  static const String _sortOldest = 'oldest';
  static const String _sortLongest = 'longest';
  static const String _sortMood = 'mood';
  late AppLocalizations l10n;
  final DatabaseService _db = DatabaseService();
  final TextEditingController _controller = TextEditingController();

  String _query = '';
  String? _selectedMood;
  late List<String> _selectedTags = [
    if (widget.initialTag case final tag?) tag,
  ];
  bool _favoritesOnly = false;
  String _sortBy = _sortNewest;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    l10n = AppLocalizations.of(context);
    ref.watch(dataRevisionProvider);
    final results = _performSearch();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: l10n.t('search.hint'),
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_query.isNotEmpty ||
              _selectedMood != null ||
              _selectedTags.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // ─── Filters ───
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                // Mood + Favorites row
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip(
                              label: l10n.t('common.all'),
                              selected: _selectedMood == null,
                              onTap: () => setState(() => _selectedMood = null),
                            ),
                            ...Mood.journalMoods.map((m) => _filterChip(
                                  label: m.emoji,
                                  selected: _selectedMood == m.id,
                                  onTap: () =>
                                      setState(() => _selectedMood = m.id),
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_db.getAllTags().isNotEmpty)
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _db.getAllTags().map((tag) {
                        final selected = _selectedTags.contains(tag.name);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(
                                '#${localizedTagName(l10n, tag.name)}'),
                            selected: selected,
                            onSelected: (value) => setState(() {
                              if (value) {
                                _selectedTags = [..._selectedTags, tag.name];
                              } else {
                                _selectedTags = _selectedTags
                                    .where((item) => item != tag.name)
                                    .toList();
                              }
                            }),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                SizedBox(height: 8),
                // Sort + Favorites
                Row(
                  children: [
                    ChoiceChip(
                      label: const Icon(Icons.favorite, size: 16),
                      selected: _favoritesOnly,
                      onSelected: (v) => setState(() => _favoritesOnly = v),
                    ),
                    SizedBox(width: 8),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      items: [
                        DropdownMenuItem(
                          value: _sortNewest,
                          child: Text(l10n.t('search.sort.newest')),
                        ),
                        DropdownMenuItem(
                          value: _sortOldest,
                          child: Text(l10n.t('search.sort.oldest')),
                        ),
                        DropdownMenuItem(
                          value: _sortLongest,
                          child: Text(l10n.t('search.sort.longest')),
                        ),
                        DropdownMenuItem(
                          value: _sortMood,
                          child: Text(l10n.t('search.sort.mood')),
                        ),
                      ],
                      onChanged: (v) => setState(() => _sortBy = v ?? _sortNewest),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── Results count ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${results.length} ${results.length == 1 ? l10n.t('search.result.one') : l10n.t('search.result.many')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // ─── Results ───
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: AppColors.textTertiary.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(l10n.t('search.empty.title')),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context).t('search.empty.hint'),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: results.length,
                    itemBuilder: (_, i) => EntryCard(
                      entry: results[i],
                      onTap: () async {
                        await context.push(
                          '/editor',
                          extra: results[i].id,
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  void _clearFilters() {
    _controller.clear();
    setState(() {
      _query = '';
      _selectedMood = null;
      _selectedTags = [];
      _favoritesOnly = false;
    });
  }

  List<JournalEntry> _performSearch() {
    var results = _db.getAllEntries();

    // Query
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      results = results
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.content.toLowerCase().contains(q) ||
              e.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }

    // Mood
    if (_selectedMood != null) {
      results = results.where((e) => e.mood == _selectedMood).toList();
    }

    // Tags
    if (_selectedTags.isNotEmpty) {
      results = results
          .where((e) => _selectedTags.any((t) =>
              e.tags.any((tag) => Tag.keyOf(tag) == Tag.keyOf(t))))
          .toList();
    }

    // Favorites
    if (_favoritesOnly) {
      results = results.where((e) => e.isFavorite).toList();
    }

    // Sort
    switch (_sortBy) {
      case _sortOldest:
        results.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _sortLongest:
        results.sort((a, b) => b.content.length.compareTo(a.content.length));
        break;
      case _sortMood:
        results.sort((a, b) {
          final ma = Mood.getById(a.mood)?.value ?? 5;
          final mb = Mood.getById(b.mood)?.value ?? 5;
          return mb.compareTo(ma);
        });
        break;
      default:
        results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return results;
  }
}
