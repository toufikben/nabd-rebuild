import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/l10n/app_localizations.dart';
import '../core/streak.dart';
import '../core/writing_prompts.dart';
import 'database_service.dart';

/// Feeds the Android home-screen widget: the streak and today's prompt.
/// Journal text never leaves the app this way.
class HomeWidgetService {
  const HomeWidgetService._();

  static const _channel = MethodChannel('nabd/widget');

  static Future<void> refresh(AppLocalizations l10n) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final moments =
          DatabaseService().getAllEntries().map((entry) => entry.createdAt);
      final streak = StreakCalculator.current(moments);
      await _channel.invokeMethod<void>('update', {
        'title': l10n.t('app.name'),
        'streak': streak == 0 ? '' : '🔥 $streak ${l10n.t('widget.streak')}',
        'prompt': StreakCalculator.wroteToday(moments)
            ? l10n.t('widget.doneToday')
            : WritingPrompts.today(l10n),
      });
    } on MissingPluginException {
      // Tests and platforms without the widget.
    } catch (error) {
      debugPrint('Widget refresh failed: $error');
    }
  }
}
