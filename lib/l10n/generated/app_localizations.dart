import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Nabd'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Your Private Journal'**
  String get appTagline;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New Entry'**
  String get newEntry;

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit Entry'**
  String get editEntry;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Write your thoughts...'**
  String get content;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @mood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get mood;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @garden.
  ///
  /// In en, this message translates to:
  /// **'My Garden'**
  String get garden;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @challenges.
  ///
  /// In en, this message translates to:
  /// **'Challenges'**
  String get challenges;

  /// No description provided for @wordCloud.
  ///
  /// In en, this message translates to:
  /// **'Word Cloud'**
  String get wordCloud;

  /// No description provided for @emotionRadar.
  ///
  /// In en, this message translates to:
  /// **'Emotion Radar'**
  String get emotionRadar;

  /// No description provided for @yearReview.
  ///
  /// In en, this message translates to:
  /// **'Year in Review'**
  String get yearReview;

  /// No description provided for @unsentLetters.
  ///
  /// In en, this message translates to:
  /// **'Unsent Letters'**
  String get unsentLetters;

  /// No description provided for @legacyJournal.
  ///
  /// In en, this message translates to:
  /// **'Legacy Journal'**
  String get legacyJournal;

  /// No description provided for @timeCapsule.
  ///
  /// In en, this message translates to:
  /// **'Time Capsules'**
  String get timeCapsule;

  /// No description provided for @futureLetters.
  ///
  /// In en, this message translates to:
  /// **'Future Letters'**
  String get futureLetters;

  /// No description provided for @dreamJournal.
  ///
  /// In en, this message translates to:
  /// **'Dream Journal'**
  String get dreamJournal;

  /// No description provided for @worryBox.
  ///
  /// In en, this message translates to:
  /// **'Worry Box'**
  String get worryBox;

  /// No description provided for @worryRelease.
  ///
  /// In en, this message translates to:
  /// **'Release a Worry'**
  String get worryRelease;

  /// No description provided for @breathing.
  ///
  /// In en, this message translates to:
  /// **'Breathing'**
  String get breathing;

  /// No description provided for @gratitude.
  ///
  /// In en, this message translates to:
  /// **'Daily Gratitude'**
  String get gratitude;

  /// No description provided for @gratitudeGarden.
  ///
  /// In en, this message translates to:
  /// **'Gratitude Garden'**
  String get gratitudeGarden;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Mood Weather'**
  String get weather;

  /// No description provided for @heatmap.
  ///
  /// In en, this message translates to:
  /// **'Activity Heatmap'**
  String get heatmap;

  /// No description provided for @moodWeather.
  ///
  /// In en, this message translates to:
  /// **'Mood Weather'**
  String get moodWeather;

  /// No description provided for @weeklyPulse.
  ///
  /// In en, this message translates to:
  /// **'Weekly Pulse'**
  String get weeklyPulse;

  /// No description provided for @monthlyAverage.
  ///
  /// In en, this message translates to:
  /// **'Monthly Average'**
  String get monthlyAverage;

  /// No description provided for @moodDistribution.
  ///
  /// In en, this message translates to:
  /// **'Mood Distribution'**
  String get moodDistribution;

  /// No description provided for @seedSelection.
  ///
  /// In en, this message translates to:
  /// **'Choose a Seed'**
  String get seedSelection;

  /// No description provided for @plantSeed.
  ///
  /// In en, this message translates to:
  /// **'Plant Seed'**
  String get plantSeed;

  /// No description provided for @yourGarden.
  ///
  /// In en, this message translates to:
  /// **'Your Garden'**
  String get yourGarden;

  /// No description provided for @treeGrowth.
  ///
  /// In en, this message translates to:
  /// **'Tree Growth'**
  String get treeGrowth;

  /// No description provided for @needsWater.
  ///
  /// In en, this message translates to:
  /// **'Needs water'**
  String get needsWater;

  /// No description provided for @fullyGrown.
  ///
  /// In en, this message translates to:
  /// **'Fully Grown!'**
  String get fullyGrown;

  /// No description provided for @echoes.
  ///
  /// In en, this message translates to:
  /// **'Echoes'**
  String get echoes;

  /// No description provided for @resolvedEcho.
  ///
  /// In en, this message translates to:
  /// **'Resolved echo'**
  String get resolvedEcho;

  /// No description provided for @awaitingEcho.
  ///
  /// In en, this message translates to:
  /// **'An echo waiting for a response'**
  String get awaitingEcho;

  /// No description provided for @laterPositiveEntry.
  ///
  /// In en, this message translates to:
  /// **'Later positive entry'**
  String get laterPositiveEntry;

  /// No description provided for @original.
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get original;

  /// No description provided for @resolved.
  ///
  /// In en, this message translates to:
  /// **'Resolved'**
  String get resolved;

  /// No description provided for @echoesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Echoes appear when a difficult mood has a later positive entry 3–90 days afterward.'**
  String get echoesEmpty;

  /// No description provided for @sage.
  ///
  /// In en, this message translates to:
  /// **'Sage'**
  String get sage;

  /// No description provided for @quietThought.
  ///
  /// In en, this message translates to:
  /// **'A quiet thought'**
  String get quietThought;

  /// No description provided for @sageLocalNote.
  ///
  /// In en, this message translates to:
  /// **'Sage uses the app’s local library. It changes only when you press Refresh.'**
  String get sageLocalNote;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @unknownMood.
  ///
  /// In en, this message translates to:
  /// **'Unknown mood'**
  String get unknownMood;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
