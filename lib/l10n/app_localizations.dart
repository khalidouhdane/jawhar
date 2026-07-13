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
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get navPractice;

  /// No description provided for @navRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get navRead;

  /// No description provided for @navListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get navListen;

  /// No description provided for @navAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get navAudio;

  /// No description provided for @navHifz.
  ///
  /// In en, this message translates to:
  /// **'Hifz'**
  String get navHifz;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navUnderstand.
  ///
  /// In en, this message translates to:
  /// **'Understand'**
  String get navUnderstand;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Assalamu Alaikum'**
  String get homeGreeting;

  /// No description provided for @homeResumeTitle.
  ///
  /// In en, this message translates to:
  /// **'Resume Your Journey'**
  String get homeResumeTitle;

  /// No description provided for @homeResumeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Continue where you left off'**
  String get homeResumeSubtitle;

  /// No description provided for @homeContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get homeContinue;

  /// No description provided for @homeNoHistory.
  ///
  /// In en, this message translates to:
  /// **'Start reading to track your progress'**
  String get homeNoHistory;

  /// No description provided for @homeQuickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get homeQuickAccess;

  /// No description provided for @homeBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get homeBookmarks;

  /// No description provided for @homeRandom.
  ///
  /// In en, this message translates to:
  /// **'Random\nPage'**
  String get homeRandom;

  /// No description provided for @homeAyahTitle.
  ///
  /// In en, this message translates to:
  /// **'Ayah of the Day'**
  String get homeAyahTitle;

  /// No description provided for @homeAyahSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily inspiration from the Quran'**
  String get homeAyahSubtitle;

  /// No description provided for @homeHifzTitle.
  ///
  /// In en, this message translates to:
  /// **'Hifz Progress'**
  String get homeHifzTitle;

  /// No description provided for @homeHifzSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Memorization journey'**
  String get homeHifzSubtitle;

  /// No description provided for @homeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get homeComingSoon;

  /// No description provided for @homeLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading verse...'**
  String get homeLoading;

  /// No description provided for @homePage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get homePage;

  /// No description provided for @homeRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get homeRead;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get homeWelcome;

  /// No description provided for @homeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get homeJustNow;

  /// No description provided for @homeMinAgo.
  ///
  /// In en, this message translates to:
  /// **'m ago'**
  String get homeMinAgo;

  /// No description provided for @homeHourAgo.
  ///
  /// In en, this message translates to:
  /// **'h ago'**
  String get homeHourAgo;

  /// No description provided for @homeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get homeYesterday;

  /// No description provided for @homeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get homeDaysAgo;

  /// No description provided for @readTitle.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readTitle;

  /// No description provided for @readSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore the Holy Quran'**
  String get readSubtitle;

  /// No description provided for @readSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search surahs...'**
  String get readSearchHint;

  /// No description provided for @readTabSurah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get readTabSurah;

  /// No description provided for @readTabJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get readTabJuz;

  /// No description provided for @readTabHizb.
  ///
  /// In en, this message translates to:
  /// **'Hizb'**
  String get readTabHizb;

  /// No description provided for @readVerses.
  ///
  /// In en, this message translates to:
  /// **'verses'**
  String get readVerses;

  /// No description provided for @readPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get readPages;

  /// No description provided for @audioTitle.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get audioTitle;

  /// No description provided for @audioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore reciters and listen to the Quran'**
  String get audioSubtitle;

  /// No description provided for @audioSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search reciters or surahs...'**
  String get audioSearchHint;

  /// No description provided for @audioTabReciters.
  ///
  /// In en, this message translates to:
  /// **'Reciters'**
  String get audioTabReciters;

  /// No description provided for @audioTabSurahs.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get audioTabSurahs;

  /// No description provided for @audioNowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get audioNowPlaying;

  /// No description provided for @audioActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get audioActive;

  /// No description provided for @audioVerses.
  ///
  /// In en, this message translates to:
  /// **'verses'**
  String get audioVerses;

  /// No description provided for @hifzTitle.
  ///
  /// In en, this message translates to:
  /// **'Memorization'**
  String get hifzTitle;

  /// No description provided for @hifzSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track your Hifz journey'**
  String get hifzSubtitle;

  /// No description provided for @hifzDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get hifzDayStreak;

  /// No description provided for @hifzBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best streak'**
  String get hifzBestStreak;

  /// No description provided for @hifzSabaq.
  ///
  /// In en, this message translates to:
  /// **'Sabaq'**
  String get hifzSabaq;

  /// No description provided for @hifzSabaqDesc.
  ///
  /// In en, this message translates to:
  /// **'New lessons'**
  String get hifzSabaqDesc;

  /// No description provided for @hifzSabqi.
  ///
  /// In en, this message translates to:
  /// **'Sabqi'**
  String get hifzSabqi;

  /// No description provided for @hifzSabqiDesc.
  ///
  /// In en, this message translates to:
  /// **'Recent review'**
  String get hifzSabqiDesc;

  /// No description provided for @hifzManzil.
  ///
  /// In en, this message translates to:
  /// **'Manzil'**
  String get hifzManzil;

  /// No description provided for @hifzManzilDesc.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get hifzManzilDesc;

  /// No description provided for @hifzOverall.
  ///
  /// In en, this message translates to:
  /// **'Overall Progress'**
  String get hifzOverall;

  /// No description provided for @hifzOfSurahs.
  ///
  /// In en, this message translates to:
  /// **'of 114 surahs'**
  String get hifzOfSurahs;

  /// No description provided for @hifzAllSurahs.
  ///
  /// In en, this message translates to:
  /// **'All Surahs'**
  String get hifzAllSurahs;

  /// No description provided for @hifzNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not Started'**
  String get hifzNotStarted;

  /// No description provided for @hifzLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning (Sabaq)'**
  String get hifzLearning;

  /// No description provided for @hifzReviewing.
  ///
  /// In en, this message translates to:
  /// **'Reviewing (Sabqi)'**
  String get hifzReviewing;

  /// No description provided for @hifzMemorized.
  ///
  /// In en, this message translates to:
  /// **'Memorized (Manzil)'**
  String get hifzMemorized;

  /// No description provided for @hifzMarkReviewed.
  ///
  /// In en, this message translates to:
  /// **'Mark Reviewed Today'**
  String get hifzMarkReviewed;

  /// No description provided for @hifzTotal.
  ///
  /// In en, this message translates to:
  /// **'total'**
  String get hifzTotal;

  /// No description provided for @hifzNeverReviewed.
  ///
  /// In en, this message translates to:
  /// **'Never reviewed'**
  String get hifzNeverReviewed;

  /// No description provided for @hifzLastReviewed.
  ///
  /// In en, this message translates to:
  /// **'Last reviewed:'**
  String get hifzLastReviewed;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your experience'**
  String get profileSubtitle;

  /// No description provided for @profileJourney.
  ///
  /// In en, this message translates to:
  /// **'Your Journey'**
  String get profileJourney;

  /// No description provided for @profileMemorized.
  ///
  /// In en, this message translates to:
  /// **'Memorized'**
  String get profileMemorized;

  /// No description provided for @profileLastPage.
  ///
  /// In en, this message translates to:
  /// **'Last page'**
  String get profileLastPage;

  /// No description provided for @profileAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get profileAppearance;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get profileReading;

  /// No description provided for @profileThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get profileThemeLight;

  /// No description provided for @profileThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get profileThemeDark;

  /// No description provided for @profileDefaultReciter.
  ///
  /// In en, this message translates to:
  /// **'Default Reciter'**
  String get profileDefaultReciter;

  /// No description provided for @profileDefaultReciterDesc.
  ///
  /// In en, this message translates to:
  /// **'Default reciter for audio playback'**
  String get profileDefaultReciterDesc;

  /// No description provided for @profileBookmarksTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Bookmarks'**
  String get profileBookmarksTitle;

  /// No description provided for @profileBookmarksDesc.
  ///
  /// In en, this message translates to:
  /// **'Save and organize your favorite verses'**
  String get profileBookmarksDesc;

  /// No description provided for @profileSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get profileSoon;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileAbout;

  /// No description provided for @profileVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get profileVersion;

  /// No description provided for @profileMadeWith.
  ///
  /// In en, this message translates to:
  /// **'Made with love'**
  String get profileMadeWith;

  /// No description provided for @profileCompanion.
  ///
  /// In en, this message translates to:
  /// **'A modern Quran companion'**
  String get profileCompanion;

  /// No description provided for @profileData.
  ///
  /// In en, this message translates to:
  /// **'Data Source'**
  String get profileData;

  /// No description provided for @profileReplayOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Replay Onboarding'**
  String get profileReplayOnboarding;

  /// No description provided for @profileReplayOnboardingDesc.
  ///
  /// In en, this message translates to:
  /// **'Change language and reading preference'**
  String get profileReplayOnboardingDesc;

  /// No description provided for @readingRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readingRead;

  /// No description provided for @readingTafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get readingTafsir;

  /// No description provided for @readingSelectVerse.
  ///
  /// In en, this message translates to:
  /// **'Select a verse'**
  String get readingSelectVerse;

  /// No description provided for @themeAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeAppearance;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get themeActive;

  /// No description provided for @themeFitScreen.
  ///
  /// In en, this message translates to:
  /// **'Fit Screen Height'**
  String get themeFitScreen;

  /// No description provided for @themeFitScreenDesc.
  ///
  /// In en, this message translates to:
  /// **'Auto-calculates the perfect font size to fit the entire page without scrolling.'**
  String get themeFitScreenDesc;

  /// No description provided for @themeFontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get themeFontSize;

  /// No description provided for @themeLineSpacing.
  ///
  /// In en, this message translates to:
  /// **'Line Spacing'**
  String get themeLineSpacing;

  /// No description provided for @themeTextAlign.
  ///
  /// In en, this message translates to:
  /// **'Text Align'**
  String get themeTextAlign;

  /// No description provided for @themeContentAlign.
  ///
  /// In en, this message translates to:
  /// **'Content Align'**
  String get themeContentAlign;

  /// No description provided for @themeOverlayTypo.
  ///
  /// In en, this message translates to:
  /// **'Overlay Typography'**
  String get themeOverlayTypo;

  /// No description provided for @themeOpacity.
  ///
  /// In en, this message translates to:
  /// **'Opacity'**
  String get themeOpacity;

  /// No description provided for @themeOverlayIndicators.
  ///
  /// In en, this message translates to:
  /// **'Overlay Indicators'**
  String get themeOverlayIndicators;

  /// No description provided for @themeAlternateInfo.
  ///
  /// In en, this message translates to:
  /// **'Alternate Info Layout per Page'**
  String get themeAlternateInfo;

  /// No description provided for @themeShowHizb.
  ///
  /// In en, this message translates to:
  /// **'Show Hizb Info'**
  String get themeShowHizb;

  /// No description provided for @themeShowJuz.
  ///
  /// In en, this message translates to:
  /// **'Show Juz Info'**
  String get themeShowJuz;

  /// No description provided for @themeShowBookIcon.
  ///
  /// In en, this message translates to:
  /// **'Show Book Icon Indicator'**
  String get themeShowBookIcon;

  /// No description provided for @themePageShadow.
  ///
  /// In en, this message translates to:
  /// **'Page Shadow Effects'**
  String get themePageShadow;

  /// No description provided for @themeCenterSpine.
  ///
  /// In en, this message translates to:
  /// **'Center Spine'**
  String get themeCenterSpine;

  /// No description provided for @themeOuterEdge.
  ///
  /// In en, this message translates to:
  /// **'Outer Edge'**
  String get themeOuterEdge;

  /// No description provided for @themeIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get themeIntensity;

  /// No description provided for @themeSpineWidth.
  ///
  /// In en, this message translates to:
  /// **'Spine Width'**
  String get themeSpineWidth;

  /// No description provided for @themeEdgeWidth.
  ///
  /// In en, this message translates to:
  /// **'Edge Width'**
  String get themeEdgeWidth;

  /// No description provided for @themeSpinePadding.
  ///
  /// In en, this message translates to:
  /// **'Spine Padding'**
  String get themeSpinePadding;

  /// No description provided for @themeEdgePadding.
  ///
  /// In en, this message translates to:
  /// **'Edge Padding'**
  String get themeEdgePadding;

  /// No description provided for @themeTabAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeTabAppearance;

  /// No description provided for @themeTabSpotlight.
  ///
  /// In en, this message translates to:
  /// **'Spotlight'**
  String get themeTabSpotlight;

  /// No description provided for @themeSpotlightDesc.
  ///
  /// In en, this message translates to:
  /// **'Spotlight mode hides the Quran page during active Hifz sessions. Press down with your stylus or touch to temporarily peek at the text.'**
  String get themeSpotlightDesc;

  /// No description provided for @themeSpotlightMinRadius.
  ///
  /// In en, this message translates to:
  /// **'Base Spotlight Size'**
  String get themeSpotlightMinRadius;

  /// No description provided for @themeSpotlightMidRadius.
  ///
  /// In en, this message translates to:
  /// **'Mid-point Peek Size'**
  String get themeSpotlightMidRadius;

  /// No description provided for @themeSpotlightSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Pressure Sensitivity'**
  String get themeSpotlightSensitivity;

  /// No description provided for @themeSpotlightMaskOpacity.
  ///
  /// In en, this message translates to:
  /// **'Mask Opacity'**
  String get themeSpotlightMaskOpacity;

  /// No description provided for @themeSpotlightFeathering.
  ///
  /// In en, this message translates to:
  /// **'Feathering (Softness)'**
  String get themeSpotlightFeathering;

  /// No description provided for @themeSpotlightCurve.
  ///
  /// In en, this message translates to:
  /// **'Pressure Scaling Curve'**
  String get themeSpotlightCurve;

  /// No description provided for @themeSpotlightCurveLinear.
  ///
  /// In en, this message translates to:
  /// **'Linear'**
  String get themeSpotlightCurveLinear;

  /// No description provided for @themeSpotlightCurveQuadratic.
  ///
  /// In en, this message translates to:
  /// **'Quadratic'**
  String get themeSpotlightCurveQuadratic;

  /// No description provided for @themeSpotlightCurveQuartic.
  ///
  /// In en, this message translates to:
  /// **'Quartic'**
  String get themeSpotlightCurveQuartic;

  /// No description provided for @themeSpotlightCurveDualZone.
  ///
  /// In en, this message translates to:
  /// **'Dual-Zone'**
  String get themeSpotlightCurveDualZone;

  /// No description provided for @werdSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Your Daily Werd'**
  String get werdSetTitle;

  /// No description provided for @werdSetDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a daily recitation goal to\nstay consistent with your reading'**
  String get werdSetDesc;

  /// No description provided for @werdGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get werdGetStarted;

  /// No description provided for @werdDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily Werd'**
  String get werdDaily;

  /// No description provided for @werdComplete.
  ///
  /// In en, this message translates to:
  /// **'Masha\'Allah!'**
  String get werdComplete;

  /// No description provided for @werdCompleteDesc.
  ///
  /// In en, this message translates to:
  /// **'You completed your daily werd'**
  String get werdCompleteDesc;

  /// No description provided for @werdPagesOf.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get werdPagesOf;

  /// No description provided for @werdPagesLabel.
  ///
  /// In en, this message translates to:
  /// **'pages'**
  String get werdPagesLabel;

  /// No description provided for @werdPagesRemaining.
  ///
  /// In en, this message translates to:
  /// **'pages remaining today'**
  String get werdPagesRemaining;

  /// No description provided for @werdPagesRange.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get werdPagesRange;

  /// No description provided for @werdStartReading.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get werdStartReading;

  /// No description provided for @werdSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Werd Setup'**
  String get werdSetupTitle;

  /// No description provided for @werdSetupDesc.
  ///
  /// In en, this message translates to:
  /// **'Set your daily Quran reading goal'**
  String get werdSetupDesc;

  /// No description provided for @werdFixedRange.
  ///
  /// In en, this message translates to:
  /// **'Fixed Range'**
  String get werdFixedRange;

  /// No description provided for @werdDailyPages.
  ///
  /// In en, this message translates to:
  /// **'Daily Pages'**
  String get werdDailyPages;

  /// No description provided for @werdFromPage.
  ///
  /// In en, this message translates to:
  /// **'From Page'**
  String get werdFromPage;

  /// No description provided for @werdToPage.
  ///
  /// In en, this message translates to:
  /// **'To Page'**
  String get werdToPage;

  /// No description provided for @werdPagesPerDay.
  ///
  /// In en, this message translates to:
  /// **'Pages per day'**
  String get werdPagesPerDay;

  /// No description provided for @werd_1Page.
  ///
  /// In en, this message translates to:
  /// **'1 page'**
  String get werd_1Page;

  /// No description provided for @werd_30Pages.
  ///
  /// In en, this message translates to:
  /// **'30 pages'**
  String get werd_30Pages;

  /// No description provided for @werdSave.
  ///
  /// In en, this message translates to:
  /// **'Save Werd'**
  String get werdSave;

  /// No description provided for @werdSummaryFixed.
  ///
  /// In en, this message translates to:
  /// **'Read {pages} pages daily (Pages {start}–{end})'**
  String werdSummaryFixed(Object end, Object pages, Object start);

  /// No description provided for @werdSummaryDaily.
  ///
  /// In en, this message translates to:
  /// **'Read {pages} pages daily ≈ {days} days to finish'**
  String werdSummaryDaily(Object days, Object pages);

  /// No description provided for @werdErrorRange.
  ///
  /// In en, this message translates to:
  /// **'Start page must be before end page'**
  String get werdErrorRange;

  /// No description provided for @navIndex.
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get navIndex;

  /// No description provided for @navTabSurah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get navTabSurah;

  /// No description provided for @navTabJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get navTabJuz;

  /// No description provided for @navTabBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get navTabBookmarks;

  /// No description provided for @navSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search surah name or number...'**
  String get navSearchHint;

  /// No description provided for @navJuzComing.
  ///
  /// In en, this message translates to:
  /// **'Juz list coming soon'**
  String get navJuzComing;

  /// No description provided for @navAyahs.
  ///
  /// In en, this message translates to:
  /// **'Ayahs'**
  String get navAyahs;

  /// No description provided for @navNoBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get navNoBookmarks;

  /// No description provided for @navBookmarkHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark icon on any surah'**
  String get navBookmarkHint;

  /// No description provided for @navPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get navPage;

  /// No description provided for @navPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get navPages;

  /// No description provided for @navVerses.
  ///
  /// In en, this message translates to:
  /// **'Verses'**
  String get navVerses;

  /// No description provided for @navNoPageBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No page bookmarks yet'**
  String get navNoPageBookmarks;

  /// No description provided for @navPageBookmarkHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark icon in the top bar\nwhile reading to save a page'**
  String get navPageBookmarkHint;

  /// No description provided for @navNoVerseBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No verse bookmarks yet'**
  String get navNoVerseBookmarks;

  /// No description provided for @navVerseBookmarkHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press any verse and tap the\nbookmark icon to save it'**
  String get navVerseBookmarkHint;

  /// No description provided for @bmEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Bookmark'**
  String get bmEditTitle;

  /// No description provided for @bmColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get bmColor;

  /// No description provided for @bmNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get bmNote;

  /// No description provided for @bmNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a personal note...'**
  String get bmNoteHint;

  /// No description provided for @bmCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get bmCollection;

  /// No description provided for @bmUncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get bmUncategorized;

  /// No description provided for @bmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Bookmark'**
  String get bmDelete;

  /// No description provided for @bmAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get bmAll;

  /// No description provided for @bmNewCollection.
  ///
  /// In en, this message translates to:
  /// **'New Collection'**
  String get bmNewCollection;

  /// No description provided for @bmCollectionNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Favorite Duas'**
  String get bmCollectionNameHint;

  /// No description provided for @bmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bmCancel;

  /// No description provided for @bmCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get bmCreate;

  /// No description provided for @bmAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get bmAdd;

  /// No description provided for @bmRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get bmRename;

  /// No description provided for @bmDeleteCollection.
  ///
  /// In en, this message translates to:
  /// **'Delete Collection'**
  String get bmDeleteCollection;

  /// No description provided for @bmSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get bmSave;

  /// No description provided for @reciterTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Reciter'**
  String get reciterTitle;

  /// No description provided for @reciterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by reciter name...'**
  String get reciterSearchHint;

  /// No description provided for @reciterTabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get reciterTabFavorites;

  /// No description provided for @reciterTabRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get reciterTabRecent;

  /// No description provided for @reciterTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reciterTabAll;

  /// No description provided for @reciterHafs.
  ///
  /// In en, this message translates to:
  /// **'Hafs'**
  String get reciterHafs;

  /// No description provided for @reciterWarsh.
  ///
  /// In en, this message translates to:
  /// **'Warsh'**
  String get reciterWarsh;

  /// No description provided for @reciterStyleAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reciterStyleAll;

  /// No description provided for @reciterRecitation.
  ///
  /// In en, this message translates to:
  /// **'Recitation'**
  String get reciterRecitation;

  /// No description provided for @reciterStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get reciterStandard;

  /// No description provided for @reciterNoFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorite reciters yet'**
  String get reciterNoFavorites;

  /// No description provided for @reciterNoRecent.
  ///
  /// In en, this message translates to:
  /// **'No recent reciters'**
  String get reciterNoRecent;

  /// No description provided for @reciterNoFound.
  ///
  /// In en, this message translates to:
  /// **'No reciters found'**
  String get reciterNoFound;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search surah name or number...'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get searchNoResults;

  /// No description provided for @audioSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Audio Settings'**
  String get audioSettingsTitle;

  /// No description provided for @audioPlaybackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Playback Speed'**
  String get audioPlaybackSpeed;

  /// No description provided for @audioRepeatMode.
  ///
  /// In en, this message translates to:
  /// **'Repeat Mode'**
  String get audioRepeatMode;

  /// No description provided for @audioRepeatOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get audioRepeatOff;

  /// No description provided for @audioRepeatVerse.
  ///
  /// In en, this message translates to:
  /// **'Verse'**
  String get audioRepeatVerse;

  /// No description provided for @audioRepeatTimes.
  ///
  /// In en, this message translates to:
  /// **'Repeat times'**
  String get audioRepeatTimes;

  /// No description provided for @audioSyncCompensation.
  ///
  /// In en, this message translates to:
  /// **'Sync Calibration'**
  String get audioSyncCompensation;

  /// No description provided for @audioSyncCompensationDesc.
  ///
  /// In en, this message translates to:
  /// **'Adjust if the highlighted words don\'t match the voice (e.g. over Bluetooth).'**
  String get audioSyncCompensationDesc;

  /// No description provided for @audioSyncAdvance.
  ///
  /// In en, this message translates to:
  /// **'← Advance Highlight'**
  String get audioSyncAdvance;

  /// No description provided for @audioSyncDelay.
  ///
  /// In en, this message translates to:
  /// **'Delay Highlight →'**
  String get audioSyncDelay;

  /// No description provided for @readingJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz'**
  String get readingJuz;

  /// No description provided for @readingHizb.
  ///
  /// In en, this message translates to:
  /// **'Hizb'**
  String get readingHizb;

  /// No description provided for @readingVerse.
  ///
  /// In en, this message translates to:
  /// **'Verse'**
  String get readingVerse;

  /// No description provided for @readingPlaying.
  ///
  /// In en, this message translates to:
  /// **'Playing...'**
  String get readingPlaying;

  /// No description provided for @readingPageNa.
  ///
  /// In en, this message translates to:
  /// **'Page not available'**
  String get readingPageNa;

  /// No description provided for @practiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practiceTitle;

  /// No description provided for @practiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Strengthen your memorization'**
  String get practiceSubtitle;

  /// No description provided for @practiceComingTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get practiceComingTitle;

  /// No description provided for @practiceComingDesc.
  ///
  /// In en, this message translates to:
  /// **'Flashcards and mutashabihat drills to reinforce your memorization journey.'**
  String get practiceComingDesc;

  /// No description provided for @practiceFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get practiceFlashcards;

  /// No description provided for @practiceMutashabihat.
  ///
  /// In en, this message translates to:
  /// **'Mutashabihat'**
  String get practiceMutashabihat;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @updateWhatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s New'**
  String get updateWhatsNew;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get updateDownloading;

  /// No description provided for @updateError.
  ///
  /// In en, this message translates to:
  /// **'Update failed. Please try again later.'**
  String get updateError;

  /// No description provided for @updateInstall.
  ///
  /// In en, this message translates to:
  /// **'Install Now'**
  String get updateInstall;

  /// No description provided for @updateReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to Install'**
  String get updateReady;

  /// No description provided for @assessBuildProfile.
  ///
  /// In en, this message translates to:
  /// **'Let\\\'s build your Hifz profile'**
  String get assessBuildProfile;

  /// No description provided for @assessQuickQuestions.
  ///
  /// In en, this message translates to:
  /// **'A few quick questions to personalize your journey'**
  String get assessQuickQuestions;

  /// No description provided for @assessNameHint.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get assessNameHint;

  /// No description provided for @assessChooseAvatar.
  ///
  /// In en, this message translates to:
  /// **'Choose an avatar'**
  String get assessChooseAvatar;

  /// No description provided for @assessHowOld.
  ///
  /// In en, this message translates to:
  /// **'How old are you?'**
  String get assessHowOld;

  /// No description provided for @assessAgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us tailor session length, load, and pace'**
  String get assessAgeSubtitle;

  /// No description provided for @assessAgeAuto.
  ///
  /// In en, this message translates to:
  /// **'Your age group is auto-detected'**
  String get assessAgeAuto;

  /// No description provided for @assessWhereJourney.
  ///
  /// In en, this message translates to:
  /// **'Where are you in your Hifz journey?'**
  String get assessWhereJourney;

  /// No description provided for @assessShapesPlan.
  ///
  /// In en, this message translates to:
  /// **'This shapes your starting plan'**
  String get assessShapesPlan;

  /// No description provided for @assessFresh.
  ///
  /// In en, this message translates to:
  /// **'Starting fresh'**
  String get assessFresh;

  /// No description provided for @assessFreshDesc.
  ///
  /// In en, this message translates to:
  /// **'I haven\\\'t memorized before or starting over'**
  String get assessFreshDesc;

  /// No description provided for @assessResuming.
  ///
  /// In en, this message translates to:
  /// **'Resuming'**
  String get assessResuming;

  /// No description provided for @assessResumingDesc.
  ///
  /// In en, this message translates to:
  /// **'I memorized some before and want to continue'**
  String get assessResumingDesc;

  /// No description provided for @assessReviewing.
  ///
  /// In en, this message translates to:
  /// **'Reviewing'**
  String get assessReviewing;

  /// No description provided for @assessReviewingDesc.
  ///
  /// In en, this message translates to:
  /// **'I\\\'ve memorized a lot and need to strengthen it'**
  String get assessReviewingDesc;

  /// No description provided for @assessWhatHelps.
  ///
  /// In en, this message translates to:
  /// **'When you memorize something new, what helps most?'**
  String get assessWhatHelps;

  /// No description provided for @assessNoWrong.
  ///
  /// In en, this message translates to:
  /// **'Pick the one that resonates — no wrong answers!'**
  String get assessNoWrong;

  /// No description provided for @assessPrefVisual.
  ///
  /// In en, this message translates to:
  /// **'Looking and reading'**
  String get assessPrefVisual;

  /// No description provided for @assessPrefVisualDesc.
  ///
  /// In en, this message translates to:
  /// **'I stare at the text until it sticks'**
  String get assessPrefVisualDesc;

  /// No description provided for @assessPrefWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing it down'**
  String get assessPrefWriting;

  /// No description provided for @assessPrefWritingDesc.
  ///
  /// In en, this message translates to:
  /// **'Writing helps me remember'**
  String get assessPrefWritingDesc;

  /// No description provided for @assessPrefVerbal.
  ///
  /// In en, this message translates to:
  /// **'Repeating out loud'**
  String get assessPrefVerbal;

  /// No description provided for @assessPrefVerbalDesc.
  ///
  /// In en, this message translates to:
  /// **'I just keep saying it until I know it'**
  String get assessPrefVerbalDesc;

  /// No description provided for @assessImaginePage.
  ///
  /// In en, this message translates to:
  /// **'Imagine memorizing a new page...'**
  String get assessImaginePage;

  /// No description provided for @assessAfter_30.
  ///
  /// In en, this message translates to:
  /// **'After 30 minutes of focused effort, how much would you typically remember?'**
  String get assessAfter_30;

  /// No description provided for @assessMostPage.
  ///
  /// In en, this message translates to:
  /// **'Most of the page'**
  String get assessMostPage;

  /// No description provided for @assessMostPageDesc.
  ///
  /// In en, this message translates to:
  /// **'I pick things up quickly'**
  String get assessMostPageDesc;

  /// No description provided for @assessHalfPage.
  ///
  /// In en, this message translates to:
  /// **'About half'**
  String get assessHalfPage;

  /// No description provided for @assessHalfPageDesc.
  ///
  /// In en, this message translates to:
  /// **'I need a few sessions to finish a page'**
  String get assessHalfPageDesc;

  /// No description provided for @assessFewLines.
  ///
  /// In en, this message translates to:
  /// **'A few lines'**
  String get assessFewLines;

  /// No description provided for @assessFewLinesDesc.
  ///
  /// In en, this message translates to:
  /// **'I prefer to go slow and careful'**
  String get assessFewLinesDesc;

  /// No description provided for @assessThinkLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Think about something you memorized last month...'**
  String get assessThinkLastMonth;

  /// No description provided for @assessIfAsked.
  ///
  /// In en, this message translates to:
  /// **'If someone asked you to recite it today, how would it go?'**
  String get assessIfAsked;

  /// No description provided for @assessPrettySmooth.
  ///
  /// In en, this message translates to:
  /// **'Pretty smoothly'**
  String get assessPrettySmooth;

  /// No description provided for @assessPrettySmoothDesc.
  ///
  /// In en, this message translates to:
  /// **'It sticks with me once I learn it'**
  String get assessPrettySmoothDesc;

  /// No description provided for @assessQuickRefresh.
  ///
  /// In en, this message translates to:
  /// **'I\\\'d need a quick refresh'**
  String get assessQuickRefresh;

  /// No description provided for @assessQuickRefreshDesc.
  ///
  /// In en, this message translates to:
  /// **'Then it comes back'**
  String get assessQuickRefreshDesc;

  /// No description provided for @assessStruggle.
  ///
  /// In en, this message translates to:
  /// **'I\\\'d struggle'**
  String get assessStruggle;

  /// No description provided for @assessStruggleDesc.
  ///
  /// In en, this message translates to:
  /// **'Things fade if I don\\\'t review regularly'**
  String get assessStruggleDesc;

  /// No description provided for @assessDailyCommit.
  ///
  /// In en, this message translates to:
  /// **'Your daily commitment'**
  String get assessDailyCommit;

  /// No description provided for @assessHowMuchTime.
  ///
  /// In en, this message translates to:
  /// **'How much time can you dedicate each day?'**
  String get assessHowMuchTime;

  /// No description provided for @assessPrefTime.
  ///
  /// In en, this message translates to:
  /// **'Preferred time'**
  String get assessPrefTime;

  /// No description provided for @assessWhichDays.
  ///
  /// In en, this message translates to:
  /// **'Which days will you study?'**
  String get assessWhichDays;

  /// No description provided for @assessTapToggle.
  ///
  /// In en, this message translates to:
  /// **'Tap to toggle — rest days are important too!'**
  String get assessTapToggle;

  /// No description provided for @assessGoalPace.
  ///
  /// In en, this message translates to:
  /// **'Your goal & pace'**
  String get assessGoalPace;

  /// No description provided for @assessWhatMemorize.
  ///
  /// In en, this message translates to:
  /// **'What do you want to memorize and how fast?'**
  String get assessWhatMemorize;

  /// No description provided for @assessWhatAim.
  ///
  /// In en, this message translates to:
  /// **'What\\\'s your aim?'**
  String get assessWhatAim;

  /// No description provided for @assessEntireQuran.
  ///
  /// In en, this message translates to:
  /// **'The entire Quran'**
  String get assessEntireQuran;

  /// No description provided for @assessEntireQuranDesc.
  ///
  /// In en, this message translates to:
  /// **'Full memorization journey'**
  String get assessEntireQuranDesc;

  /// No description provided for @assessSpecificJuz.
  ///
  /// In en, this message translates to:
  /// **'Specific Juz'**
  String get assessSpecificJuz;

  /// No description provided for @assessSpecificJuzDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose which juz to memorize'**
  String get assessSpecificJuzDesc;

  /// No description provided for @assessSpecificSurah.
  ///
  /// In en, this message translates to:
  /// **'Specific Surahs'**
  String get assessSpecificSurah;

  /// No description provided for @assessSpecificSurahDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick individual surahs'**
  String get assessSpecificSurahDesc;

  /// No description provided for @assessHowFast.
  ///
  /// In en, this message translates to:
  /// **'How fast do you want to go?'**
  String get assessHowFast;

  /// No description provided for @assessPushMe.
  ///
  /// In en, this message translates to:
  /// **'Push me'**
  String get assessPushMe;

  /// No description provided for @assessPushMeDesc.
  ///
  /// In en, this message translates to:
  /// **'Higher load, faster progression'**
  String get assessPushMeDesc;

  /// No description provided for @assessBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced and consistent'**
  String get assessBalanced;

  /// No description provided for @assessBalancedDesc.
  ///
  /// In en, this message translates to:
  /// **'Lighter load, focus on retention'**
  String get assessBalancedDesc;

  /// No description provided for @assessChooseQari.
  ///
  /// In en, this message translates to:
  /// **'Choose your Qari'**
  String get assessChooseQari;

  /// No description provided for @assessStickingOne.
  ///
  /// In en, this message translates to:
  /// **'Sticking with one reciter helps build stronger auditory memory'**
  String get assessStickingOne;

  /// No description provided for @assessLoadingReciters.
  ///
  /// In en, this message translates to:
  /// **'Loading reciters...'**
  String get assessLoadingReciters;

  /// No description provided for @assessWhereStart.
  ///
  /// In en, this message translates to:
  /// **'Where would you like to start?'**
  String get assessWhereStart;

  /// No description provided for @assessPickAny.
  ///
  /// In en, this message translates to:
  /// **'Pick any page or surah — you\\\'re in full control'**
  String get assessPickAny;

  /// No description provided for @assessJuz_30.
  ///
  /// In en, this message translates to:
  /// **'Juz 30 (Juz \\\'Amma)'**
  String get assessJuz_30;

  /// No description provided for @assessJuz_30Desc.
  ///
  /// In en, this message translates to:
  /// **'Most common starting point — Page 582'**
  String get assessJuz_30Desc;

  /// No description provided for @assessSurahBaqarah.
  ///
  /// In en, this message translates to:
  /// **'Surah Al-Baqarah'**
  String get assessSurahBaqarah;

  /// No description provided for @assessSurahBaqarahDesc.
  ///
  /// In en, this message translates to:
  /// **'Start from the beginning — Page 2'**
  String get assessSurahBaqarahDesc;

  /// No description provided for @assessPickSpecific.
  ///
  /// In en, this message translates to:
  /// **'Or pick a specific page (1-604)'**
  String get assessPickSpecific;

  /// No description provided for @assessYourPlan.
  ///
  /// In en, this message translates to:
  /// **'Your Plan'**
  String get assessYourPlan;

  /// No description provided for @assessActiveDays.
  ///
  /// In en, this message translates to:
  /// **'Active days'**
  String get assessActiveDays;

  /// No description provided for @assessDailyNew.
  ///
  /// In en, this message translates to:
  /// **'Daily new material'**
  String get assessDailyNew;

  /// No description provided for @assessTargetReps.
  ///
  /// In en, this message translates to:
  /// **'Target repetitions'**
  String get assessTargetReps;

  /// No description provided for @assessTimeSplit.
  ///
  /// In en, this message translates to:
  /// **'Time split'**
  String get assessTimeSplit;

  /// No description provided for @assessStartingAt.
  ///
  /// In en, this message translates to:
  /// **'Starting at'**
  String get assessStartingAt;

  /// No description provided for @assessEstTimeline.
  ///
  /// In en, this message translates to:
  /// **'Estimated Timeline'**
  String get assessEstTimeline;

  /// No description provided for @assessStartJourney.
  ///
  /// In en, this message translates to:
  /// **'Start My Journey'**
  String get assessStartJourney;

  /// No description provided for @assessYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Your Memory Profile'**
  String get assessYourProfile;

  /// No description provided for @assessContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue →'**
  String get assessContinue;

  /// No description provided for @homeGreatWork.
  ///
  /// In en, this message translates to:
  /// **'Great work today!'**
  String get homeGreatWork;

  /// No description provided for @homeBeginJourney.
  ///
  /// In en, this message translates to:
  /// **'Begin your memorization journey today'**
  String get homeBeginJourney;

  /// No description provided for @homeJourneyAwaits.
  ///
  /// In en, this message translates to:
  /// **'Your journey awaits'**
  String get homeJourneyAwaits;

  /// No description provided for @homeTapBelow.
  ///
  /// In en, this message translates to:
  /// **'Tap below to generate today\\\'s plan'**
  String get homeTapBelow;

  /// No description provided for @homeGeneratePlan.
  ///
  /// In en, this message translates to:
  /// **'Generate Plan'**
  String get homeGeneratePlan;

  /// No description provided for @homeAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your progress'**
  String get homeAnalyzing;

  /// No description provided for @homeGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating your plan'**
  String get homeGenerating;

  /// No description provided for @homeValidating.
  ///
  /// In en, this message translates to:
  /// **'Validating & optimizing'**
  String get homeValidating;

  /// No description provided for @homeAiPreparing.
  ///
  /// In en, this message translates to:
  /// **'AI is preparing your plan'**
  String get homeAiPreparing;

  /// No description provided for @homeWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get homeWelcomeBack;

  /// No description provided for @homeLetsGo.
  ///
  /// In en, this message translates to:
  /// **'Let\\\'s Go!'**
  String get homeLetsGo;

  /// No description provided for @pracMutashabihat.
  ///
  /// In en, this message translates to:
  /// **'Mutashabihat'**
  String get pracMutashabihat;

  /// No description provided for @pracSpotDiff.
  ///
  /// In en, this message translates to:
  /// **'Spot Diff'**
  String get pracSpotDiff;

  /// No description provided for @pracTapReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal similar verse'**
  String get pracTapReveal;

  /// No description provided for @pracReadContext.
  ///
  /// In en, this message translates to:
  /// **'اقرأ الآيات في سياقها'**
  String get pracReadContext;

  /// No description provided for @pracHafsScript.
  ///
  /// In en, this message translates to:
  /// **'KFGQPC Uthmanic Script HAFS'**
  String get pracHafsScript;

  /// No description provided for @pracNoDiffWords.
  ///
  /// In en, this message translates to:
  /// **'No distinguishing words available for this pair.'**
  String get pracNoDiffWords;

  /// No description provided for @pracCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get pracCorrect;

  /// No description provided for @pracWrong.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get pracWrong;

  /// No description provided for @pracNext.
  ///
  /// In en, this message translates to:
  /// **'Next →'**
  String get pracNext;

  /// No description provided for @pracComplete.
  ///
  /// In en, this message translates to:
  /// **'Practice Complete!'**
  String get pracComplete;

  /// No description provided for @pracNoMut.
  ///
  /// In en, this message translates to:
  /// **'No mutashabihat loaded yet'**
  String get pracNoMut;

  /// No description provided for @pracCheckConn.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get pracCheckConn;

  /// No description provided for @pracStrengthen.
  ///
  /// In en, this message translates to:
  /// **'Strengthen your memorization'**
  String get pracStrengthen;

  /// No description provided for @pracRegenCards.
  ///
  /// In en, this message translates to:
  /// **'Regenerate all cards'**
  String get pracRegenCards;

  /// No description provided for @pracMixedReview.
  ///
  /// In en, this message translates to:
  /// **'Mixed Review'**
  String get pracMixedReview;

  /// No description provided for @pracMixedReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} cards · ~{minutes} min · All types'**
  String pracMixedReviewSubtitle(int count, int minutes);

  /// No description provided for @pracAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get pracAllCaughtUp;

  /// No description provided for @pracNoFlashcards.
  ///
  /// In en, this message translates to:
  /// **'No flashcards due right now'**
  String get pracNoFlashcards;

  /// No description provided for @pracNextVerse.
  ///
  /// In en, this message translates to:
  /// **'Next Verse'**
  String get pracNextVerse;

  /// No description provided for @pracPrevVerse.
  ///
  /// In en, this message translates to:
  /// **'Previous Verse'**
  String get pracPrevVerse;

  /// No description provided for @pracCompleteIt.
  ///
  /// In en, this message translates to:
  /// **'Complete It'**
  String get pracCompleteIt;

  /// No description provided for @pracSurahDetective.
  ///
  /// In en, this message translates to:
  /// **'Surah Detective'**
  String get pracSurahDetective;

  /// No description provided for @pracSequence.
  ///
  /// In en, this message translates to:
  /// **'Sequence'**
  String get pracSequence;

  /// No description provided for @pracMutArabic.
  ///
  /// In en, this message translates to:
  /// **'Similar verses'**
  String get pracMutArabic;

  /// No description provided for @pracMutSimilar.
  ///
  /// In en, this message translates to:
  /// **'Mutashabihat (Similar Verses)'**
  String get pracMutSimilar;

  /// No description provided for @pracBrowseStudy.
  ///
  /// In en, this message translates to:
  /// **'Browse, study & practice'**
  String get pracBrowseStudy;

  /// No description provided for @pracBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get pracBrowse;

  /// No description provided for @pracPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get pracPractice;

  /// No description provided for @pracTotalCards.
  ///
  /// In en, this message translates to:
  /// **'Total cards'**
  String get pracTotalCards;

  /// No description provided for @pracCreateProfileUnlock.
  ///
  /// In en, this message translates to:
  /// **'Create a Hifz profile to unlock flashcards'**
  String get pracCreateProfileUnlock;

  /// No description provided for @assessAgeChild.
  ///
  /// In en, this message translates to:
  /// **'Child (7-12)'**
  String get assessAgeChild;

  /// No description provided for @assessAgeTeen.
  ///
  /// In en, this message translates to:
  /// **'Teen (13-17)'**
  String get assessAgeTeen;

  /// No description provided for @assessAgeYoungAdult.
  ///
  /// In en, this message translates to:
  /// **'Young Adult (18-30)'**
  String get assessAgeYoungAdult;

  /// No description provided for @assessAgeAdult.
  ///
  /// In en, this message translates to:
  /// **'Adult (31-45)'**
  String get assessAgeAdult;

  /// No description provided for @assessAgeMiddle.
  ///
  /// In en, this message translates to:
  /// **'Middle-Aged (46-55)'**
  String get assessAgeMiddle;

  /// No description provided for @assessAgeSenior.
  ///
  /// In en, this message translates to:
  /// **'Senior (56-70)'**
  String get assessAgeSenior;

  /// No description provided for @assessAgeElderly.
  ///
  /// In en, this message translates to:
  /// **'Elderly (71+)'**
  String get assessAgeElderly;

  /// No description provided for @assessOnePage.
  ///
  /// In en, this message translates to:
  /// **'1 page'**
  String get assessOnePage;

  /// No description provided for @assessOneTwoPages.
  ///
  /// In en, this message translates to:
  /// **'1-2 pages'**
  String get assessOneTwoPages;

  /// No description provided for @assessTwoThreePages.
  ///
  /// In en, this message translates to:
  /// **'2-3 pages'**
  String get assessTwoThreePages;

  /// No description provided for @assessTwoThreeLines.
  ///
  /// In en, this message translates to:
  /// **'2-3 lines'**
  String get assessTwoThreeLines;

  /// No description provided for @assessThreeFiveLines.
  ///
  /// In en, this message translates to:
  /// **'3-5 lines'**
  String get assessThreeFiveLines;

  /// No description provided for @assessFiveEightLines.
  ///
  /// In en, this message translates to:
  /// **'5-8 lines'**
  String get assessFiveEightLines;

  /// No description provided for @assessOnePageLines.
  ///
  /// In en, this message translates to:
  /// **'1 page (15 lines)'**
  String get assessOnePageLines;

  /// No description provided for @assessThirtyPerSection.
  ///
  /// In en, this message translates to:
  /// **'30+ per section'**
  String get assessThirtyPerSection;

  /// No description provided for @assessTwentyPerSection.
  ///
  /// In en, this message translates to:
  /// **'20 per section'**
  String get assessTwentyPerSection;

  /// No description provided for @assessFifteenPerSection.
  ///
  /// In en, this message translates to:
  /// **'15 per section'**
  String get assessFifteenPerSection;

  /// No description provided for @assessTheEntireQuran.
  ///
  /// In en, this message translates to:
  /// **'the entire Quran'**
  String get assessTheEntireQuran;

  /// No description provided for @assessYourSelectedSurahs.
  ///
  /// In en, this message translates to:
  /// **'your selected surahs'**
  String get assessYourSelectedSurahs;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get syncError;

  /// No description provided for @syncIdle.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncIdle;

  /// No description provided for @profileAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get profileAccountDeleted;

  /// No description provided for @profileError.
  ///
  /// In en, this message translates to:
  /// **'Error occurred'**
  String get profileError;

  /// No description provided for @profileSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get profileSyncing;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @profileProgressReset.
  ///
  /// In en, this message translates to:
  /// **'Progress reset successfully'**
  String get profileProgressReset;

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @progressDays.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get progressDays;

  /// No description provided for @progressLast.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get progressLast;

  /// No description provided for @timeMin.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get timeMin;

  /// No description provided for @reportSame.
  ///
  /// In en, this message translates to:
  /// **'Same as last week'**
  String get reportSame;

  /// No description provided for @homePlanComplete.
  ///
  /// In en, this message translates to:
  /// **'Plan Complete'**
  String get homePlanComplete;

  /// No description provided for @homeStartExtra.
  ///
  /// In en, this message translates to:
  /// **'Start Extra Session'**
  String get homeStartExtra;

  /// No description provided for @homeSwitchProfile.
  ///
  /// In en, this message translates to:
  /// **'Switch Profile'**
  String get homeSwitchProfile;

  /// No description provided for @homeCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get homeCreateProfile;

  /// No description provided for @homePreparingPlan.
  ///
  /// In en, this message translates to:
  /// **'Preparing Plan'**
  String get homePreparingPlan;

  /// No description provided for @syncSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing'**
  String get syncSyncing;

  /// No description provided for @syncSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncSynced;

  /// No description provided for @hifzNoPlanAvailable.
  ///
  /// In en, this message translates to:
  /// **'No plan available'**
  String get hifzNoPlanAvailable;

  /// No description provided for @hifzNoActiveProfile.
  ///
  /// In en, this message translates to:
  /// **'No active profile'**
  String get hifzNoActiveProfile;

  /// No description provided for @sessionLastVerseLearned.
  ///
  /// In en, this message translates to:
  /// **'Last verse learned'**
  String get sessionLastVerseLearned;

  /// No description provided for @sessionExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit Session?'**
  String get sessionExitTitle;

  /// No description provided for @sessionExitDesc.
  ///
  /// In en, this message translates to:
  /// **'Your progress will be lost.'**
  String get sessionExitDesc;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get actionExit;

  /// No description provided for @sharePrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Privacy notice'**
  String get sharePrivacyNotice;

  /// No description provided for @homeWeeklyInsights.
  ///
  /// In en, this message translates to:
  /// **'Weekly Insights'**
  String get homeWeeklyInsights;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionVs.
  ///
  /// In en, this message translates to:
  /// **'Vs'**
  String get actionVs;

  /// No description provided for @profileNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotificationsTitle;

  /// No description provided for @profileSessionReminders.
  ///
  /// In en, this message translates to:
  /// **'Session Reminders'**
  String get profileSessionReminders;

  /// No description provided for @profileSessionRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Daily notification for your Hifz session'**
  String get profileSessionRemindersDesc;

  /// No description provided for @profileSocialSharingSection.
  ///
  /// In en, this message translates to:
  /// **'Social & Sharing'**
  String get profileSocialSharingSection;

  /// No description provided for @profileAccountabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Accountability & Sharing'**
  String get profileAccountabilityTitle;

  /// No description provided for @profileAccountabilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Share progress with friends and teachers'**
  String get profileAccountabilityDesc;

  /// No description provided for @profileHifzSection.
  ///
  /// In en, this message translates to:
  /// **'Hifz Profile'**
  String get profileHifzSection;

  /// No description provided for @profileRetakeAssessment.
  ///
  /// In en, this message translates to:
  /// **'Retake Assessment'**
  String get profileRetakeAssessment;

  /// No description provided for @profileRetakeAssessmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your memory profile settings'**
  String get profileRetakeAssessmentDesc;

  /// No description provided for @profileAiModel.
  ///
  /// In en, this message translates to:
  /// **'AI Model'**
  String get profileAiModel;

  /// No description provided for @profileAiModelFlash.
  ///
  /// In en, this message translates to:
  /// **'Gemini 3.1 Flash (fast)'**
  String get profileAiModelFlash;

  /// No description provided for @profileAiModelPro.
  ///
  /// In en, this message translates to:
  /// **'Gemini 3.1 Pro (smart)'**
  String get profileAiModelPro;

  /// No description provided for @profileResetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset Progress'**
  String get profileResetProgress;

  /// No description provided for @profileResetProgressDesc.
  ///
  /// In en, this message translates to:
  /// **'Erase all sessions & progress, keep profile'**
  String get profileResetProgressDesc;

  /// No description provided for @profileDeleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete Profile'**
  String get profileDeleteProfile;

  /// No description provided for @profileDeleteProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove everything and start over'**
  String get profileDeleteProfileDesc;

  /// No description provided for @profileCloudAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Cloud & Account'**
  String get profileCloudAccountSection;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @profileSignOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out?'**
  String get profileSignOutDialogTitle;

  /// No description provided for @profileSignOutDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Your data will remain saved locally and in the cloud. You can sign back in anytime.'**
  String get profileSignOutDialogDesc;

  /// No description provided for @profileActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileActionCancel;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get profileDeleteAccountDialogTitle;

  /// No description provided for @profileDeleteAccountDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your cloud data and Google account link. Your local data will remain on this device.'**
  String get profileDeleteAccountDialogDesc;

  /// No description provided for @profileSignInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get profileSignInGoogle;

  /// No description provided for @profileSignInGoogleDesc.
  ///
  /// In en, this message translates to:
  /// **'Back up and sync your data across devices'**
  String get profileSignInGoogleDesc;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @pracPracticeTab.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get pracPracticeTab;

  /// No description provided for @pracAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get pracAccuracy;

  /// No description provided for @progYourProgress.
  ///
  /// In en, this message translates to:
  /// **'Your Progress'**
  String get progYourProgress;

  /// No description provided for @progOfQuran.
  ///
  /// In en, this message translates to:
  /// **'of Quran'**
  String get progOfQuran;

  /// No description provided for @progPages.
  ///
  /// In en, this message translates to:
  /// **'pages'**
  String get progPages;

  /// No description provided for @progMemorized.
  ///
  /// In en, this message translates to:
  /// **'Memorized'**
  String get progMemorized;

  /// No description provided for @progReviewing.
  ///
  /// In en, this message translates to:
  /// **'Reviewing'**
  String get progReviewing;

  /// No description provided for @progLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get progLearning;

  /// No description provided for @progActiveDays.
  ///
  /// In en, this message translates to:
  /// **'Active Days'**
  String get progActiveDays;

  /// No description provided for @progPagesPerWeek.
  ///
  /// In en, this message translates to:
  /// **'pages/wk'**
  String get progPagesPerWeek;

  /// No description provided for @progAssStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get progAssStrong;

  /// No description provided for @progAssOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get progAssOkay;

  /// No description provided for @progAssNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Needs Work'**
  String get progAssNeedsWork;

  /// No description provided for @homeReadyToStart.
  ///
  /// In en, this message translates to:
  /// **'Ready to start, {name}?'**
  String homeReadyToStart(Object name);

  /// No description provided for @homeActiveDaysKeepItUp.
  ///
  /// In en, this message translates to:
  /// **'{days} active days — keep it up!'**
  String homeActiveDaysKeepItUp(Object days);

  /// No description provided for @homeSessionCompleted.
  ///
  /// In en, this message translates to:
  /// **'Today: {count} session completed'**
  String homeSessionCompleted(Object count);

  /// No description provided for @homeSessionsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Today: {count} sessions completed'**
  String homeSessionsCompleted(Object count);

  /// No description provided for @planFullQuran.
  ///
  /// In en, this message translates to:
  /// **'Full Quran'**
  String get planFullQuran;

  /// No description provided for @planTodaysPlan.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Plan'**
  String get planTodaysPlan;

  /// No description provided for @planExtraSession.
  ///
  /// In en, this message translates to:
  /// **'Extra Session #{count}'**
  String planExtraSession(Object count);

  /// No description provided for @planSabaqNew.
  ///
  /// In en, this message translates to:
  /// **'Sabaq · New'**
  String get planSabaqNew;

  /// No description provided for @planSabqiReview.
  ///
  /// In en, this message translates to:
  /// **'Sabqi · Review'**
  String get planSabqiReview;

  /// No description provided for @planManzilRevision.
  ///
  /// In en, this message translates to:
  /// **'Manzil · Revision'**
  String get planManzilRevision;

  /// No description provided for @planNoReviewYet.
  ///
  /// In en, this message translates to:
  /// **'No review yet'**
  String get planNoReviewYet;

  /// No description provided for @planNotStartedYet.
  ///
  /// In en, this message translates to:
  /// **'Not started yet'**
  String get planNotStartedYet;

  /// No description provided for @planPageLines.
  ///
  /// In en, this message translates to:
  /// **'Page {page} · Lines {start}–{end}'**
  String planPageLines(int page, int start, int end);

  /// No description provided for @planPageFromVerse.
  ///
  /// In en, this message translates to:
  /// **'Page {page} · from verse {verse}'**
  String planPageFromVerse(int page, int verse);

  /// No description provided for @planPagesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pages'**
  String planPagesCount(Object count);

  /// No description provided for @planPagesList.
  ///
  /// In en, this message translates to:
  /// **'Pages {pages}'**
  String planPagesList(Object pages);

  /// No description provided for @planPagesListMore.
  ///
  /// In en, this message translates to:
  /// **'Pages {pages}… (+{more})'**
  String planPagesListMore(Object more, Object pages);

  /// No description provided for @planJuzPages.
  ///
  /// In en, this message translates to:
  /// **'Juz {juz} · {count} pages'**
  String planJuzPages(Object count, Object juz);

  /// No description provided for @planEstimatedTotal.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min total'**
  String planEstimatedTotal(Object minutes);

  /// No description provided for @planTimeNew.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m new'**
  String planTimeNew(Object minutes);

  /// No description provided for @planTimeReview.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m review'**
  String planTimeReview(Object minutes);

  /// No description provided for @planTimeRevision.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m revision'**
  String planTimeRevision(Object minutes);

  /// No description provided for @planFlashcardsDue.
  ///
  /// In en, this message translates to:
  /// **'{count} flashcards due'**
  String planFlashcardsDue(Object count);

  /// No description provided for @planSessionSteps.
  ///
  /// In en, this message translates to:
  /// **'Session steps'**
  String get planSessionSteps;

  /// No description provided for @planStartSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get planStartSession;

  /// No description provided for @planCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get planCompleted;

  /// No description provided for @planWhyThisPlan.
  ///
  /// In en, this message translates to:
  /// **'Why this plan?'**
  String get planWhyThisPlan;

  /// No description provided for @preSessionDoneOffline.
  ///
  /// In en, this message translates to:
  /// **'Done any offline?'**
  String get preSessionDoneOffline;

  /// No description provided for @preSessionCheckPhases.
  ///
  /// In en, this message translates to:
  /// **'Check phases you\'ve already completed to skip them'**
  String get preSessionCheckPhases;

  /// No description provided for @preSessionMarkDone.
  ///
  /// In en, this message translates to:
  /// **'Mark Session as Done'**
  String get preSessionMarkDone;

  /// No description provided for @sessionHowDidItGo.
  ///
  /// In en, this message translates to:
  /// **'How did it go?'**
  String get sessionHowDidItGo;

  /// No description provided for @sessionRatePerformance.
  ///
  /// In en, this message translates to:
  /// **'Rate your {phase} performance'**
  String sessionRatePerformance(Object phase);

  /// No description provided for @sessionAssessmentStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get sessionAssessmentStrong;

  /// No description provided for @sessionAssessmentStrongDesc.
  ///
  /// In en, this message translates to:
  /// **'I nailed it — confident'**
  String get sessionAssessmentStrongDesc;

  /// No description provided for @sessionAssessmentOkay.
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get sessionAssessmentOkay;

  /// No description provided for @sessionAssessmentOkayDesc.
  ///
  /// In en, this message translates to:
  /// **'Got through it, some mistakes'**
  String get sessionAssessmentOkayDesc;

  /// No description provided for @sessionAssessmentNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Needs Work'**
  String get sessionAssessmentNeedsWork;

  /// No description provided for @sessionAssessmentNeedsWorkDesc.
  ///
  /// In en, this message translates to:
  /// **'I struggled — need more practice'**
  String get sessionAssessmentNeedsWorkDesc;

  /// No description provided for @coverageHowMuch.
  ///
  /// In en, this message translates to:
  /// **'How much did you cover?'**
  String get coverageHowMuch;

  /// No description provided for @coveragePlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned: Page {page} · {lines}'**
  String coveragePlanned(Object lines, Object page);

  /// No description provided for @coverageAllLines.
  ///
  /// In en, this message translates to:
  /// **'All planned lines'**
  String get coverageAllLines;

  /// No description provided for @coverageAllLinesDesc.
  ///
  /// In en, this message translates to:
  /// **'I completed page {page} ({lines})'**
  String coverageAllLinesDesc(Object lines, Object page);

  /// No description provided for @coveragePartOfPage.
  ///
  /// In en, this message translates to:
  /// **'Part of the page'**
  String get coveragePartOfPage;

  /// No description provided for @coveragePartOfPageDesc.
  ///
  /// In en, this message translates to:
  /// **'I\'ll specify which verses I covered'**
  String get coveragePartOfPageDesc;

  /// No description provided for @coverageMoreThanPlanned.
  ///
  /// In en, this message translates to:
  /// **'More than planned'**
  String get coverageMoreThanPlanned;

  /// No description provided for @coverageMoreThanPlannedDesc.
  ///
  /// In en, this message translates to:
  /// **'I covered extra pages!'**
  String get coverageMoreThanPlannedDesc;

  /// No description provided for @completeSessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session Complete!'**
  String get completeSessionComplete;

  /// No description provided for @completeTimeSpent.
  ///
  /// In en, this message translates to:
  /// **'Time spent'**
  String get completeTimeSpent;

  /// No description provided for @completeTotalReps.
  ///
  /// In en, this message translates to:
  /// **'Total reps'**
  String get completeTotalReps;

  /// No description provided for @completeTomorrowsPreview.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow\'s preview'**
  String get completeTomorrowsPreview;

  /// No description provided for @completePracticeFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Practice {count} Flashcards'**
  String completePracticeFlashcards(Object count);

  /// No description provided for @completeBackToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get completeBackToDashboard;

  /// No description provided for @overlayNewMemorization.
  ///
  /// In en, this message translates to:
  /// **'New Memorization'**
  String get overlayNewMemorization;

  /// No description provided for @overlayReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get overlayReview;

  /// No description provided for @overlayRevision.
  ///
  /// In en, this message translates to:
  /// **'Revision'**
  String get overlayRevision;

  /// No description provided for @overlayPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get overlayPractice;

  /// No description provided for @overlaySimilarVerses.
  ///
  /// In en, this message translates to:
  /// **'This page has similar verses'**
  String get overlaySimilarVerses;

  /// No description provided for @overlayFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get overlayFree;

  /// No description provided for @overlayGuided.
  ///
  /// In en, this message translates to:
  /// **'Guided'**
  String get overlayGuided;

  /// No description provided for @overlayListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get overlayListen;

  /// No description provided for @overlayListenDesc.
  ///
  /// In en, this message translates to:
  /// **'Listen to the page being recited. Focus on the melody and pronunciation'**
  String get overlayListenDesc;

  /// No description provided for @overlayTarget.
  ///
  /// In en, this message translates to:
  /// **'target × {count}'**
  String overlayTarget(Object count);

  /// No description provided for @overlaySkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get overlaySkip;

  /// No description provided for @overlayPrev.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get overlayPrev;

  /// No description provided for @overlayNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get overlayNext;

  /// No description provided for @overlayFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get overlayFinish;

  /// No description provided for @overlayDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get overlayDone;

  /// No description provided for @phaseSabaq.
  ///
  /// In en, this message translates to:
  /// **'New Memorization'**
  String get phaseSabaq;

  /// No description provided for @phaseSabqi.
  ///
  /// In en, this message translates to:
  /// **'Recent Review'**
  String get phaseSabqi;

  /// No description provided for @phaseManzil.
  ///
  /// In en, this message translates to:
  /// **'Long-term Review'**
  String get phaseManzil;

  /// No description provided for @phaseFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get phaseFlashcards;

  /// No description provided for @recipeStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String recipeStepOf(int current, int total);

  /// No description provided for @recipeDoneBadge.
  ///
  /// In en, this message translates to:
  /// **'✓ Done'**
  String get recipeDoneBadge;

  /// No description provided for @recipeTargetTimesLabel.
  ///
  /// In en, this message translates to:
  /// **'{target} × target'**
  String recipeTargetTimesLabel(int target);

  /// No description provided for @recipeTimes.
  ///
  /// In en, this message translates to:
  /// **'{count} ×'**
  String recipeTimes(int count);

  /// No description provided for @recipeTargetMinLabel.
  ///
  /// In en, this message translates to:
  /// **'{target} min target'**
  String recipeTargetMinLabel(int target);

  /// No description provided for @recipeMin.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String recipeMin(int count);

  /// No description provided for @recipeBtnPrev.
  ///
  /// In en, this message translates to:
  /// **'Prev'**
  String get recipeBtnPrev;

  /// No description provided for @recipeBtnNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get recipeBtnNext;

  /// No description provided for @recipeBtnSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get recipeBtnSkip;

  /// No description provided for @recipeBtnFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get recipeBtnFinish;

  /// No description provided for @recipeFreeModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Free Mode'**
  String get recipeFreeModeTitle;

  /// No description provided for @recipeFreeModeDesc.
  ///
  /// In en, this message translates to:
  /// **'No recipe available for this phase. Use the + button to count your reps.'**
  String get recipeFreeModeDesc;

  /// No description provided for @recipeActionListen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get recipeActionListen;

  /// No description provided for @recipeActionReadAlong.
  ///
  /// In en, this message translates to:
  /// **'Read Along'**
  String get recipeActionReadAlong;

  /// No description provided for @recipeActionReadSolo.
  ///
  /// In en, this message translates to:
  /// **'Read Solo'**
  String get recipeActionReadSolo;

  /// No description provided for @recipeActionReciteMemory.
  ///
  /// In en, this message translates to:
  /// **'Recite from Memory'**
  String get recipeActionReciteMemory;

  /// No description provided for @recipeActionLinkPractice.
  ///
  /// In en, this message translates to:
  /// **'Link Practice'**
  String get recipeActionLinkPractice;

  /// No description provided for @recipeActionWrite.
  ///
  /// In en, this message translates to:
  /// **'Write'**
  String get recipeActionWrite;

  /// No description provided for @recipeActionReviewMeaning.
  ///
  /// In en, this message translates to:
  /// **'Review Meaning'**
  String get recipeActionReviewMeaning;

  /// No description provided for @recipeActionSelfTest.
  ///
  /// In en, this message translates to:
  /// **'Self Test'**
  String get recipeActionSelfTest;

  /// No description provided for @recipeInstListen.
  ///
  /// In en, this message translates to:
  /// **'Listen to the page being recited. Focus on the melody and pronunciation.'**
  String get recipeInstListen;

  /// No description provided for @recipeInstReadAlong.
  ///
  /// In en, this message translates to:
  /// **'Read along with the audio. Match the reciter\'s pace and tajweed.'**
  String get recipeInstReadAlong;

  /// No description provided for @recipeInstReadSolo.
  ///
  /// In en, this message translates to:
  /// **'Read on your own without audio. Check your accuracy after each attempt.'**
  String get recipeInstReadSolo;

  /// No description provided for @recipeInstReciteMemory.
  ///
  /// In en, this message translates to:
  /// **'Close the mushaf and recite from memory. Repeat until confident.'**
  String get recipeInstReciteMemory;

  /// No description provided for @recipeInstSabqiReadSolo.
  ///
  /// In en, this message translates to:
  /// **'Read through the review pages. Note any areas that feel uncertain.'**
  String get recipeInstSabqiReadSolo;

  /// No description provided for @recipeInstSabqiSelfTest.
  ///
  /// In en, this message translates to:
  /// **'Close the mushaf and recite each page from memory. Check and correct.'**
  String get recipeInstSabqiSelfTest;

  /// No description provided for @recipeInstManzilReadSolo.
  ///
  /// In en, this message translates to:
  /// **'Read through the manzil pages at a steady pace. Focus on fluency.'**
  String get recipeInstManzilReadSolo;

  /// No description provided for @recipeInstManzilSelfTest.
  ///
  /// In en, this message translates to:
  /// **'Recite from memory. Use the mushaf only to check uncertain sections.'**
  String get recipeInstManzilSelfTest;

  /// No description provided for @recipeTipFocusLines.
  ///
  /// In en, this message translates to:
  /// **'Focus on 2-3 lines at a time, then connect them together.'**
  String get recipeTipFocusLines;

  /// No description provided for @recipeTipRecord.
  ///
  /// In en, this message translates to:
  /// **'Record yourself and compare with the reciter to spot mistakes.'**
  String get recipeTipRecord;

  /// No description provided for @recipeTipMeaning.
  ///
  /// In en, this message translates to:
  /// **'Review the meaning to build deeper neural connections.'**
  String get recipeTipMeaning;

  /// No description provided for @recipeTipMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Don\'t skip pages that feel easy — even strong pages need maintenance.'**
  String get recipeTipMaintenance;

  /// No description provided for @recipeTipWeakPage.
  ///
  /// In en, this message translates to:
  /// **'If a page feels weak, add an extra repetition.'**
  String get recipeTipWeakPage;

  /// No description provided for @recipeTipManzilLongTerm.
  ///
  /// In en, this message translates to:
  /// **'Manzil keeps your long-term memorization strong.'**
  String get recipeTipManzilLongTerm;

  /// No description provided for @recipeTipConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency matters more than perfection here.'**
  String get recipeTipConsistency;

  /// No description provided for @overlayPageLines.
  ///
  /// In en, this message translates to:
  /// **'Page {page} · Lines {start}-{end}'**
  String overlayPageLines(int page, int start, int end);

  /// No description provided for @audioSelectVerse.
  ///
  /// In en, this message translates to:
  /// **'Select verse to play'**
  String get audioSelectVerse;

  /// No description provided for @assessmentPerformanceIn.
  ///
  /// In en, this message translates to:
  /// **'Assess your performance in {phase}'**
  String assessmentPerformanceIn(String phase);

  /// No description provided for @overlayFreeMode.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get overlayFreeMode;

  /// No description provided for @overlayGuidedMode.
  ///
  /// In en, this message translates to:
  /// **'Guided'**
  String get overlayGuidedMode;

  /// No description provided for @tomorrowPreview.
  ///
  /// In en, this message translates to:
  /// **'Page {page} · Review today\\\'s pages'**
  String tomorrowPreview(int page);

  /// No description provided for @khatmCongrats.
  ///
  /// In en, this message translates to:
  /// **'You\\\'ve completed the Quran!'**
  String get khatmCongrats;

  /// No description provided for @feedbackSabaqStrong.
  ///
  /// In en, this message translates to:
  /// **'Excellent! You rated this page as strong — great foundation!'**
  String get feedbackSabaqStrong;

  /// No description provided for @feedbackSabaqNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'Every difficult session is progress. The pages that challenge you today will be your strongest tomorrow.'**
  String get feedbackSabaqNeedsWork;

  /// No description provided for @feedbackRepetition.
  ///
  /// In en, this message translates to:
  /// **'Masha\\\'Allah! {reps} repetitions — building rock-solid memory!'**
  String feedbackRepetition(int reps);

  /// No description provided for @feedbackFallback.
  ///
  /// In en, this message translates to:
  /// **'Masha\\\'Allah! Great work today. Every session counts!'**
  String get feedbackFallback;

  /// No description provided for @feedbackFallbackShort.
  ///
  /// In en, this message translates to:
  /// **'Masha\\\'Allah! Great work today.'**
  String get feedbackFallbackShort;

  /// No description provided for @feedbackTime.
  ///
  /// In en, this message translates to:
  /// **'Masha\\\'Allah! A solid {minutes}-minute session. Consistency builds mountains!'**
  String feedbackTime(int minutes);

  /// No description provided for @loadingPage.
  ///
  /// In en, this message translates to:
  /// **'Loading page {page}…'**
  String loadingPage(int page);

  /// No description provided for @failedToLoadPage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load page {page}'**
  String failedToLoadPage(int page);

  /// No description provided for @hifzCtaTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Your Hifz Journey'**
  String get hifzCtaTitle;

  /// No description provided for @hifzCtaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a quick assessment and get a personalized memorization plan.'**
  String get hifzCtaSubtitle;

  /// No description provided for @hifzCtaButton.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get hifzCtaButton;

  /// No description provided for @homeRestDayTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest Day'**
  String get homeRestDayTitle;

  /// No description provided for @homeRestDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Today is your rest day. Recharge and come back stronger.'**
  String get homeRestDaySubtitle;

  /// No description provided for @homeRestDayContinueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get homeRestDayContinueReading;

  /// No description provided for @homeRestDayStartAnyway.
  ///
  /// In en, this message translates to:
  /// **'Start a session anyway'**
  String get homeRestDayStartAnyway;

  /// No description provided for @undExploreDeeper.
  ///
  /// In en, this message translates to:
  /// **'Explore the Quran\'s deeper meaning'**
  String get undExploreDeeper;

  /// No description provided for @undSearchSurahs.
  ///
  /// In en, this message translates to:
  /// **'Search surahs...'**
  String get undSearchSurahs;

  /// No description provided for @undAllSurahs.
  ///
  /// In en, this message translates to:
  /// **'114 Surahs'**
  String get undAllSurahs;

  /// No description provided for @undResults.
  ///
  /// In en, this message translates to:
  /// **'results'**
  String get undResults;

  /// No description provided for @profileQfTitle.
  ///
  /// In en, this message translates to:
  /// **'Quran Foundation'**
  String get profileQfTitle;

  /// No description provided for @profileQfConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected · Syncing bookmarks & sessions'**
  String get profileQfConnected;

  /// No description provided for @profileQfActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get profileQfActive;

  /// No description provided for @profileQfDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get profileQfDisconnect;

  /// No description provided for @profileQfDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected from Quran Foundation'**
  String get profileQfDisconnected;

  /// No description provided for @profileQfSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Quran Foundation'**
  String get profileQfSignIn;

  /// No description provided for @profileQfSignInDesc.
  ///
  /// In en, this message translates to:
  /// **'Sync bookmarks, streaks & reading sessions'**
  String get profileQfSignInDesc;

  /// No description provided for @profileQfConnectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connected to Quran Foundation'**
  String get profileQfConnectedSuccess;

  /// No description provided for @profileQfSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in cancelled or failed'**
  String get profileQfSignInFailed;

  /// No description provided for @profilePreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get profilePreferences;

  /// No description provided for @profileFeatures.
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get profileFeatures;

  /// No description provided for @profileAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get profileAccounts;

  /// No description provided for @profileTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileTabSettings;

  /// No description provided for @profileTabHifz.
  ///
  /// In en, this message translates to:
  /// **'Hifz'**
  String get profileTabHifz;

  /// No description provided for @profileTabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileTabAccount;

  /// No description provided for @undStories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get undStories;

  /// No description provided for @undThemes.
  ///
  /// In en, this message translates to:
  /// **'Themes'**
  String get undThemes;

  /// No description provided for @todaysStudyContext.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Study Context'**
  String get todaysStudyContext;

  /// No description provided for @yourSabaqIsOnPage.
  ///
  /// In en, this message translates to:
  /// **'Your sabaq is on page {page}'**
  String yourSabaqIsOnPage(int page);

  /// No description provided for @actionOpenPage.
  ///
  /// In en, this message translates to:
  /// **'Open Page'**
  String get actionOpenPage;

  /// No description provided for @actionResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get actionResume;

  /// No description provided for @surahInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} · {type} · {count} verses'**
  String surahInfoLabel(String name, String type, int count);

  /// No description provided for @revelationMeccan.
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get revelationMeccan;

  /// No description provided for @revelationMedinan.
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get revelationMedinan;

  /// No description provided for @understandingContext.
  ///
  /// In en, this message translates to:
  /// **'Understanding Context'**
  String get understandingContext;

  /// No description provided for @understandingContextDesc.
  ///
  /// In en, this message translates to:
  /// **'Today\'s sabaq is on page {page}. Build deeper understanding of these verses before you memorize.'**
  String understandingContextDesc(int page);

  /// No description provided for @flashcardsDue.
  ///
  /// In en, this message translates to:
  /// **'due {count}'**
  String flashcardsDue(int count);

  /// No description provided for @planPageAwaits.
  ///
  /// In en, this message translates to:
  /// **'Page {page} awaits · ~{min} min'**
  String planPageAwaits(int page, int min);

  /// No description provided for @planMinDuration.
  ///
  /// In en, this message translates to:
  /// **'{min} min'**
  String planMinDuration(int min);

  /// No description provided for @dashboardFlashcards.
  ///
  /// In en, this message translates to:
  /// **'Flashcards'**
  String get dashboardFlashcards;

  /// No description provided for @fcMixedReview.
  ///
  /// In en, this message translates to:
  /// **'Mixed Review'**
  String get fcMixedReview;

  /// No description provided for @fcNextVerse.
  ///
  /// In en, this message translates to:
  /// **'Next Verse'**
  String get fcNextVerse;

  /// No description provided for @fcPreviousVerse.
  ///
  /// In en, this message translates to:
  /// **'Previous Verse'**
  String get fcPreviousVerse;

  /// No description provided for @fcCompleteIt.
  ///
  /// In en, this message translates to:
  /// **'Complete It'**
  String get fcCompleteIt;

  /// No description provided for @fcSurahDetective.
  ///
  /// In en, this message translates to:
  /// **'Surah Detective'**
  String get fcSurahDetective;

  /// No description provided for @fcSequence.
  ///
  /// In en, this message translates to:
  /// **'Sequence'**
  String get fcSequence;

  /// No description provided for @fcMutashabihat.
  ///
  /// In en, this message translates to:
  /// **'Mutashabihat'**
  String get fcMutashabihat;

  /// No description provided for @fcMixedReviewDesc.
  ///
  /// In en, this message translates to:
  /// **'All card types combined'**
  String get fcMixedReviewDesc;

  /// No description provided for @fcNextVerseDesc.
  ///
  /// In en, this message translates to:
  /// **'What comes next?'**
  String get fcNextVerseDesc;

  /// No description provided for @fcPreviousVerseDesc.
  ///
  /// In en, this message translates to:
  /// **'What comes before?'**
  String get fcPreviousVerseDesc;

  /// No description provided for @fcCompleteItDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete the verse'**
  String get fcCompleteItDesc;

  /// No description provided for @fcSurahDetectiveDesc.
  ///
  /// In en, this message translates to:
  /// **'Which surah is this from?'**
  String get fcSurahDetectiveDesc;

  /// No description provided for @fcSequenceDesc.
  ///
  /// In en, this message translates to:
  /// **'Order the verses'**
  String get fcSequenceDesc;

  /// No description provided for @fcMutashabihatDesc.
  ///
  /// In en, this message translates to:
  /// **'Similar verses'**
  String get fcMutashabihatDesc;

  /// No description provided for @undSpotlightTitle.
  ///
  /// In en, this message translates to:
  /// **'Understanding Spotlight'**
  String get undSpotlightTitle;

  /// No description provided for @pracNextVerseSub.
  ///
  /// In en, this message translates to:
  /// **'What comes next?'**
  String get pracNextVerseSub;

  /// No description provided for @pracPrevVerseSub.
  ///
  /// In en, this message translates to:
  /// **'What comes before?'**
  String get pracPrevVerseSub;

  /// No description provided for @pracCompleteItSub.
  ///
  /// In en, this message translates to:
  /// **'Complete the verse'**
  String get pracCompleteItSub;

  /// No description provided for @pracSurahDetectiveSub.
  ///
  /// In en, this message translates to:
  /// **'Which surah is this from?'**
  String get pracSurahDetectiveSub;

  /// No description provided for @pracSequenceSub.
  ///
  /// In en, this message translates to:
  /// **'Order the verses'**
  String get pracSequenceSub;

  /// No description provided for @pracMutashabihatSub.
  ///
  /// In en, this message translates to:
  /// **'Which verse is from the correct Surah?'**
  String get pracMutashabihatSub;

  /// No description provided for @dashboardExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get dashboardExplore;

  /// No description provided for @topicSurahsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} surahs'**
  String topicSurahsCount(int count);

  /// No description provided for @progressStripInfo.
  ///
  /// In en, this message translates to:
  /// **'{pct}% · {pages} pages · Juz {juz}'**
  String progressStripInfo(String pct, int pages, int juz);

  /// No description provided for @homeStatusFreshStart.
  ///
  /// In en, this message translates to:
  /// **'Every return is a fresh start'**
  String get homeStatusFreshStart;

  /// No description provided for @homeStatusWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back · review session ready'**
  String get homeStatusWelcomeBack;

  /// No description provided for @homeStatusDoneToday.
  ///
  /// In en, this message translates to:
  /// **'Done for today · {activeDays} active days'**
  String homeStatusDoneToday(int activeDays);

  /// No description provided for @homeStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Ready when you are'**
  String get homeStatusReady;

  /// No description provided for @homeStatusPageAwaits.
  ///
  /// In en, this message translates to:
  /// **'Page {page} awaits'**
  String homeStatusPageAwaits(int page);

  /// No description provided for @homeStatusSessionReady.
  ///
  /// In en, this message translates to:
  /// **'Session ready'**
  String get homeStatusSessionReady;

  /// No description provided for @homeStatusEstimate.
  ///
  /// In en, this message translates to:
  /// **'{info} · ~{minutes} min'**
  String homeStatusEstimate(String info, int minutes);

  /// No description provided for @surahSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{revelationType} · {versesCount} verses · Page {page}'**
  String surahSubtitle(String revelationType, int versesCount, int page);

  /// No description provided for @meccan.
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get meccan;

  /// No description provided for @medinan.
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get medinan;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'jawhar'**
  String get appName;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @progressTabPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get progressTabPages;

  /// No description provided for @progressTabSurahs.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get progressTabSurahs;

  /// No description provided for @progressTotalPages.
  ///
  /// In en, this message translates to:
  /// **'{total}/604 pages'**
  String progressTotalPages(int total);

  /// No description provided for @progressActiveDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String progressActiveDays(int days);

  /// No description provided for @progressMemorized.
  ///
  /// In en, this message translates to:
  /// **'{count} memorized'**
  String progressMemorized(int count);

  /// No description provided for @progressPagesPerWeek.
  ///
  /// In en, this message translates to:
  /// **'{pages}/wk'**
  String progressPagesPerWeek(int pages);

  /// No description provided for @progressEstWeeks.
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks'**
  String progressEstWeeks(int weeks);

  /// No description provided for @progressEstYears.
  ///
  /// In en, this message translates to:
  /// **'{years} years'**
  String progressEstYears(String years);

  /// No description provided for @progressComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete!'**
  String get progressComplete;

  /// No description provided for @progressViewHistory.
  ///
  /// In en, this message translates to:
  /// **'View Session History'**
  String get progressViewHistory;

  /// No description provided for @progressSessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} sessions'**
  String progressSessionsCount(int count);

  /// No description provided for @progressJuz.
  ///
  /// In en, this message translates to:
  /// **'Juz {num}'**
  String progressJuz(int num);

  /// No description provided for @progressLegendMemorized.
  ///
  /// In en, this message translates to:
  /// **'Memorized'**
  String get progressLegendMemorized;

  /// No description provided for @progressLegendLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get progressLegendLearning;

  /// No description provided for @progressLegendReviewing.
  ///
  /// In en, this message translates to:
  /// **'Reviewing'**
  String get progressLegendReviewing;

  /// No description provided for @progressLegendNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get progressLegendNotStarted;

  /// No description provided for @progressPageRangeSingle.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String progressPageRangeSingle(int page);

  /// No description provided for @progressPageRangeMultiple.
  ///
  /// In en, this message translates to:
  /// **'Pages {start}–{end}'**
  String progressPageRangeMultiple(int start, int end);

  /// No description provided for @tafsirTitle.
  ///
  /// In en, this message translates to:
  /// **'Tafsir — {verse}'**
  String tafsirTitle(String verse);

  /// No description provided for @tafsirTabBrief.
  ///
  /// In en, this message translates to:
  /// **'Brief'**
  String get tafsirTabBrief;

  /// No description provided for @tafsirTabDetailed.
  ///
  /// In en, this message translates to:
  /// **'Detailed'**
  String get tafsirTabDetailed;

  /// No description provided for @tafsirTabOccasion.
  ///
  /// In en, this message translates to:
  /// **'Occasion'**
  String get tafsirTabOccasion;

  /// No description provided for @tafsirEmptyBrief.
  ///
  /// In en, this message translates to:
  /// **'No brief tafsir available for this verse.'**
  String get tafsirEmptyBrief;

  /// No description provided for @tafsirEmptyDetailed.
  ///
  /// In en, this message translates to:
  /// **'Tap the Detailed tab to load.'**
  String get tafsirEmptyDetailed;

  /// No description provided for @tafsirEmptyOccasion.
  ///
  /// In en, this message translates to:
  /// **'No occasion of revelation recorded for this verse.'**
  String get tafsirEmptyOccasion;

  /// No description provided for @tafsirOccasionTitle.
  ///
  /// In en, this message translates to:
  /// **'Occasion of Revelation'**
  String get tafsirOccasionTitle;

  /// No description provided for @tafsirNarrationCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1 {1 narration} other {{count} narrations}}'**
  String tafsirNarrationCount(num count);

  /// No description provided for @tafsirNarrationLabel.
  ///
  /// In en, this message translates to:
  /// **'Narration {number}'**
  String tafsirNarrationLabel(Object number);

  /// No description provided for @undReadSurah.
  ///
  /// In en, this message translates to:
  /// **'Read Surah'**
  String get undReadSurah;

  /// No description provided for @undOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get undOverview;

  /// No description provided for @undKeyThemes.
  ///
  /// In en, this message translates to:
  /// **'Key Themes'**
  String get undKeyThemes;

  /// No description provided for @undReasonsOfRevelation.
  ///
  /// In en, this message translates to:
  /// **'Reasons of Revelation'**
  String get undReasonsOfRevelation;

  /// No description provided for @undEntriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String undEntriesCount(int count);

  /// No description provided for @undMoreEntries.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more entries'**
  String undMoreEntries(int count);

  /// No description provided for @undIntroComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Detailed introduction coming soon.\nOpen the surah to explore translations and tafsir.'**
  String get undIntroComingSoon;

  /// No description provided for @undVersesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} verses'**
  String undVersesCount(int count);

  /// No description provided for @undPagePrefix.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String undPagePrefix(int page);

  /// No description provided for @pracContextNeeded.
  ///
  /// In en, this message translates to:
  /// **'Context needed'**
  String get pracContextNeeded;

  /// No description provided for @pracNotStudied.
  ///
  /// In en, this message translates to:
  /// **'Not Studied'**
  String get pracNotStudied;

  /// No description provided for @pracSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get pracSource;

  /// No description provided for @pracSimilar.
  ///
  /// In en, this message translates to:
  /// **'Similar'**
  String get pracSimilar;

  /// No description provided for @pracMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get pracMastered;

  /// No description provided for @pracMarkForPractice.
  ///
  /// In en, this message translates to:
  /// **'Mark for Practice'**
  String get pracMarkForPractice;

  /// No description provided for @pracAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get pracAll;

  /// No description provided for @pracNeedsPractice.
  ///
  /// In en, this message translates to:
  /// **'Needs Practice'**
  String get pracNeedsPractice;

  /// No description provided for @pracTapToReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap to reveal'**
  String get pracTapToReveal;

  /// No description provided for @ratingForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot'**
  String get ratingForgot;

  /// No description provided for @ratingWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get ratingWeak;

  /// No description provided for @ratingOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ratingOk;

  /// No description provided for @ratingStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get ratingStrong;

  /// No description provided for @fcReviewComplete.
  ///
  /// In en, this message translates to:
  /// **'Review Complete!'**
  String get fcReviewComplete;

  /// No description provided for @fcCardsReviewed.
  ///
  /// In en, this message translates to:
  /// **'Cards reviewed'**
  String get fcCardsReviewed;

  /// No description provided for @fcDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get fcDone;

  /// No description provided for @fcAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get fcAllCaughtUp;

  /// No description provided for @fcNoCardsDue.
  ///
  /// In en, this message translates to:
  /// **'No cards due right now.\nKeep memorizing and cards will appear!'**
  String get fcNoCardsDue;

  /// No description provided for @fcBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get fcBack;

  /// No description provided for @fcSandboxMode.
  ///
  /// In en, this message translates to:
  /// **'Sandbox Mode'**
  String get fcSandboxMode;

  /// No description provided for @fcCorrectOrder.
  ///
  /// In en, this message translates to:
  /// **'Correct order!'**
  String get fcCorrectOrder;

  /// No description provided for @cardTypeVerseCompletion.
  ///
  /// In en, this message translates to:
  /// **'Verse Completion'**
  String get cardTypeVerseCompletion;

  /// No description provided for @cardTypeNextVerse.
  ///
  /// In en, this message translates to:
  /// **'Next Verse'**
  String get cardTypeNextVerse;

  /// No description provided for @cardTypePreviousVerse.
  ///
  /// In en, this message translates to:
  /// **'Previous Verse'**
  String get cardTypePreviousVerse;

  /// No description provided for @cardTypeIdentifySurah.
  ///
  /// In en, this message translates to:
  /// **'Identify Surah'**
  String get cardTypeIdentifySurah;

  /// No description provided for @cardTypeTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get cardTypeTranslation;

  /// No description provided for @cardTypeRootWord.
  ///
  /// In en, this message translates to:
  /// **'Root Word'**
  String get cardTypeRootWord;

  /// No description provided for @pracDifference.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get pracDifference;

  /// No description provided for @pracShowOriginal.
  ///
  /// In en, this message translates to:
  /// **'Show original verse from {surah}'**
  String pracShowOriginal(String surah);

  /// No description provided for @pracWhichSurahWord.
  ///
  /// In en, this message translates to:
  /// **'In which surah is this word:'**
  String get pracWhichSurahWord;

  /// No description provided for @pracContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get pracContext;

  /// No description provided for @pracQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get pracQuiz;

  /// No description provided for @pracPracticing.
  ///
  /// In en, this message translates to:
  /// **'Practicing'**
  String get pracPracticing;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Memorize with Meaning'**
  String get appTagline;

  /// No description provided for @onboardingBrandStatement.
  ///
  /// In en, this message translates to:
  /// **'We believe memorization without\nunderstanding is incomplete.'**
  String get onboardingBrandStatement;

  /// No description provided for @onboardingReadTitle.
  ///
  /// In en, this message translates to:
  /// **'Read & Listen'**
  String get onboardingReadTitle;

  /// No description provided for @onboardingReadDesc.
  ///
  /// In en, this message translates to:
  /// **'Begin with the Mushaf itself: Hafs or Warsh, the full Madani page layout, and audio recitation that matches the verse you are reading.'**
  String get onboardingReadDesc;

  /// No description provided for @onboardingUnderstandTitle.
  ///
  /// In en, this message translates to:
  /// **'Understand with Depth'**
  String get onboardingUnderstandTitle;

  /// No description provided for @onboardingUnderstandDesc.
  ///
  /// In en, this message translates to:
  /// **'Meaning is not an add-on. Translations, tafsir, and reasons of revelation sit beside the verse so memorization has context.'**
  String get onboardingUnderstandDesc;

  /// No description provided for @onboardingMemorizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Memorize & Master'**
  String get onboardingMemorizeTitle;

  /// No description provided for @onboardingMemorizeDesc.
  ///
  /// In en, this message translates to:
  /// **'A daily rhythm: Sabaq (new memorization), Sabqi (recent review), and Manzil (revision) guided by smart spaced repetition.'**
  String get onboardingMemorizeDesc;

  /// No description provided for @onboardingBegin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get onboardingBegin;

  /// No description provided for @onboardingChooseLang.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardingChooseLang;

  /// No description provided for @onboardingChangeLater.
  ///
  /// In en, this message translates to:
  /// **'You can change this later in settings'**
  String get onboardingChangeLater;

  /// No description provided for @onboardingEnglishSub.
  ///
  /// In en, this message translates to:
  /// **'Continue in English'**
  String get onboardingEnglishSub;

  /// No description provided for @onboardingArabicSub.
  ///
  /// In en, this message translates to:
  /// **'المتابعة بالعربية'**
  String get onboardingArabicSub;

  /// No description provided for @onboardingChooseRecitation.
  ///
  /// In en, this message translates to:
  /// **'Choose your Quranic recitation'**
  String get onboardingChooseRecitation;

  /// No description provided for @onboardingChooseRecitationAr.
  ///
  /// In en, this message translates to:
  /// **'اختر القراءة'**
  String get onboardingChooseRecitationAr;

  /// No description provided for @onboardingHafsSub.
  ///
  /// In en, this message translates to:
  /// **'Hafs · Most widely used'**
  String get onboardingHafsSub;

  /// No description provided for @onboardingWarshSub.
  ///
  /// In en, this message translates to:
  /// **'Warsh · North & West Africa'**
  String get onboardingWarshSub;

  /// No description provided for @onboardingSyncProgress.
  ///
  /// In en, this message translates to:
  /// **'Sync your progress'**
  String get onboardingSyncProgress;

  /// No description provided for @onboardingSyncDesc.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync across devices.\nYour data stays on your device otherwise.'**
  String get onboardingSyncDesc;

  /// No description provided for @onboardingSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get onboardingSignIn;

  /// No description provided for @onboardingSignInCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sign-in was cancelled'**
  String get onboardingSignInCancelled;

  /// No description provided for @onboardingSignInError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect. Try again later.'**
  String get onboardingSignInError;

  /// No description provided for @actionTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get actionTryAgain;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onboardingSkip;

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set things up.'**
  String get setupSubtitle;

  /// No description provided for @setupMatchedSystem.
  ///
  /// In en, this message translates to:
  /// **'Matched to your system preference'**
  String get setupMatchedSystem;

  /// No description provided for @pracDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get pracDone;

  /// No description provided for @sessionPaused.
  ///
  /// In en, this message translates to:
  /// **'PAUSED'**
  String get sessionPaused;

  /// No description provided for @sessionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get sessionSkip;

  /// No description provided for @sessionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get sessionDone;

  /// No description provided for @sessionMin.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get sessionMin;

  /// No description provided for @sessionTimes.
  ///
  /// In en, this message translates to:
  /// **'×'**
  String get sessionTimes;

  /// No description provided for @coverageVerseX.
  ///
  /// In en, this message translates to:
  /// **'Verse {verse}'**
  String coverageVerseX(int verse);

  /// No description provided for @coverageFullPageCovered.
  ///
  /// In en, this message translates to:
  /// **'Full page covered'**
  String get coverageFullPageCovered;

  /// No description provided for @coverageNextTimeStartsFromVerse.
  ///
  /// In en, this message translates to:
  /// **'Next time starts from verse {verse}'**
  String coverageNextTimeStartsFromVerse(int verse);

  /// No description provided for @coverageConfirmVersesXtoY.
  ///
  /// In en, this message translates to:
  /// **'Confirm Verses {start} to {end}'**
  String coverageConfirmVersesXtoY(int start, int end);

  /// No description provided for @coverageConfirmVerseXtoY.
  ///
  /// In en, this message translates to:
  /// **'Confirm Verse 1 to {end}'**
  String coverageConfirmVerseXtoY(int end);

  /// No description provided for @planPhaseSabaq.
  ///
  /// In en, this message translates to:
  /// **'Sabaq'**
  String get planPhaseSabaq;

  /// No description provided for @planPhaseSabqi.
  ///
  /// In en, this message translates to:
  /// **'Sabqi'**
  String get planPhaseSabqi;

  /// No description provided for @planPhaseManzil.
  ///
  /// In en, this message translates to:
  /// **'Manzil'**
  String get planPhaseManzil;

  /// No description provided for @tafsirReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read more'**
  String get tafsirReadMore;

  /// No description provided for @tafsirShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get tafsirShowLess;

  /// No description provided for @tafsirSourceMukhtasar.
  ///
  /// In en, this message translates to:
  /// **'Al-Mukhtasar fi Tafsir'**
  String get tafsirSourceMukhtasar;

  /// No description provided for @tafsirSourceIbnKathir.
  ///
  /// In en, this message translates to:
  /// **'Ibn Kathir'**
  String get tafsirSourceIbnKathir;

  /// No description provided for @sessionReviewCards.
  ///
  /// In en, this message translates to:
  /// **'Review Cards'**
  String get sessionReviewCards;

  /// No description provided for @coveragePagesCovered.
  ///
  /// In en, this message translates to:
  /// **'Pages covered'**
  String get coveragePagesCovered;

  /// No description provided for @coveragePageXtoY.
  ///
  /// In en, this message translates to:
  /// **'Page {start} to {end}'**
  String coveragePageXtoY(int start, int end, int count);

  /// No description provided for @coveragePageX.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String coveragePageX(int page);

  /// No description provided for @coverageConfirmPages.
  ///
  /// In en, this message translates to:
  /// **'Confirm {count} Pages'**
  String coverageConfirmPages(int count);

  /// No description provided for @coverageVersesCoveredOnPage.
  ///
  /// In en, this message translates to:
  /// **'Verses covered on page {page}'**
  String coverageVersesCoveredOnPage(int page);

  /// No description provided for @coverageVersesOnPageStartFrom.
  ///
  /// In en, this message translates to:
  /// **'{total} verses on page, starting from {start}'**
  String coverageVersesOnPageStartFrom(int total, int start);

  /// No description provided for @coverageVersesOnPage.
  ///
  /// In en, this message translates to:
  /// **'{total} verses on page'**
  String coverageVersesOnPage(int total);

  /// No description provided for @sessionPagesToReview.
  ///
  /// In en, this message translates to:
  /// **'{count} pages to review'**
  String sessionPagesToReview(int count);

  /// No description provided for @sessionJuzAndPages.
  ///
  /// In en, this message translates to:
  /// **'Juz {juz} · {count} pages'**
  String sessionJuzAndPages(String juz, int count);

  /// No description provided for @pracChangeFilter.
  ///
  /// In en, this message translates to:
  /// **'Change Filter'**
  String get pracChangeFilter;

  /// No description provided for @pracTapToDownload.
  ///
  /// In en, this message translates to:
  /// **'Tap to download dataset'**
  String get pracTapToDownload;

  /// No description provided for @pracDownloadDataset.
  ///
  /// In en, this message translates to:
  /// **'Download Dataset'**
  String get pracDownloadDataset;

  /// No description provided for @pracAlreadyImported.
  ///
  /// In en, this message translates to:
  /// **'Already imported'**
  String get pracAlreadyImported;

  /// No description provided for @sessionOpenDigitalQuran.
  ///
  /// In en, this message translates to:
  /// **'Open Digital Quran'**
  String get sessionOpenDigitalQuran;

  /// No description provided for @sessionFromVerse.
  ///
  /// In en, this message translates to:
  /// **'From verse {verse}'**
  String sessionFromVerse(int verse);

  /// No description provided for @sessionPageAndInfo.
  ///
  /// In en, this message translates to:
  /// **'Page {page} · {info}'**
  String sessionPageAndInfo(String page, String info);

  /// No description provided for @pracReimport.
  ///
  /// In en, this message translates to:
  /// **'Re-import'**
  String get pracReimport;

  /// No description provided for @pracVerseNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Verse text not available'**
  String get pracVerseNotAvailable;

  /// No description provided for @pracNoGroupsStatus.
  ///
  /// In en, this message translates to:
  /// **'No groups for this status.'**
  String get pracNoGroupsStatus;

  /// No description provided for @pracNotImported.
  ///
  /// In en, this message translates to:
  /// **'Dataset not imported yet.'**
  String get pracNotImported;

  /// No description provided for @undSurahOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get undSurahOverview;

  /// No description provided for @undSurahKeyThemes.
  ///
  /// In en, this message translates to:
  /// **'Key Themes'**
  String get undSurahKeyThemes;

  /// No description provided for @undSurahReasonsOfRevelation.
  ///
  /// In en, this message translates to:
  /// **'Reasons of Revelation'**
  String get undSurahReasonsOfRevelation;

  /// No description provided for @undSurahEntriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String undSurahEntriesCount(int count);

  /// No description provided for @undSurahMoreEntriesCount.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more entries'**
  String undSurahMoreEntriesCount(int count);

  /// No description provided for @undSurahBegin.
  ///
  /// In en, this message translates to:
  /// **'Begin'**
  String get undSurahBegin;

  /// No description provided for @undSurahVersesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} verses'**
  String undSurahVersesCount(int count);

  /// No description provided for @undSurahPageX.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String undSurahPageX(int page);

  /// No description provided for @undSurahMeccan.
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get undSurahMeccan;

  /// No description provided for @undSurahMedinan.
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get undSurahMedinan;

  /// No description provided for @undSurahVerse.
  ///
  /// In en, this message translates to:
  /// **'Verse {verse}'**
  String undSurahVerse(int verse);

  /// No description provided for @undSurahVersesRange.
  ///
  /// In en, this message translates to:
  /// **'Verses {start}–{end}'**
  String undSurahVersesRange(int start, int end);

  /// No description provided for @topicOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get topicOverview;

  /// No description provided for @topicKeyVerses.
  ///
  /// In en, this message translates to:
  /// **'Key Verses'**
  String get topicKeyVerses;

  /// No description provided for @topicReadInMushaf.
  ///
  /// In en, this message translates to:
  /// **'Read in Mushaf'**
  String get topicReadInMushaf;

  /// No description provided for @topicVerseRange.
  ///
  /// In en, this message translates to:
  /// **'Verses {start}–{end}'**
  String topicVerseRange(int start, int end);

  /// No description provided for @topicComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Detailed exploration coming soon.'**
  String get topicComingSoon;

  /// No description provided for @topicMentionedIn.
  ///
  /// In en, this message translates to:
  /// **'Mentioned in {count} surahs'**
  String topicMentionedIn(int count);

  /// No description provided for @topicShowVerses.
  ///
  /// In en, this message translates to:
  /// **'Show key verses'**
  String get topicShowVerses;

  /// No description provided for @topicHideVerses.
  ///
  /// In en, this message translates to:
  /// **'Hide key verses'**
  String get topicHideVerses;

  /// No description provided for @topicOfflineVerse.
  ///
  /// In en, this message translates to:
  /// **'Translation unavailable offline'**
  String get topicOfflineVerse;

  /// No description provided for @readingTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get readingTranslation;

  /// No description provided for @translationLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading translations...'**
  String get translationLoading;

  /// No description provided for @contextTranslate.
  ///
  /// In en, this message translates to:
  /// **'Translate'**
  String get contextTranslate;

  /// No description provided for @contextTafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get contextTafsir;

  /// No description provided for @asbabNuzulTitle.
  ///
  /// In en, this message translates to:
  /// **'سبب النزول'**
  String get asbabNuzulTitle;

  /// No description provided for @asbabOccasion.
  ///
  /// In en, this message translates to:
  /// **'Occasion of Revelation'**
  String get asbabOccasion;

  /// No description provided for @asbabReadFull.
  ///
  /// In en, this message translates to:
  /// **'Read full narration →'**
  String get asbabReadFull;

  /// No description provided for @pageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load page {pageNumber}'**
  String pageLoadError(int pageNumber);

  /// No description provided for @verseCopied.
  ///
  /// In en, this message translates to:
  /// **'Verse copied — {verseKey}'**
  String verseCopied(String verseKey);

  /// No description provided for @verseCopiedForSharing.
  ///
  /// In en, this message translates to:
  /// **'Verse copied for sharing'**
  String get verseCopiedForSharing;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
