import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';
import 'services/biometric_service.dart';
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // Transient interruptions such as the biometric prompt are not
        // backgrounding events and must not start the lock timeout.
        return;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _biometric.markBackgrounded();
        return;
      case AppLifecycleState.resumed:
        final shouldLock = _biometric.shouldShowLock();
        if (!shouldLock) {
          _biometric.clearBackgrounded();
          return;
        }
        if (router.state.uri.path != '/lock') {
          router.go('/lock');
        }
        return;
      case AppLifecycleState.detached:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final genderTheme = ref.watch(genderThemeProvider);
    final lightTheme = AppTheme.getTheme('light', genderTheme);
    final darkTheme = AppTheme.getTheme('dark', genderTheme);

    return MaterialApp.router(
      title: 'نبض',
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
