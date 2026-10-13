import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';

/// The five sections of the app: Today, Journal, Practice, Garden, Insights.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onToday = navigationShell.currentIndex == 0;
    // Each section is its own branch with no history between them, so Back
    // on any section but Today would close the app. It goes to Today first.
    return PopScope(
      canPop: onToday,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) navigationShell.goBranch(0);
      },
      child: _scaffold(l10n),
    );
  }

  Widget _scaffold(AppLocalizations l10n) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the current tab again returns it to its first screen.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.wb_twilight_outlined),
            selectedIcon: const Icon(Icons.wb_twilight_rounded),
            label: l10n.t('nav.today'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_rounded),
            label: l10n.t('nav.journal'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.self_improvement_outlined),
            selectedIcon: const Icon(Icons.self_improvement_rounded),
            label: l10n.t('nav.sessions'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.park_outlined),
            selectedIcon: const Icon(Icons.park_rounded),
            label: l10n.t('nav.garden'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights_rounded),
            label: l10n.t('nav.stats'),
          ),
        ],
      ),
    );
  }
}
