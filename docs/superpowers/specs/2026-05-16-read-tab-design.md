# Read Tab UX Design Spec

## Goal
Transform the Read Tab from a simple directory index into a personalized reading and listening hub. This centralizes the user's active context (resume reading, daily goal tracking, active audio) while maintaining the exploration functionality (Surah/Juz/Hizb lists).

## User Flows & Core Features
- **Resume Reading:** Users can instantly jump back to their last read page via a prominent `ContinueReadingCard`.
- **Werd Tracking:** Users can see their daily page goal progress seamlessly within the read tab via the `WerdCard`.
- **Audio Quick Access:** Users can change their active reciter via a shortcut in the header, bypassing the need to enter a Surah first.
- **Exploration:** Users can search and browse the full Quran index.

## Architecture & Components

### 1. `ReadIndexScreen` Layout Redesign
The screen will be stacked using the Geist Design System aesthetic:

*   **Header Row:**
    *   Left: "Read" (H1, bold)
    *   Right: A small pill button (using `GeistButton.ghost` or custom pill) showing an audio icon + the active reciter's first name (e.g., "Mishary"). Tapping this triggers `_openReciterMenu()`.
*   **Personalized Hub (New Section):**
    *   `ContinueReadingCard`: A full-width widget placed immediately below the header.
    *   `WerdCard`: The existing `WerdCard`, moved from the Dashboard layout.
*   **Index Section (Existing):**
    *   Search Bar
    *   `TabBar` (Surah | Juz | Hizb)
    *   `TabBarView` with lists

### 2. New Component: `ContinueReadingCard`
**Path:** `lib/widgets/read/continue_reading_card.dart`
*   **Data Source:** Reads `lastReadPage` and `lastReadSurahName` from `LocalStorageService`. (Requires adding `LocalStorageService` to the widget or using a provider if applicable, though currently `LocalStorageService` is primarily accessed directly).
*   **Visuals:**
    *   Background: Dark, premium surface (e.g., `theme.cardColor` with a subtle gradient or border).
    *   Top Label: "Continue Reading" (12px, `theme.mutedText`).
    *   Title: Surah Name in English/Arabic + "• Page X" (18px, bold, `theme.primaryText`).
    *   Action: A `GeistButton` labeled "Resume" aligned to the right or bottom.
*   **Behavior:** Tapping the card or "Resume" pushes the `ReadingScreen` initialized at the saved page.

### 3. Cleanup & Deprecation
*   The `AudioScreen` (tab index 2) will be decoupled from the bottom navigation. The Read tab will completely assume the "hub" role for both reading and listening.
*   `AppShell`: Remove the `AudioScreen` from the `IndexedStack` to clear the way for the new "Understand" tab implementation.

## Data Flow & State Management
*   **Reciter State:** Read from `AudioProvider` (for the header shortcut).
*   **Werd State:** Read from `WerdProvider` (via `WerdCard`).
*   **Reading Position:** Read from `LocalStorageService`. If no last position exists (e.g., first launch), the `ContinueReadingCard` gracefully hides or shows a "Start Reading: Al-Fatihah" fallback.

## Verification
*   Verify the `WerdCard` updates correctly when navigating between the Reading Canvas and the Read Index.
*   Ensure the `ContinueReadingCard` updates its displayed page immediately after returning from the `ReadingScreen`.
*   Verify that `ReciterMenuSheet` opens correctly from the header shortcut.
