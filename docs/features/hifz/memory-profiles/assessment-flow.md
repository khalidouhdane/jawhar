# 🧭 Assessment Flow — Onboarding Wizard

> **Purpose:** Document the screen-by-screen profile creation and memory assessment experience.

---

## Design Principles

1. **Feels like a conversation, not an exam** — warm language, relatable scenarios
2. **No wrong answers** — every response is valid, there's no "bad memory type"
3. **Quick** — 7 screens, under 3 minutes total
4. **Beautiful** — each screen has an illustration or animation, matches app aesthetics
5. **Skip-friendly** — user can skip assessment and manually choose a method later

---

## Screen-by-Screen Flow

### Screen 1: Welcome 👋
**Header:** "Let's build your Hifz profile"  
**Subtext:** "A few quick questions to personalize your journey"

**Fields:**
- Name input (text field, placeholder: "What should we call you?")
- Avatar picker (horizontal scroll of 8-10 pre-built illustrations)

**CTA:** "Continue →"

---

### Screen 2: Age Group 🎂
**Header:** "How old are you?"  
**Subtext:** "This helps us tailor the experience"

**Options (large tap cards):**
- 🧒 Child (7-12)
- 🧑 Teen (13-17)
- 🧔 Adult (18+)

**Why we ask:** Children benefit from shorter sessions, more gamification, auditory-heavy methods. Adults benefit from meaning-based approaches and self-discipline tools.

---

### Screen 3: Learning Preference 📖
**Header:** "When you memorize something new, what helps most?"  
**Subtext:** "Pick the one that resonates most — no wrong answers!"

**Options (illustrated cards):**
- 👁️ **Looking and reading** — "I stare at the text until it sticks"
- 👂 **Listening** — "I listen to it over and over"
- ✍️ **Writing it down** — "Writing helps me remember"
- 🔄 **Repeating out loud** — "I just keep saying it until I know it"

**Maps to:** `learningPreference` → Influences method recommendation priority.

---

### Screen 4: Memorization Speed ⚡
**Header:** "Imagine memorizing a new page..."  
**Subtext:** "After 30 minutes of focused effort, how much would you typically remember?"

**Options (friendly, visual):**
- 🚀 **"Most of the page"** — I pick things up quickly → `fast`
- 📖 **"About half"** — I need a few sessions to finish a page → `moderate`
- 🐢 **"A few lines"** — I prefer to go slow and careful → `slow`

**Maps to:** `encodingSpeed`

---

### Screen 5: Retention ♻️
**Header:** "Think about something you memorized last month..."  
**Subtext:** "If someone asked you to recite it today, how would it go?"

**Options:**
- 💪 **"Pretty smoothly"** — It sticks with me once I learn it → `strong`
- 🤔 **"I'd need a quick refresh"** — Then it comes back → `moderate`
- 😅 **"I'd struggle"** — Things fade if I don't review regularly → `fragile`

**Maps to:** `retentionStrength`

---

### Screen 6: Schedule & Goal ⏰🎯
**Combined screen to reduce step count.**

**Top half — Time commitment:**
- "How much time daily?" — Slider from 15 min to 4+ hours
- "When do you prefer to study?" — Chips: Fajr / Morning / Afternoon / Evening

**Bottom half — Goal:**
- "What's your aim?" — Three large cards:
  - 📖 The entire Quran
  - 📑 Specific Juz (opens multi-select)
  - 📄 Specific Surahs (opens multi-select)

---

### Screen 7: Your Reciter 🎙️
**Header:** "Choose your Qari"  
**Subtext:** "Sticking with one reciter helps build stronger auditory memory"

- Same reciter list from the app's audio screen
- Filtered by user's rewaya preference (Hafs/Warsh)
- Shows a play button to preview each reciter
- Default pre-selected: Mishary al-Afasy (ID 7) or their existing preference

**CTA:** "Continue →"

---

### Screen 8: Starting Point 📍
**Header:** "Where would you like to start?"  
**Subtext:** "Pick any page or surah — you're in full control"

**Suggested options (based on assessment + goal):**
- ⭐ Juz 30 (Juz 'Amma) — "Most common starting point"
- ⭐ Surah Al-Baqarah — "Start from the beginning"

**Custom options:**
- 🔍 Browse Surahs (opens surah list picker)
- 📄 Pick a Page (opens page number input)

**💡 Suggestion note:** "Based on your profile, we suggest starting with Juz 'Amma"

**CTA:** "Continue →"

---

### Screen 9: Profile Summary ✨
**Header:** "Your Hifz Profile"

**Shows:**
- Name + avatar
- Memory profile visualization (a simple 2-axis graphic):
  - X-axis: Encoding Speed (slow → fast)
  - Y-axis: Retention Strength (fragile → strong)
  - User's dot placed on the chart
- Framework parameters summary:
  - Daily new material: "Half a page per day"
  - Target repetitions: "10 per section"
  - Time distribution: "25 min new / 15 min review / 15 min manzil"
- Starting point: "Juz 30, Page 582"
- Estimated timeline: "At 30 minutes/day, you could complete Juz Amma in ~6 weeks"

**CTAs:**
- ✅ "Start My Journey" (creates profile, navigates to hifz dashboard)
- ✏️ "Edit" (goes back to change any answer)

---

## Assessment Mapping Summary

| Question | Field | Options → Values |
|---|---|---|
| Learning preference | `learningPreference` | Visual / Auditory / Kinesthetic / Repetition |
| Memorization speed | `encodingSpeed` | Fast / Moderate / Slow |
| Retention ability | `retentionStrength` | Strong / Moderate / Fragile |

These three values combine to determine the **framework parameters** and **plan generation** (see [plan-generation.md](../methods-and-planning/plan-generation.md)).

---

## Adaptive Calibration (Post-Onboarding)

After the first 7 days, the app has real data from actual sessions:
- Actual pages/lines memorized per session
- Self-assessment scores from reviews
- Session completion rate

If the data diverges significantly from the assessment:
> "Based on your first week, it looks like you retain material better than expected! 🎉 Want to adjust your review schedule?"

This appears as a **suggestion on the dashboard** — the user accepts or dismisses. Nothing changes automatically.

---

## Returning to the Assessment

Users can **re-take the assessment** at any time from Profile Settings. This resets the framework parameters without losing progress data.
