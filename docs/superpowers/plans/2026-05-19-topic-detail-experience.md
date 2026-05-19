# Topic Detail Experience — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the shallow surah-list bottom sheet with a full-screen TopicDetailScreen that keeps topic context while surfacing actual Quranic verse content inline.

**Architecture:** Hybrid content — curated static data (narratives, verse ranges, perspectives) + API-fetched translations. Full EN/AR bilingual with RTL. Arabic verse text from the bundled `quran` package (offline). Translations from the Quran Foundation API via existing `TafsirService`.

**Tech Stack:** Flutter, Provider, `quran` package, Quran Foundation API v4, existing `TafsirService`/`ApiClient`

**Spec:** `docs/superpowers/specs/2026-05-19-topic-detail-experience-design.md`

---

### Task 1: Extend QuranTopic Data Model

**Files:**
- Modify: `lib/data/quran_topics.dart`

- [ ] **Step 1: Add `isComplete` field to `QuranTopic`**

```dart
class QuranTopic {
  final String id;
  final String title;
  final String titleAr;
  final String subtitle;
  final String subtitleAr;
  final IconData icon;
  final List<int> surahIds;
  final Color color;
  final bool isComplete; // NEW

  const QuranTopic({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.subtitle,
    required this.subtitleAr,
    required this.icon,
    required this.surahIds,
    required this.color,
    this.isComplete = false, // Default false
  });
}
```

- [ ] **Step 2: Set `isComplete: true` on v1 topics**

Set `isComplete: true` on these 6 topic entries: `musa`, `yusuf`, `ibrahim`, `patience`, `akhirah`, `tawhid`. Leave all others as default `false`.

- [ ] **Step 3: Verify no build errors**

Run: `flutter analyze`
Expected: No new errors

- [ ] **Step 4: Commit**

```
git add lib/data/quran_topics.dart
git commit -m "feat(understand): add isComplete field to QuranTopic"
```

---

### Task 2: Create TopicContent Data Model + Curated Content

**Files:**
- Create: `lib/data/topic_content.dart`

- [ ] **Step 1: Create models and content registry**

Create `lib/data/topic_content.dart` with:

```dart
import 'package:quran_app/data/surah_metadata.dart';

/// Rich curated content for a Quranic topic (story or theme).
class TopicContent {
  final String topicId;
  final String narrative;
  final String narrativeAr;
  final List<TopicSection> sections;

  const TopicContent({
    required this.topicId,
    required this.narrative,
    required this.narrativeAr,
    required this.sections,
  });
}

/// A single surah's contribution to a topic.
class TopicSection {
  final int surahId;
  final int startVerse;
  final int endVerse;
  final String perspective;
  final String perspectiveAr;
  final List<String> keyVerseKeys;

  const TopicSection({
    required this.surahId,
    required this.startVerse,
    required this.endVerse,
    required this.perspective,
    required this.perspectiveAr,
    required this.keyVerseKeys,
  });

  /// Get the Mushaf start page for this section's surah.
  int get startPage => surahStartPages[surahId];
}

/// Registry: topicId → TopicContent. Null for uncurated topics.
const Map<String, TopicContent> topicContentRegistry = {
  'musa': _musaContent,
  'yusuf': _yusufContent,
  'ibrahim': _ibrahimContent,
  'patience': _patienceContent,
  'akhirah': _akhirahContent,
  'tawhid': _tawhidContent,
};
```

Then define the 6 content constants (`_musaContent`, `_yusufContent`, etc.) with:
- 2-3 paragraph EN/AR narratives
- `TopicSection` entries per surah with verse ranges, perspective descriptions, and 2-3 key verse keys each

**Content guidelines:**
- Narratives: scholarly but accessible, 150-250 words each
- Perspectives: 1-2 sentences explaining what this surah contributes to the topic
- Key verses: the most iconic/impactful verses for the topic in that surah
- Arabic narratives: equivalent quality, not machine-translated

- [ ] **Step 2: Verify build**

Run: `flutter analyze`
Expected: No errors

- [ ] **Step 3: Commit**

```
git add lib/data/topic_content.dart
git commit -m "feat(understand): add curated topic content for 6 topics"
```

---

### Task 3: Add Localization Keys

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`

- [ ] **Step 1: Add EN keys to `app_en.arb`**

Add these keys (following existing naming patterns like `undStories`, `undThemes`):

```json
"topicOverview": "Overview",
"topicKeyVerses": "Key Verses",
"topicReadInMushaf": "Read in Mushaf",
"topicVerseRange": "Verses {start}–{end}",
"@topicVerseRange": { "placeholders": { "start": {}, "end": {} } },
"topicComingSoon": "Detailed exploration coming soon.",
"topicMentionedIn": "Mentioned in {count} surahs",
"@topicMentionedIn": { "placeholders": { "count": {} } },
"topicShowVerses": "Show key verses",
"topicHideVerses": "Hide key verses",
"topicOfflineVerse": "Translation unavailable offline"
```

- [ ] **Step 2: Add AR keys to `app_ar.arb`**

```json
"topicOverview": "نظرة عامة",
"topicKeyVerses": "آيات مفتاحية",
"topicReadInMushaf": "اقرأ في المصحف",
"topicVerseRange": "الآيات {start}–{end}",
"@topicVerseRange": { "placeholders": { "start": {}, "end": {} } },
"topicComingSoon": "استكشاف مفصل قريباً.",
"topicMentionedIn": "مذكور في {count} سور",
"@topicMentionedIn": { "placeholders": { "count": {} } },
"topicShowVerses": "عرض الآيات المفتاحية",
"topicHideVerses": "إخفاء الآيات المفتاحية",
"topicOfflineVerse": "الترجمة غير متوفرة بدون اتصال"
```

- [ ] **Step 3: Regenerate localizations**

Run: `flutter gen-l10n`
Expected: No errors, `app_localizations.dart` updated

- [ ] **Step 4: Commit**

```
git add lib/l10n/
git commit -m "feat(l10n): add topic detail localization keys (EN/AR)"
```

---

### Task 4: Create TopicSectionCard Widget

**Files:**
- Create: `lib/widgets/understand/topic_section_card.dart`

- [ ] **Step 1: Create the collapsible section card**

This widget renders one surah's contribution to a topic. Key behaviors:
- Shows surah name (locale-aware) + verse range badge + perspective text
- Collapsible: tap header to expand/collapse
- When expanded, fetches key verse translations via `TafsirService.getTranslation()`
- Arabic verse text from `quran.getVerse()` (offline, always available)
- "Read in Mushaf" CTA at bottom → `ReadingScreen(initialPage: section.startPage)`
- Shimmer loading while translations load
- Offline fallback: shows Arabic text + `topicOfflineVerse` message

Constructor:
```dart
class TopicSectionCard extends StatefulWidget {
  final TopicSection section;
  final bool initiallyExpanded;
  
  const TopicSectionCard({
    super.key,
    required this.section,
    this.initiallyExpanded = false,
  });
}
```

**Font rules (follow existing patterns):**
- Arabic Quranic text: `GoogleFonts.amiri()`
- Arabic UI: `GoogleFonts.amiri()` for perspective when `isArabic`, Geist for labels
- English UI: `GeistTypography.primaryFontFamily` throughout
- Check `AppLocalizations.of(context)!.localeName == 'ar'` for locale switching

**API pattern (from `TafsirService`):**
```dart
final tafsirService = context.read<ContextProvider>().tafsirService; // Wrong — TafsirService isn't exposed
// Instead, create a local TafsirService instance or use ContextProvider methods
```

Actually, looking at `ContextProvider`, it doesn't expose `TafsirService` directly for arbitrary verse translation calls. The simplest approach: instantiate a local `TafsirService()` in the widget state, call `getTranslation(verseKey, translationId: translationId)` where `translationId` comes from `context.read<ContextProvider>().selectedTranslationId`.

- [ ] **Step 2: Verify build**

Run: `flutter analyze`

- [ ] **Step 3: Commit**

```
git add lib/widgets/understand/topic_section_card.dart
git commit -m "feat(understand): add TopicSectionCard with collapsible verse content"
```

---

### Task 5: Create TopicDetailScreen

**Files:**
- Create: `lib/screens/topic_detail_screen.dart`

- [ ] **Step 1: Create the full-screen topic detail page**

Structure:
1. `Scaffold` with `AppBar` showing topic title (locale-aware) + Arabic subtitle
2. `SingleChildScrollView` body with:
   - Hero section: icon container, title, Arabic name, subtitle
   - "Overview" section header + narrative text (from `topicContentRegistry`)
   - "{N} surahs" count badge
   - List of `TopicSectionCard` widgets — one per `TopicContent.sections`
3. For `isComplete == false` topics (no `TopicContent`):
   - Show hero + `topicComingSoon` message
   - Fall back to simple surah list (reuse existing surah-list pattern from `topic_carousel.dart`)
   - Each surah row opens `SurahDetailSheet` (preserves current behavior)

Constructor:
```dart
class TopicDetailScreen extends StatelessWidget {
  final QuranTopic topic;
  const TopicDetailScreen({super.key, required this.topic});
}
```

**Collapse logic:**
- `sections.length <= 3` → all start expanded (`initiallyExpanded: true`)
- `sections.length > 3` → all start collapsed

**Bilingual:**
- Title: `isArabic ? topic.titleAr : topic.title`
- Narrative: `isArabic ? content.narrativeAr : content.narrative`
- Font switching follows established patterns

- [ ] **Step 2: Verify build**

Run: `flutter analyze`

- [ ] **Step 3: Commit**

```
git add lib/screens/topic_detail_screen.dart
git commit -m "feat(understand): add TopicDetailScreen with curated content"
```

---

### Task 6: Wire Up Navigation

**Files:**
- Modify: `lib/widgets/understand/topic_carousel.dart` (lines 74-315 — `_showRelatedSurahs` method + onTap)

- [ ] **Step 1: Replace bottom sheet with Navigator.push**

In `_TopicCard`, change `_showRelatedSurahs(context)` to:

```dart
void _openTopicDetail(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => TopicDetailScreen(topic: topic),
    ),
  );
}
```

Update the `onTap` in `build()`:
```dart
onTap: () => _openTopicDetail(context),
```

Add import:
```dart
import 'package:quran_app/screens/topic_detail_screen.dart';
```

The old `_showRelatedSurahs` method can be removed entirely (the fallback surah list for incomplete topics is now handled inside `TopicDetailScreen`).

- [ ] **Step 2: Update ExploreCarousel (dashboard)**

The `ExploreCarousel` in `lib/widgets/dashboard/explore_carousel.dart` reuses `TopicCarousel`, so the navigation change propagates automatically. No code change needed — just verify.

- [ ] **Step 3: Verify build and test**

Run: `flutter analyze`
Then: `flutter run -d windows --dart-define-from-file=.env`

Manual test:
1. Go to Understand tab → tap a curated topic card (e.g., Musa) → verify full-screen TopicDetailScreen opens
2. Verify narrative, sections, key verses load
3. Tap "Read in Mushaf" → verify ReadingScreen opens at correct page
4. Go back → tap an uncurated topic → verify fallback surah list appears
5. Switch to Arabic locale → verify all content switches
6. Test from Dashboard explore carousel → same behavior

- [ ] **Step 4: Commit**

```
git add lib/widgets/understand/topic_carousel.dart lib/screens/topic_detail_screen.dart
git commit -m "feat(understand): wire topic cards to TopicDetailScreen"
```

---

### Task 7: Final Polish & Verification

- [ ] **Step 1: Full analyze**

Run: `flutter analyze`
Expected: 0 errors, 0 warnings

- [ ] **Step 2: RTL verification**

Switch app to Arabic, navigate through:
- Understand tab → topic card → TopicDetailScreen
- Verify RTL layout, Arabic fonts, narrative text direction
- Verify section cards expand/collapse correctly in RTL
- Verify "Read in Mushaf" CTA works

- [ ] **Step 3: Offline verification**

Disconnect network, open a curated topic. Verify:
- Narrative and perspectives render (static data)
- Arabic verse text renders (bundled `quran` package)
- Translation shows `topicOfflineVerse` fallback
- No crashes

- [ ] **Step 4: Final commit**

```
git add -A
git commit -m "feat(understand): topic detail experience complete"
```
