import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/providers/audio_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QuranReadingProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: const QuranApp(),
    ),
  );
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
        primaryColor: const Color(0xFF1A454E),
        scaffoldBackgroundColor: const Color(0xFFF3F4F6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A454E),
          primary: const Color(0xFF1A454E),
        ),
      ),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.trackpad
        },
      ),
      home: const Scaffold(
        body: Center(
          child: ReadingScreen(),
        ),
      ),
    );
  }
}
