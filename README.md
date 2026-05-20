# Jawhar (جوهر) — Memorize with Meaning

[![Live Demo](https://img.shields.io/badge/Live_Demo-Website-000000)](https://jawhar.alphafoundr.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](https://opensource.org/licenses/MIT)

**Jawhar** is a modern, privacy-first Quran memorization (Hifz) companion designed to bridge the gap between rote memorization and deep comprehension. Built on the core philosophy that memorization without understanding is incomplete, Jawhar integrates localized translations, tafsir, reasons of revelation (Asbab al-Nuzul), and adaptive daily scheduling into a unified, distraction-free reading experience.

---

## 💎 The Pillars of Jawhar

### 1. The Plan (Adaptive Scheduling)
*   **Methodology-Driven:** Automatically structures your day using the traditional *Sabaq* (new memorization), *Sabqi* (recent revision), and *Manzil* (long-term revision) pipeline.
*   **Adaptive Calibration:** The system monitors session completion and recall rates, dynamically calibrating the length and difficulty of upcoming daily goals.
*   **Pace Projection:** Simulates future progress based on historical performance to project completion dates.

### 2. The Session (Accountability & Focus)
*   **Distraction-Free Reading:** A dedicated digital session mode where navigation bars disappear, leaving only the pristine Madani page layout.
*   **Timer & Repetition Counters:** Built-in tools track active focus time and verse repetitions.
*   **Self-Assessment Overlays:** Prompts users to rate their recall after each page, feeding metrics back into the scheduling engine.
*   **Synchronized Recitation:** Gapless audio playback synced to verse-level highlighting (supports 40+ reciters).

### 3. The Understanding (Comprehension Layer)
*   **Context-Aware Content:** Single-tap access to translations, brief or detailed Tafsir, and historical reasons of revelation (Asbab al-Nuzul) without breaking the reading flow.
*   **Surah Introductions:** Hand-curated structural outlines and key themes for surahs to establish context before reading.

---

## ⚡ Practice & Retention Tools

*   **SRS Flashcards:** Six distinct flashcard types powered by the SM-2 Spaced Repetition Algorithm (e.g., *Complete the Verse*, *Identify Surah*, *Spot the Difference*).
*   **Mutashabihat Practice:** A dedicated training module featuring three practice modes to master similar or easily-confused verses across the Quran.
*   **Weekly Snapshot Analytics:** Comprehensive visual reports tracking focus time, review consistency, and retention performance.

---

## 🛠️ Architecture & Tech Stack

*   **Core Framework:** [Flutter](https://flutter.dev) for cross-platform rendering (Windows, Android, iOS, macOS, Linux, Web).
*   **Database:** SQLite (`sqflite` / `sqlite3`) serving as the offline-first local source of truth.
*   **Cloud Synchronization:** Optional Firebase Authentication and Firestore backend supporting fire-and-forget background synchronization.
*   **Ecosystem Integration:** Secure OAuth2 authorization code flow with PKCE to sync bookmarks and reading sessions back to user profiles.
*   **Audio Engine:** Gapless chapter-level MP3 playback using native SChannel/OS media bridges.

---

## 🚀 Getting Started

### Prerequisites
Ensure you have the Flutter SDK installed and configured on your system.

### Build and Run
1. Clone the repository and navigate to the project directory:
   ```bash
   git clone https://github.com/khalidouhdane/jawhar.git
   cd jawhar
   ```
2. Retrieve dependencies:
   ```bash
   flutter pub get
   ```
3. Run the development build (e.g., on Windows desktop):
   ```bash
   flutter run -d windows
   ```

---

## 🛡️ License & Philosophy

*   **Free & Open:** Ad-free, tracking-free, and open to the community.
*   **License:** Distributed under the MIT License. See `LICENSE` for details.
