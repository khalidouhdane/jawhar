# Gemini — Project Context & Instructions

> This file is for AI assistants working on this project. It contains essential context, architecture decisions, and instructions to maintain consistency across sessions.

---

## Project Overview

**Le Quran Prototype** — A Flutter desktop/mobile Quran reading app with:
- Page-by-page Mushaf reading (604 pages of the Madani layout)
- Word-by-word Arabic text rendering with proper line layout
- Audio recitation with verse-level synchronization
- Multiple reciter support
- Contextual overlays (verse tafsir, bookmarks, reciter selection)

**Target platforms**: Windows (primary dev), Android, iOS, Web, macOS, Linux

---

## Architecture

```
lib/
├── main.dart                         # App entry, MultiProvider setup
├── models/
│   └── quran_models.dart             # Verse, Word, Chapter, Reciter models
├── providers/
│   ├── audio_provider.dart           # Audio playback (full chapter audio + seek)
│   └── quran_reading_provider.dart   # Page loading, caching, chapter/reciter lists
├── services/
│   └── quran_api_service.dart        # HTTP calls to quran.com API
├── screens/
│   └── reading_screen.dart           # Main reading screen (PageView + overlays)
└── widgets/
    ├── reading_canvas.dart           # Renders Arabic text word-by-word per page
    ├── audio_player_bridge.dart      # Audio playback UI (controls, progress bar)
    ├── top_nav_bar.dart              # Top navigation bar overlay
    ├── bottom_dock.dart              # Bottom navigation dock overlay
    ├── overlays.dart                 # All overlay panels (settings, chapters, etc.)
    └── animated_svg_icon.dart        # Custom animated icon widget
```

### State Management
- **Provider** package with `ChangeNotifier`
- `QuranReadingProvider` — page data, chapter list, reciter list, page cache
- `AudioProvider` — audio playback state, verse timing, reciter switching

### Data Flow
1. `QuranReadingProvider` fetches page data from quran.com API
2. `ReadingCanvas` renders words for the current page
3. `AudioProvider` fetches chapter audio + timing data (see `findings.md`)
4. Position tracking maps playback position → active verse → UI highlighting

---

## Key Technical Decisions

### Audio: Full Chapter Audio with Verse Seeking
**DO NOT go back to per-verse audio files.** The current approach plays a single chapter mp3 and seeks using timestamp data from the `?segments=true` API parameter. This eliminates the "tick" sound and gaps between verses. See [findings.md](./findings.md) for full details.

### API: quran.com v4
All data comes from `https://api.quran.com/api/v4`. No authentication needed. Key endpoints and discoveries documented in [findings.md](./findings.md).

### Default Reciter
Reciter ID `7` = Mishary Rashid al-Afasy (default). Users can switch reciters via the settings overlay.

---

## Dependencies

| Package | Purpose |
|---|---|
| `provider` | State management |
| `http` | API requests |
| `audioplayers` | Audio playback (Windows-compatible) |
| `google_fonts` | Typography |
| `lucide_icons` | UI icons |
| `path_drawing` | SVG path rendering |
| `just_audio` | In pubspec but NOT actively used (Windows issues) |
| `just_audio_web` | In pubspec but NOT actively used |

---

## Important Reminders

1. **Test on Windows** — This is the primary dev platform. Audio behavior differs significantly across platforms.
2. **`just_audio` doesn't work on Windows** — `ConcatenatingAudioSource` and `setSourceUrl` both fail. Stick with `audioplayers` + full chapter audio.
3. **Page numbers are 1-604** — Madani Mushaf layout. Never go outside this range.
4. **Verse keys format**: `"chapter:verse"` (e.g., `"2:255"` = Al-Baqarah, Ayat al-Kursi)
5. **Word-level segments** from the API can enable word-by-word highlighting — this is a planned feature, not yet implemented in the UI.
6. **Cache chapter audio data per reciter** — Key pattern: `"reciterId:chapterNumber"`

---

## Planned / Upcoming Features

- [ ] Word-by-word highlighting synced with audio (using word-level `segments` data)
- [ ] Offline audio caching
- [ ] Bookmarks and reading progress persistence
- [ ] Translation overlay
- [ ] Search
- [ ] Dark mode

---

## Reference

- **API Docs**: https://api-docs.quran.com/docs/category/quran.com-api
- **Technical Discoveries**: [findings.md](./findings.md)
