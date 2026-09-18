import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../services/database_service.dart';

/// LegacyJournalScreen — إرث رقمي للأحفاد.
///
/// الفكرة: اختر مذكرات معينة لتشكيل "الإرث" الذي سيُحفظ للأبد.
class LegacyJournalScreen extends StatefulWidget {
  const LegacyJournalScreen({super.key});

  @override
  State<LegacyJournalScreen> createState() => _LegacyJournalScreenState();
}

class _LegacyJournalScreenState extends State<LegacyJournalScreen> {
  final DatabaseService _db = DatabaseService();
  final Box _settings = Hive.box('settings');

  Set<String> get _legacyIds {
    final raw = _settings.get('legacy_entries', defaultValue: <dynamic>[]) as List;
    return raw.map((e) => e.toString()).toSet();
  }

  Future<void> _toggleEntry(String id) async {
    final ids = _legacyIds;
    if (ids.contains(id)) {
      ids.remove(id);
    } else {
      ids.add(id);
    }
    await _settings.put('legacy_entries', ids.toList());
    setState(() {});
  }

  Future<void> _exportLegacy() async {
    final ids = _legacyIds;
    if (ids.isEmpty) return;

    final entries = _db.getAllEntries().where((e) => ids.contains(e.id));
    final buffer = StringBuffer();
    buffer.writeln('LEGACY JOURNAL');
    buffer.writeln('==============');
    buffer.writeln();

    for (final entry in entries) {
      buffer.writeln('---');
      buffer.writeln('Date: ${entry.createdAt.toIso8601String()}');
      if (entry.title.isNotEmpty) buffer.writeln('Title: ${entry.title}');
      buffer.writeln();
      buffer.writeln(entry.content);
      buffer.writeln();
    }

    await Share.share(
      buffer.toString(),
      subject: 'My Legacy Journal',
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _db.getAllEntries();
    final legacyCount = _legacyIds.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Legacy Journal'),
        actions: [
          if (legacyCount > 0)
            IconButton(
              icon: const Icon(Icons.ios_share),
              onPressed: _exportLegacy,
              tooltip: 'Export legacy',
            ),
        ],
      ),
      body: Column(
        children: [
          // Info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFF8B6914)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.auto_stories,
                  color: Colors.white,
                  size: 36,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Legacy Journal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$legacyCount entries selected',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select entries that matter most.\n'
                  'These will be your legacy.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Entries list
          Expanded(
            child: entries.isEmpty
                ? const Center(
                    child: Text('No entries yet'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final entry = entries[i];
                      final isLegacy = _legacyIds.contains(entry.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isLegacy
                                ? const Color(0xFFD4AF37)
                                : Colors.transparent,
                            width: isLegacy ? 2 : 0,
                          ),
                        ),
                        child: ListTile(
                          onTap: () => _toggleEntry(entry.id),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isLegacy
                                  ? const Color(0xFFD4AF37)
                                      .withValues(alpha: 0.2)
                                  : AppColors.textTertiary
                                      .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isLegacy
                                  ? Icons.star
                                  : Icons.star_border,
                              color: isLegacy
                                  ? const Color(0xFFD4AF37)
                                  : AppColors.textTertiary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            entry.title.isEmpty
                                ? 'Untitled'
                                : entry.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            entry.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
