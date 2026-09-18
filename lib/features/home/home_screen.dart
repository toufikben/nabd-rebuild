// lib/features/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/journal_entry.dart';
import '../../models/mood.dart';
import '../../services/database_service.dart';
import '../../widgets/entry_card.dart';
import '../../widgets/soundscape_bar.dart';
import '../navigation/app_bottom_navigation.dart';

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
    final entries = _db.getAllEntries();
    final filtered = _filterEntries(entries);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Journal'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Explore features',
            onSelected: (route) => context.push(route),
            itemBuilder: (_) => const [
              PopupMenuItem(value: '/search', child: Text('Search')),
              PopupMenuItem(value: '/tags', child: Text('Tags')),
              PopupMenuItem(value: '/stats', child: Text('Statistics')),
              PopupMenuItem(value: '/heatmap', child: Text('Heatmap')),
              PopupMenuItem(value: '/weather', child: Text('Mood weather')),
              PopupMenuItem(value: '/word-cloud', child: Text('Word cloud')),
              PopupMenuItem(
                  value: '/emotion-radar', child: Text('Emotion radar')),
              PopupMenuItem(value: '/year-review', child: Text('Year review')),
              PopupMenuItem(value: '/garden', child: Text('Garden')),
              PopupMenuItem(value: '/worry-box', child: Text('Worry box')),
              PopupMenuItem(
                  value: '/worry-release', child: Text('Worry release')),
              PopupMenuItem(value: '/breathing', child: Text('Breathing')),
              PopupMenuItem(
                  value: '/dream-journal', child: Text('Dream journal')),
              PopupMenuItem(
                  value: '/gratitude-garden', child: Text('Gratitude garden')),
              PopupMenuItem(
                  value: '/gratitude-journal',
                  child: Text('Gratitude journal')),
              PopupMenuItem(
                  value: '/future-letters', child: Text('Future letters')),
              PopupMenuItem(
                  value: '/unsent-letters', child: Text('Unsent letters')),
              PopupMenuItem(
                  value: '/legacy-journal', child: Text('Legacy journal')),
              PopupMenuItem(
                  value: '/time-capsule', child: Text('Time capsule')),
              PopupMenuItem(
                  value: '/achievements', child: Text('Achievements')),
              PopupMenuItem(value: '/challenges', child: Text('Challenges')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => context.push('/calendar'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
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
                hintText: 'Search entries...',
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
                      label: const Text('All'),
                      selected: _selectedMood == null,
                      onSelected: (_) => setState(() => _selectedMood = null),
                    ),
                  );
                }
                final mood = Mood.all[i - 1];
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

          // Optional ambient sound control for the main journal view.
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SoundscapeBar(),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _statCard(Icons.book, '${_db.getEntryCount()}', 'Entries'),
                const SizedBox(width: 12),
                _statCard(Icons.text_fields, '${_db.getWordCount()}', 'Words'),
                const SizedBox(width: 12),
                _statCard(Icons.local_fire_department, '${_calculateStreak()}',
                    'Streak'),
              ],
            ),
          ),

          // Entries List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.book_outlined,
                            size: 80,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No entries yet',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Tap + to write your first entry',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => EntryCard(
                      entry: filtered[i],
                      onTap: () =>
                          context.push('/editor', extra: filtered[i].id),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/editor'),
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
      bottomNavigationBar: const AppBottomNavigation(currentIndex: 0),
    );
  }

  List<JournalEntry> _filterEntries(List<JournalEntry> entries) {
    var result = entries;
    if (_searchQuery.isNotEmpty) {
      result = result
          .where((e) =>
              e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              e.content.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    if (_selectedMood != null) {
      result = result.where((e) => e.mood == _selectedMood).toList();
    }
    return result;
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
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
