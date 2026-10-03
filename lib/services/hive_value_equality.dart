import 'dart:convert';

/// Deep equality for values read back from Hive, where a map written as
/// `Map<String, dynamic>` comes back as `Map<dynamic, dynamic>` and lists lose
/// their element type. Used to prove a re-encrypted box holds exactly what
/// was written into it.
bool hiveValuesEqual(Object? left, Object? right) {
  if (left is Map && right is Map) {
    if (left.length != right.length) return false;
    for (final key in left.keys) {
      if (!right.containsKey(key) || !hiveValuesEqual(left[key], right[key])) {
        return false;
      }
    }
    return true;
  }
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (!hiveValuesEqual(left[i], right[i])) return false;
    }
    return true;
  }
  if (left is DateTime && right is DateTime) return left == right;
  if (left is num && right is num) return left == right;
  if (left == null || right == null) return left == right;
  try {
    return jsonEncode(left) == jsonEncode(right);
  } catch (_) {
    return left == right;
  }
}
