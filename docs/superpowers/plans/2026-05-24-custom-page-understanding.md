# Custom Page Understanding & Redesigned Progress Cards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign progress tracking on the Home Tab, simplify context cards, and introduce a verse-by-verse PageUnderstandingScreen linking translation, Tafseer, reasons of revelation, and stories.

**Architecture:** We will dynamically reposition the progress card based on the active profile's progress metrics. We will implement `PageUnderstandingScreen` using `PageView` and custom horizontal tab controls, dynamically hiding/showing tabs (like Asbab al-Nuzul) and related story carousels by filtering static and context providers. All verse references are formatted using `VerseRefFormatter`.

**Tech Stack:** Flutter, Dart 3, Provider State Management, Lucide Icons, Google Fonts.

---

### Task 1: Redesign and Dynamically Place Progress Card

**Files:**
- Modify: [progress_strip.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/widgets/dashboard/progress_strip.dart)
- Modify: [profile_dashboard.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/widgets/dashboard/profile_dashboard.dart)

- [ ] **Step 1: Redesign ProgressStrip to show three stats columns**
  Modify `ProgressStrip` to accept streak, memorized, and session count parameters, rendering a card with three columns:
  * Streak (Flame icon)
  * Memorized (BookOpen icon)
  * Sessions (History icon)
  * A tap-bar at the bottom "View Detailed Progress" with a chevron.
  
  ```dart
  // In lib/widgets/dashboard/progress_strip.dart
  import 'package:flutter/material.dart';
  import 'package:lucide_icons/lucide_icons.dart';
  import 'package:quran_app/providers/theme_provider.dart';
  import 'package:provider/provider.dart';
  import 'package:quran_app/theme/geist_typography.dart';
  import 'package:quran_app/l10n/app_localizations.dart';

  class ProgressStrip extends StatelessWidget {
    final int memorizedPages;
    final int streakDays;
    final int sessionCount;
    final VoidCallback onTap;

    const ProgressStrip({
      super.key,
      required this.memorizedPages,
      required this.streakDays,
      required this.sessionCount,
      required this.onTap,
    });

    @override
    Widget build(BuildContext context) {
      final theme = context.watch<ThemeProvider>();
      final l = AppLocalizations.of(context)!;
      final pct = (memorizedPages / 604) * 100;

      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(theme.radiusLg),
            border: Border.all(color: theme.dividerColor),
            boxShadow: theme.shadowCard,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol(theme, LucideIcons.flame, streakDays.toString(), l.progressActiveDays(streakDays)),
                    _buildDivider(theme),
                    _buildStatCol(theme, LucideIcons.bookOpen, memorizedPages.toString(), l.progressLegendMemorized),
                    _buildDivider(theme),
                    _buildStatCol(theme, LucideIcons.history, sessionCount.toString(), l.progressViewHistory),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(theme.radiusLg),
                    bottomRight: Radius.circular(theme.radiusLg),
                  ),
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${pct.toStringAsFixed(1)}% - ${l.progressViewHistory}",
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(LucideIcons.chevronRight, size: 14, color: theme.accentColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildStatCol(ThemeProvider theme, IconData icon, String value, String label) {
      return Column(
        children: [
          Icon(icon, size: 20, color: theme.accentColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 10,
              color: theme.mutedText,
            ),
          ),
        ],
      );
    }

    Widget _buildDivider(ThemeProvider theme) {
      return Container(width: 1, height: 36, color: theme.dividerColor);
    }
  }
  ```

- [ ] **Step 2: Update profile_dashboard.dart to dynamically reposition the card**
  Retrieve streak totalActiveDays, memorizedPages count, and sessionCount (from `session_history`). Show card right under PlanCard if any metric > 0, else show at the bottom.
  ```dart
  // In lib/widgets/dashboard/profile_dashboard.dart
  // Fetch session count and status counts in build
  final db = context.read<HifzDatabaseService>();
  return FutureBuilder<List<dynamic>>(
    future: Future.wait([
      db.getPageStatusCounts(profile.id),
      db.getSessionHistory(profile.id, limit: 1),
    ]),
    builder: (context, snapshot) {
      final counts = (snapshot.data?[0] as Map<PageStatus, int>?) ?? {};
      final history = (snapshot.data?[1] as List<SessionRecord>?) ?? [];
      final memorizedCount = counts[PageStatus.memorized] ?? 0;
      final sessionCount = history.length;
      final streakDays = profileProvider.streak.totalActiveDays;

      final hasProgress = streakDays > 0 || memorizedCount > 0 || sessionCount > 0;
      // reposition...
    }
  )
  ```

- [ ] **Step 3: Run analysis & verify no compile issues**
  Run: `flutter analyze`
  Expected: No analysis errors in progress_strip or profile_dashboard.

- [ ] **Step 4: Commit changes**
  ```bash
  git add lib/widgets/dashboard/progress_strip.dart lib/widgets/dashboard/profile_dashboard.dart
  git commit -m "feat(dashboard): Redesign progress strip to stats card and add dynamic positioning"
  ```

---

### Task 2: Redesign and Simplify Context Cards

**Files:**
- Modify: [understanding_spotlight.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/widgets/dashboard/understanding_spotlight.dart)
- Modify: [today_context_card.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/widgets/understand/today_context_card.dart)

- [ ] **Step 1: Redesign Home Tab UnderstandingSpotlight card**
  Update design with 4dp left Pink border and single "Explore" action.
  ```dart
  // In lib/widgets/dashboard/understanding_spotlight.dart
  import 'package:quran_app/theme/semantic_colors.dart';
  import 'package:quran_app/screens/hifz/page_understanding_screen.dart';
  // ...
  final accentColor = SemanticColors.pillarUnderstand.fg(theme.isDark);
  // Add left-border and button to navigate to PageUnderstandingScreen(sabaqPage: sabaqPage)
  ```

- [ ] **Step 2: Simplify Understand Tab TodayContextCard card**
  Reduce actions to one "Explore" button.
  ```dart
  // In lib/widgets/understand/today_context_card.dart
  // Navigate to PageUnderstandingScreen(sabaqPage: sabaqPage) on tap
  ```

- [ ] **Step 3: Verify compile safety**
  Run: `flutter analyze`
  Expected: PASS

- [ ] **Step 4: Commit changes**
  ```bash
  git add lib/widgets/dashboard/understanding_spotlight.dart lib/widgets/understand/today_context_card.dart
  git commit -m "feat(context): Redesign home and understand context cards to a single page-explore action"
  ```

---

### Task 3: Implement PageUnderstandingScreen

**Files:**
- Create: [page_understanding_screen.dart](file:///c:/Users/khali/OneDrive/Bureau/Quran%20App/lib/screens/hifz/page_understanding_screen.dart)

- [ ] **Step 1: Write initial structure for PageUnderstandingScreen**
  Implement scrollable top toggle bar, page view, side navigation arrows, and tabs (Translation, Tafseer, Asbab if available).
  Format verse references strictly using `VerseRefFormatter`.

- [ ] **Step 2: Add inline Tafseer details toggle and Related Topics**
  Add inline button in the Tafseer tab to expand detailed Tafseer. Add bottom horizontal list of topics matching `topic.surahIds.contains(activeSurahId)`.

- [ ] **Step 3: Run analysis & verify screen builds**
  Run: `flutter analyze`
  Expected: PASS

- [ ] **Step 4: Commit changes**
  ```bash
  git add lib/screens/hifz/page_understanding_screen.dart
  git commit -m "feat(screens): Add page-level verse-by-verse PageUnderstandingScreen with Tafseer, Asbab, and Topics"
  ```
