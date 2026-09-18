import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../features/splash/splash_screen.dart';
import '../features/lock/lock_screen.dart';
import '../features/home/home_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/search/search_screen.dart';
import '../features/tags/tags_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/billing/paywall_screen.dart';
import '../features/stats/stats_screen.dart';
import '../features/stats/weather_screen.dart';
import '../features/stats/heatmap_screen.dart';
import '../features/stats/advanced/word_cloud_screen.dart';
import '../features/stats/advanced/emotion_radar_screen.dart';
import '../features/stats/advanced/year_review_screen.dart';
import '../features/garden/garden_screen.dart';
import '../features/garden/seed_selection_screen.dart';
import '../features/worry/worry_box_screen.dart';
import '../features/worry/worry_release_screen.dart';
import '../features/breathing/breathing_screen.dart';
import '../features/dream/dream_journal_screen.dart';
import '../features/gratitude/gratitude_garden_screen.dart';
import '../features/gratitude/gratitude_journal_screen.dart';
import '../features/future_self/future_letters_screen.dart';
import '../features/social/unsent_letters_screen.dart';
import '../features/social/legacy_journal_screen.dart';
import '../features/social/time_capsule_screen.dart';
import '../features/motivation/achievements_screen.dart';
import '../features/motivation/challenges_screen.dart';
import '../features/navigation/section_hub_screen.dart';
import '../services/biometric_service.dart';

String? _entryIdFromState(GoRouterState state) {
  final extra = state.extra;
  if (extra == null) return state.uri.queryParameters['id'];
  if (extra is! String || extra.trim().isEmpty) return null;
  return extra;
}

final router = GoRouter(
  initialLocation: '/',
  redirect: (_, state) {
    final location = state.uri.path;
    final externalHost = state.uri.host;
    final externalRoute = switch (externalHost) {
      'editor' => '/editor',
      'garden' => '/garden',
      'calendar' => '/calendar',
      'stats' => '/stats',
      _ => null,
    };
    if (externalRoute != null) return externalRoute;
    if (state.uri.host == 'nabd.app') {
      final webRoute = switch (location) {
        '/journal' => '/editor',
        '/garden' => '/garden',
        _ => null,
      };
      if (webRoute != null) return webRoute;
    }
    final onboardingComplete =
        Hive.box('settings').get('onboarding_completed', defaultValue: false) ==
            true;
    final exempt = location == '/' ||
        location == '/lock' ||
        (location == '/seed-selection' && !onboardingComplete);
    if (!exempt && BiometricService().shouldShowLock()) return '/lock';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/lock', builder: (_, __) => const LockScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(
        path: '/writing',
        builder: (_, __) =>
            const SectionHubScreen(section: NabdSection.writing)),
    GoRoute(
        path: '/journey',
        builder: (_, __) =>
            const SectionHubScreen(section: NabdSection.journey)),
    GoRoute(
        path: '/analytics',
        builder: (_, __) =>
            const SectionHubScreen(section: NabdSection.analytics)),
    GoRoute(
        path: '/editor',
        builder: (_, state) => EditorScreen(entryId: _entryIdFromState(state))),
    GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
    GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
    GoRoute(path: '/tags', builder: (_, __) => const TagsScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),
    GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
    GoRoute(path: '/heatmap', builder: (_, __) => const HeatmapScreen()),
    GoRoute(path: '/weather', builder: (_, __) => const WeatherScreen()),
    GoRoute(path: '/word-cloud', builder: (_, __) => const WordCloudScreen()),
    GoRoute(
        path: '/emotion-radar', builder: (_, __) => const EmotionRadarScreen()),
    GoRoute(path: '/year-review', builder: (_, __) => const YearReviewScreen()),
    GoRoute(path: '/garden', builder: (_, __) => const GardenScreen()),
    GoRoute(
        path: '/seed-selection',
        builder: (_, __) => const SeedSelectionScreen()),
    GoRoute(path: '/worry-box', builder: (_, __) => const WorryBoxScreen()),
    GoRoute(
        path: '/worry-release', builder: (_, __) => const WorryReleaseScreen()),
    GoRoute(path: '/breathing', builder: (_, __) => const BreathingScreen()),
    GoRoute(
        path: '/dream-journal', builder: (_, __) => const DreamJournalScreen()),
    GoRoute(
        path: '/gratitude-garden',
        builder: (_, __) => const GratitudeGardenScreen()),
    GoRoute(
        path: '/gratitude-journal',
        builder: (_, __) => const GratitudeJournalScreen()),
    GoRoute(
        path: '/future-letters',
        builder: (_, __) => const FutureLettersScreen()),
    GoRoute(
        path: '/unsent-letters',
        builder: (_, __) => const UnsentLettersScreen()),
    GoRoute(
        path: '/legacy-journal',
        builder: (_, __) => const LegacyJournalScreen()),
    GoRoute(
        path: '/time-capsule', builder: (_, __) => const TimeCapsuleScreen()),
    GoRoute(
        path: '/achievements', builder: (_, __) => const AchievementsScreen()),
    GoRoute(path: '/challenges', builder: (_, __) => const ChallengesScreen()),
  ],
);
