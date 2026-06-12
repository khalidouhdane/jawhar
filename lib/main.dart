import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/models/hifz_models.dart';
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
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:quran_app/services/account_api.dart';
import 'package:quran_app/services/app_check_service.dart';
import 'package:quran_app/services/auth_service.dart';
import 'package:quran_app/services/auth_sync_coordinator.dart';
import 'package:quran_app/services/cloud_sync_service.dart';
import 'package:quran_app/services/outbox_service.dart';
import 'package:quran_app/services/sync_worker.dart';
import 'package:quran_app/services/write_path_store.dart';
import 'package:quran_app/widgets/update_required_banner.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_app/screens/splash_screen.dart';
import 'package:device_preview_screenshot/device_preview_screenshot.dart';

// Conditional imports for native-only packages
import 'package:quran_app/services/native_init.dart'
    if (dart.library.js_interop) 'package:quran_app/services/native_init_web.dart'
    as native_init;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _runAppGuarded();
}

Future<void> _runAppGuarded() async {
  try {
    await _bootstrap();
  } catch (error, stackTrace) {
    debugPrint('Application startup failed: $error\n$stackTrace');
    runApp(StartupFailureApp(error: error, onRetry: _runAppGuarded));
  }
}

Future<void> _bootstrap() async {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  GoogleFonts.config.allowRuntimeFetching = false;

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
  await audioProvider.initProxy();

  // Initialize Hifz database
  final hifzDb = HifzDatabaseService();
  // Trigger DB creation/migration early
  await hifzDb.database;

  // Initialize Firebase (guarded so a startup retry doesn't hit duplicate-app)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // App Check, LOG-ONLY wave (roadmap §8 Phase 8 task 3): Android only
  // (Play Integrity / debug provider); iOS+web deferred, Windows exempt
  // (§9 — no provider exists). Fail-open: never blocks startup.
  await AppCheckService.activate();

  // Initialize auth service
  final authService = AuthService();
  authService.init();

  // Per-user sync flags + the §5 force-update gate. The build number feeds
  // the gate (`updateRequired`): below the server's minSupportedBuild, SYNC
  // ONLY pauses — the offline core loop is untouched.
  final writePathStore = WritePathStore(prefs);
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    writePathStore.currentBuildNumber = int.tryParse(packageInfo.buildNumber);
  } catch (e) {
    // Unknown build number disables the gate (fail-open, sync keeps going).
    debugPrint('PackageInfo unavailable, update gate disabled: $e');
  }

  // ID-token source shared by every /v1 client below.
  Future<String?> idTokenProvider({bool forceRefresh = false}) async =>
      FirebaseAuth.instance.currentUser?.getIdToken(forceRefresh);

  // Facts write path (roadmap §7): uid-partitioned outbox + drain worker.
  final outboxService = OutboxService(hifzDb);
  final syncWorker = SyncWorker(
    outbox: outboxService,
    store: writePathStore,
    authChanges: authService,
    uidProvider: () => authService.uid,
    idTokenProvider: idTokenProvider,
    appCheckTokenProvider: AppCheckService.getToken,
    connectivityChanges: Connectivity().onConnectivityChanged,
  );

  // Initialize cloud sync service (legacy direct-Firestore mirror — kept
  // compiled-in as the Phase 4 rollback target). Account deletion goes
  // through `DELETE /v1/me` first (§5 #11), legacy cascade as fallback;
  // the worker + outbox are quiesced before the deletion so a racing
  // drain cannot recreate orphaned docs under the deleted uid.
  final cloudSyncService = CloudSyncService(
    hifzDb,
    writePathStore: writePathStore,
    accountApi: AccountApi(idTokenProvider: idTokenProvider),
    syncWorker: syncWorker,
    outbox: outboxService,
  );

  // App-start trigger: bootstrap meta (writePath/datasetEpoch) + drain.
  unawaited(syncWorker.start());

  // Import mutashabihat dataset if needed (non-blocking)
  unawaited(MutashabihatImportService(hifzDb).importIfNeeded());

  // Import asbab al-nuzul dataset if needed (non-blocking)
  final asbabService = AsbabNuzulService();
  unawaited(asbabService.importIfNeeded());

  // Determine initial language from saved or system locale
  final savedLocale = prefs.getString('app_locale');
  final systemLang = PlatformDispatcher.instance.locale.languageCode;
  final initialLang = savedLocale ?? (systemLang == 'ar' ? 'ar' : 'en');

  // Set default reciter: check SharedPreferences first, then active profile, then default rewaya
  final savedReciterId = storageService.defaultReciterId;
  if (savedReciterId != null) {
    final name = storageService.defaultReciterName ?? '';
    final apiSourceStr =
        storageService.defaultReciterApiSource ?? 'quranDotCom';
    final serverUrl = storageService.defaultReciterServerUrl;
    final moshafId = storageService.defaultReciterMoshafId;

    audioProvider.setReciter(
      savedReciterId,
      name: name,
      apiSource: apiSourceStr == 'mp3Quran'
          ? ApiSource.mp3Quran
          : ApiSource.quranDotCom,
      serverUrl: serverUrl,
      moshafId: moshafId,
    );
  } else {
    // Try profile default reciter
    final activeProfile = await hifzDb.getActiveProfile();
    if (activeProfile != null) {
      final profileReciterId = activeProfile.defaultReciterId;
      final profileReciterSource = activeProfile.defaultReciterSource;

      String reciterName = '';
      if (profileReciterSource == ReciterSource.mp3Quran) {
        if (profileReciterId == 16) {
          reciterName = initialLang == 'ar'
              ? 'العيون الكوشي'
              : 'Al Ayoun Al Koushi';
        } else {
          reciterName = 'Reciter $profileReciterId';
        }
      } else {
        reciterName = initialLang == 'ar'
            ? (Reciter.arabicNamesById[profileReciterId] ??
                  'قارئ $profileReciterId')
            : 'Reciter $profileReciterId';
      }

      audioProvider.setReciter(
        profileReciterId,
        name: reciterName,
        apiSource: profileReciterSource == ReciterSource.mp3Quran
            ? ApiSource.mp3Quran
            : ApiSource.quranDotCom,
        serverUrl:
            profileReciterSource == ReciterSource.mp3Quran &&
                profileReciterId == 16
            ? "https://server11.mp3quran.net/koshi/"
            : null,
        moshafId:
            profileReciterSource == ReciterSource.mp3Quran &&
                profileReciterId == 16
            ? 16
            : null,
      );
    } else {
      // Fallback to default rewaya reciter
      if (storageService.savedRewaya == 2) {
        // Warsh: Al Ayoun Al Koushi
        final name = initialLang == 'ar'
            ? 'العيون الكوشي'
            : 'Al Ayoun Al Koushi';
        audioProvider.setReciter(
          16,
          name: name,
          apiSource: ApiSource.mp3Quran,
          serverUrl: "https://server11.mp3quran.net/koshi/",
          moshafId: 16,
        );
      } else {
        // Hafs default: Mishary Rashid Alafasy (QDC id=7)
        if (initialLang == 'ar') {
          final arabicName = Reciter.arabicNamesById[7] ?? 'مشاري راشد العفاسي';
          audioProvider.updateReciterName(arabicName);
        }
      }
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
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      // Disable performance tracing in debug — was 1.0 (100%), caused
      // significant CPU overhead by tracing every UI operation.
      options.tracesSampleRate = kReleaseMode ? 0.2 : 0.0;
    },
    appRunner: () {
      // Enable DevicePreview only on desktop debug builds
      final enablePreview =
          !kReleaseMode &&
          !kIsWeb &&
          (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

      // Save screenshots to a 'screenshots' folder in the project directory
      // Only create on desktop debug builds — on Android, Directory.current
      // is '/' which is not writable and would crash the app.
      Directory? screenshotDir;
      if (enablePreview) {
        screenshotDir = Directory('${Directory.current.path}/screenshots');
        if (!screenshotDir.existsSync()) {
          screenshotDir.createSync();
        }
      }

      runApp(
        DevicePreview(
          enabled: enablePreview,
          tools: [
            ...DevicePreview.defaultTools,
            if (screenshotDir != null)
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
              ChangeNotifierProvider(
                create: (_) => NavigationProvider(defaultTab),
              ),
              ChangeNotifierProvider(
                create: (_) => HifzProfileProvider(
                  hifzDb,
                  authService,
                  cloudSyncService,
                  writePathStore: writePathStore,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => PlanProvider(
                  hifzDb,
                  authService,
                  cloudSyncService,
                  aiPlanService: aiPlanService,
                  outbox: outboxService,
                  writePathStore: writePathStore,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => SessionProvider(
                  hifzDb,
                  authService,
                  cloudSyncService,
                  outbox: outboxService,
                  writePathStore: writePathStore,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => FlashcardProvider(
                  hifzDb,
                  authService,
                  cloudSyncService,
                  outbox: outboxService,
                  writePathStore: writePathStore,
                ),
              ),
              ChangeNotifierProvider(
                create: (_) => WerdProvider(storageService),
              ),
              ChangeNotifierProvider(create: (_) => LocaleProvider(prefs)),
              ChangeNotifierProvider(create: (_) => UpdateProvider()),
              ChangeNotifierProvider(
                create: (_) => BookmarkProvider(
                  storageService,
                  authService,
                  cloudSyncService,
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
                  final notificationService = NotificationService(
                    analyticsService,
                  );
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
              ChangeNotifierProvider.value(value: outboxService),
              ChangeNotifierProvider.value(value: syncWorker),
              Provider.value(value: writePathStore),
              Provider(
                create: (_) =>
                    AuthSyncCoordinator(authService, cloudSyncService),
                dispose: (_, coordinator) => coordinator.dispose(),
              ),
            ],
            child: const QuranApp(),
          ),
        ),
      );
    },
  );
}

class StartupFailureApp extends StatelessWidget {
  final Object error;
  final Future<void> Function()? onRetry;

  const StartupFailureApp({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isArabic =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'ar';
    final title = isArabic ? 'تعذّر تشغيل جوهر' : 'Jawhar could not start';
    final message = isArabic
        ? 'حدث خطأ أثناء بدء التطبيق. حاول مرة أخرى، وإذا استمرت المشكلة '
              'فأعد تشغيل التطبيق.'
        : 'Something went wrong while starting the app. Try again; if the '
              'problem continues, restart the app.';
    final retryLabel = isArabic ? 'إعادة المحاولة' : 'Retry';

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(
                      error.toString(),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    if (onRetry != null) ...[
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => unawaited(onRetry!()),
                        icon: const Icon(Icons.refresh),
                        label: Text(retryLabel),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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
          builder: (context, child) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: themeProvider.systemOverlayStyle,
              child: DevicePreview.appBuilder(
                context,
                // §5 force-update gate: non-dismissable banner over every
                // route while sync is paused; the app (offline core loop)
                // stays fully usable behind it.
                UpdateRequiredGate(child: child),
              ),
            );
          },
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
