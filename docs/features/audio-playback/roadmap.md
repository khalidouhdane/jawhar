# 🔊 Audio Playback — Feature Roadmap

> **Status:** Phase 3 (In Progress)
> **Files:** `audio_provider.dart`, `quran_audio_handler.dart`, `audio_player_bridge.dart`, `audio_settings_sheet.dart`

---

## ✅ Completed

- [x] Full chapter audio playback (single mp3 per chapter)
- [x] Verse seeking using `?segments=true` timestamp data
- [x] Multiple reciter support (quran.com + mp3quran.net)
- [x] Lock screen / notification media controls (`audio_service`)
- [x] Reciter selection sheet with search
- [x] Audio settings sheet (repeat mode)
- [x] Hafs and Warsh reciter filtering

## 🚀 In Progress

- [ ] **Verse-by-verse highlighting** — Highlight the active verse in `ReadingCanvas` during audio playback using timestamp data
- [ ] **Word-by-word highlighting** — Use `segments` word-level timing for real-time word highlighting (quran.com style)

## 📋 Planned

- [ ] **Offline audio caching** — Download chapter mp3s for offline use
- [ ] **Auto-advance to next chapter** — Seamless chapter transitions during playback
- [ ] **Playback speed control** — 0.5x to 2.0x speed adjustment
- [ ] **Repeat verse/range** — Loop a single verse or custom range for memorization

---

## Technical Notes

- **Engine**: `audioplayers` (NOT `just_audio` — doesn't work on Windows)
- **Background**: `audio_service` wraps playback for system media controls
- **Cache key pattern**: `"reciterId:chapterNumber"`
- **Timing data**: Fetched via `?segments=true` on chapter recitation endpoint
- See [api-reference.md](../api-reference.md) for full endpoint details
