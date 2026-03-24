# 🔌 API Reference

> **All external APIs, authentication, and CDN endpoints used by Le Quran.**

---

## 1. Quran Foundation API (v4) — Primary Data Source

### Base URL
```
https://apis.quran.foundation/content/api/v4
```

> ⚠️ The legacy `api.quran.com` endpoints are **deprecated** and returning 503 errors.

### Authentication

| Field | Value |
|-------|-------|
| Auth URL | `https://oauth2.quran.foundation/oauth2/token` |
| Method | `POST` with `grant_type=client_credentials&scope=content` |
| Client ID | `879421dc-68cb-4a1d-a500-c060d10478e6` |
| Client Secret | `cKEt~daJ4tgXiJ1td0t4JwBB_z` |

**Required headers on every request:**
```
x-auth-token: <bearer_token>
x-client-id: <client_id>
```

Token management is handled by `QuranAuthService`.

### Key Endpoints

| Endpoint | Purpose | Notes |
|----------|---------|-------|
| `GET /verses/by_page/{page}?words=true` | Page text + word-by-word data | Add `&word_fields=text_uthmani,location,audio_url` for full word data |
| `GET /chapters` | List of all 114 surahs | Names, verse counts |
| `GET /resources/recitations` | Available reciters | Each reciter has a unique ID |
| `GET /chapter_recitations/{reciter_id}/{chapter}` | Chapter audio file | Add `?segments=true` for timing data |

---

## 2. Chapter Audio with Verse Timing (`segments=true`)

**The single most important API discovery for audio synchronization.**

### Endpoint
```
GET /chapter_recitations/{reciter_id}/{chapter_number}?segments=true
```

### Response Structure
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
        "segments": [[1, 0, 1230], [2, 1230, 2890]]
      }
    ]
  }
}
```

| Field | Description |
|-------|-------------|
| `audio_url` | Full chapter mp3 (single file, can be 2+ hours for long surahs) |
| `timestamp_from` | Verse start position in milliseconds |
| `timestamp_to` | Verse end position in milliseconds |
| `duration` | Verse duration in milliseconds |
| `segments` | Word-level timing: `[word_index, start_ms, end_ms]` per word |

### Why This Matters
- **Gapless playback**: One continuous mp3 per chapter = zero gaps between verses
- **Precise seeking**: Seek to any verse by millisecond offset
- **Word-by-word highlighting**: Word-level segments enable real-time sync
- **No verse stitching**: Per-verse files caused audible "ticks" at transitions

### Without `segments=true`
Returns only `audio_url` — no timing data at all.

---

## 3. Per-Verse Audio URLs (Reference Only)

Individual verse audio files follow this pattern:
```
https://verses.quran.com/{reciter_path}/{padded_chapter}{padded_verse}.mp3
```

Example: `https://verses.quran.com/Alafasy/128/002001.mp3`

> ⚠️ Useful for single-verse playback but **not for continuous recitation** due to inter-file gaps.

---

## 4. MP3Quran API — Warsh Reciters

**Service**: `Mp3QuranService` (`mp3quran_service.dart`)

Used to fetch reciters for the Warsh rewaya, which has limited coverage on quran.com.

### Base URL
```
https://mp3quran.net/api/v3
```

### Key Endpoints
| Endpoint | Purpose |
|----------|---------|
| `GET /reciters?language=ar&rewaya=2` | List Warsh reciters |
| Moshaf `server` field | Base URL for chapter mp3s |

### Audio URL Pattern
```
{server}/{padded_chapter}.mp3
```

---

## 5. Warsh Text CDN

**Service**: `WarshTextService` (`warsh_text_service.dart`)

### Source
```
https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/ara-quranwarsh.json
```

Returns a flat JSON array of all 6236 Warsh verses in Unicode. No custom fonts needed — renders with the system's Arabic font.

**Caching**: In-memory only (fetched once per app session).

---

## 6. Quran Page Structure

| Fact | Value |
|------|-------|
| Total pages | 604 (Madani Mushaf layout) |
| API endpoint | `GET /verses/by_page/{1-604}` |
| Page spanning | Pages can span multiple surahs |
| Word layout | Each word has a `line_number` for positioning within the page |
| Word types | `"word"` (Arabic text) and `"end"` (verse number marker) |
| Verse key format | `"chapter:verse"` (e.g., `"2:255"`) |

---

## 7. Translations & Tafsir

> **IMPORTANT:** The `/quran/translations/{id}` and `/quran/tafsirs/{id}` endpoints return **empty arrays** in v4.
> Always use the `/verses/` endpoints with query parameters instead.

### Single Verse Translation

```
GET /verses/by_key/{verse_key}?translations={translation_id}
```

### Page Batch Translations (used by TranslationOverlay)

```
GET /verses/by_page/{page}?translations={translation_id}&per_page=50
```

### Single Verse Tafsir

```
GET /verses/by_key/{verse_key}?tafsirs={tafsir_id}
```

### Verified Resource IDs

| ID | Resource | Type | Language |
|----|----------|------|----------|
| 85 | Abdel Haleem | Translation | English |
| 1014 | Tafsir Al-Muyasser | Translation | Arabic |
| 169 | Ibn Kathir Abridged | Tafsir (Brief) | English |
| 168 | Ma'arif al-Qur'an | Tafsir (Detailed) | English |
| 16 | Muyassar | Tafsir (Brief) | Arabic |
| 14 | Ibn Kathir | Tafsir (Detailed) | Arabic |

### Resource Discovery

```
GET /resources/translations   — list all available translation resources
GET /resources/tafsirs        — list all available tafsir resources
```

> Resource IDs auto-switch by locale in `ContextProvider.setLocale()`.

