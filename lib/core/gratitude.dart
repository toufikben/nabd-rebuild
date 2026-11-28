import 'package:hive/hive.dart';

import 'storage.dart';

/// A single gratitude line, whichever screen wrote it.
///
/// Gratitude used to have two stores: the journal wrote one list per day under
/// `gratitude_<y>_<m>_<d>`, and the garden wrote every flower into one list
/// under `gratitude_items`. A line written in one screen was invisible in the
/// other, never reached the achievements count, and had no date history. There
/// is one store now — the dated one — and the garden is a view of it.
class GratitudeEntry {
  const GratitudeEntry({
    required this.date,
    required this.text,
    required this.slot,
  });

  /// The day the line belongs to, at local midnight.
  final DateTime date;
  final String text;

  /// Position inside that day. Kept so deleting one line removes the right
  /// one when the same words were written twice, and so a flower does not
  /// change shape when an earlier line is removed.
  final int slot;

  String get dayKey => gratitudeDayKey(date);
}

/// The content-box key holding one day's gratitude lines.
String gratitudeDayKey(DateTime day) =>
    '${ContentKeys.gratitudeDayPrefix}${day.year}_${day.month}_${day.day}';

/// The day a `gratitude_<y>_<m>_<d>` key stands for, or null for anything else
/// that shares the prefix.
///
/// The parts are checked against the date they build, because
/// `DateTime.parse` happily rolls an impossible day like `2026-9-31` into the
/// next month.
DateTime? gratitudeDateFromKey(String key) {
  if (!key.startsWith(ContentKeys.gratitudeDayPrefix)) return null;
  final parts = key.split('_');
  if (parts.length != 4) return null;
  final year = int.tryParse(parts[1]);
  final month = int.tryParse(parts[2]);
  final day = int.tryParse(parts[3]);
  if (year == null || month == null || day == null) return null;
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

/// The lines stored for one day, trimmed, without the empty slots the journal
/// leaves for the three prompts it shows.
List<String> gratitudeLinesFor(Box box, DateTime day) {
  final raw = box.get(gratitudeDayKey(day));
  if (raw is! Iterable) return const [];
  return [
    for (final value in raw)
      if (value?.toString().trim().isNotEmpty ?? false) value.toString().trim(),
  ];
}

/// The stored slots of one day with their positions kept, empty ones included.
///
/// The journal fills three fields from these, so a blank second prompt must
/// stay blank instead of pulling the third line up into it.
List<String> gratitudeSlotsFor(Box box, DateTime day) {
  final raw = box.get(gratitudeDayKey(day));
  if (raw is! Iterable) return const [];
  return [for (final value in raw) value?.toString() ?? ''];
}

/// Every gratitude line in the box, newest day first, oldest line first inside
/// a day so the garden keeps the order the words were written in.
List<GratitudeEntry> gratitudeEntries(Box box) {
  final byDay = <DateTime, List<GratitudeEntry>>{};
  for (final key in box.keys) {
    final name = key.toString();
    final date = gratitudeDateFromKey(name);
    if (date == null) continue;
    final raw = box.get(key);
    if (raw is! Iterable) continue;
    var slot = 0;
    for (final value in raw) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        byDay.putIfAbsent(date, () => []).add(
              GratitudeEntry(date: date, text: text, slot: slot),
            );
      }
      slot++;
    }
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in days) ...byDay[day]!,
  ];
}

/// Appends [text] to [day]'s lines (today by default) and returns the entry.
Future<GratitudeEntry> addGratitude(
  Box box,
  String text, {
  DateTime? day,
}) async {
  final trimmed = text.trim();
  final when = day ?? DateTime.now();
  final date = DateTime(when.year, when.month, when.day);
  final key = gratitudeDayKey(date);
  final raw = box.get(key);
  final lines = <String>[
    if (raw is Iterable) ...raw.map((value) => value?.toString() ?? ''),
  ];
  final slot = lines.length;
  lines.add(trimmed);
  await box.put(key, lines);
  return GratitudeEntry(date: date, text: trimmed, slot: slot);
}

/// Writes the first [firstSlots] lines of [day], keeping anything past them.
///
/// The journal screen owns three prompts; the garden appends to the same day.
/// Writing the three controllers straight into the key would delete a flower
/// planted today, so the lines the journal does not own are carried over
/// untouched.
Future<void> saveGratitudeSlots(
  Box box,
  DateTime day,
  List<String> firstSlots,
) async {
  final date = DateTime(day.year, day.month, day.day);
  final key = gratitudeDayKey(date);
  final raw = box.get(key);
  final existing = <String>[
    if (raw is Iterable) ...raw.map((value) => value?.toString() ?? ''),
  ];
  final kept = existing.length > firstSlots.length
      ? existing.sublist(firstSlots.length)
      : const <String>[];
  await box.put(key, [...firstSlots, ...kept]);
}

/// Removes one line, matching on its slot first and falling back to the first
/// line with the same words.
///
/// The slot is blanked rather than spliced out: the journal's three prompts are
/// positions, so removing one must not pull the next line up into it and make
/// the remaining text jump fields under the writer.
Future<void> removeGratitude(Box box, GratitudeEntry entry) async {
  final raw = box.get(entry.dayKey);
  if (raw is! Iterable) return;
  final lines = raw.map((value) => value?.toString() ?? '').toList();
  var index = -1;
  if (entry.slot >= 0 &&
      entry.slot < lines.length &&
      lines[entry.slot].trim() == entry.text) {
    index = entry.slot;
  } else {
    index = lines.indexWhere((line) => line.trim() == entry.text);
  }
  if (index < 0) return;
  lines[index] = '';
  await box.put(entry.dayKey, lines);
}

/// The garden kept every flower in one list under `gratitude_items`. Each
/// flower becomes a line on the day it was planted, so it shows up in the
/// journal's history, in the garden, and in the gratitude achievement count.
///
/// Copies first and only then deletes, the same way the other content
/// migrations work: an interruption can at worst leave a duplicate that the
/// next launch skips by text.
Future<int> foldGratitudeItems(Box content) async {
  final raw = content.get(ContentKeys.gratitudeItems);
  if (raw == null) return 0;
  if (raw is! Iterable) {
    await content.delete(ContentKeys.gratitudeItems);
    return 0;
  }
  var folded = 0;
  for (final item in raw) {
    if (item is! Map) continue;
    final text = item['text']?.toString().trim() ?? '';
    if (text.isEmpty) continue;
    final planted =
        DateTime.tryParse(item['createdAt']?.toString() ?? '') ?? DateTime.now();
    final date = DateTime(planted.year, planted.month, planted.day);
    final key = gratitudeDayKey(date);
    final existing = content.get(key);
    final lines = <String>[
      if (existing is Iterable) ...existing.map((value) => value?.toString() ?? ''),
    ];
    if (lines.any((line) => line.trim() == text)) continue;
    lines.add(text);
    await content.put(key, lines);
    folded++;
  }
  await content.delete(ContentKeys.gratitudeItems);
  return folded;
}
