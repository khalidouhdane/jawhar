# Geist Design System Migration — Phased Roadmap

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate Le Quran from the current teal-brand 3-theme system to a Vercel (Geist)-inspired binary light/dark design system using IBM Plex Sans Arabic as the unified font.

**Architecture:** ThemeProvider becomes the single source of truth for all Geist tokens (neutral gray scale, shadows, radii). A new `SemanticColors` class provides muted functional colors for practice cards, analytics, and milestones. All 460+ `fontFamily: 'Inter'` references are replaced via global ThemeData default + targeted cleanup.

**Tech Stack:** Flutter, Provider, google_fonts (IBM Plex Sans Arabic + IBM Plex Mono), existing KFGQPC for Quranic text.

**Design Reference:** `docs/vercel_design.md`

---

## Phase Overview

| Phase | Scope | Files | Risk |
|-------|-------|-------|------|
| **1** | Foundation (Theme + Tokens + Font) | 3 new, 2 modify | Low — no UI changes yet |
| **2** | Global Font Swap | 40 files, mechanical | Low — find-and-replace |
| **3** | Shadow-as-Border + Radii | 43 files, mechanical | Medium — visual changes |
| **4** | Color Migration (Screens) | 18 files, design-sensitive | High — most visible |
| **5** | Polish + Theme Picker + Cleanup | 5 files | Low — finishing touches |

Each phase produces a working, testable app. No phase depends on a later phase.

---

## Phase 1: Foundation

> Build the new token system. No UI changes — just new files and ThemeProvider rewrite.

### Task 1.1: Create SemanticColors

**Files:**
- Create: `lib/theme/semantic_colors.dart`

- [ ] **Step 1: Create the semantic color class**

```dart
// lib/theme/semantic_colors.dart
import 'package:flutter/material.dart';

/// Functional colors for content differentiation.
/// These are NOT part of the Geist neutral scale.
/// Used only in specific content contexts (practice, analytics, milestones).
class SemanticColors {
  SemanticColors._();

  // ── Practice Card Identity (muted, whispered tints) ──
  // Light mode: soft tinted background + muted text
  // Dark mode: same hue at 8% opacity + lighter text

  static const practiceBlue = _SemanticPair(
    lightBg: Color(0xFFF0F4FF), lightFg: Color(0xFF4B6A9B),
    darkBg: Color(0x143B82F6), darkFg: Color(0xFF7DA4D4),
  );
  static const practiceCyan = _SemanticPair(
    lightBg: Color(0xFFEFFCFC), lightFg: Color(0xFF3D8A8A),
    darkBg: Color(0x1406B6D4), darkFg: Color(0xFF6DB5B5),
  );
  static const practiceEmerald = _SemanticPair(
    lightBg: Color(0xFFEEFBF4), lightFg: Color(0xFF3D7A5F),
    darkBg: Color(0x1410B981), darkFg: Color(0xFF6DBF9A),
  );
  static const practicePurple = _SemanticPair(
    lightBg: Color(0xFFF3F0FF), lightFg: Color(0xFF6B5CA5),
    darkBg: Color(0x148B5CF6), darkFg: Color(0xFFA893E0),
  );
  static const practiceAmber = _SemanticPair(
    lightBg: Color(0xFFFFF9EB), lightFg: Color(0xFF8A6D2B),
    darkBg: Color(0x14F59E0B), darkFg: Color(0xFFCDB06A),
  );
  static const practiceRed = _SemanticPair(
    lightBg: Color(0xFFFEF1F1), lightFg: Color(0xFF9B4B4B),
    darkBg: Color(0x14EF4444), darkFg: Color(0xFFD48A8A),
  );

  // ── Flashcard Ratings ──
  static const ratingForgot = Color(0xFFB84040);   // Muted red
  static const ratingWeak = Color(0xFFC4882A);      // Muted amber
  static const ratingOk = Color(0xFF4B7BBF);        // Muted blue
  static const ratingStrong = Color(0xFF3DA06A);    // Muted green

  // ── Progress States ──
  static const progressMemorized = Color(0xFF3DA06A);
  static const progressReviewing = Color(0xFF4B7BBF);
  static const progressLearning = Color(0xFFC4882A);

  // ── Suggestion Types ──
  static const suggPositive = _SemanticPair(
    lightBg: Color(0xFFEEFBF4), lightFg: Color(0xFF3D7A5F),
    darkBg: Color(0x144DB6AC), darkFg: Color(0xFF6DB5B5),
  );
  static const suggGentle = _SemanticPair(
    lightBg: Color(0xFFF0F0FF), lightFg: Color(0xFF5A5CA5),
    darkBg: Color(0x147986CB), darkFg: Color(0xFF9AA4D4),
  );
  static const suggAttention = _SemanticPair(
    lightBg: Color(0xFFFFF9EB), lightFg: Color(0xFF8A6D2B),
    darkBg: Color(0x14FFB74D), darkFg: Color(0xFFCDB06A),
  );
  static const suggInfo = _SemanticPair(
    lightBg: Color(0xFFF0F4FF), lightFg: Color(0xFF4B6A9B),
    darkBg: Color(0x1490CAF9), darkFg: Color(0xFF7DA4D4),
  );

  // ── Milestone Gradients (kept — celebratory content) ──
  static const milestoneJuz = [Color(0xFF1A454E), Color(0xFF2D7A6F)];
  static const milestoneKhatm = [Color(0xFFB8860B), Color(0xFFDAA520)];
  static const milestoneStreak = [Color(0xFFD84315), Color(0xFFFF6D00)];

  // ── Analytics ──
  static const analyticsSessions = Color(0xFF5AA0A0);
  static const analyticsPages = Color(0xFF6B7BBF);
  static const analyticsCompletion = Color(0xFFCDA04A);
  static const analyticsTime = Color(0xFF7DA4D4);

  // ── Assessment ──
  static const assessStrong = Color(0xFF5AAA6A);
  static const assessOkay = Color(0xFFCDA030);
  static const assessNeedsWork = Color(0xFFBF5050);
}

/// A color pair for light/dark mode semantic usage.
class _SemanticPair {
  final Color lightBg, lightFg, darkBg, darkFg;
  const _SemanticPair({
    required this.lightBg, required this.lightFg,
    required this.darkBg, required this.darkFg,
  });

  Color bg(bool isDark) => isDark ? darkBg : lightBg;
  Color fg(bool isDark) => isDark ? darkFg : lightFg;
}
```

- [ ] **Step 2: Verify file compiles**

Run: `cd "c:\Users\khali\OneDrive\Bureau\Quran App" && dart analyze lib/theme/semantic_colors.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add lib/theme/semantic_colors.dart
git commit -m "feat(theme): add SemanticColors for functional color tokens"
```

---

### Task 1.2: Create GeistShadows

**Files:**
- Create: `lib/theme/geist_shadows.dart`

- [ ] **Step 1: Create the shadow factory class**

```dart
// lib/theme/geist_shadows.dart
import 'package:flutter/material.dart';

/// Shadow-as-border system from the Vercel design spec.
/// Replaces Border.all() across the app.
class GeistShadows {
  GeistShadows._();

  /// Level 1: Ring border — replaces Border.all()
  static List<BoxShadow> ring({bool isDark = false}) => [
    BoxShadow(
      color: isDark
          ? const Color(0x1FFFFFFF)  // white at 12%
          : const Color(0x14000000), // black at 8%
      spreadRadius: 1,
      blurRadius: 0,
    ),
  ];

  /// Level 2: Subtle card — ring + soft lift
  static List<BoxShadow> subtleCard({bool isDark = false}) => [
    ...ring(isDark: isDark),
    BoxShadow(
      color: isDark
          ? const Color(0x33000000)
          : const Color(0x0A000000),
      offset: const Offset(0, 2),
      blurRadius: 2,
    ),
  ];

  /// Level 3: Full card — ring + lift + depth
  static List<BoxShadow> fullCard({bool isDark = false}) => [
    ...subtleCard(isDark: isDark),
    BoxShadow(
      color: isDark
          ? const Color(0x40000000)
          : const Color(0x0A000000),
      offset: const Offset(0, 8),
      blurRadius: 8,
      spreadRadius: -8,
    ),
  ];
}
```

- [ ] **Step 2: Verify file compiles**
- [ ] **Step 3: Commit**

```bash
git add lib/theme/geist_shadows.dart
git commit -m "feat(theme): add GeistShadows shadow-as-border system"
```

---

### Task 1.3: Rewrite ThemeProvider

**Files:**
- Modify: `lib/providers/theme_provider.dart`

- [ ] **Step 1: Replace AppTheme enum**

Change `enum AppTheme { classic, warm, dark }` → `enum AppTheme { light, dark }`

- [ ] **Step 2: Remove `_pick()` helper, replace with ternary**

Replace the 3-way `_pick(classic:, warm:, dark:)` with a simple `isDark ? dark : light` pattern.

- [ ] **Step 3: Replace all color values with Geist neutral scale**

Key token mapping:

| Token | Light | Dark |
|-------|-------|------|
| scaffoldBackground | `#FFFFFF` | `#000000` |
| surfaceColor / cardColor | `#FFFFFF` | `#0A0A0A` |
| primaryText | `#171717` | `#EDEDED` |
| secondaryText | `#666666` | `#A1A1A1` |
| mutedText | `#999999` | `#666666` |
| dividerColor | `#EAEAEA` | `#333333` |
| accentColor | `#171717` | `#EDEDED` |
| accentLight | `#F5F5F5` | `#1A1A1A` |
| pillBackground | `#FAFAFA` | `#111111` |
| inputFill | `#FAFAFA` | `#111111` |
| chipSelected | `#171717` | `#EDEDED` |
| chipUnselected | `#FAFAFA` | `#111111` |
| iconColor | `#171717` | `#EDEDED` |

- [ ] **Step 4: Remove warm-specific getters** (`isWarm`)

- [ ] **Step 5: Add shadow getters that delegate to GeistShadows**

```dart
List<BoxShadow> get shadowRing => GeistShadows.ring(isDark: isDark);
List<BoxShadow> get shadowCard => GeistShadows.subtleCard(isDark: isDark);
List<BoxShadow> get shadowCardFull => GeistShadows.fullCard(isDark: isDark);
```

- [ ] **Step 6: Verify file compiles**

Run: `flutter analyze`
Expected: Warnings about `AppTheme.classic` and `AppTheme.warm` in other files (expected — Phase 4 fixes those)

- [ ] **Step 7: Commit**

```bash
git add lib/providers/theme_provider.dart lib/theme/
git commit -m "feat(theme): rewrite ThemeProvider to Geist light/dark binary"
```

---

### Task 1.4: Fix AppTheme references across codebase

**Files:**
- Modify: `lib/widgets/sheets/theme_picker_sheet.dart`
- Modify: Any file referencing `AppTheme.classic` or `AppTheme.warm`

- [ ] **Step 1: Find all references**

```powershell
Get-ChildItem lib -Recurse -Include "*.dart" | Select-String "AppTheme\.(classic|warm)" | ForEach-Object { $_.Path + ":" + $_.LineNumber }
```

- [ ] **Step 2: Replace `AppTheme.classic` → `AppTheme.light`, `AppTheme.warm` → `AppTheme.light`**

- [ ] **Step 3: Update theme_picker_sheet.dart to show only Light/Dark**

- [ ] **Step 4: Run `flutter analyze` — zero errors**

- [ ] **Step 5: Commit**

```bash
git commit -am "refactor(theme): migrate AppTheme.classic/warm → light"
```

---

## Phase 2: Global Font Swap

> Replace all 460+ `fontFamily: 'Inter'` with IBM Plex Sans Arabic via ThemeData default.

### Task 2.1: Set Global Font in main.dart

**Files:**
- Modify: `lib/main.dart:256`

- [ ] **Step 1: Import google_fonts and set default**

```dart
import 'package:google_fonts/google_fonts.dart';

// In the ThemeData construction:
theme: ThemeData(
  fontFamily: GoogleFonts.ibmPlexSansArabic().fontFamily,
  // ... rest of theme
),
```

- [ ] **Step 2: Commit**

```bash
git commit -am "feat(font): set IBM Plex Sans Arabic as global default font"
```

---

### Task 2.2: Remove hardcoded fontFamily: 'Inter' (batch)

**Files:** 40 files, ~460 occurrences

This is a mechanical find-and-replace. Since the global font is now IBM Plex Sans Arabic, every `fontFamily: 'Inter'` line can be deleted.

- [ ] **Step 1: Batch remove all `fontFamily: 'Inter'` lines**

Process files in groups by directory:
1. `lib/widgets/` (all widget files)
2. `lib/widgets/sheets/` (all sheet files)
3. `lib/widgets/hifz/` (all hifz widgets)
4. `lib/widgets/context/` (all context widgets)
5. `lib/screens/` (all screen files)
6. `lib/screens/hifz/` (all hifz screens)

For each file: remove the `fontFamily: 'Inter',` line. The font now comes from ThemeData.

- [ ] **Step 2: Add IBM Plex Mono for metrics/timers**

In files with timer/counter displays (session_screen, progress_card, weekly_report), replace the deleted fontFamily with:
```dart
fontFamily: GoogleFonts.ibmPlexMono().fontFamily,
```

Target locations:
- `lib/screens/hifz/session_screen.dart` — timer display, rep counter
- `lib/widgets/hifz/progress_card.dart` — stat numbers, percentages
- `lib/widgets/hifz/weekly_report.dart` — stat numbers

- [ ] **Step 3: Run `flutter analyze` — zero errors**
- [ ] **Step 4: Run app, verify text renders in IBM Plex**
- [ ] **Step 5: Commit**

```bash
git commit -am "refactor(font): remove all hardcoded Inter, use global IBM Plex Sans Arabic"
```

---

## Phase 3: Shadow-as-Border + Border Radius

> Replace all `Border.all()` with shadow rings. Normalize all `BorderRadius.circular()` values.

### Task 3.1: Shadow-as-Border Migration (batch)

**Files:** 43 files with `Border.all()`

- [ ] **Step 1: For each file with `Border.all()`, replace with shadow ring**

Pattern:
```dart
// BEFORE:
decoration: BoxDecoration(
  border: Border.all(color: theme.dividerColor),
  // existing boxShadow if any
),

// AFTER:
decoration: BoxDecoration(
  // border: removed
  boxShadow: theme.shadowCard, // or theme.shadowRing for flat elements
),
```

Priority order (highest impact first):
1. Dashboard widgets: plan_card, progress_card, suggestion_card, hifz_cta_card
2. Practice widgets: practice_screen, flashcard_review_screen
3. Session widgets: session_screen, session_overlay, pre_session_screen
4. Sheets: all bottom sheets
5. Remaining screens

- [ ] **Step 2: Commit per group**

---

### Task 3.2: Border Radius Normalization (batch)

**Files:** 50 files with `BorderRadius.circular()`

Vercel scale: `2 / 4 / 6 / 8 / 12 / 9999` px

Mapping:
- `6` → `6` (keep)
- `8` → `8` (keep)
- `10` → `8`
- `12` → `12` (keep)
- `14` → `8`
- `16` → `8`
- `18` → `8`
- `20` → `12`
- `24` → `12`
- Anything that was a pill/badge → `9999`

- [ ] **Step 1: Batch update all BorderRadius.circular values per mapping**
- [ ] **Step 2: Run app, visually verify cards look clean**
- [ ] **Step 3: Commit**

```bash
git commit -am "refactor(ui): normalize border radii to Geist scale"
```

---

## Phase 4: Color Migration

> The most design-sensitive phase. Replace hardcoded colors with ThemeProvider tokens and SemanticColors.

### Task 4.1: Practice Screen Colors

**Files:**
- Modify: `lib/screens/practice_screen.dart`

- [ ] **Step 1: Import SemanticColors**
- [ ] **Step 2: Replace 6 bright card colors with SemanticColors pairs**

```dart
// BEFORE:
color: const Color(0xFF3B82F6), // bright blue

// AFTER:
color: SemanticColors.practiceBlue.bg(theme.isDark),
// text:
color: SemanticColors.practiceBlue.fg(theme.isDark),
```

- [ ] **Step 3: Replace mixed hero gradient with solid dark card**

```dart
// BEFORE: LinearGradient(colors: [...])
// AFTER:
color: theme.isDark ? const Color(0xFF1A1A1A) : const Color(0xFF171717),
```

- [ ] **Step 4: Run app, verify practice screen is muted but scannable**
- [ ] **Step 5: Commit**

---

### Task 4.2: Flashcard Review Screen

**Files:**
- Modify: `lib/screens/hifz/flashcard_review_screen.dart`

- [ ] **Step 1: Replace 4 rating button colors with SemanticColors**
- [ ] **Step 2: Replace card borders with shadow system**
- [ ] **Step 3: Commit**

---

### Task 4.3: Progress Card + Weekly Report

**Files:**
- Modify: `lib/widgets/hifz/progress_card.dart`
- Modify: `lib/widgets/hifz/weekly_report.dart`

- [ ] **Step 1: Replace `Colors.green/blue/orange` stat colors with SemanticColors.progress*`**
- [ ] **Step 2: Replace `Colors.orange` streak badge with muted version**
- [ ] **Step 3: Weekly report: replace stat chip colors with SemanticColors.analytics*`**
- [ ] **Step 4: Commit**

---

### Task 4.4: Suggestion Card

**Files:**
- Modify: `lib/widgets/hifz/suggestion_card.dart`

- [ ] **Step 1: Replace `_accentForType` colors with SemanticColors.sugg* pairs**
- [ ] **Step 2: Commit**

---

### Task 4.5: Milestone Card (minimal changes)

**Files:**
- Modify: `lib/widgets/hifz/milestone_card.dart`

- [ ] **Step 1: Keep gradients, source from SemanticColors.milestone***
- [ ] **Step 2: Update font, border radius only**
- [ ] **Step 3: Commit**

---

### Task 4.6: Remaining Screens (batch)

**Files:**
- `lib/screens/home_screen.dart` — greeting, extra session card
- `lib/screens/profile_screen.dart` — settings sections
- `lib/screens/onboarding_screen.dart` — onboarding flow
- `lib/screens/hifz/session_screen.dart` — timer, buttons
- `lib/screens/hifz/assessment_screen.dart` — wizard steps
- `lib/screens/hifz/analytics_screen.dart` — charts
- `lib/screens/hifz/pre_session_screen.dart` — plan review
- `lib/screens/hifz/progress_detail_screen.dart` — page grid
- `lib/screens/hifz/session_history_screen.dart` — date groups
- `lib/screens/hifz/mutashabihat_practice_screen.dart` — practice modes
- `lib/screens/hifz/mutashabihat_screen.dart` — browse collection
- `lib/screens/hifz/share_progress_screen.dart` — teacher mode
- `lib/screens/hifz/accountability_screen.dart` — partners

All: replace any remaining hardcoded `Color(0xFF...)` with `theme.*` or `SemanticColors.*`.

- [ ] **Step 1: Process each screen, replace colors**
- [ ] **Step 2: Run `flutter analyze`**
- [ ] **Step 3: Commit per batch**

---

## Phase 5: Polish

### Task 5.1: Theme Picker Sheet

**Files:**
- Modify: `lib/widgets/sheets/theme_picker_sheet.dart`

- [ ] **Step 1: Remove warm theme option, show only Light / Dark toggle**
- [ ] **Step 2: Commit**

---

### Task 5.2: Verify Reading Canvas

**Files:**
- Review: `lib/widgets/reading_canvas.dart`

- [ ] **Step 1: Verify Quranic font (KFGQPC) is untouched**
- [ ] **Step 2: Adapt verse highlight colors to neutral scale**
- [ ] **Step 3: Commit**

---

### Task 5.3: Full App Smoke Test

- [ ] **Step 1: `flutter analyze` — zero warnings**
- [ ] **Step 2: Run on Windows, navigate all 5 tabs**
- [ ] **Step 3: Toggle light ↔ dark mode, verify everything adapts**
- [ ] **Step 4: Open practice screen — verify 6 muted card colors are distinct**
- [ ] **Step 5: Open flashcard review — verify rating buttons are color-coded**
- [ ] **Step 6: Check milestones — verify gradients still render**
- [ ] **Step 7: Open analytics — verify chart colors are legible**
- [ ] **Step 8: Read Quran page — verify Arabic text is unaffected**

---

### Task 5.4: Grep Audit

- [ ] **Step 1: Verify no remaining `fontFamily: 'Inter'`**
```powershell
Select-String -Path lib\**\*.dart -Pattern "fontFamily: 'Inter'" -Recurse
```
Expected: 0 results

- [ ] **Step 2: Verify no remaining `AppTheme.classic` or `AppTheme.warm`**
- [ ] **Step 3: Verify no remaining raw `Border.all(` (except intentional cases like reading canvas verse markers)**

---

## Execution Notes

- **Phase 1 is the critical path** — everything depends on it
- **Phases 2 and 3 are mechanical** — safe to parallelize or batch
- **Phase 4 is design-sensitive** — review after each task visually
- **Phase 5 is verification** — no new code, just validation

Total estimated files touched: ~50 unique files across all phases.
