# Phase 3 — Schema Request: Asbab al-Nuzul Table

> **From:** Agent 1 (Context-Aware Content)
> **To:** Core Engine Agent
> **Priority:** Low — not blocking. Phase 3 currently uses file-based + in-memory caching.

## Requested Table: `asbab_nuzul`

When the Core Engine agent is ready to add this to `hifz_database_service.dart`, here is the proposed schema:

```sql
CREATE TABLE IF NOT EXISTS asbab_nuzul (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  surah INTEGER NOT NULL,
  ayah INTEGER NOT NULL,
  occasion_text TEXT NOT NULL,
  occasion_index INTEGER NOT NULL DEFAULT 0,
  imported_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(surah, ayah, occasion_index)
);

CREATE INDEX IF NOT EXISTS idx_asbab_surah_ayah ON asbab_nuzul(surah, ayah);
```

## Fields

| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER PK | Auto-increment primary key |
| `surah` | INTEGER | Surah number (1-114) |
| `ayah` | INTEGER | Ayah number within the surah |
| `occasion_text` | TEXT | The Arabic narration text |
| `occasion_index` | INTEGER | 0-based index when multiple narrations exist for the same verse |
| `imported_at` | TEXT | Timestamp of import |

## Usage Pattern

- Lookup: `SELECT * FROM asbab_nuzul WHERE surah = ? AND ayah = ?`
- Bulk import: Batch INSERT from the GitHub JSON dataset
- One-time import flag: `SELECT COUNT(*) FROM asbab_nuzul` > 0

## Current Workaround

`AsbabNuzulService` downloads `all.json` from GitHub, saves it as a local file in the app documents directory, and builds an in-memory `Map<String, AsbabNuzulEntry>` for O(1) lookups. This works but doesn't persist across cache clears and requires re-download if the file is deleted.
