import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/app_shell.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/providers/hifz_provider.dart';
import 'package:quran_app/providers/werd_provider.dart';
import 'package:quran_app/providers/locale_provider.dart';
import 'package:quran_app/providers/update_provider.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/services/quran_audio_handler.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quran_app/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage
  final prefs = await SharedPreferences.getInstance();
  final storageService = LocalStorageService(prefs);

  // Initialize audio_service — creates a foreground service for media notification
  final audioHandler = await AudioService.init(
    builder: () => QuranAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.quranapp.audio',
      androidNotificationChannelName: 'Quran Audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  // Create AudioProvider and wire the handler
  final audioProvider = AudioProvider();
  audioProvider.attachAudioHandler(audioHandler);

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

  // Default tab: Home (0) if user has reading history, else Read (1)
  final defaultTab = storageService.hasReadingHistory ? 0 : 1;

  runApp(
    MultiProvider(
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
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider(defaultTab)),
        ChangeNotifierProvider(create: (_) => HifzProvider(prefs)),
        ChangeNotifierProvider(create: (_) => WerdProvider(storageService)),
        ChangeNotifierProvider(create: (_) => LocaleProvider(prefs)),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider(storageService)),
        Provider.value(value: storageService),
      ],
      child: DevicePreview(
        enabled:
            !kReleaseMode &&
            !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.windows ||
             defaultTargetPlatform == TargetPlatform.macOS ||
             defaultTargetPlatform == TargetPlatform.linux),
        builder: (context) => const QuranApp(),
      ),
    ),
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
          title: 'Le Quran',
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          supportedLocales: const [Locale('en'), Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: DevicePreview.appBuilder,
          theme: ThemeData(
            fontFamily: 'Inter',
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
          home: Builder(
            builder: (context) {
              final storage = context.read<LocalStorageService>();
              if (!storage.hasCompletedOnboarding) {
                return const OnboardingScreen();
              }
              return const AppShell();
            },
          ),
        );
      },
    );
  }
}
