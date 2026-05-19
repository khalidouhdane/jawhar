# Topic Detail Experience — Design Spec

> **Problem:** Tapping a Story/Theme card in the Understand tab leads to a surah list → surah detail sheet flow that loses the original topic context entirely. The data model is too shallow (just surah IDs) and the destination (SurahDetailSheet) has no topic awareness.
>
> **Solution:** Replace the surah-list bottom sheet with a full-screen TopicDetailScreen that keeps the topic front-and-center while surfacing actual Quranic verse content inline, powered by curated editorial data + live API translations.

---

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Content approach | **Hybrid** — curated narrative + API-fetched verses | Curated data gives editorial soul; API provides actual Quranic content dynamically |
| Navigation | **Full-screen page** (TopicDetailScreen) | Rich content needs room; bottom sheets feel cramped and lose context |
| Scope | **Focused** — only the topic flow changes | Surah browser, TodayContextCard, SurahDetailSheet stay as-is |
| Content scope | **5-6 topics for v1** | Curate quality content for a subset; rest show graceful fallback |
| Bilingual | **Full EN/AR** with RTL layout support | All curated content, UI strings, and API content respect locale |

---

## Data Model

### Extended QuranTopic

Add one field to the existing `QuranTopic` class:

```dart
class QuranTopic {
  // ... existing fields (id, title, titleAr, subtitle, subtitleAr, icon, surahIds, color)
  final bool isComplete; // true if curated TopicContent exists
}
```

### New: TopicContent

Companion content model stored in a new `topic_content.dart` file.

```dart
/// Rich curated content for a single Quranic topic (story or theme).
class TopicContent {
  final String topicId;              // Links to QuranTopic.id (e.g., 'musa')
  final String narrative;            // 2-3 paragraph overview (English)
  final String narrativeAr;          // 2-3 paragraph overview (Arabic)
  final List<TopicSection> sections; // One per surah where this topic appears

  const TopicContent({
    required this.topicId,
    required this.narrative,
    required this.narrativeAr,
    required this.sections,
  });
}

/// A single surah's contribution to a topic.
class TopicSection {
  final int surahId;                 // e.g., 28 for Al-Qasas
  final int startVerse;              // e.g., 3 (for 28:3)
  final int endVerse;                // e.g., 42 (for 28:42)
  final String perspective;          // What this surah contributes (EN)
  final String perspectiveAr;        // What this surah contributes (AR)
  final List<String> keyVerseKeys;   // Standout verses: ["28:7", "28:15", "28:30"]

  const TopicSection({
    required this.surahId,
    required this.startVerse,
    required this.endVerse,
    required this.perspective,
    required this.perspectiveAr,
    required this.keyVerseKeys,
  });
}
```

### Content Registry

A top-level `Map<String, TopicContent>` in `topic_content.dart`:

```dart
const Map<String, TopicContent> topicContentRegistry = {
  'musa': TopicContent(topicId: 'musa', narrative: '...', ...),
  'yusuf': TopicContent(topicId: 'yusuf', narrative: '...', ...),
  // ...
};
```

Lookup: `topicContentRegistry[topic.id]` — returns `null` for topics without curated content.

---

## Screen: TopicDetailScreen

### Route

Pushed from `TopicCarousel._TopicCard.onTap` via `Navigator.push`:

```dart
Navigator.push(context, MaterialPageRoute(
  builder: (_) => TopicDetailScreen(topic: topic),
));
```

### Layout Structure

```
┌─────────────────────────────────────┐
│ ← [Topic Title]        [Arabic]    │  App bar — sticky, shows topic name
├─────────────────────────────────────┤
│                                     │
│  [Icon]                             │
│  [Title] / [TitleAr]               │  Hero section
│  [Subtitle] / [SubtitleAr]         │
│                                     │
│  ── [Overview] ──                   │
│  [Narrative paragraph 1]           │  Curated narrative (2-3 paragraphs)
│  [Narrative paragraph 2]           │  Uses locale to pick EN or AR
│                                     │
│  [X surahs badge]                  │  Count indicator
│                                     │
├─────────────────────────────────────┤
│                                     │
│  ▶ Al-Baqarah · 2:49–73           │  Section card (collapsed)
│    [Perspective one-liner]         │
│                                     │
│  ▼ Taha · 20:9–98                 │  Section card (expanded)
│    [Perspective text]              │
│    ┌─ Key Verses ──────────────┐   │
│    │  20:9  [Arabic text]      │   │  Fetched via API
│    │  [Translation text]       │   │
│    │                           │   │
│    │  20:17  [Arabic text]     │   │
│    │  [Translation text]       │   │
│    └───────────────────────────┘   │
│    [ Read in Mushaf → Page 312 ]   │  CTA → ReadingScreen
│                                     │
│  ▶ Al-Qasas · 28:3–42             │  Section card (collapsed)
│    [Perspective one-liner]         │
│                                     │
│  ...more sections...               │
│                                     │
└─────────────────────────────────────┘
```

### Bilingual Behavior

| Element | English | Arabic |
|---------|---------|--------|
| App bar title | `topic.title` | `topic.titleAr` |
| Narrative text | `content.narrative` | `content.narrativeAr` |
| Perspective text | `section.perspective` | `section.perspectiveAr` |
| Verse Arabic text | Always shown (Amiri font) | Always shown (Amiri font) |
| Verse translation | English translation (resource ID from ContextProvider) | Arabic tafsir/translation (resource ID from ContextProvider) |
| Section headers | "Key Verses", "Overview" | Localized via AppLocalizations |
| CTA labels | "Read in Mushaf" | Localized via AppLocalizations |
| Layout direction | LTR | RTL (automatic via `Directionality`) |

**Font rules:**
- Arabic Quranic text: `GoogleFonts.amiri()` — always
- Arabic UI text (perspectives, narrative): `GoogleFonts.amiri()` for body, Geist for labels/badges
- English UI text: Geist Sans throughout
- These follow the existing patterns in `TopicCarousel` and `SurahDetailSheet`

### Section Card Behavior

- **Default state:** Collapsed — shows surah name, verse range badge, perspective one-liner
- **Tap to expand:** Reveals the full perspective text + key verses area
- **Key verses load on expand:** When a section expands, fetch translations for `keyVerseKeys` via the Quran Foundation API. Show shimmer loading states during fetch.
- **For topics with ≤3 sections:** All sections start expanded (no need to collapse)
- **For topics with >3 sections:** All start collapsed; user expands what interests them

### API Integration for Verse Content

Use the existing `TafsirService` endpoint pattern:

```
GET /verses/by_key/{verse_key}?translations={translation_id}&language={lang}
```

- Translation resource IDs are already managed by `ContextProvider` based on locale
- Fetch key verses per section on expand (not on screen load — lazy)
- Cache responses in memory for the session (navigating back doesn't re-fetch)
- Error state: if API fails, show the verse reference without translation text and a subtle retry link

### "Coming Soon" Fallback

For topics where `isComplete == false`:

- The topic card in the carousel looks identical (no visual downgrade)
- Tapping navigates to TopicDetailScreen but shows a **minimal version**:
  - Topic hero (icon, title, subtitle) — same as complete topics
  - Instead of a narrative, show a single line: "Detailed exploration coming soon."
  - Below, show the **existing surah list** (same data as current bottom sheet) so the user isn't at a dead-end. Each surah still opens `SurahDetailSheet`.
  - This preserves current functionality while signaling that richer content is planned

---

## V1 Curated Topics

### Stories (3)

#### 1. Musa & Pharaoh (`musa`)
- **Surahs:** Al-Baqarah (2:49–73), Al-A'raf (7:103–162), Yunus (10:75–92), Taha (20:9–98), Ash-Shu'ara (26:10–68), Al-Qasas (28:3–42), Ghafir (40:23–46), An-Nazi'at (79:15–26)
- **Narrative focus:** The most-told story in the Quran, retold from different angles in each surah — from Musa's birth, to the burning bush, to confronting Pharaoh, to the exodus, to Bani Isra'il afterward
- **Key verses per section:** 2-3 standout ayat per surah

#### 2. Yusuf (`yusuf`)
- **Surahs:** Yusuf (12:1–111)
- **Narrative focus:** The only complete narrative in a single surah — "the best of stories." From the childhood dream to reunion as Egypt's minister.
- **Sections:** Can be broken into narrative phases within the single surah (e.g., The Dream 12:4–6, The Brothers' Plot 12:7–18, In the Well 12:19–20, In Egypt 12:21–34, The Prison 12:35–42, The King's Dream 12:43–57, The Reunion 12:58–100, The Reflection 12:101–111)

#### 3. Ibrahim (`ibrahim`)
- **Surahs:** Al-Baqarah (2:124–141), Al-An'am (6:74–83), Ibrahim (14:35–41), Al-Hijr (15:51–60), Maryam (19:41–50), Al-Anbiya (21:51–73), As-Saffat (37:83–113)
- **Narrative focus:** The father of prophets — his argument with his father, smashing the idols, the fire, building the Ka'bah, the sacrifice of Isma'il

### Themes (3)

#### 4. Patience & Trust (`patience`)
- **Surahs:** Al-Baqarah (2:153–157), Aal-Imran (3:200), Yusuf (12:18, 12:83, 12:90), Al-Kahf (18:28), Ad-Duha (93:1–11), Ash-Sharh (94:1–8)
- **Narrative focus:** How the Quran frames patience — not as passive endurance but as active trust in divine wisdom

#### 5. The Afterlife (`akhirah`)
- **Surahs:** Ya-Sin (36:51–67), Qaf (50:19–35), Al-Waqi'ah (56:1–96), Al-Haqqah (69:13–37), Al-Qiyamah (75:1–40), An-Naba (78:1–40), At-Takwir (81:1–14), Al-Infitar (82:1–19), Al-Inshiqaq (84:1–15), Az-Zalzalah (99:1–8), Al-Qari'ah (101:1–11)
- **Narrative focus:** How the Quran paints the Day of Judgment — cosmic imagery, accountability, the contrast between Paradise and Hell

#### 6. Monotheism (`tawhid`)
- **Surahs:** Al-Fatiha (1:1–7), Al-Baqarah (2:255), Al-An'am (6:1–3, 6:95–103), Al-Ikhlas (112:1–4)
- **Narrative focus:** The foundational principle — from Ayatul Kursi to the cosmic signs to the pure declaration of Al-Ikhlas

---

## New Localization Keys

All new UI strings go through `AppLocalizations`. Estimated new keys:

```
topicOverview        → "Overview" / "نظرة عامة"
topicKeyVerses       → "Key Verses" / "آيات مفتاحية"
topicReadInMushaf    → "Read in Mushaf" / "اقرأ في المصحف"
topicVerseRange      → "Verses {start}–{end}" / "الآيات {start}–{end}"
topicComingSoon      → "Detailed exploration coming soon." / "استكشاف مفصل قريباً."
topicMentionedIn     → "Mentioned in {count} surahs" / "مذكور في {count} سور"
topicExpandSection   → "Show key verses" / "عرض الآيات المفتاحية"
topicCollapseSection → "Hide key verses" / "إخفاء الآيات المفتاحية"
```

---

## File Changes

### New Files

| File | Purpose |
|------|---------|
| `lib/data/topic_content.dart` | `TopicContent`, `TopicSection` models + `topicContentRegistry` map with curated content for 6 topics |
| `lib/screens/topic_detail_screen.dart` | Full-screen topic detail page with hero, narrative, collapsible section cards |
| `lib/widgets/understand/topic_section_card.dart` | Collapsible card widget: surah perspective + lazy-loaded key verses |

### Modified Files

| File | Change |
|------|--------|
| `lib/data/quran_topics.dart` | Add `isComplete` field to `QuranTopic`; set `true` for v1 topics, `false` for rest |
| `lib/widgets/understand/topic_carousel.dart` | Change `_TopicCard.onTap` from `_showRelatedSurahs()` bottom sheet to `Navigator.push(TopicDetailScreen)` |
| `lib/widgets/dashboard/explore_carousel.dart` | Same navigation change for dashboard topic cards |
| `lib/l10n/app_en.arb` | Add ~8 new localization keys |
| `lib/l10n/app_ar.arb` | Add ~8 new Arabic localization keys |

### Untouched Files

| File | Why |
|------|-----|
| `surah_detail_sheet.dart` | Still used by the 114-surah browser |
| `today_context_card.dart` | Works well as-is |
| `understand_screen.dart` | Layout unchanged — carousels + surah browser stay |

---

## Edge Cases

1. **No network:** Curated content (narrative, perspectives) renders fully offline. Key verses show "Translation unavailable offline" with just the verse reference. No crash.
2. **Yusuf special case:** Single surah with 8 narrative phases (sections within the same surah). The verse range for each section is within Surah 12. The "Read in Mushaf" CTA points to the correct page for each phase.
3. **RTL layout:** TopicDetailScreen uses `Directionality` from `LocaleProvider`. All `CrossAxisAlignment.start` and `EdgeInsets` respect text direction. Arabic narrative text uses `Amiri` with appropriate line height.
4. **Long narratives:** Narrative text is scrollable within the page. No truncation — this is the deep-dive content the user came for.
5. **API rate limits:** Key verses are fetched per-section on expand, not all at once. Max ~3 API calls per section (one per key verse). With 8 sections on Musa, worst case is 24 calls — but only if user expands all. Lazy loading prevents this.

---

## What This Does NOT Include

- No changes to the surah browser or SurahDetailSheet
- No hifz-progress integration in the topic view (future enhancement: "You've memorized 3/8 surahs where Musa appears")
- No search/filter within topics
- No topic-to-topic cross-references
- No audio playback of key verses (future enhancement)

These are intentional YAGNI cuts for v1. Each is a natural follow-up once the core experience proves its value.
