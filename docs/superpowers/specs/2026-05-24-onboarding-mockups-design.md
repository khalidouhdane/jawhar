# Onboarding Screenshots Design

We will replace the current programmatic/generic drawn phone mock-ups in the onboarding showcase slides with real high-fidelity app screenshots. These screenshots are already used on the landing page of the Quran App. To fit two mock-ups per onboarding section on limited mobile screen real estate, we will implement an interactive depth-swapping card layout.

## Proposed Changes

### Assets and Configuration
1. **Copy Screenshot Assets:** Copy the required screenshots from the landing page directory (`website/public/images/screenshots/`) to the Flutter project's assets directory (`assets/images/screenshots/`):
   * `mushaf_audio_playing.png` (Read foreground)
   * `read_index_home.png` (Read background)
   * `tafsir_sheet_brief.png` (Understand foreground)
   * `understand_index_home.png` (Understand background)
   * `hifz_dashboard_today_plan.png` (Memorize foreground)
   * `practice_home_flashcards.png` (Memorize background)
2. **Update `pubspec.yaml`:** Declare the new screenshot asset folder so the Flutter app can load the images:
   ```yaml
   flutter:
     assets:
       - assets/images/screenshots/
   ```

### UI Implementation (`lib/screens/showcase_screen.dart`)
1. **Remove Old Programmatic Layouts:** Remove the old simulated phone screen widgets (`_ReadPhoneContent`, `_UnderstandPhoneContent`, `_MemorizePhoneContent`, and the simplified `_PhoneFrame`).
2. **Create a `ScreenshotMockupStack` Widget:**
   * Receives two image paths (`foregroundPath` and `backgroundPath`).
   * Uses a `StatefulWidget` to track which card is currently in the foreground (a boolean `isSwapped`).
   * Displays the two screenshots using an overlapping stacked layout (`Stack` with `AnimatedPositioned`, `AnimatedScale`, and `AnimatedOpacity`).
   * When tapped, toggles the state, causing the background card to animate smoothly to the front and the foreground card to slide to the back.
   * Both screenshots will have premium styling: rounded corners (`BorderRadius.circular(16)`), a subtle border (`Border.all(color: Colors.white12, width: 1.5)`), and a soft shadow.

## Verification Plan

### Automated/Manual Testing
* Verify that the app builds correctly after adding assets.
* Manually inspect the onboarding showcase on different screen sizes to ensure the screenshots fit perfectly and scale responsively without overflow.
* Verify that tapping the screenshots triggers a smooth depth-swap animation.
