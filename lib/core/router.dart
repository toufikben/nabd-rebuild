import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../features/splash/splash_screen.dart';
import '../features/lock/lock_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/today/today_screen.dart';
import '../features/journal/journal_screen.dart';
import '../features/practice/practice_screen.dart';
import '../features/sessions/screens/session_runner_screen.dart';
import '../features/silent/silent_companion_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/search/search_screen.dart';
import '../features/tags/tags_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/billing/paywall_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/stats/weather_screen.dart';
import '../features/stats/heatmap_screen.dart';
import '../features/stats/monthly_summary_screen.dart';
import '../features/practice/habits_screen.dart';
import '../features/stats/advanced/word_cloud_screen.dart';
import '../features/stats/advanced/emotion_radar_screen.dart';
import '../features/stats/advanced/year_review_screen.dart';
import '../features/garden/garden_screen.dart';
import '../features/garden/seed_selection_screen.dart';
import '../features/garden/sound_garden_screen.dart';
import '../features/worry/worry_box_screen.dart';
import '../features/worry/worry_release_screen.dart';
import '../features/motivation/motivation_screen.dart';
import '../features/motivation/wisdom_screen.dart';
import '../features/breathing/breathing_screen.dart';
import '../features/dream/dream_journal_screen.dart';
import '../features/gratitude/gratitude_garden_screen.dart';
import '../features/gratitude/gratitude_journal_screen.dart';
import '../features/social/legacy_journal_screen.dart';
import '../features/motivation/achievements_screen.dart';
import '../features/motivation/challenges_screen.dart';
import '../features/personal/letters_screen.dart';
import '../features/personal/echoes_screen.dart';
import '../features/personal/weekly_pulse_screen.dart';
import '../models/mood.dart';
import '../services/biometric_service.dart';
import '../widgets/pro_gate.dart';

/// `yyyy-mm`, as the Today card links last month's summary.
DateTime? _monthFromQuery(String? value) {
  final match = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(value ?? '');
  if (match == null) return null;
  final month = int.parse(match.group(2)!);
  if (month < 1 || month > 12) return null;
  return DateTime(int.parse(match.group(1)!), month);
}

String? _entryIdFromState(GoRouterState state) {
  final extra = state.extra;
  if (extra == null) return state.uri.queryParameters['id'];
  if (extra is! String || extra.trim().isEmpty) return null;
  return extra;
}

/// Maps a link from outside the app (shortcut, widget, App Link) to a route,
/// or null when [uri] is already an in-app location. From the home-screen
/// widget, `nabd://editor?mood=sad` opens a new entry with that mood; only a
/// known mood id is passed on.
@visibleForTesting
String? externalLocation(Uri uri) {
  final route = switch (uri.host) {
    'editor' => '/editor',
    'garden' => '/garden',
    'calendar' => '/calendar',
    'stats' => '/stats',
    _ => null,
  };
  if (route == '/editor') {
    final mood = uri.queryParameters['mood'];
    final known = mood != null && Mood.journalMoods.any((m) => m.id == mood);
    return known ? '/editor?mood=$mood' : route;
  }
  if (route != null) return route;
  if (uri.host == 'nabd.app') {
    return switch (uri.path) {
      '/journal' => '/editor',
      '/garden' => '/garden',
      _ => null,
    };
  }
  return null;
}

/// Deep link read from the launch intent before Flutter started handing
/// routes to the navigation channel. Set from `main()` while the app boots.
String? pendingInitialLink;

String? externalLocationForLink(String link) {
  if (link.isEmpty) return null;
  final Uri? uri = Uri.tryParse(link);
  if (uri == null) return null;
  if (!uri.hasScheme) return link;
  return externalLocation(uri);
}

String _initialLocation() {
  final String? pending = pendingInitialLink;
  debugPrint('NABD_INITIAL pending=$pending');
  if (pending != null) {
    final String? external = externalLocationForLink(pending);
    if (external != null) return external;
  }
  final String platformRoute =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  debugPrint('NABD_INITIAL platform=$platformRoute');
  if (platformRoute == '/') return '/';
  final Uri? uri = Uri.tryParse(platformRoute);
  if (uri == null) return '/';
  if (!uri.hasScheme) return platformRoute;
  return externalLocation(uri) ?? '/';
}

final router = GoRouter(
  initialLocation: _initialLocation(),
  redirect: (_, state) {
    final location = state.uri.path;
    final external = externalLocation(state.uri);
    if (external != null) return external;
    final onboardingComplete =
        Hive.box('settings').get('onboarding_completed', defaultValue: false) ==
            true;
    final exempt = location == '/' ||
        location == '/lock' ||
        (location == '/seed-selection' && !onboardingComplete);
    if (!exempt &&
        BiometricService().shouldShowLock(coldStart: location != '/')) {
      BiometricService.pendingLocation = state.uri.toString();
      return '/lock';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/lock', builder: (_, __) => const LockScreen()),
    // Old addresses of screens that were merged, kept so links and
    // shortcuts saved by users still land somewhere sensible.
    GoRoute(path: '/home', redirect: (_, __) => '/today'),
    GoRoute(path: '/writing', redirect: (_, __) => '/journal'),
    GoRoute(path: '/journey', redirect: (_, __) => '/sessions'),
    GoRoute(path: '/analytics', redirect: (_, __) => '/stats'),
    GoRoute(path: '/gratitude', redirect: (_, __) => '/gratitude-journal'),
    GoRoute(path: '/future-letters', redirect: (_, __) => '/letters'),
    GoRoute(path: '/unsent-letters', redirect: (_, __) => '/letters'),
    GoRoute(path: '/time-capsule', redirect: (_, __) => '/letters'),
    GoRoute(path: '/sage', redirect: (_, __) => '/motivation'),
    GoRoute(
      path: '/sessions/run',
      builder: (_, GoRouterState state) =>
          SessionRunnerScreen(sessionId: state.uri.queryParameters['id'] ?? ''),
    ),
    GoRoute(path: '/silent', builder: (_, __) => const SilentCompanionScreen()),
    StatefulShellRoute.indexedStack(
      builder: (
        BuildContext context,
        GoRouterState state,
        StatefulNavigationShell navigationShell,
      ) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(path: '/today', builder: (_, __) => const TodayScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/journal',
              builder: (_, __) => const JournalScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/sessions',
              builder: (_, __) => const PracticeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(path: '/garden', builder: (_, __) => const GardenScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/editor',
      builder: (_, state) => EditorScreen(
        entryId: _entryIdFromState(state),
        initialMood: state.uri.queryParameters['mood'],
      ),
    ),
    GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
    GoRoute(
      path: '/search',
      builder: (_, state) =>
          SearchScreen(initialTag: state.uri.queryParameters['tag']),
    ),
    GoRoute(path: '/tags', builder: (_, __) => const TagsScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
    GoRoute(path: '/heatmap', builder: (_, __) => const HeatmapScreen()),
    GoRoute(
      path: '/monthly',
      builder: (_, state) => MonthlySummaryScreen(
        initialMonth: _monthFromQuery(state.uri.queryParameters['month']),
      ),
    ),
    GoRoute(path: '/weather', builder: (_, __) => const WeatherScreen()),
    GoRoute(
      path: '/word-cloud',
      builder: (_, __) => const ProGate(
        icon: Icons.cloud_outlined,
        child: WordCloudScreen(),
      ),
    ),
    GoRoute(
      path: '/emotion-radar',
      builder: (_, __) => const ProGate(
        icon: Icons.radar,
        child: EmotionRadarScreen(),
      ),
    ),
    GoRoute(
      path: '/year-review',
      builder: (_, __) => const ProGate(
        icon: Icons.auto_awesome,
        child: YearReviewScreen(),
      ),
    ),
    GoRoute(
      path: '/seed-selection',
      builder: (_, __) => const SeedSelectionScreen(),
    ),
    GoRoute(
      path: '/sound-garden',
      builder: (_, __) => const SoundGardenScreen(),
    ),
    GoRoute(path: '/worry-box', builder: (_, __) => const WorryBoxScreen()),
    GoRoute(
      path: '/worry-release',
      builder: (_, __) => const WorryReleaseScreen(),
    ),
    GoRoute(path: '/breathing', builder: (_, __) => const BreathingScreen()),
    GoRoute(path: '/habits', builder: (_, __) => const HabitsScreen()),
    GoRoute(
      path: '/dream-journal',
      builder: (_, __) => const DreamJournalScreen(),
    ),
    GoRoute(
      path: '/gratitude-garden',
      builder: (_, __) => const GratitudeGardenScreen(),
    ),
    GoRoute(
      path: '/gratitude-journal',
      builder: (_, __) => const GratitudeJournalScreen(),
    ),
    GoRoute(path: '/motivation', builder: (_, __) => const MotivationScreen()),
    GoRoute(path: '/wisdom', builder: (_, __) => const WisdomScreen()),
    GoRoute(path: '/letters', builder: (_, __) => const LettersScreen()),
    GoRoute(path: '/echoes', builder: (_, __) => const EchoesScreen()),
    GoRoute(
      path: '/weekly-pulse',
      builder: (_, __) => const WeeklyPulseScreen(),
    ),
    GoRoute(
      path: '/legacy-journal',
      builder: (_, __) => const LegacyJournalScreen(),
    ),
    GoRoute(
      path: '/achievements',
      builder: (_, __) => const AchievementsScreen(),
    ),
    GoRoute(path: '/challenges', builder: (_, __) => const ChallengesScreen()),
  ],
);
