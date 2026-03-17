# 🔬 Technical Findings & Platform Quirks

> Raw technical discoveries uncovered during development. Platform-specific issues, workarounds, and gotchas.

---

## 1. Audio Playback — Windows Platform Quirks

### `audioplayers` on Windows
- `setSourceUrl()` throws `PlatformException` on Windows backend — cannot pre-load a URL without playing it
- Dual-player A/B transition approach partially works but still produces a "tick" sound
- Individual verse mp3 files: gaps are audible between files regardless of pre-loading strategy
- The Windows media backend does not support the same level of gapless features as Android/iOS

### `just_audio` on Windows
- `ConcatenatingAudioSource` (native gapless playlists) throws `MissingPluginException` on Windows
- The Windows plugin is not fully functional for advanced features
- **Not recommended for Windows targets** as of early 2026

### Solution
Full chapter audio with seek positions (using `segments=true` timing data) avoids all platform-specific gapless playback issues entirely.

---

## 2. Windows Accessibility Bridge

- Large `RichText` widgets (like `ReadingCanvas` with 1000+ spans) crash the Windows Accessibility Bridge when dynamically updated (e.g., font size slider)
- **Fix**: Wrap large `RichText` in `ExcludeSemantics()` widget
- This is critical for any widget with many `TextSpan` children that may be rebuilt frequently

---

## 3. Quran.com API Migration

- Legacy `api.quran.com` endpoints returned 503 errors as of early 2026
- Migrated to new authenticated API: `apis.quran.foundation/content/api/v4`
- Requires OAuth2 client credentials flow for authentication
- `arabic_name` field in QDC reciter API response is always empty — local Arabic name map needed as fallback

---

## 4. Rewaya & Reciter Filtering

- Not all reciters are available for both Hafs and Warsh
- MP3Quran API (`mp3quran.net`) has better Warsh reciter coverage than quran.com
- Reciter filtering by rewaya is handled client-side based on `apiSource`
