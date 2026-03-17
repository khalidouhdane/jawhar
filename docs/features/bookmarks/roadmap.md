# 🔖 Bookmarks — Feature Roadmap

> **Status:** Phase 3 Complete
> **Files:** `bookmark_model.dart`, `bookmark_collection.dart`, `bookmark_provider.dart`, `local_storage_service.dart`, `nav_menu_sheet.dart`, `bookmark_edit_sheet.dart`, `reading_canvas.dart`, `top_nav_bar.dart`, `home_screen.dart`, `profile_screen.dart`, `reading_screen.dart`

---

## ✅ Completed (UI Only)

- [x] Bookmark icon in surah list (NavMenuSheet) — toggles in-memory
- [x] Bookmarks tab in NavMenuSheet — lists bookmarked surahs
- [x] Empty state for bookmarks tab
- [x] Bookmark icon in contextual menu (long-press verse) — **stub, no logic**
- [x] Bookmark icon in bottom dock — **stub, no logic**
- [x] "Bookmarks" quick-access tile on Home Screen — **no navigation target**
- [x] "Your Bookmarks" section on Profile Screen — **no logic**

---

## ✅ Phase 1: Persistence & Core Logic (COMPLETE)

> **Goal**: Make existing bookmarks actually persist and work everywhere.

- [x] **`BookmarkProvider`** — `ChangeNotifier` managing all bookmark state
- [x] **`Bookmark` data model** — `lib/models/bookmark_model.dart`
- [x] **Wire NavMenuSheet** — replaced `static Map` with `BookmarkProvider`
- [x] **Wire contextual menu** — bookmark icon saves/removes verse bookmarks
- [x] **Wire top nav bar** — bookmark icon saves/removes page bookmark, icon fills when bookmarked
- [x] **Persistence** — `LocalStorageService` stores/loads bookmarks JSON

---

## ✅ Phase 2: Bookmarks Across the App (COMPLETE)

> **Goal**: Bookmarks accessible from every entry point.

- [x] **Home Screen** — "Bookmarks" tile shows count badge + navigates to most recent bookmark
- [x] **Profile Screen** — "Your Bookmarks" shows count + navigates to most recent bookmark
- [x] **Profile stats card** — bookmark count added as fourth stat column
- [x] **Visual feedback** — SnackBar appears when bookmarking/unbookmarking from top nav
- [x] **NavMenuSheet** — verse/page bookmarks shown with delete and tap-to-navigate

---

## ✅ Phase 2.5: UX Refinements (COMPLETE)

> **Goal**: Separate page and verse bookmark flows with better navigation.

- [x] **Pages/Verses segmented switcher** — in NavMenuSheet bookmarks tab
- [x] **Home/Profile open NavMenuSheet** — directly to bookmarks tab
- [x] **Verse highlight** — flash-highlights bookmarked verse for 2s on navigation

---

## ✅ Phase 3: Organization & Collections (COMPLETE)

> **Goal**: Let users organize bookmarks into meaningful groups.

- [x] **Collections/folders** — user-created groups with create/rename/delete
- [x] **Collection filtering** — horizontal chip strip to filter bookmarks by collection
- [x] **Notes on bookmarks** — add a personal note to any bookmark
- [x] **Color-coded bookmarks** — 6-color palette with visual dot indicator
- [x] **Bookmark edit sheet** — full edit UI (color, note, collection, delete)
- [x] **Export/share bookmarks** — formatted text export via `share_plus`

---

## Technical Notes

### Current Implementation
- `BookmarkProvider` as a `ChangeNotifier` in `main.dart`'s `MultiProvider`
- `Bookmark` model with `collectionId`, `note`, `colorIndex` fields
- `BookmarkCollection` model for user-created groups
- JSON persistence via `LocalStorageService` (keys: `bookmarks`, `bookmark_collections`)
- Both verse-level and page-level bookmarks supported
- Full-featured edit sheet with color picker, note field, collection assignment
- Export via `share_plus` package
