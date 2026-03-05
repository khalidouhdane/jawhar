import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_service/audio_service.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/app_shell.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/providers/hifz_provider.dart';
import 'package:quran_app/providers/werd_provider.dart';
import 'package:quran_app/providers/locale_provider.dart';
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

  // Default tab: Home (0) if user has reading history, else Read (1)
  final defaultTab = storageService.hasReadingHistory ? 0 : 1;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => QuranReadingProvider(storage: storageService),
        ),
        ChangeNotifierProvider.value(value: audioProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider(defaultTab)),
        ChangeNotifierProvider(create: (_) => HifzProvider(prefs)),
        ChangeNotifierProvider(create: (_) => WerdProvider(storageService)),
        ChangeNotifierProvider(create: (_) => LocaleProvider(prefs)),
        Provider.value(value: storageService),
      ],
      child: DevicePreview(
        enabled:
            !kReleaseMode &&
            (Platform.isWindows || Platform.isMacOS || Platform.isLinux),
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
