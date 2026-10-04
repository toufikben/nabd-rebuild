// ignore_for_file: invalid_use_of_visible_for_testing_member
// Renders the main screens to PNG files for a visual review of the design.
// Not part of the normal test run:
//   flutter test tool/screenshots_test.dart --dart-define=SHOTS_DIR=/some/dir
// With --dart-define=STORE=true it also composes the Play Store screenshots
// (1080x1920, caption above a framed screen) into assets/store/output/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nabd/core/l10n/app_localizations.dart';
import 'package:nabd/core/storage.dart';
import 'package:nabd/core/theme/app_colors.dart';
import 'package:nabd/core/theme/app_theme.dart';
import 'package:nabd/core/theme/gender_themes.dart';
import 'package:nabd/features/billing/paywall_screen.dart';
import 'package:nabd/features/editor/editor_screen.dart';
import 'package:nabd/features/journal/journal_screen.dart';
import 'package:nabd/features/practice/practice_screen.dart';
import 'package:nabd/features/shell/app_shell.dart';
import 'package:nabd/features/stats/stats_screen.dart';
import 'package:nabd/features/settings/settings_screen.dart';
import 'package:nabd/features/garden/garden_screen.dart';
import 'package:nabd/features/garden/seed_selection_screen.dart';
import 'package:nabd/features/personal/letters_screen.dart';
import 'package:nabd/features/today/today_screen.dart';
import 'package:nabd/models/journal_entry.dart';
import 'package:nabd/models/seed.dart';
import 'package:nabd/services/database_service.dart';
import 'package:nabd/services/monetization_service.dart';

const _shotsDir = String.fromEnvironment('SHOTS_DIR', defaultValue: 'build/shots');
const _store = bool.fromEnvironment('STORE');
const _storeDir = 'assets/store/output';

/// The store set: which screen, and the caption above it.
const _storeShots = <(String, Map<String, (String, String)>)>[
  ('today', {
    'ar': ('مساحتك الخاصة كل يوم', 'سؤال اليوم، مزاجك، ولحظة هدوء'),
    'en': ('Your private space, every day', "Today's question, your mood, a calm moment"),
  }),
  ('editor', {
    'ar': ('اكتب بحرية، مشفّرًا في هاتفك', 'صور وصوت وإملاء، بلا حساب ولا سحابة'),
    'en': ('Write freely, encrypted on your phone', 'Photos, voice and dictation. No account, no cloud.'),
  }),
  ('journal', {
    'ar': ('كل أيامك في مكان واحد', 'ابحث بالكلمة أو بالمزاج'),
    'en': ('All your days in one place', 'Search by word or by mood'),
  }),
  ('practice', {
    'ar': ('جلسات تهدئة موجّهة', 'تنفّس، أصوات طبيعة، وتمارين قصيرة'),
    'en': ('Guided calming sessions', 'Breathing, nature sounds and short exercises'),
  }),
  ('garden', {
    'ar': ('حديقة تنمو مع كتابتك', 'حتى الأيام الصعبة تسقيها'),
    'en': ('A garden that grows as you write', 'Even the hard days water it'),
  }),
  ('insights', {
    'ar': ('افهم مشاعرك', 'إحصاءات وتحليل يجريان على هاتفك فقط'),
    'en': ('Understand your feelings', 'Insights computed on your phone only'),
  }),
];

const _emojiFamily = 'NotoColorEmoji';

ThemeData _withEmoji(ThemeData theme) => theme.copyWith(
      textTheme: theme.textTheme.apply(fontFamilyFallback: const [_emojiFamily]),
      chipTheme: theme.chipTheme.copyWith(
        labelStyle: (theme.chipTheme.labelStyle ?? theme.textTheme.labelLarge ?? const TextStyle())
            .copyWith(fontFamilyFallback: const [_emojiFamily]),
      ),
    );

Future<void> _loadFonts() async {
  final family = FontLoader(GenderThemes.fontFamily);
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/IBMPlexSansArabic-$weight.ttf').readAsBytesSync();
    family.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await family.load();
  // Colour emoji, so mood faces and seeds are not drawn as empty boxes.
  final emoji = File('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf');
  if (emoji.existsSync()) {
    final loader = FontLoader(_emojiFamily)
      ..addFont(Future.value(ByteData.sublistView(emoji.readAsBytesSync())));
    await loader.load();
  }
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final icons = File(
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
}

Future<void> _seed() async {
  final journal = Hive.box(HiveBoxes.journal);
  final now = DateTime.now();
  final samples = [
    ('يوم على البحر', 'مشيت طويلًا على الشاطئ وشعرت أن الهواء يغسل التعب. أريد أن أتذكر هذا الهدوء.', 'peaceful', 0),
    ('رسالة من أمي', 'اتصلت أمي في الصباح وضحكنا كثيرًا. ممتن لهذه اللحظات الصغيرة.', 'grateful', 1),
    ('اجتماع صعب', 'كان الاجتماع متوترًا، لكنني قلت ما أريد بهدوء. فخور بنفسي قليلًا.', 'anxious', 2),
    ('A quiet evening', 'Read a few pages and made tea. Nothing special, and that felt good.', 'happy', 4),
  ];
  for (var i = 0; i < samples.length; i++) {
    final (title, content, mood, daysAgo) = samples[i];
    final at = now.subtract(Duration(days: daysAgo, hours: i));
    await journal.put('s$i', JournalEntry(
      id: 's$i',
      title: title,
      content: content,
      mood: mood,
      createdAt: at,
      updatedAt: at,
      isPinned: i == 1,
      tags: i == 0 ? const ['travel'] : const [],
    ).toMap());
  }
  // A few weeks of moods, so the insight screens have patterns to show.
  const history = <(String, List<String>, int)>[
    ('peaceful', ['family'], 9), ('happy', ['family'], 10), ('anxious', ['work'], 22),
    ('sad', ['work'], 23), ('grateful', ['family'], 8), ('tired', ['work'], 21),
    ('peaceful', [], 9), ('anxious', ['work'], 23), ('happy', ['family'], 19),
  ];
  for (var i = 0; i < history.length; i++) {
    final (mood, tags, hour) = history[i];
    final day = now.subtract(Duration(days: 6 + i * 3));
    final at = DateTime(day.year, day.month, day.day, hour);
    const notes = [
      ('غداء العائلة', 'جلسنا طويلًا حول الطاولة وضحكنا على ذكريات قديمة.'),
      ('نزهة قصيرة', 'مشيت بعد العصر وشعرت أن رأسي صار أخف.'),
      ('موعد التسليم', 'العمل كثير هذا الأسبوع، وأحاول ألا أحمله معي إلى البيت.'),
      ('ليلة طويلة', 'لم أنم جيدًا. كتبت ما يقلقني حتى يهدأ.'),
    ];
    final (title, content) = notes[i % notes.length];
    await journal.put('h$i', JournalEntry(
      id: 'h$i',
      title: title,
      content: content,
      mood: mood,
      tags: tags,
      createdAt: at,
      updatedAt: at,
    ).toMap());
  }
  // A year-old entry, so "On this day" has something to show.
  final yearAgo = DateTime(now.year - 1, now.month, now.day, 20);
  await journal.put('memory', JournalEntry(
    id: 'memory',
    title: 'أول يوم في العمل الجديد',
    content: 'كنت متوترًا جدًا في الصباح، ثم وجدت زملاء لطفاء. قلت لنفسي: خطوة خطوة.',
    mood: 'hopeful',
    createdAt: yearAgo,
    updatedAt: yearAgo,
  ).toMap());
  DatabaseService.invalidate();
  // A garden in mid-growth, so the garden and Today screens show it alive.
  final garden = Hive.box(HiveBoxes.garden);
  for (final (i, type, points) in const [(0, 'peace', 64), (1, 'joy', 38), (2, 'hope', 12)]) {
    await garden.put('g$i', PlantedSeed(
      id: 'g$i',
      seedTypeId: type,
      plantedAt: now.subtract(Duration(days: 20 - i * 6)),
      growthPoints: points,
      daysCared: points ~/ 4,
      // The first two were watered today; the third still waits.
      lastWateredDay: i < 2 ? now.year * 10000 + now.month * 100 + now.day : 0,
    ).toMap());
  }
  await Hive.box(HiveBoxes.settings).put('onboarding_completed', true);
  // Store art shows a journal that is backed up; the review run shows the
  // reminder card.
  if (_store) {
    await Hive.box(HiveBoxes.settings)
        .put('last_backup_at', now.toIso8601String());
  }
}

Widget _app(Widget home,
    {required Locale locale, required Brightness brightness, bool shell = false, bool pro = false}) {
  AppColors.brightness = brightness;
  final router = GoRouter(
    initialLocation: '/',
    routes: shell
        ? [
            StatefulShellRoute.indexedStack(
              builder: (_, __, shell) => AppShell(navigationShell: shell),
              branches: [
                StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, __) => home)]),
                StatefulShellBranch(routes: [GoRoute(path: '/journal', builder: (_, __) => const SizedBox())]),
                StatefulShellBranch(routes: [GoRoute(path: '/sessions', builder: (_, __) => const SizedBox())]),
                StatefulShellBranch(routes: [GoRoute(path: '/garden', builder: (_, __) => const SizedBox())]),
                StatefulShellBranch(routes: [GoRoute(path: '/stats', builder: (_, __) => const SizedBox())]),
              ],
            ),
          ]
        : [GoRoute(path: '/', builder: (_, __) => home)],
  );
  return ProviderScope(
    overrides: [
      monetizationProvider.overrideWith(
        (_) => MonetizationService.preset(MonetizationState(
          storeAvailable: true,
          productsLoaded: true,
          isPro: pro,
          isLifetime: pro,
        )),
      ),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: _withEmoji(AppTheme.getTheme('light', GenderTheme.neutral)),
      darkTheme: _withEmoji(AppTheme.getTheme('dark', GenderTheme.neutral)),
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    ),
  );
}

Future<void> _capture(WidgetTester tester, String name, {String dir = _shotsDir}) async {
  final element = tester.element(find.byType(MaterialApp));
  final boundary = element.findRenderObject()!;
  RenderObject? node = boundary;
  while (node != null && node is! RenderRepaintBoundary) {
    node = node.parent;
  }
  final repaint = node as RenderRepaintBoundary? ??
      tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
  final image = await repaint.toImage(pixelRatio: 1);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('$dir/$name.png')..createSync(recursive: true);
  file.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  late Directory hiveDir;

  setUpAll(() async {
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Pulse',
      packageName: 'com.nabd.journal',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await initializeDateFormatting();
    await _loadFonts();
  });

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp('nabd_shots');
    Hive.init(hiveDir.path);
    for (final name in HiveBoxes.all) {
      await Hive.openBox<dynamic>(name);
    }
    await Hive.box(HiveBoxes.settings).put('ui_sounds_enabled', false);
    await _seed();
  });

  tearDown(() async {
    await Hive.close();
    DatabaseService.invalidate();
    await hiveDir.delete(recursive: true);
  });

  final screens = <String, (Widget, bool)>{
    'today': (const TodayScreen(), true),
    'journal': (const JournalScreen(), false),
    'practice': (const PracticeScreen(), false),
    'insights': (const StatsScreen(), false),
    'patterns': (const StatsScreen(), false),
    'editor': (const EditorScreen(entryId: 's0'), false),
    'paywall': (const PaywallScreen(), false),
    'settings': (const SettingsScreen(), false),
    'garden': (const GardenScreen(), false),
    'seeds': (const SeedSelectionScreen(), false),
    'letters': (const LettersScreen(), false),
  };

  for (final locale in const [Locale('ar'), Locale('en')]) {
    for (final brightness in Brightness.values) {
      for (final entry in screens.entries) {
        final name = '${entry.key}_${locale.languageCode}_${brightness.name}';
        testWidgets(name, (tester) async {
          tester.view.physicalSize = const Size(1080, 2340);
          tester.view.devicePixelRatio = 2.75;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(RepaintBoundary(
            child: _app(entry.value.$1,
                locale: locale,
                brightness: brightness,
                shell: entry.value.$2,
                // Store art shows the full app; the paywall shows the offer.
                pro: _store && entry.key != 'paywall'),
          ));
          // Let async loads (platform mocks) finish, then run animations on
          // the test clock so entrance effects have played.
          await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 300)));
          for (var i = 0; i < 30; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          if (entry.key == 'patterns') {
            await tester.drag(find.byType(Scrollable).first, const Offset(0, -1500));
            await tester.pumpAndSettle();
          }
          await tester.runAsync(() => _capture(tester, name));
        });
      }
    }
  }

  if (!_store) return;
  for (final locale in const ['ar', 'en']) {
    for (var i = 0; i < _storeShots.length; i++) {
      final (screen, captions) = _storeShots[i];
      final (title, subtitle) = captions[locale]!;
      final name = '${(i + 1).toString().padLeft(2, '0')}_${screen}_$locale';
      testWidgets('store $name', (tester) async {
        tester.view.physicalSize = const Size(1080, 1920);
        tester.view.devicePixelRatio = 2.75;
        addTearDown(tester.view.reset);
        final bytes = File('$_shotsDir/${screen}_${locale}_light.png').readAsBytesSync();
        final image = MemoryImage(bytes);
        await tester.pumpWidget(RepaintBoundary(
          child: _StoreFrame(
            title: title,
            subtitle: subtitle,
            rtl: locale == 'ar',
            screen: image,
          ),
        ));
        await tester.runAsync(() async {
          await precacheImage(image, tester.element(find.byType(_StoreFrame)));
        });
        await tester.pump();
        await tester.runAsync(() => _captureStore(tester, name));
      });
    }
  }
}

Future<void> _captureStore(WidgetTester tester, String name) async {
  final repaint = tester.renderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary).first);
  final image = await repaint.toImage(pixelRatio: 2.75);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File('$_storeDir/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

/// One store image: the caption on the brand gradient, the real screen below
/// it in a rounded phone outline.
class _StoreFrame extends StatelessWidget {
  const _StoreFrame({
    required this.title,
    required this.subtitle,
    required this.rtl,
    required this.screen,
  });

  final String title;
  final String subtitle;
  final bool rtl;
  final ImageProvider screen;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.brandGradient),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 46, 28, 0),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: GenderThemes.fontFamily,
                  fontSize: 27,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: GenderThemes.fontFamily,
                  fontSize: 15.5,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 28),
              // The phone runs off the bottom edge, as store art usually does,
              // so the screen stays large enough to read.
              Expanded(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: double.infinity,
                  child: SizedBox(
                    width: 300,
                    height: 300 * 2340 / 1080,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.55),
                          width: 5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55000000),
                            blurRadius: 30,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image(image: screen, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
