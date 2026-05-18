import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/plan_provider.dart';
import 'package:quran_app/providers/session_provider.dart';
import 'package:quran_app/providers/flashcard_provider.dart';
import 'package:quran_app/services/mutashabihat_import_service.dart';
import 'package:quran_app/providers/werd_provider.dart';
import 'package:quran_app/providers/locale_provider.dart';
import 'package:quran_app/providers/update_provider.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/providers/analytics_provider.dart';
import 'package:quran_app/services/analytics_service.dart';
import 'package:quran_app/services/notification_service.dart';
import 'package:quran_app/providers/context_provider.dart';
import 'package:quran_app/services/asbab_nuzul_service.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/notification_provider.dart';
import 'package:quran_app/providers/social_provider.dart';
import 'package:quran_app/services/push_notification_service.dart';
import 'package:quran_app/services/sharing_service.dart';
import 'package:quran_app/services/ai_plan_service.dart';
import 'package:quran_app/services/ai_calibration_service.dart';
import 'package:quran_app/services/break_recovery_service.dart';
import 'package:quran_app/services/contextual_tips_service.dart';
import 'package:quran_app/services/motivational_messages_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:quran_app/firebase_options.dart';
import 'package:quran_app/services/auth_service.dart';
import 'package:quran_app/services/cloud_sync_service.dart';
import 'package:quran_app/services/qf_user_auth_service.dart';
import 'package:quran_app/services/qf_user_api_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_app/screens/splash_screen.dart';
import 'package:device_preview/device_preview.dart';
import 'package:device_preview_screenshot/device_preview_screenshot.dart';

// Conditional imports for native-only packages
import 'package:quran_app/services/native_init.dart'
    if (dart.library.js_interop) 'package:quran_app/services/native_init_web.dart'
    as native_init;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage
  final prefs = await SharedPreferences.getInstance();
  final storageService = LocalStorageService(prefs);

  // Create AudioProvider (works on all platforms for basic playback)
  final audioProvider = AudioProvider();

  // Initialize push notification service
  final pushNotifService = PushNotificationService();

  // Initialize native-only services (SQLite FFI, AudioSession, AudioService, push notifs)
  // On web this is a no-op via conditional import
  await native_init.initNativePlatform(audioProvider, pushNotifService);

  // Initialize Hifz database
  final hifzDb = HifzDatabaseService();
  // Trigger DB creation/migration early
  await hifzDb.database;

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize auth service
  final authService = AuthService();
  authService.init();

  // Initialize cloud sync service
  final cloudSyncService = CloudSyncService(hifzDb);

  // Auto-sync on sign-in
  authService.addListener(() {
    if (authService.isSignedIn && authService.uid != null) {
      cloudSyncService.performInitialSync(authService.uid!);
    }
  });

  // Initialize QF User Auth (OAuth2 PKCE) — loads stored tokens
  final qfUserAuth = QfUserAuthService();
  await qfUserAuth.init();

  // Initialize QF User API client
  final qfUserApi = QfUserApiService(qfUserAuth);

  // Import mutashabihat dataset if needed (non-blocking)
  MutashabihatImportService(hifzDb).importIfNeeded();

  // Import asbab al-nuzul dataset if needed (non-blocking)
  final asbabService = AsbabNuzulService();
  asbabService.importIfNeeded();



  // Determine initial language from saved or system locale
  final savedLocale = prefs.getString('app_locale');
  final systemLang = PlatformDispatcher.instance.locale.languageCode;
  final initialLang = savedLocale ?? (systemLang == 'ar' ? 'ar' : 'en');

  // Set default reciter based on saved rewaya with locale-aware name
  if (storageService.savedRewaya == 2) {
    // Warsh: Al Ayoun Al Koushi (MP3Quran id=16, but not in QDC map)
    final name = initialLang == 'ar' ? 'العيون الكوشي' : 'Al Ayoun Al Koushi';
    audioProvider.setReciter(
      16, // Al Ayoun Al Koushi
      name: name,
      apiSource: ApiSource.mp3Quran,
      serverUrl: "https://server11.mp3quran.net/koshi/",
      moshafId: 16,
    );
  } else {
    // Hafs default: Mishary Rashid Alafasy (QDC id=7)
    // setReciter would bail early because _reciterId already defaults to 7,
    // so we directly update the name via updateReciterName.
    if (initialLang == 'ar') {
      final arabicName = Reciter.arabicNamesById[7] ?? 'مشاري راشد العفاسي';
      audioProvider.updateReciterName(arabicName);
    }
  }

  // Default tab: Dashboard (0) if user has reading history, else Read (2)
  final defaultTab = storageService.hasReadingHistory ? 0 : 2;

  // Initialize AI services
  final aiPlanService = AIPlanService();
  final aiCalibrationService = AICalibrationService();
  final breakRecoveryService = BreakRecoveryService(
    hifzDb,
    aiService: aiPlanService,
  );
  final contextualTipsService = ContextualTipsService();
  final motivationalService = MotivationalMessagesService();

  // Initialize ThemeProvider with persistence
  final themeProvider = ThemeProvider();
  themeProvider.initWithPrefs(prefs);

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN',
          defaultValue: 'https://8baf4d34321edd20db58050f76b24bbe@o4511200061816832.ingest.de.sentry.io/4511200063258704');
      // Disable performance tracing in debug — was 1.0 (100%), caused
      // significant CPU overhead by tracing every UI operation.
      options.tracesSampleRate = kReleaseMode ? 0.2 : 0.0;
    },
    appRunner: () {
      // Enable DevicePreview only on desktop debug builds
      final enablePreview = !kReleaseMode &&
          !kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

      // Save screenshots to a 'screenshots' folder in the project directory
      final screenshotDir = Directory('${Directory.current.path}/screenshots');
      if (!screenshotDir.existsSync()) {
        screenshotDir.createSync();
      }

      runApp(
        DevicePreview(
          enabled: enablePreview,
          tools: [
            ...DevicePreview.defaultTools,
            DevicePreviewScreenshot(
              onScreenshot: screenshotAsFiles(screenshotDir),
            ),
          ],
          builder: (context) => MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) {
                  // Detect initial locale for reciter names
                  final savedLocale = prefs.getString('app_locale');
                  String lang;
                  if (savedLocale != null) {
                    lang = savedLocale;
                  } else {
                    final systemLang =
                        PlatformDispatcher.instance.locale.languageCode;
                    lang = systemLang == 'ar' ? 'ar' : 'en';
                  }
                  return QuranReadingProvider(
                    storage: storageService,
                    language: lang,
                  );
                },
              ),
              ChangeNotifierProvider.value(value: audioProvider),
              ChangeNotifierProvider.value(value: themeProvider),
              ChangeNotifierProvider(create: (_) => NavigationProvider(defaultTab)),
              ChangeNotifierProvider(
                create: (_) => HifzProfileProvider(
                  hifzDb,
                  authService,
                  cloudSyncService,
                  qfApi: qfUserApi,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => PlanProvider(
                  hifzDb,
                  authService,
                  cloudSyncService,
                  aiPlanService: aiPlanService,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => SessionProvider(
                  hifzDb,
                  authService,
                  cloudSyncService,
                  qfApi: qfUserApi,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) =>
                    FlashcardProvider(hifzDb, authService, cloudSyncService),
              ),
              ChangeNotifierProvider(
                create: (_) => WerdProvider(storageService, qfApi: qfUserApi),
              ),
              ChangeNotifierProvider(create: (_) => LocaleProvider(prefs)),
              ChangeNotifierProvider(create: (_) => UpdateProvider()),
              ChangeNotifierProvider(
                create: (_) => BookmarkProvider(
                  storageService,
                  authService,
                  cloudSyncService,
                  qfApi: qfUserApi,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => NotificationProvider(pushNotifService, prefs),
              ),
              ChangeNotifierProvider(
                create: (_) => SocialProvider(SharingService(), hifzDb),
              ),
              ChangeNotifierProvider(
                create: (_) {
                  final analyticsService = AnalyticsService(hifzDb);
                  final notificationService = NotificationService(analyticsService);
                  return AnalyticsProvider(
                    analyticsService,
                    notificationService,
                    calibrationService: aiCalibrationService,
                  );
                },
              ),
              ChangeNotifierProvider(
                create: (_) => ContextProvider(asbabService: asbabService),
              ),
              Provider.value(value: storageService),
              Provider.value(value: hifzDb),
              Provider.value(value: aiPlanService),
              Provider.value(value: breakRecoveryService),
              Provider.value(value: contextualTipsService),
              Provider.value(value: motivationalService),
              ChangeNotifierProvider.value(value: authService),
              ChangeNotifierProvider.value(value: cloudSyncService),
              ChangeNotifierProvider.value(value: qfUserAuth),
              Provider.value(value: qfUserApi),
            ],
            child: const QuranApp(),
          ),
        ),
      );
    },
  );
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        // Sync reciter language when locale changes
        final readingProvider = context.read<QuranReadingProvider>();
        readingProvider.setLanguage(localeProvider.locale.languageCode);
        return MaterialApp(
          useInheritedMediaQuery: true,
          builder: DevicePreview.appBuilder,
          title: 'Jawhar',
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          theme: ThemeData(
            textTheme: GoogleFonts.geistTextTheme(),
            useMaterial3: true,
            primaryColor: themeProvider.accentColor,
            scaffoldBackgroundColor: themeProvider.scaffoldBackground,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A454E),
              primary: themeProvider.accentColor,
              brightness: themeProvider.isDark
                  ? Brightness.dark
                  : Brightness.light,
            ),
          ),
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.trackpad,
            },
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}
