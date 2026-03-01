# Findings & Technical Discoveries

This document captures important API discoveries, platform quirks, and technical insights uncovered during development.

---

## 1. Quran.com API — Chapter Audio with Verse Timing (`segments=true`)

**The single most important API discovery for audio synchronization.**

### Endpoint
```
GET https://api.quran.com/api/v4/chapter_recitations/{reciter_id}/{chapter_number}?segments=true
```

### What It Returns
The `segments=true` parameter adds full timing data to the response:

```json
{
  "audio_file": {
    "audio_url": "https://download.quranicaudio.com/.../002.mp3",
    "timestamps": [
      {
        "verse_key": "2:1",
        "timestamp_from": 0,
        "timestamp_to": 5420,
        "duration": 5420,
        "segments": [[1, 0, 1230], [2, 1230, 2890], ...]
      }
    ]
  }
}
```

| Field | Description |
|---|---|
| `audio_url` | Full chapter mp3 (single file, can be 2+ hours for long surahs) |
| `timestamp_from` | Verse start position in milliseconds |
| `timestamp_to` | Verse end position in milliseconds |
| `duration` | Verse duration in milliseconds |
| `segments` | Word-level timing: `[word_index, start_ms, end_ms]` per word |

### Why This Matters
- **Gapless playback**: One continuous mp3 per chapter = zero gaps between verses
- **Precise seeking**: Seek to any verse by millisecond offset
- **Word-by-word highlighting**: Word-level segments enable real-time sync (this is how quran.com does it)
- **No verse stitching**: Previous approach of playing individual `/verse_audio/` files caused audible "ticks" at transitions

### Without `segments=true`
The same endpoint without the parameter returns only `audio_url` — no timing data at all.

---

## 2. Quran.com API — Key Endpoints Used

| Endpoint | Purpose | Notes |
|---|---|---|
| `/verses/by_page/{page}?words=true` | Page text + word-by-word data | Add `&word_fields=text_uthmani,location,audio_url` for full word data |
| `/chapters` | List of all 114 surahs | Names, verse counts |
| `/resources/recitations` | Available reciters | Each reciter has a unique ID |
| `/chapter_recitations/{reciter_id}/{chapter}` | Chapter audio file | Add `?segments=true` for timing data |

**Base URL**: `https://api.quran.com/api/v4`

---

## 3. Audio Playback — Platform Quirks (Windows)

### `audioplayers` on Windows
- **`setSourceUrl()` throws `PlatformException`** on Windows backend — cannot pre-load a URL into a player without playing it
- **Dual-player A/B approach** partially works but transitions still produce a "tick" sound
- Individual verse mp3 files: gaps are audible between files regardless of pre-loading strategy
- The Windows media backend does not support the same level of gapless features as Android/iOS

### `just_audio` on Windows
- `ConcatenatingAudioSource` (native gapless playlists) throws `MissingPluginException` on Windows
- The Windows plugin is not fully functional for advanced features
- **Not recommended for Windows targets** as of early 2026

### Solution: Full Chapter Audio
Playing a single chapter mp3 with seek positions (using the `segments=true` timing data) avoids all platform-specific gapless playback issues entirely.

---

## 4. Quran.com API — Verse Audio URLs (Per-Verse Files)

Individual verse audio files follow this pattern:
```
https://verses.quran.com/{reciter_path}/{padded_chapter}{padded_verse}.mp3
```

Example: `https://verses.quran.com/Alafasy/128/002001.mp3` (Al-Baqarah, verse 1, Alafasy)

These are useful for single-verse playback but **not for continuous recitation** due to inter-file gaps.

---

## 5. Quran Page Structure

- The Quran has **604 pages** (Madani Mushaf layout)
- Each page is fetched via `/verses/by_page/{1-604}`
- Pages can span multiple surahs (a surah can start mid-page)
- Each word has a `line_number` for layout within the page
- Word types: `"word"` (Arabic text) and `"end"` (verse number marker)
