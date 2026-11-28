import 'package:hive/hive.dart';

import 'storage.dart';

/// The finished-session counter, in one place.
///
/// Both the guided session runner and the standalone breathing exercise
/// counted completions with their own copy of this code, and Insights read the
/// key directly with a third. Any screen that finishes a session adds to it,
/// so the number the writer sees never depends on which route they took.
class SessionLog {
  const SessionLog._();

  static int completed([Box? box]) {
    final raw = (box ?? _box()).get(ContentKeys.sessionsCompleted);
    return raw is int ? raw : 0;
  }

  /// Adds one finished session. Returns the new total, or the unchanged one
  /// when the write fails: a counter that cannot be written must not break the
  /// finished screen the writer is looking at.
  static Future<int> record([Box? box]) async {
    final target = box ?? _box();
    final next = completed(target) + 1;
    try {
      await target.put(ContentKeys.sessionsCompleted, next);
      return next;
    } catch (_) {
      return completed(target);
    }
  }

  static Box _box() => Hive.box(HiveBoxes.content);
}
