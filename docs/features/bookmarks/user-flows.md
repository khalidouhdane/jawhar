# 🔖 Bookmarks — User Flows

> **Files:** `nav_menu_sheet.dart`, `reading_canvas.dart`, `bottom_dock.dart`, `home_screen.dart`, `profile_screen.dart`

---

## Current State (What Exists)

### Flow 1: Bookmark a Surah from Nav Menu

```
User opens Reading Screen
  → Taps Nav icon (bottom dock) → NavMenuSheet opens
    → Surah tab shows all 114 surahs with bookmark icon
    → User taps 🔖 icon next to any surah
      → Bookmark toggles on/off (in-memory only, static Map)
      → Surah appears in Bookmarks tab
```

**Current limitation**: Bookmarks are stored in a `static Map<int, String>` inside `_NavMenuSheetState`. They are **in-memory only** — lost on app restart.

### Flow 2: View Bookmarks List

```
User opens NavMenuSheet → taps "Bookmarks" tab
  → If empty: shows empty state (bookmark icon + "No bookmarks yet" + hint text)
  → If populated: shows sorted list of bookmarked surahs
    → Each entry shows: bookmark icon + surah name + page number
    → Tap entry → navigates to that page
    → Tap trash icon → removes bookmark
```

### Flow 3: Contextual Menu Bookmark (Stub)

```
User long-presses a verse in ReadingCanvas
  → Contextual menu appears with icons: Play, Copy, Bookmark, Share, Tafsir
  → Bookmark icon exists but onTap is EMPTY (no-op)
```

### Flow 4: UI Touchpoints (No Logic)

```
Home Screen → Quick Access section has a "Bookmarks" tile (navigates nowhere specific)
Bottom Dock → Bookmark icon exists (no-op)
Profile Screen → "Your Bookmarks" section exists (no-op, just UI placeholder)
```

---

## Planned Flows

### Flow A: Bookmark a Verse (from Reading)

```
User long-presses a verse → contextual menu appears
  → Taps 🔖 Bookmark icon
    → Verse is bookmarked (persisted to SharedPreferences)
    → Brief feedback (icon fills / subtle animation)
    → Verse key + page + surah name + timestamp stored
  
User long-presses a BOOKMARKED verse → menu appears
  → Bookmark icon is FILLED
  → Tapping it removes the bookmark
```

### Flow B: Bookmark Current Page (from Bottom Dock)

```
User is on any page → taps bookmark icon in bottom dock
  → Current page is bookmarked (page-level bookmark)
  → Icon toggles to filled state
  → Tapping again removes bookmark
```

### Flow C: Browse & Manage Bookmarks (Nav Menu)

```
User opens NavMenuSheet → Bookmarks tab
  → Shows all bookmarks, grouped or flat:
    - Verse bookmarks: show verse key + surah name + verse text preview
    - Page bookmarks: show page number + surah name
  → Tap any bookmark → navigates to that page (and optionally highlights verse)
  → Swipe to delete or tap trash icon → removes bookmark
  → Search/filter bookmarks (future)
```

### Flow D: Bookmarks from Home Screen

```
User taps "Bookmarks" quick-access tile on Home Screen
  → Opens a dedicated bookmarks view or the NavMenuSheet's Bookmarks tab
  → Shows all bookmarks across the app
```

### Flow E: Bookmarks from Profile Screen

```
User navigates to Profile → taps "Your Bookmarks"
  → Opens dedicated bookmarks management view
  → Can see, organize, and delete bookmarks
```

### Flow F: Bookmark Categories/Folders (Future)

```
User creates a named collection (e.g., "Favorite Duas", "Weekly Hifz Review")
  → When bookmarking a verse, can choose which collection to add it to
  → Collections viewable from Bookmarks tab, Home, or Profile
```
