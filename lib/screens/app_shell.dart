import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/update_provider.dart';
import 'package:quran_app/screens/home_screen.dart';
import 'package:quran_app/screens/practice_screen.dart';
import 'package:quran_app/screens/read_index_screen.dart';
import 'package:quran_app/screens/audio_screen.dart';
import 'package:quran_app/screens/profile_screen.dart';
import 'package:quran_app/widgets/bottom_nav_bar.dart';
import 'package:quran_app/widgets/update_dialog.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    // Check for updates after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    if (!mounted) return;
    final updateProvider = context.read<UpdateProvider>();
    final hasUpdate = await updateProvider.checkForUpdate();
    if (hasUpdate && mounted) {
      UpdateDialog.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final theme = context.watch<ThemeProvider>();

    // Tab order: Dashboard / Practice / Read / Listen / Profile
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: IndexedStack(
        index: nav.currentIndex,
        children: const [
          HomeScreen(),      // 0: Dashboard (will be rewritten in Batch C)
          PracticeScreen(),  // 1: Practice (placeholder)
          ReadIndexScreen(), // 2: Read
          AudioScreen(),     // 3: Listen
          ProfileScreen(),   // 4: Profile
        ],
      ),
      bottomNavigationBar: nav.isInReadingView ? null : const AppBottomNavBar(),
    );
  }
}
