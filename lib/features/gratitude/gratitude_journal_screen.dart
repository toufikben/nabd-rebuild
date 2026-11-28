import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/gratitude.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/storage.dart';

/// Three gratitude lines a day, and the days already written.
///
/// The lines are the same ones the garden shows as flowers: one store, two
/// views. Writing here plants a flower there, and the achievement counts both.
class GratitudeJournalScreen extends StatefulWidget {
  const GratitudeJournalScreen({super.key});

  @override
  State<GratitudeJournalScreen> createState() => _GratitudeJournalScreenState();
}

class _GratitudeJournalScreenState extends State<GratitudeJournalScreen> {
  final Box _box = contentBox();
  final List<TextEditingController> _controllers = List.generate(
    gratitudePromptSlots,
    (_) => TextEditingController(),
  );

  /// Every line ever written, newest day first.
  List<GratitudeEntry> get _entries => gratitudeEntries(_box);

  /// Everything the three prompts above do not already show: earlier days,
  /// plus any line the garden planted today past the third prompt.
  List<GratitudeEntry> get _earlierEntries {
    final today = DateTime.now();
    final midnight = DateTime(today.year, today.month, today.day);
    return _entries
        .where((e) => e.date != midnight || e.slot >= _controllers.length)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  void _loadToday() {
    final saved = gratitudeSlotsFor(_box, DateTime.now());
    for (var i = 0; i < saved.length && i < _controllers.length; i++) {
      _controllers[i].text = saved[i].trim();
    }
  }

  Future<void> _save() async {
    final values =
        _controllers.map((controller) => controller.text.trim()).toList();
    if (values.every((value) => value.isEmpty)) {
      // Nothing written: no blank day saved, and no "saved" either.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(AppLocalizations.of(context).t('gratitudeJournal.needOne')),
      ));
      return;
    }
    final now = DateTime.now();
    await saveGratitudeSlots(_box, now, values);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).t('gratitudeJournal.saved')),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _delete(GratitudeEntry entry) async {
    await removeGratitude(_box, entry);
    if (!mounted) return;
    // A line deleted from today's list must also leave its field, otherwise the
    // next save writes it straight back.
    _syncTodayFields();
    setState(() {});
  }

  void _syncTodayFields() {
    final saved = gratitudeSlotsFor(_box, DateTime.now());
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].text = i < saved.length ? saved[i].trim() : '';
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _earlierEntries;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.t('hub.feature.gratitudeJournal.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.t('gratitudeJournal.saveTooltip'),
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF48FB1), Color(0xFFEC407A)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text('🙏', style: TextStyle(fontSize: 50)),
                const SizedBox(height: 12),
                Text(
                  l10n.t('gratitudeJournal.threeThings'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(gratitudePromptSlots, (index) => _input(index)),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(l10n.t('gratitudeJournal.save')),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.t('gratitudeJournal.previous'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Center(
                child: Text(
                  l10n.t('gratitudeJournal.empty'),
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...items.map((item) => _itemCard(item)),
        ],
      ),
    );
  }

  Widget _input(int index) {
    final l10n = AppLocalizations.of(context);
    final hints = [
      l10n.t('gratitudeJournal.hintPerson'),
      l10n.t('gratitudeJournal.hintMoment'),
      l10n.t('gratitudeJournal.hintSmall'),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controllers[index],
              maxLines: 3,
              decoration: InputDecoration(
                // A label stays announced once the field has text; a hint
                // alone goes silent.
                labelText: hints[index],
                floatingLabelBehavior: FloatingLabelBehavior.never,
                hintText: hints[index],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(GratitudeEntry item) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Text('🌻', style: TextStyle(fontSize: 22)),
        title: Text(item.text),
        subtitle: Text(MaterialLocalizations.of(context).formatMediumDate(item.date)),
        trailing: IconButton(
          onPressed: () => _delete(item),
          tooltip: l10n.t('gratitudeJournal.deleteTooltip'),
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}
