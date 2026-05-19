# Quran Foundation Hackathon 2026 Submission

**Team Member**: Khalid Ouhdane  
**Project Title**: Jawhar — Memorize with Meaning  

---

## Short Description
Jawhar is the first Hifz companion that shifts the focus from rote memorization to profound comprehension. By combining AI-generated daily plans, structured digital sessions, and seamlessly integrated contextual resources (translations, tafsir, Asbab al-Nuzul), Jawhar ensures that every verse memorized is a verse understood.

---

## Detailed Explanation
Millions reconnect with the Quran during Ramadan, but many struggle to maintain that connection, especially when attempting to memorize without understanding. Memorization without comprehension is inherently fragile.

Jawhar solves this by building a customized path to mastery centered on three core pillars:
1. **The Plan**: Adaptive daily plans (Sabaq, Sabqi, and Manzil) powered by AI that dynamically adjust to the user's pace and historical performance, complete with pace projections and analytics.
2. **The Session**: A highly structured digital reading mode that acts as an accountability partner, featuring timers, repetition tracking, and self-assessment overlays.
3. **The Understanding**: Deep integration with the Quran Foundation API to deliver context precisely when it's needed—offering instant access to brief and detailed Tafsir, Asbab al-Nuzul (reasons of revelation), and Surah introductions without breaking the reading flow.

With Jawhar, the app disappears, and the Quran appears.

---

## Live Demo & GitHub
- **Live Website Demo**: [https://website-lilac-phi-50.vercel.app/hackathon](https://website-lilac-phi-50.vercel.app/hackathon)
- **Web App Demo**: [https://quran-app-e5e86.web.app/](https://quran-app-e5e86.web.app/)
- **GitHub Repository**: [https://github.com/khalidouhdane/jawhar](https://github.com/khalidouhdane/jawhar)

---

## API Usage Description
Jawhar deeply integrates both the **Content API** and the **User API** to power its core features, aligning seamlessly with the hackathon's requirement for robust ecosystem integration.

**1. Content API Integration (Core Content & Understanding):**
*   **Audio (V4):** We utilize the chapter-level audio endpoints with `?segments=true`. This allows Jawhar's custom audio engine to play gapless recitation while seeking to precise verse timestamps to power the UI's real-time verse highlighting.
*   **Translations & Tafsir (V4):** Jawhar fetches localized translations and tafsir using the `/verses/by_key/{key}?translations={id}` and `?tafsirs={id}` endpoints. This data powers the "Understand" beat of the app, dynamically rendering Brief or Detailed tafsir in the bottom sheet overlays based on the user's selected language.
*   **Page Layout & Font:** We leverage the API's Madani page layout data to accurately render all 604 pages of the Mushaf, allowing for a pixel-perfect, page-by-page digital reading experience.

**2. User API Integration (OAuth2 PKCE & Sync):**
*   **Bookmarks & Collections:** We use the OAuth2 PKCE flow to authenticate the user and sync their bookmarks and custom verse collections back to Quran.com.
*   **Reading Sessions & Activity:** Jawhar's offline-first SQLite database tracks session history, and subsequently syncs reading sessions and activity days to the User API, ensuring the user's streak and reading progress on Jawhar reflect on their main Quran.com profile.

---

## 2-3 Minute Demo Video Script

**Title**: Jawhar — Memorize with Meaning

**[0:00 - 0:15] Intro & The Problem**
*   **Visual**: Screen recording starts on the sleek, dark-themed Jawhar dashboard (Home Screen).
*   **Voiceover**: "Welcome to Jawhar. For too many, memorizing the Quran relies on rote repetition without comprehension. Jawhar changes this by ensuring you memorize with meaning."

**[0:15 - 0:45] The Plan (Adaptive Intelligence)**
*   **Visual**: Click on the 'Generate Plan' card. Show the AI creating today's Sabaq, Sabqi, and Manzil. Scroll through the Weekly Analytics and Pace Projection graphs.
*   **Voiceover**: "It starts with your personal plan. Jawhar’s intelligence adapts to your progress, generating daily goals for new memorization and revision, while predicting when you'll reach your ultimate milestones."

**[0:45 - 1:20] The Session (Read & Listen)**
*   **Visual**: Start a session. Transition to the Digital Session Mode. Show the page layout, start the audio playback, and highlight the verses syncing with the audio. 
*   **Voiceover**: "During a session, Jawhar becomes your accountability partner. The distraction-free digital mode tracks your repetitions and time. Our gapless audio engine, powered by the Quran Foundation API, syncs recitation perfectly with the text."

**[1:20 - 1:55] The Understanding (Content API)**
*   **Visual**: Tap on a specific verse to open the Context Menu. Swipe up the Tafsir Bottom Sheet. Toggle between 'Brief' and 'Detailed' Tafsir, and check the 'Occasion of Revelation' (Asbab al-Nuzul).
*   **Voiceover**: "But memorization is nothing without understanding. Tapping any verse instantly fetches translations, detailed Tafsir, and reasons of revelation directly from the Quran Foundation Content API, keeping you in the flow of learning."

**[1:55 - 2:20] The Sync (User API)**
*   **Visual**: Add a bookmark to a verse. Navigate to the Profile screen and tap 'Sync to Quran.com'. Show a brief snippet of code or terminal logs indicating the PKCE OAuth flow.
*   **Voiceover**: "And because your journey shouldn't be locked into one app, Jawhar uses the User API to sync your bookmarks, reading sessions, and streaks directly back to your Quran.com profile securely using OAuth2."

**[2:20 - 2:30] Outro**
*   **Visual**: Return to the Jawhar Landing Page/Website. 
*   **Voiceover**: "Jawhar: Encode the Essence. Memorize with Meaning. Thank you for watching."
