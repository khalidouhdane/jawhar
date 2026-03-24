# AI-Powered Hifz Plan Generation — Task Board

> **Project:** AI-Powered Hifz Plan Generation  
> **Status:** Planning  
> **Roadmap:** [ai-plan-generation-roadmap.md](../docs/features/hifz/roadmaps/ai-plan-generation-roadmap.md)

---

## Architecture Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Bundled Gemini API key (dev phase) | Simplifies dev. Move to backend proxy before public release. |
| 2 | Single AI call for plan + recipes | Reduces API calls, ensures coherent plan-recipe alignment. |
| 3 | Offline fallback to deterministic math | AI enhances but never blocks. No internet = still functional. |
| 4 | System prompt as versioned asset file | Easy iteration without code changes. A/B testable. |

---

## Risks

| Risk | Likelihood | Impact | Treatment |
|------|-----------|--------|-----------|
| Gemini returns malformed JSON | Medium | High | Validation layer + offline fallback |
| API key exposure in bundled app | High | Medium | Accept for dev phase, migrate to backend proxy before distribution |
| AI latency on slow networks | Medium | Medium | 15s timeout + cached plan fallback |
| Recipe quality varies by model | Medium | Low | Flash/Pro toggle for comparison |
| Breaking change to assessment schema | Low | High | SQLite migration with defaults for existing profiles |

---

## Task Dependency Graph

```
Priority 1 (Independent):
  task-1: MemoryProfile model + DB schema
  
Priority 2 (depends on task-1):
  task-2: Assessment wizard screens ──────────┐
  task-3: Rest days integration               │
  task-4: AIPlanService + Gemini integration   ├── All depend on task-1
  task-5: System prompt design                 │
                                               │
Priority 3 (depends on task-4/5/6):           │
  task-6: Validation layer + SQLite pipeline ◄─┤─ depends on task-4, task-5
  task-7: Offline fallback system ◄────────────┤─ depends on task-4, task-6
  task-8: SessionRecipe model + storage ◄──────┘─ depends on task-6

Priority 4 (depends on task-8/9):
  task-9:  Guided session UI ◄──────── depends on task-8
  task-10: Digital mode recipe ◄────── depends on task-9
  task-11: Plan card enhancement ◄──── depends on task-6, task-8

Priority 5 (depends on task-6/9):
  task-12: Weekly calibration ◄─────── depends on task-6, task-9
  task-13: Break recovery plan ◄────── depends on task-6

Priority 6 (depends on task-9/12):
  task-14: Contextual tips ◄────────── depends on task-9
  task-15: Motivational messages ◄──── depends on task-12
```

---

## Task Board

### Priority 1 — Foundation (No Dependencies)

| ID | Title | Complexity | Status |
|----|-------|-----------|--------|
| `task-1` | Expand MemoryProfile model + database schema | Medium | ✅ DONE |

**Acceptance Criteria:**
- AgeGroup enum → 7 values (child/teen/youngAdult/adult/middleAged/senior/elderly)
- New fields: `age` (int), `activeDays` (List\<int\>), `pacePreference`, `hifzExperience`
- SQLite migration with safe defaults for existing profiles
- Serialization (toMap/fromMap) covers all new fields

---

### Priority 2 — Assessment + AI Core (Depends on task-1)

| ID | Title | Complexity | Status | Depends On |
|----|-------|-----------|--------|------------|
| `task-2` | Enhanced assessment wizard (11 screens) | High | ⬜ TODO | task-1 |
| `task-3` | Rest days integration across app | Medium | ⬜ TODO | task-1 |
| `task-4` | AIPlanService + Gemini 3.1 integration | High | ⬜ TODO | task-1 |
| `task-5` | System prompt design + versioned asset | High | ⬜ TODO | task-1 |

**task-2 Criteria:** 11 screens, age number picker, experience selector, weekly day picker, pace selector  
**task-3 Criteria:** PlanProvider skips rest days, notifications silent, missed-day excluded, timeline adjusted  
**task-4 Criteria:** google_generative_ai package, Flash/Pro toggle, context assembler, structured JSON output  
**task-5 Criteria:** `assets/prompts/plan_system_prompt_v1.md` with all framework rules, methods, safety rails

---

### Priority 3 — Pipeline + Recipes (Depends on AI core)

| ID | Title | Complexity | Status | Depends On |
|----|-------|-----------|--------|------------|
| `task-6` | Validation layer + SQLite pipeline | Medium | ⬜ TODO | task-4, task-5 |
| `task-7` | Offline fallback system | Medium | ⬜ TODO | task-4, task-6 |
| `task-8` | SessionRecipe model + storage | Medium | ⬜ TODO | task-6 |

**task-6 Criteria:** Page/rep/time clamping, malformed response handling, reasoning text stored  
**task-7 Criteria:** Cached params, deterministic fallback, template recipes, offline indicator  
**task-8 Criteria:** SessionRecipe + RecipeStep models, actions enum, SQLite table, serialization

---

### Priority 4 — Session UX (Depends on recipes)

| ID | Title | Complexity | Status | Depends On |
|----|-------|-----------|--------|------------|
| `task-9` | Guided session UI — step-by-step view | Very High | ⬜ TODO | task-8 |
| `task-10` | Digital mode recipe integration | High | ⬜ TODO | task-9 |
| `task-11` | Plan card enhancement + reasoning | Medium | ⬜ TODO | task-6, task-8 |

**task-9 Criteria:** Step view with instruction/rep target/progress indicator, skip/prev/next, free mode toggle  
**task-10 Criteria:** Listen→auto-play, read→show text, recite→hide text, context-aware controls  
**task-11 Criteria:** Per-phase time estimates, "Why this plan?" expandable, recipe preview

---

### Priority 5 — Adaptive Intelligence (Depends on pipeline + UI)

| ID | Title | Complexity | Status | Depends On |
|----|-------|-----------|--------|------------|
| `task-12` | Weekly AI calibration + suggestions | High | ⬜ TODO | task-6, task-9 |
| `task-13` | Break recovery plan | Medium | ⬜ TODO | task-6 |

**task-12 Criteria:** 7-session trigger, performance analysis, suggestion cards with reasoning  
**task-13 Criteria:** 3+ day gap detection, review-first recovery, compassionate messaging, ramp-up plan

---

### Priority 6 — Advanced Features (Future)

| ID | Title | Complexity | Status | Depends On |
|----|-------|-----------|--------|------------|
| `task-14` | Contextual tips + difficulty prediction | High | ⬜ TODO | task-9 |
| `task-15` | Personalized motivational messages | Medium | ⬜ TODO | task-12 |

---

## Execution Strategy

### Parallel Execution Opportunities

```
Sprint 1:  task-1 (foundation — must go first)
Sprint 2:  task-2 + task-3 + task-4 + task-5 (all parallel, all depend only on task-1)
Sprint 3:  task-6 → task-7 + task-8 (sequential: validate first, then fallback + recipes)
Sprint 4:  task-9 + task-11 (parallel: session UI + plan card, both depend on task-8)
Sprint 5:  task-10 + task-12 + task-13 (parallel: digital mode, calibration, recovery)
Sprint 6:  task-14 + task-15 (parallel: tips + motivation)
```

### Mapping to Roadmap Phases

| Roadmap Phase | Tasks |
|---------------|-------|
| **AI-1:** Assessment Enhancement | task-1, task-2, task-3 |
| **AI-2:** AI Plan Service | task-4, task-5, task-6, task-7 |
| **AI-3:** Session Recipes | task-8, task-9, task-10, task-11 |
| **AI-4:** Adaptive Calibration | task-12, task-13 |
| **AI-5:** Intelligent Session Features | task-14, task-15 |
| **AI-6:** Community Intelligence | Not yet decomposed (requires backend) |
