# Task 3: Rest Days Integration

## Context
You are working on the Le Quran Flutter app — a Quran memorization companion.
Project root: `c:\Users\khali\OneDrive\Bureau\Quran App`

## What Was Already Done (task-1)
The `MemoryProfile` model now has `activeDays` field — a `List<int>` where 0=Mon..6=Sun. Default is `[0,1,2,3,4,5,6]` (all days active). This field is already persisted in SQLite.

## Your Task
Wire the `activeDays` field into the rest of the app so rest days are respected:

### 1. PlanProvider (`lib/providers/plan_provider.dart`)
- In `loadOrGeneratePlan()`, check if today is an active day:
  ```dart
  final today = DateTime.now().weekday - 1; // 0=Mon..6=Sun
  final profile = profileProvider.activeProfile;
  final isActiveDay = profile?.activeDays.contains(today) ?? true;
  ```
- If NOT active day: either skip plan generation entirely OR generate a review-only plan (manzil only, no sabaq)
- Add a `bool get isRestDay` getter to PlanProvider

### 2. NotificationProvider (`lib/providers/notification_provider.dart`)
- When scheduling daily notifications, skip rest days
- Check if `activeDays` contains the day-of-week before scheduling

### 3. MissedDayDialog (`lib/widgets/hifz/missed_day_dialog.dart`)
- When calculating missed days, exclude rest days from the count
- A rest day is NOT a "missed" day — do not show the dialog for rest days

### 4. Dashboard (`lib/screens/home_screen.dart`)
- On rest days, show a rest day indicator on the plan card
- Something like: "📚 Rest day — Enjoy your break!" or offer optional review

### 5. Timeline Calculation
- If `assessment_screen.dart` has a timeline estimate, update it to use `activeDays.length / 7` as a multiplier

### Important:
- Read AGENTS.md and GEMINI.md for project architecture context
- Use Provider pattern (ChangeNotifier) — don't create new services
- activeDays format: List<int> where 0=Monday, 6=Sunday
- Dart's DateTime.weekday: 1=Monday..7=Sunday, so convert with `weekday - 1`

## Acceptance Criteria
- PlanProvider skips plan generation on rest days (or generates review-only)
- PlanProvider.isRestDay getter works correctly
- NotificationProvider doesn't schedule on rest days
- MissedDayDialog excludes rest days from count
- Dashboard shows rest day indicator
- No compilation errors (run `dart analyze`)
