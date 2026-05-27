# Audio Player Sync Issues & Multiplatform Research Brief

This document serves as an **Executive Summary** of the timing synchronization and seeking issues observed on Android, and a **Research Brief** to guide the selection of the best multiplatform audio player for the Quran App.

---

## 📋 Part 1: Executive Summary of the Sync & Seek Issue

### The Symptom
* When playing recitations (specifically Yasser al-Dosari, Surah Al-Baqarah) on Android, the **verse highlighter is ahead of the reciter** (or the reciter is behind the highlighter) by 2 to 3 words on average (roughly **1.2s to 2.0s**).
* Seeking or tapping directly on specific verses (e.g., verses 10, 11, 13, 14) is inaccurate, often starting from the end of the previous verse or dropping/lagging.
* On the web version of the tool, the synchronization and highlighting are **perfectly accurate**.

### The Root Cause
1. **Variable Bit Rate (VBR) MP3s**: The audio files hosted on QuranicAudio / Quran.com are encoded in VBR format to optimize audio file sizes for speech without sacrificing quality.
2. **Legacy Android MediaPlayer Limitation**: By default, the `audioplayers` package on Android wraps the native system `MediaPlayer`. The native Android `MediaPlayer` is notorious for failing to parse the VBR header metadata (such as the Xing/VBRI frame indices) in MP3 streams.
3. **Inaccurate Time Estimation**: Lacking a proper frame-to-time map, `MediaPlayer` estimates time and seeking positions linearly based on byte offsets. As a result, the reported playhead position drifts significantly during playback, and seeks land on the wrong timeframes.
4. **Why Web Works**: Modern web browsers (Chrome, Safari) utilize advanced, spec-compliant audio decoders that correctly index VBR MP3 streams, meaning the timing database is correct but the mobile playback engine is failing to parse it.

---

## 🛠️ Part 2: Current Workaround & State of Code

To fix this within the current architecture without changing player APIs:
* **Proxy Server Removed for Android**: The `AudioProxyServer` loopback server was disabled for Android because piping streams through `127.0.0.1` caused the `MediaPlayer` to buffer ahead aggressively, exacerbating the estimation error. The proxy remains active only on Windows to bypass TLS renegotiation bugs.
* **ExoPlayer Integration Attempt**: We added the `audioplayers_android_exo: ^0.1.3` dependency to `pubspec.yaml` and triggered a native Android compile. Adding this package instructs `audioplayers` to use Google's modern **ExoPlayer (Media3)** backend on Android instead of `MediaPlayer`. ExoPlayer handles VBR index tables much more accurately.

---

## 🔍 Part 3: Instructions for Multiplatform Audio Player Research

For the incoming developer or AI agent, perform a deep comparative study to identify the **absolute best audio player engine** for the Quran App's requirements.

### Core Requirements Checklists

- **Timing Precision**: Must support millisecond-level position reporting and seek precision for variable bit-rate (VBR) audio streams.
- **Gapless Playback**: Must play continuous Surah files without audio pops, lag, or clicks between verse seeking/triggers.
- **Cross-Platform Parity**: Must support Android, iOS, and Windows.
- **Windows compatibility**: Must work seamlessly on Windows without falling victim to the native SSL/TLS renegotiation bug (0x80072F8F) that breaks direct HTTPS streams.
- **Media Controls Integration**: Must integrate with native platform lock-screen/background controls (e.g. `audio_service`).
- **Speed Modulation**: Must support custom playback rates (`0.5x`, `0.75x`, `1.0x`, `1.25x`, `1.5x`, `2.0x`).

### Players to Compare

Please evaluate the following libraries against our requirements:

| Library | Android Backend | Windows Backend | SSL Renegotiation Handling (Windows) | VBR MP3 Precision | Lock Screen Integration |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`audioplayers`** (Current) | `MediaPlayer` / `ExoPlayer` (via plugin) | `MediaFoundation` | Requires custom loopback HTTP proxy | Poor on MediaPlayer; Good on ExoPlayer | Custom implementation |
| **`just_audio`** | `ExoPlayer` (Media3) | `dart_vlc` or native | Needs validation | Excellent (ExoPlayer indexing) | Via `audio_service` |
| **`flutter_soloud`** | `SoLoud` (C++ Engine) | `SoLoud` (C++ Engine) | Bypasses OS limitations (built-in parser) | Excellent (Fully decoded in memory) | Requires custom glue |
| **`assets_audio_player`** | `ExoPlayer` | `native` | Needs validation | Good | Built-in |

### Research Directives for the Next Agent

1. **Verify `audioplayers_android_exo`**: First, test if the newly added ExoPlayer backend completely resolves the Yasser al-Dosari sync and seek issues on Android.
2. **Evaluate Windows SSL Renegotiation with `just_audio`**: If migrating to `just_audio`, research if it suffers from the same Windows SSL bug (0x80072F8F) that forced us to build `AudioProxyServer` for `audioplayers`.
3. **Assess `flutter_soloud`**: Assess if a low-level C++ engine like `flutter_soloud` is viable. Since it bypasses OS decoders completely by doing it in C++, does it offer the ultimate cross-platform consistency for timeline-scrubbed audio?
4. **Draft Migration Plan**: If a package migration is necessary, draft a step-by-step conversion for `lib/providers/audio_provider.dart` to preserve repeating modes, ranges, and state transitions.
