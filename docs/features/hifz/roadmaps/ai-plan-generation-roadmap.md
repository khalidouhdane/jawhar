# 🤖 AI-Powered Plan Generation — Roadmap

> **Vision:** Transform the Hifz companion from a timer + rep counter into an **AI-guided memorization coach** that generates personalized plans, step-by-step session recipes, and adaptive weekly calibration — all driven by Gemini 3.1.
>
> **Status:** Planning  
> **Start Phase:** AI-1 (Assessment Enhancement)

---

## Phase AI-1: Assessment Enhancement ✨

> Gather richer profile data so AI has meaningful context to work with. Without better inputs, even the best AI will generate generic plans.

### AI-1.1 — Expanded Age Groups
- [ ] Replace 3-value `AgeGroup` enum with 7 values: `child` (7–12), `teen` (13–17), `youngAdult` (18–30), `adult` (31–45), `middleAged` (46–55), `senior` (56–70), `elderly` (71+)
- [ ] Add `age` (int) field to `MemoryProfile` — user inputs actual age, system auto-maps to group
- [ ] Update assessment Screen 2 with age number input + group confirmation
- [ ] Update database schema (`profiles` table) + migration
- [ ] 📄 Reference: [hifz-struggles.md](../research/hifz-struggles.md) — age affects encoding, attention span, session length

### AI-1.2 — Weekly Schedule & Rest Days
- [ ] Add `activeDays` field to `MemoryProfile` — `List<int>` (0=Mon..6=Sun)
- [ ] New assessment screen: **Weekly Schedule Picker** — tap days to toggle active/rest
- [ ] Integrate with `NotificationProvider` — silence notifications on rest days
- [ ] Integrate with `MissedDayDialog` — rest days are not "missed"
- [ ] Update `PlanProvider` — skip plan generation on rest days (or generate review-only plans)
- [ ] Update timeline calculation in assessment summary to account for active days/week

### AI-1.3 — Pace Preference
- [ ] Add `pacePreference` enum to `MemoryProfile`: `aggressive`, `steady`, `gentle`
- [ ] New assessment screen: Pace selection with clear descriptions
- [ ] Impact: AI uses as a multiplier on daily load (same encoding speed, different pace = different plan)

### AI-1.4 — Prior Hifz Experience
- [ ] Add `hifzExperience` enum to `MemoryProfile`: `fresh`, `resuming`, `reviewing`
- [ ] New assessment screen: Experience selection
- [ ] Impact: `fresh` → normal progression; `resuming` → review-first period; `reviewing` → manzil-heavy, minimal sabaq

### AI-1.5 — Assessment Flow Polish
- [ ] Reorder screens for natural flow: Welcome → Age → Experience → Learning Pref → Encoding → Retention → Schedule → Weekly Schedule → Goal + Pace → Reciter + Start → Summary
- [ ] Update summary screen with the new fields
- [ ] Ensure backward compatibility — existing profiles get sensible defaults for new fields

---

## Phase AI-2: AI Plan Service 🧠

> Replace hard-coded `PlanGenerationService._getFrameworkParams()` with Gemini-powered plan generation. The math tables become AI guidelines instead of rigid code.

### AI-2.1 — Gemini Integration
- [ ] Add `google_generative_ai` package
- [ ] Create `AIPlanService` class with bundled API key
- [ ] Support two models: `gemini-3.1-flash` (default), `gemini-3.1-pro` (optional)
- [ ] Add model switcher in Profile Settings for development testing
- [ ] Implement request/response serialization (structured JSON output)

### AI-2.2 — System Prompt Design
- [ ] Craft comprehensive system prompt containing:
  - Sabaq/Sabqi/Manzil framework rules and constraints
  - Age-group-specific guidelines (load ceilings, session lengths, rep ranges)
  - Traditional method knowledge from research (3×3, Rabt linking, audio-first, visual tracking, overlap technique)
  - Safety rails (max/min pages, reps, session time)
  - Available app features (audio playback, digital reading, flashcards, mutashabihat)
  - Strict JSON output schema
- [ ] Version the system prompt — store in `assets/prompts/plan_system_prompt.md` for easy iteration
- [ ] 📄 Reference: [methods-overview.md](../methods-and-planning/methods-overview.md), [plan-generation.md](../methods-and-planning/plan-generation.md), [hifz-struggles.md](../research/hifz-struggles.md)

### AI-2.3 — Daily Plan Generation Pipeline
- [ ] Build user context assembler: profile + progress snapshot + recent sessions → JSON
- [ ] Call Gemini API with system prompt + user context
- [ ] Parse and validate AI response:
  - Pages clamped to 1–604 (or goal-scoped pages)
  - Reps clamped to safety ranges (1–50)
  - Time fits within `dailyTimeMinutes`
  - All required fields present
- [ ] Save validated plan to SQLite via `HifzDatabaseService`
- [ ] Store AI reasoning text for user visibility

### AI-2.4 — Offline Fallback
- [ ] Cache last successful AI-generated framework params locally
- [ ] If AI call fails (no internet, API error, rate limit): use cached params or fall back to current `_getFrameworkParams()` deterministic math
- [ ] Generate template-based recipes from `learningPreference` (hard-coded fallback)
- [ ] Show subtle "📴 Using offline plan" indicator in the plan card

### AI-2.5 — Plan Card Enhancement
- [ ] Show AI reasoning summary on dashboard plan card (expandable "Why this plan?" section)
- [ ] Display per-phase time estimates
- [ ] Show recipe preview ("Today: Listen 3x → Read 3x → Recite 3x")

---

## Phase AI-3: Session Recipes 🍳

> The core UX transformation. Sessions go from a generic timer + rep counter to an **AI-guided step-by-step experience** personalized to each user.

### AI-3.1 — Recipe Data Model
- [ ] Create `SessionRecipe` model:
  ```
  SessionRecipe { phase, steps[], estimatedMinutes, tips[] }
  RecipeStep { stepNumber, action, instruction, target, unit, icon }
  ```
- [ ] Actions vocabulary: `listen`, `read_along`, `read_solo`, `recite_memory`, `link_practice`, `write`, `review_meaning`, `self_test`
- [ ] Store recipes alongside `DailyPlan` in SQLite

### AI-3.2 — Recipe Generation
- [ ] Extend AI plan generation to include recipes for each phase (sabaq, sabqi, manzil)
- [ ] Learning preference drives recipe structure:
  - **Auditory:** Listen 5x → Read along 3x → Recite from memory 3x (audio-heavy)
  - **Visual:** Read 5x with tracking → Cover half page → Recite from visual memory
  - **Kinesthetic:** Write verses 2x → Recite while writing → Recite from memory
  - **Repetition:** Read 3x → Recite blind 3x → Re-read 2x → Final recitation 3x (classic 3×3)
- [ ] Age modifiers: children get fewer/shorter steps, elderly get gentler targets
- [ ] Pace modifiers: aggressive → higher rep targets; gentle → more listening, fewer reps
- [ ] 📄 Reference: [hifz-struggles.md](../research/hifz-struggles.md) — Rabt method, overlap technique, audio mirror, Pomodoro

### AI-3.3 — Guided Session UI
- [ ] Redesign session screen from raw rep counter → **step-by-step guided view**:
  - Current step display: icon + instruction text
  - Per-step rep counter with target (e.g., "2 / 3")
  - Previous/Next step navigation
  - Step progress indicator (dots or numbered pills)
  - "Skip step" button (flexibility preserved)
- [ ] Timer continues running across all steps (total phase time visible)
- [ ] When all steps complete → auto-trigger self-assessment
- [ ] "Free mode" toggle — switch back to classic timer + rep counter for advanced users

### AI-3.4 — Sabqi & Manzil Phase Enhancement
- [ ] Show assigned page list during sabqi/manzil phases (not just "Recent Review" label)
- [ ] Sabqi recipe: lighter than sabaq — typically 2-3 steps (read once, recite once, self-test)
- [ ] Manzil recipe: review-focused — read once quickly, identify weak spots, recite from memory
- [ ] Page-by-page navigation within multi-page phases

### AI-3.5 — Digital Mode Recipe Integration
- [ ] Sync recipe steps with digital reading canvas
- [ ] "Listen" steps → auto-play audio
- [ ] "Read solo" steps → show text without audio
- [ ] "Recite from memory" steps → hide text, show blank page prompt
- [ ] Audio controls context-aware per step

---

## Phase AI-4: Adaptive Calibration 📊

> Weekly AI analysis of performance → personalized adjustment suggestions with reasoning.

### AI-4.1 — Weekly AI Review
- [ ] Every 7 days, trigger AI calibration with full session history
- [ ] AI analyzes: completion rate, assessment distribution (strong/okay/weak), time patterns, skipped phases
- [ ] AI generates adjustment suggestions with clear reasoning
- [ ] Suggestions surfaced as `SuggestionCard` on dashboard with AI explanation

### AI-4.2 — Progressive Difficulty
- [ ] AI gradually increases load as user demonstrates consistency and strong assessments
- [ ] Automatic rep target reduction after 3 consecutive "strong" assessments on same method
- [ ] Suggest recipe variation when user plateaus (e.g., "Try adding the link practice step")

### AI-4.3 — Smart Rest Day Suggestions
- [ ] If user consistently struggles on certain days → AI suggests making those rest days
- [ ] If user overperforms on rest days (completes sessions anyway) → suggest converting to active days
- [ ] Pattern detection: "You seem to do best on mornings — consider shifting your schedule"

### AI-4.4 — Returning After a Break
- [ ] Detect gap of 3+ days → trigger AI re-evaluation
- [ ] AI generates a "welcome back" plan: review-first period, lighter load, compassionate messaging
- [ ] Gradual ramp-up plan over 1-2 weeks back to full load
- [ ] 📄 Reference: [hifz-struggles.md](../research/hifz-struggles.md) — §9 "Returning After a Long Break"

---

## Phase AI-5: Intelligent Session Features 🎓

> Advanced AI-powered features during the session itself — real-time guidance beyond just recipes.

### AI-5.1 — Contextual Tips
- [ ] AI generates page-specific tips based on content:
  - "This page has Ayat al-Kursi — a great verse to perfect first"
  - "Verses 142-145 have mutashabihat with Ali Imran — practice those transitions"
  - "This page ends mid-sentence — be extra careful with the page bridge"
- [ ] Tips shown at session start and between steps

### AI-5.2 — Difficulty Prediction
- [ ] AI predicts which pages/sections will be hardest based on:
  - Page density (verse count, word count)
  - Mutashabihat presence
  - Long vs short verses
  - User's past performance on similar content
- [ ] Pre-warn user: "This page might take a bit longer — take your time"
- [ ] Adjust recipe targets dynamically for harder pages

### AI-5.3 — Personalized Motivational Messages
- [ ] AI generates contextual encouragement based on progress:
  - Milestone approaching: "Only 3 more pages until you complete Juz 29!"  
  - After tough session: "Challenging pages build the strongest memorization. You did great."
  - Streak celebration: "20 days active — your consistency is remarkable"
- [ ] Culturally appropriate — include relevant hadith and scholar advice where fitting

### AI-5.4 — Voice-Based Self-Test (Future)
- [ ] Integrate speech-to-text for recitation verification
- [ ] AI compares user's recitation against reference text
- [ ] Identify weak verses automatically (no more self-assessment — objective measurement)
- [ ] Feed accuracy data back into plan calibration

---

## Phase AI-6: Community Intelligence 🌐

> Aggregate anonymized performance data to improve AI recommendations for everyone.

### AI-6.1 — Difficulty Heatmap
- [ ] Track which pages users consistently rate "weak" or spend extra time on
- [ ] Build a difficulty index per page (anonymized, aggregated)
- [ ] AI uses community difficulty data to pre-adjust recipes for known hard pages

### AI-6.2 — Method Effectiveness Analytics
- [ ] Track which recipe variations lead to best outcomes per learning preference
- [ ] AI A/B tests recipe structures: does auditory learners do better with 5x listen or 3x listen + 2x read?
- [ ] Feed insights back into recipe generation

### AI-6.3 — Teacher Dashboard AI
- [ ] AI generates teacher-facing summary: "This student struggles with page transitions but excels at memorization speed"
- [ ] Suggest targeted exercises for teachers to assign
- [ ] Progress predictions: "At current pace, student will complete Juz 29 by April 15"

---

## Technical Architecture

### AI Service Stack

```
┌──────────────────────────────────────────────────────────┐
│                      AIPlanService                        │
│                                                           │
│  Models: gemini-3.1-flash (default) / gemini-3.1-pro     │
│  Key: Bundled (dev) → Backend proxy (production)          │
│                                                           │
│  ┌─────────────┐   ┌──────────────┐   ┌──────────────┐  │
│  │   Profile    │   │   Progress   │   │   Session    │  │
│  │  Assembler   │ + │  Snapshot    │ + │   History    │  │
│  └──────┬──────┘   └──────┬───────┘   └──────┬───────┘  │
│         └──────────────────┼──────────────────┘           │
│                            ▼                              │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              System Prompt (versioned)                │ │
│  │  • Framework rules (Sabaq/Sabqi/Manzil)              │ │
│  │  • Age-specific guidelines                           │ │
│  │  • Method knowledge (3×3, Rabt, audio-first...)      │ │
│  │  • Safety rails                                      │ │
│  │  • JSON output schema                                │ │
│  └──────────────────────┬──────────────────────────────┘ │
│                         ▼                                 │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              Validation Layer                        │ │
│  │  • Page range (1–604 or goal-scoped)                 │ │
│  │  • Rep/time clamping                                 │ │
│  │  • Required field presence                           │ │
│  │  • Recipe step count limits                          │ │
│  └──────────────────────┬──────────────────────────────┘ │
│                         ▼                                 │
│  ┌─────────────────────────────────────────────────────┐ │
│  │      DailyPlan + SessionRecipes → SQLite             │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                           │
│  Fallback: cached plan → deterministic math → templates   │
└──────────────────────────────────────────────────────────┘
```

### Model Configuration

| Setting | Value |
|---------|-------|
| Default model | `gemini-3.1-flash` |
| Optional model | `gemini-3.1-pro` |
| API key | Bundled in app (dev phase) |
| Switchable | Yes — Profile Settings → AI Model |
| Response format | Structured JSON (schema-enforced) |
| Max output tokens | 4096 |
| Temperature | 0.3 (low creativity, high consistency) |

### When AI Runs

| Trigger | What It Generates |
|---------|-------------------|
| After assessment complete | Initial framework params + first day's plan + recipes |
| Daily (on app open, if no plan for today) | Today's plan + session recipes |
| After session complete | Next day's plan (adjusted by session results) |
| Weekly (every 7 completed sessions) | Calibration review + suggestions |
| User taps "Recalibrate" | Full re-evaluation of framework params |
| After 3+ day gap | "Welcome back" recovery plan |

---

## Dependencies

| Package | Purpose | Phase |
|---------|---------|-------|
| `google_generative_ai` | Gemini API client | AI-2 |

---

## Phase Priority & Estimates

| Phase | Name | Priority | Dependencies |
|-------|------|----------|-------------|
| **AI-1** | Assessment Enhancement | 🔴 Start here | None |
| **AI-2** | AI Plan Service | 🔴 Core | AI-1 |
| **AI-3** | Session Recipes | 🔴 Core | AI-2 |
| **AI-4** | Adaptive Calibration | 🟡 High | AI-2, AI-3 |
| **AI-5** | Intelligent Session Features | 🟢 Medium | AI-3, AI-4 |
| **AI-6** | Community Intelligence | 🔵 Future | AI-5, backend required |
