# 🗺️ Master Product Roadmap

> **Status:** Living Document
> **Purpose:** Long-term vision and feature roadmap for Le Quran. This file is PERMANENT and should never be overwritten by a temporary feature plan.

---

## 🧠 Core Vision

**Le Quran** is a beautiful, modern Quran reading app that prioritizes a clean Mushaf reading experience with synced audio recitation, memorization tracking, and personalization — all wrapped in a premium, native-feeling UI.

### Target Users
- Daily Quran readers who want a digital Mushaf
- Hifz (memorization) students tracking progress
- Users who want to follow along with recitation audio
- Both Hafs and Warsh rewaya readers

### Target Platforms
Windows (primary dev), Android, iOS, Web, macOS, Linux

---

## ✅ Phase 1: Foundation — *Complete*

- [x] Page-by-page Mushaf reading (604 pages, Madani layout)
- [x] Arabic text rendering with proper line layout (`ReadingCanvas`)
- [x] Chapter list and navigation (`QuranReadingProvider`)
- [x] Multiple reciter support with audio playback
- [x] Full chapter audio with verse seeking (gapless)
- [x] Lock screen / Media Notification controls via `audio_service`
- [x] Contextual overlays (bookmarks, reciter selection, search)
- [x] 3 themes: Classic, Warm, Dark
- [x] Advanced Theme Picker (vertical alignment, text alignment, page shadow)
- [x] Bookmarks and reading progress persistence

---

## ✅ Phase 2: Personalization & Daily Practice — *Complete*

- [x] Warsh text integration via CDN & Unicode rendering
- [x] Persistent Rewaya selection with first-launch onboarding
- [x] App Localization (English/Arabic) with auto-detection
- [x] Daily Werd with progress tracking (timer-based page counting, milestone snackbars)
- [x] Werd setup sheet (fixed page range or daily pages mode)
- [x] Home screen (greeting, resume journey hero card, quick access, Ayah of the Day)
- [x] Bottom navigation with 5 tabs (Home, Read, Audio, Hifz, Profile)
- [x] App shell with NavigationProvider for hiding nav during reading
- [x] Hifz memorization tracker screen
- [x] Surah search

---

## 🚀 Phase 3: Audio Sync & Reading Enhancements — *Current*

- [ ] Verse-by-verse highlighting synced with audio playback
- [ ] Word-by-word highlighting (using segments data)
- [ ] Infinite scroll reading mode (alternative to page-by-page)
- [ ] Appearance settings sheet (font size, line height, reading mode toggle)
- [ ] In-app updates (GitHub release-based for Android)

---

## 📖 Phase 4: Content & Study

- [ ] Translation overlay (verse-by-verse, multiple languages)
- [ ] Tafsir overlay (verse interpretation)
- [ ] Offline audio caching (download chapters for offline use)
- [ ] Juz/Hizb navigation improvements

---

## 🔮 Phase 5: Community & Scale

- [ ] Cloud sync (user data across devices)
- [ ] User accounts
- [ ] Social features (reading groups, shared progress)
- [ ] Widget support (Android/iOS home screen widgets)
