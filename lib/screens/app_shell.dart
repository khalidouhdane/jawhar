import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/home_screen.dart';
import 'package:quran_app/screens/read_index_screen.dart';
import 'package:quran_app/screens/audio_screen.dart';
import 'package:quran_app/screens/hifz_screen.dart';
import 'package:quran_app/screens/profile_screen.dart';
import 'package:quran_app/widgets/bottom_nav_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: IndexedStack(
        index: nav.currentIndex,
        children: const [
          HomeScreen(),
          ReadIndexScreen(),
          AudioScreen(),
          HifzScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: nav.isInReadingView ? null : const AppBottomNavBar(),
    );
  }
}
