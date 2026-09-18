import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/journal_entry.dart';
import '../../models/mood.dart';
import '../../services/database_service.dart';
import '../../widgets/entry_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final DatabaseService _db = DatabaseService();
  final TextEditingController _controller = TextEditingController();

  String _query = '';
  String? _selectedMood;
  List<String> _selectedTags = [];
  bool _favoritesOnly = false;
  String _sortBy = 'newest';

  @override
  Widget build(BuildContext context) {
    final results = _performSearch();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search entries...',
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
                              label: 'All',
                              selected: _selectedMood == null,
                              onTap: () => setState(() => _selectedMood = null),
                            ),
                            ...Mood.all.map((m) => _filterChip(
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
                            label: Text('#${tag.name}'),
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
                const SizedBox(height: 8),
                // Sort + Favorites
                Row(
                  children: [
                    ChoiceChip(
                      label: const Icon(Icons.favorite, size: 16),
                      selected: _favoritesOnly,
                      onSelected: (v) => setState(() => _favoritesOnly = v),
                    ),
                    const SizedBox(width: 8),
                    const Spacer(),
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                            value: 'newest', child: Text('Newest')),
                        DropdownMenuItem(
                            value: 'oldest', child: Text('Oldest')),
                        DropdownMenuItem(
                            value: 'longest', child: Text('Longest')),
                        DropdownMenuItem(value: 'mood', child: Text('By Mood')),
                      ],
                      onChanged: (v) => setState(() => _sortBy = v ?? 'newest'),
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
                  '${results.length} ${results.length == 1 ? 'result' : 'results'}',
                  style: const TextStyle(
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
                        const Text('No results'),
                        const SizedBox(height: 8),
                        const Text(
                          'Try different keywords',
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
                      onTap: () => context.push(
                        '/editor',
                        extra: results[i].id,
                      ),
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
          .where((e) => _selectedTags.any((t) => e.tags.contains(t)))
          .toList();
    }

    // Favorites
    if (_favoritesOnly) {
      results = results.where((e) => e.isFavorite).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'oldest':
        results.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'longest':
        results.sort((a, b) => b.content.length.compareTo(a.content.length));
        break;
      case 'mood':
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
