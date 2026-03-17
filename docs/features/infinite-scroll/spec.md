# 📜 Infinite Scroll — Feature Spec

> **Status:** Planned (Phase 3)
> **Origin:** Previously prototyped in a React web app (now deleted)

---

## Overview

Add a second reading mode — **infinite scroll** — alongside the existing page-by-page `PageView`. The currently-read ayah is center-locked with a smooth highlight. Switching modes lives in a new **Appearance Settings** sheet.

---

## Core UX Requirements

### 1. Reading Mode State
- `readingMode` setting (persisted via `LocalStorageService`): `'page'` (default) or `'scroll'`
- `page` mode: existing `PageView`-based `ReadingCanvas`
- `scroll` mode: `ScrollableReadingCanvas` renders all ayahs vertically

### 2. Infinite Scroll Canvas
- **Container**: Vertically scrollable widget filling the reading area
- **Content**: All ayahs rendered sequentially (not paginated by mushaf page)
- **Active ayah highlight**: Semi-transparent background band with ~400ms animated color transition
- **Center-lock behavior**:
  1. On mount, highlight starts at the top (ayah 1)
  2. As user scrolls, active ayah = nearest to viewport center
  3. Use `ScrollController.animateTo()` for smooth centering
  4. At extremes (first/last ayahs), scroll stops naturally — **no artificial padding**
- **Scroll detection**: `ScrollController` + `GlobalKey`/`RenderBox` offset measurement — **NOT `ScrollSnapPhysics`** (causes janky snapping)
- All scrolling: `Curves.easeInOut`, pure smooth animations

### 3. Appearance Settings Sheet
Triggered from Settings icon in `top_nav_bar.dart`. Same bottom sheet pattern as existing sheets.

| Setting | Scope | Details |
|---------|-------|---------|
| Reading Mode toggle | Both | Segmented: `Page-by-Page` / `Infinite Scroll` |
| Font Size slider | Both | Dynamic control |
| Line Height slider | Both | Dynamic control |
| Page Turn Animation | Page only | Toggle — hidden in scroll mode |
| Show Page Numbers | Page only | Toggle — hidden in scroll mode |
| Auto-scroll Speed | Scroll only | Slider — hidden in page mode |
| Center Lock | Scroll only | Toggle — hidden in page mode |

Mode-specific settings animate with `AnimatedSize`/`AnimatedCrossFade`.

### 4. Bottom Dock Adaptation

| Element | Page Mode | Scroll Mode |
|---------|-----------|-------------|
| Pagination slider | ✅ | ❌ |
| List (index) button | ✅ | ✅ |
| Bookmark button | ✅ | ✅ |
| Surah / Juz label | ✅ | ✅ (dynamic) |
| Scroll progress bar | ❌ | ✅ (new) |

### 5. Audio Integration
- User scrolls → updates active ayah → audio seeks (optional)
- Audio advances → updates active ayah → scroll canvas centers on it
- `AudioProvider` notifies reading screen when active verse changes

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `lib/widgets/scrollable_reading_canvas.dart` | **NEW** |
| `lib/widgets/sheets/appearance_settings_sheet.dart` | **NEW** |
| `lib/screens/reading_screen.dart` | **MODIFY** — mode toggle |
| `lib/widgets/bottom_dock.dart` | **MODIFY** — adapt layout |
| `lib/widgets/top_nav_bar.dart` | **MODIFY** — wire settings icon |
| `lib/providers/theme_provider.dart` | **MODIFY** — add `readingMode`, `fontSize`, `lineHeight` |
| `lib/services/local_storage_service.dart` | **MODIFY** — add new keys |

---

## Critical Rules
- **No `ScrollSnapPhysics`** — causes glitching
- **Persist all settings** via `LocalStorageService`
- **Windows-safe** — wrap large `RichText` in `ExcludeSemantics()`
