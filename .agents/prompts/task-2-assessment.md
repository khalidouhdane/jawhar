# Task 2: Enhanced Assessment Wizard (11 Screens)

## Context
You are working on the Le Quran Flutter app — a Quran memorization companion.
Project root: `c:\Users\khali\OneDrive\Bureau\Quran App`

## What Was Already Done (task-1)
The `MemoryProfile` model in `lib/models/hifz_models.dart` has been updated with:
- `AgeGroup` expanded to 7 values: `child, teen, youngAdult, adult, middleAged, senior, elderly`
- New enums: `PacePreference { aggressive, steady, gentle }`, `HifzExperience { fresh, resuming, reviewing }`
- New fields: `age` (int), `activeDays` (List<int>), `pacePreference`, `hifzExperience`
- Static helper: `MemoryProfile.ageGroupFromAge(int age)` maps age → AgeGroup

## Your Task
Update `lib/screens/hifz/assessment_screen.dart` to support the expanded profile:

### Screen Changes (9 → 11 screens):

1. **Screen 2 (Age) — REPLACE**: Replace the 3-option AgeGroup picker with:
   - A number input field for actual age (7–100 range)
   - Below it, show the auto-mapped AgeGroup label (using `MemoryProfile.ageGroupFromAge()`)
   - Store both `_age` (int) and `_ageGroup` (AgeGroup)

2. **Screen 3 (Experience) — NEW**: Add after Age screen:
   - Title: "Where are you in your Hifz journey?"
   - 3 options with icons + descriptions:
     - 🌱 "Starting fresh" → `HifzExperience.fresh`
     - 🔄 "Resuming" → `HifzExperience.resuming`
     - 📖 "Reviewing" → `HifzExperience.reviewing`
   - Store as `_hifzExperience`

3. **Screen 8 (Weekly Schedule) — NEW**: Add after the daily time screen:
   - Title: "Which days will you study?"
   - 7-day grid (Mon–Sun), tap to toggle active/rest
   - Show active day count
   - Default: all days active
   - Store as `_activeDays` (List<int>, 0=Mon..6=Sun)

4. **Screen 9 (Goal + Pace) — MODIFY**: Add pace preference to the existing goal screen:
   - After goal selection, add pace selector:
     - 🚀 "Push me" → `PacePreference.aggressive`
     - ⚖️ "Steady" → `PacePreference.steady`
     - 🌿 "Gentle" → `PacePreference.gentle`
   - Store as `_pacePreference`

5. **Summary screen — UPDATE**: Display all new fields (age, experience, weekly schedule, pace)

### Screen order (11 total):
Welcome → Age → Experience → LearningPref → Encoding → Retention → Schedule+Time → WeeklySchedule → Goal+Pace → Reciter+Start → Summary

### Important:
- Update `_totalPages` to 11
- Update the `_buildProfile()` method to include all new fields: `age`, `ageGroup`, `activeDays`, `pacePreference`, `hifzExperience`
- The _ageGroup default should change from `AgeGroup.adult` to `AgeGroup.youngAdult`
- When editing an existing profile, load the new fields too
- Follow existing code style: Arabic-inspired design, dark theme, gold accents
- Read AGENTS.md and GEMINI.md for project architecture context

## Acceptance Criteria
- 11 assessment screens in correct order
- Age input with auto-mapped group label
- Experience selector with 3 options
- Weekly schedule 7-day grid with toggle
- Pace preference with 3 options  
- Summary screen shows all new fields
- Existing profile editing loads new fields
- No compilation errors (run `dart analyze`)
