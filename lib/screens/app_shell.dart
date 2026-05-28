import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/providers/notification_provider.dart';
import 'package:quran_app/providers/plan_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/update_provider.dart';
import 'package:quran_app/screens/home_screen.dart';
import 'package:quran_app/screens/practice_screen.dart';
import 'package:quran_app/screens/read_index_screen.dart';
import 'package:quran_app/screens/profile_screen.dart';
import 'package:quran_app/screens/understand_screen.dart';
import 'package:quran_app/widgets/bottom_nav_bar.dart';
import 'package:quran_app/widgets/web_app_sidebar.dart';
import 'package:quran_app/widgets/update_dialog.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool? _lastIsInReadingView;
  bool? _lastIsDark;

  @override
  void initState() {
    super.initState();
    // Check for updates after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
      _ensureNotifications();
    });
  }

  Future<void> _checkForUpdate() async {
    if (!mounted) return;
    // Skip on iOS — updates are delivered via TestFlight / App Store, not APK.
    if (Theme.of(context).platform == TargetPlatform.iOS) return;
    final updateProvider = context.read<UpdateProvider>();
    final hasUpdate = await updateProvider.checkForUpdate();
    if (hasUpdate && mounted) {
      UpdateDialog.show(context);
    }
  }

  void _ensureNotifications() {
    if (!mounted) return;
    final plan = context.read<PlanProvider>();
    final notif = context.read<NotificationProvider>();
    notif.ensureScheduled(sessionCompletedToday: plan.isPlanCompleted);
  }

  void _syncSystemBars(NavigationProvider nav, ThemeProvider theme) {
    final shouldSync =
        !nav.isInReadingView &&
        (_lastIsInReadingView != nav.isInReadingView ||
            _lastIsDark != theme.isDark);

    _lastIsInReadingView = nav.isInReadingView;
    _lastIsDark = theme.isDark;

    if (!shouldSync) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setSystemUIOverlayStyle(theme.systemOverlayStyle);
    });
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final theme = context.watch<ThemeProvider>();
    _syncSystemBars(nav, theme);
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 768;

    final Widget contentStack = IndexedStack(
      index: nav.currentIndex,
      children: const [
        HomeScreen(),
        ReadIndexScreen(),
        UnderstandScreen(),
        PracticeScreen(),
        ProfileScreen(),
      ],
    );

    if (isWide) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackground,
        body: Row(
          children: [
            if (!nav.isInReadingView) const WebAppSidebar(),
            Expanded(child: contentStack),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: contentStack,
      bottomNavigationBar: nav.isInReadingView ? null : const AppBottomNavBar(),
    );
  }
}
