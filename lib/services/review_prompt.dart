import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';

import '../core/storage.dart';

/// Asks for a store rating through Google Play's own in-app review sheet,
/// only after something went well: a new entry written to the end, or a
/// breathing session finished. Never after a failure, never behind a
/// reward, and never more than the spacing below; Play applies its own
/// quota on top and may show nothing at all.
class ReviewPrompt {
  ReviewPrompt({
    Box? settings,
    DateTime Function()? now,
    Future<bool> Function()? request,
  })  : _settings = settings,
        _now = now ?? DateTime.now,
        _request = request ?? _askPlay;

  final Box? _settings;
  final DateTime Function() _now;
  final Future<bool> Function() _request;

  Box get _box => _settings ?? Hive.box(HiveBoxes.settings);

  static const winsKey = 'review_wins';
  static const askedAtKey = 'review_asked_at';

  /// Good moments before the first ask: enough to know the app is in use.
  static const winsBeforeAsking = 3;

  /// Time between two asks, should Play show the sheet again at all.
  static const spacing = Duration(days: 120);

  /// Counts a good moment and asks when the time is right. Never throws.
  Future<void> recordWin() async {
    try {
      final wins = (_box.get(winsKey) as int? ?? 0) + 1;
      await _box.put(winsKey, wins);
      if (wins < winsBeforeAsking) return;
      final asked = DateTime.tryParse('${_box.get(askedAtKey)}');
      if (asked != null && _now().difference(asked) < spacing) return;
      if (!await _request()) return;
      await _box.put(askedAtKey, _now().toIso8601String());
    } catch (error) {
      debugPrint('Review prompt skipped: $error');
    }
  }

  static Future<bool> _askPlay() async {
    final review = InAppReview.instance;
    if (!await review.isAvailable()) return false;
    await review.requestReview();
    return true;
  }

  /// The store page, for the "Rate" row in Settings.
  static Future<void> openStorePage() =>
      InAppReview.instance.openStoreListing();
}
