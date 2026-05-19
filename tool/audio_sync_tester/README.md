# Jawhar Audio Sync Calibrator

A development tool for diagnosing and micro-adjusting audio-to-verse boundary offsets live in the browser.

## How to Run

1. Open a terminal in the root directory.
2. Run the local diagnostic server:
   ```bash
   python tool/audio_sync_tester/server.py
   ```
3. The server will:
   - Read credentials from your `.env` file.
   - Fetch and cache the required OAuth access token.
   - Start a local HTTP server on port `8080`.
   - Open the diagnostic web dashboard (`http://localhost:8080`) directly in your default browser.

## Verification Checklist

### 1. Baseline Synchronization (Mishary Alafasy)
- Select **Mishary Rashid Alafasy (7)** and **Al-Fatihah (1)**.
- Press Play.
- Verify that as you hear each verse, the visual green highlight accurately shifts to the next verse.
- Since Mishary's files are properly encoded (with Xing headers and LAME tags), they should align exactly with zero manual offsets.

### 2. Drifting Synchronization (Yasser al-Dosari)
- Select **Yasser al-Dosari (174)** and **Al-Baqarah (2)**.
- Observe that the audio lacks a Bismillah reciting at the start, causing the timing API timestamps (which assume a Bismillah is present) to drift by ~3000ms.
- Click the **✨ Auto-Detect Bismillah Gap** button. It will identify the initial gap and set a global offset (e.g. `-3080ms`).
- Press Play and verify that the green highlight now accurately syncs with the recitation.
- If minor adjustments are still needed, use the global offset input or individual verse offset buttons (`+100ms`, `-100ms`, etc.) to micro-adjust.
- Export the final adjustments as JSON.
