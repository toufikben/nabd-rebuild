import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_fonts.dart';
import 'core/theme/app_theme.dart';
import 'services/biometric_service.dart';
import 'services/database_service.dart';
import 'services/home_widget_service.dart';
import 'services/monetization_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';

class NabdApp extends ConsumerStatefulWidget {
  const NabdApp({super.key});

  @override
  ConsumerState<NabdApp> createState() => _NabdAppState();
}

class _NabdAppState extends ConsumerState<NabdApp> with WidgetsBindingObserver {
  final _biometric = BiometricService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The provider is otherwise built by the first screen that reads it, which
    // makes that screen's cold answer the default `false`. Start the entitlement
    // cache load with the app instead.
    unawaited(ref.read(monetizationProvider.notifier).ensureReady());
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshWidget());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only a real trip to the background counts. `inactive` also fires for
    // the notification shade and for the biometric prompt itself, which
    // would make an immediate lock loop on its own dialog.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _biometric.markBackgrounded();
      // A day that just got an entry should not be nudged later.
      _refreshReminder();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      _refreshWidget();
      final shouldLock = _biometric.shouldShowLock();
      if (shouldLock) {
        // Pushed on top, so whatever was open (a half-written entry) is
        // still there after unlocking.
        if (router.state.uri.path != '/lock') router.push('/lock');
      } else {
        _biometric.clearBackgrounded();
      }
    }
  }

  void _refreshReminder() {
    try {
      final writtenAt =
          DatabaseService().getAllEntries().map((e) => e.createdAt).toList();
      unawaited(NotificationService.refreshDaily(writtenAt));
    } catch (error) {
      debugPrint('Reminder refresh skipped: $error');
    }
  }

  /// Keeps the home-screen widget's streak and prompt current; a new day
  /// changes both even when nothing was written.
  void _refreshWidget() {
    final context = router.routerDelegate.navigatorKey.currentContext;
    if (context == null) return;
    HomeWidgetService.refresh(AppLocalizations.of(context));
  }

  @override
  void didChangePlatformBrightness() {
    // AppColors follows the theme; in "system" mode that means the phone.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final genderTheme = ref.watch(genderThemeProvider);

    // AppColors.textPrimary and friends are static getters, so they have to be
    // told which brightness is live before any descendant reads them.
    AppColors.brightness = switch (themeMode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system =>
        WidgetsBinding.instance.platformDispatcher.platformBrightness,
    };

    final language = AppLocalizations(locale).language;
    final family = ref.watch(appFontProvider).familyFor(language);
    final lightTheme =
        AppTheme.getTheme('light', genderTheme, fontFamily: family);
    final darkTheme = AppTheme.getTheme('dark', genderTheme, fontFamily: family);

    return MaterialApp.router(
      title: AppLocalizations(locale).t('app.name'),
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
