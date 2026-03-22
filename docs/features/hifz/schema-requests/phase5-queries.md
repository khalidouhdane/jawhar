# Phase 5 — Schema Requests (Adaptive Intelligence)

> **Status:** No schema changes needed. All queries are read-only against existing tables.

## Queries Needed

### 1. Sessions in Date Range
```sql
SELECT * FROM session_history 
WHERE profileId = ? AND date >= ? AND date < ?
ORDER BY date ASC
```
Used for: weekly/monthly analysis snapshots.

### 2. Daily Plans in Date Range
```sql
SELECT * FROM daily_plans 
WHERE profileId = ? AND date >= ? AND date < ?
ORDER BY date ASC
```
Used for: completion rate (planned vs completed).

### 3. Pages Not Reviewed in N Days
```sql
SELECT pageNumber FROM page_progress 
WHERE profileId = ? AND status IN (2, 3) -- reviewing, memorized
AND (lastReviewedAt IS NULL OR lastReviewedAt < ?)
ORDER BY lastReviewedAt ASC
```
Used for: "neglected juz" smart notifications.

### 4. Assessment Distribution
```sql
SELECT sabaqAssessment, COUNT(*) as count FROM session_history 
WHERE profileId = ? AND date >= ?
GROUP BY sabaqAssessment
```
(Same pattern for sabqiAssessment, manzilAssessment.)
Used for: adaptive calibration suggestions.

### 5. Pages Memorized in Date Range
```sql
SELECT COUNT(*) FROM page_progress 
WHERE profileId = ? AND memorizedAt >= ? AND memorizedAt < ?
```
Used for: pace calculation & report metrics.
