import 'dart:ui';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuranReadingProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: DevicePreview(
        enabled: true,
        builder: (context) => const QuranApp(),
      ),
    ),
  );
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Quran Prototype',
          debugShowCheckedModeBanner: false,
          locale: DevicePreview.locale(context),
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
          home: Scaffold(
            backgroundColor: themeProvider.scaffoldBackground,
            body: const Center(child: ReadingScreen()),
          ),
        );
      },
    );
  }
}
