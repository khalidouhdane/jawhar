# 🧬 Memory Profile — Data Model & Architecture

> **Purpose:** Define what a memory profile is, what it stores, and how multiple profiles work.

---

## Overview

A **Memory Profile** is the user's personalized identity within the hifz program. It captures who they are as a learner, their framework parameters, their schedule, their default reciter, and all their progress data. One device can hold multiple profiles (household use case — parent, child, sibling).

---

## Profile Data Model

| Field | Type | Description |
|---|---|---|
| `id` | UUID | Unique profile identifier |
| `name` | String | Display name ("Khalid's Hifz", "أمي") |
| `avatarIndex` | int | Index into a set of pre-built avatar illustrations |
| `createdAt` | DateTime | When the profile was created |
| `ageGroup` | Enum | `child` (7-12), `teen` (13-17), `adult` (18+) |
| `encodingSpeed` | Enum | `fast`, `moderate`, `slow` — from assessment |
| `retentionStrength` | Enum | `strong`, `moderate`, `fragile` — from assessment |
| `learningPreference` | Enum | `visual`, `auditory`, `kinesthetic`, `repetition` |
| `dailyTimeMinutes` | int | Daily commitment (15–480) |
| `preferredTimeOfDay` | Enum | `fajr`, `morning`, `afternoon`, `evening`, `night` |
| `goal` | Enum | `fullQuran`, `specificJuz`, `specificSurahs` |
| `goalDetails` | List<int> | Juz numbers or Surah IDs if goal is specific |
| `defaultReciterId` | int | The reciter used across all hifz sessions |
| `defaultReciterSource` | Enum | `quranDotCom` or `mp3Quran` |
| `startingPage` | int | Page number where they begin memorization (1-604) |
| `startDate` | DateTime | When they began the program |
| `isActive` | bool | Whether this is the currently selected profile |

---

## Multi-Profile Architecture

### Storage
- All profiles stored in **SQLite** (not SharedPreferences)
- One `profiles` table with the fields above
- Related tables for progress data, session history, flashcard state, etc.
- Each is keyed to profile `id`

### UX
- Profile selector accessible from the hifz dashboard
- Quick switch without losing context
- Each profile has independent:
  - Memorization progress
  - Session history
  - Flashcard state
  - Review schedule
  - Streak data

### Profile Limit
- No hard limit, but UI optimized for 1-5 profiles
- "Add Profile" button always visible in the profile selector

---

## Default Reciter — Part of the Profile

The user selects a **default reciter** during profile setup (or later in profile settings). This reciter is used:

- In all hifz sessions (audio playback)
- As the default in the reading screen when opened from hifz context
- In the audio-first method (listen → recite)

**Why one reciter?** Research shows that memorizing with a single Qari builds stronger auditory memory — your brain associates the rhythm, melody, and pace of that specific reciter with the verses, creating stronger recall cues.

The user can always switch reciters temporarily, but the profile default is what loads automatically.

---

## How the Profile Shapes the Experience

The 2-axis assessment (encoding speed × retention strength) maps to practical plan parameters:

| Encoding Speed | Retention Strength | Daily New Load | Review Frequency | Method Suggestion |
|---|---|---|---|---|
| Fast | Strong | Higher (1-2 pages) | Standard intervals | Any parameter set works |
| Fast | Fragile | Moderate (0.5-1 page) | Aggressive SRS | Higher reps, audio-first emphasis |
| Slow | Strong | Lower (3-5 lines) | Relaxed intervals | Standard reps, visual emphasis |
| Slow | Fragile | Lowest (3-5 lines) | Most frequent SRS | Highest reps, smallest chunks |

These are **starting parameters** — the plan adapts based on actual performance after the first week (via user-accepted suggestions, never auto-adjusted).
