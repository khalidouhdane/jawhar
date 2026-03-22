// ──────────────────────────────────────────────
// DEPRECATED — This screen is no longer used.
// The Hifz tab has been replaced by the Practice tab.
// Dashboard functionality is now in home_screen.dart.
// Kept for reference only. Remove once migration is stable.
// ──────────────────────────────────────────────

import 'package:flutter/material.dart';

/// @deprecated Replaced by dashboard (HomeScreen) + PracticeScreen.
class HifzScreen extends StatelessWidget {
  const HifzScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Deprecated — use Dashboard')),
    );
  }
}
