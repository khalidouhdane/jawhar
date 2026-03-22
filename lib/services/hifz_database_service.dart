import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/models/flashcard_models.dart';

/// Central SQLite database service for the Hifz program.
/// Manages profiles, page progress, session history, daily plans,
/// flashcards, and mutashabihat groups.
class HifzDatabaseService {
  static const _dbName = 'hifz_data.db';
  static const _dbVersion = 3;

  Database? _db;

  /// Get or initialize the database.
  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── Profiles table ──
    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        avatarIndex INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        ageGroup INTEGER DEFAULT 2,
        encodingSpeed INTEGER DEFAULT 1,
        retentionStrength INTEGER DEFAULT 1,
        learningPreference INTEGER DEFAULT 0,
        dailyTimeMinutes INTEGER DEFAULT 30,
        preferredTimeOfDay INTEGER DEFAULT 0,
        goal INTEGER DEFAULT 0,
        goalDetails TEXT DEFAULT '',
        defaultReciterId INTEGER DEFAULT 7,
        defaultReciterSource INTEGER DEFAULT 0,
        startingPage INTEGER DEFAULT 582,
        startDate TEXT NOT NULL,
        isActive INTEGER DEFAULT 0
      )
    ''');

    // ── Page progress table ──
    await db.execute('''
      CREATE TABLE page_progress (
        pageNumber INTEGER NOT NULL,
        profileId TEXT NOT NULL,
        status INTEGER DEFAULT 0,
        lastReviewedAt TEXT,
        reviewCount INTEGER DEFAULT 0,
        memorizedAt TEXT,
        lastVerseLearned INTEGER,
        totalVersesOnPage INTEGER,
        PRIMARY KEY (pageNumber, profileId),
        FOREIGN KEY (profileId) REFERENCES profiles(id) ON DELETE CASCADE
      )
    ''');

    // ── Session history table ──
    await db.execute('''
      CREATE TABLE session_history (
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        date TEXT NOT NULL,
        durationMinutes INTEGER DEFAULT 0,
        sabaqCompleted INTEGER DEFAULT 0,
        sabqiCompleted INTEGER DEFAULT 0,
        manzilCompleted INTEGER DEFAULT 0,
        sabaqAssessment INTEGER,
        sabqiAssessment INTEGER,
        manzilAssessment INTEGER,
        sabaqPage INTEGER,
        sabqiPages TEXT DEFAULT '',
        manzilPages TEXT DEFAULT '',
        repCount INTEGER DEFAULT 0,
        FOREIGN KEY (profileId) REFERENCES profiles(id) ON DELETE CASCADE
      )
    ''');

    // ── Daily plans table ──
    await db.execute('''
      CREATE TABLE daily_plans (
        id TEXT PRIMARY KEY,
        profileId TEXT NOT NULL,
        date TEXT NOT NULL,
        sabaqPage INTEGER NOT NULL,
        sabaqLineStart INTEGER DEFAULT 1,
        sabaqLineEnd INTEGER DEFAULT 15,
        sabaqTargetMinutes INTEGER DEFAULT 25,
        sabaqRepetitionTarget INTEGER DEFAULT 10,
        sabqiPages TEXT DEFAULT '',
        sabqiTargetMinutes INTEGER DEFAULT 15,
        manzilJuz INTEGER DEFAULT 30,
        manzilPages TEXT DEFAULT '',
        manzilRotationDay INTEGER DEFAULT 1,
        manzilTargetMinutes INTEGER DEFAULT 15,
        sabaqDoneOffline INTEGER DEFAULT 0,
        sabqiDoneOffline INTEGER DEFAULT 0,
        manzilDoneOffline INTEGER DEFAULT 0,
        isCompleted INTEGER DEFAULT 0,
        sabaqStartVerse INTEGER,
        FOREIGN KEY (profileId) REFERENCES profiles(id) ON DELETE CASCADE
      )
    ''');

    // ── Streak tracking table ──
    await db.execute('''
      CREATE TABLE streak_data (
        profileId TEXT PRIMARY KEY,
        totalActiveDays INTEGER DEFAULT 0,
        lastActiveDate TEXT,
        FOREIGN KEY (profileId) REFERENCES profiles(id) ON DELETE CASCADE
      )
    ''');

    // ── Manzil rotation table ──
    await db.execute('''
      CREATE TABLE manzil_rotation (
        profileId TEXT NOT NULL,
        juzNumber INTEGER NOT NULL,
        isInRotation INTEGER DEFAULT 1,
        currentDay INTEGER DEFAULT 0,
        PRIMARY KEY (profileId, juzNumber),
        FOREIGN KEY (profileId) REFERENCES profiles(id) ON DELETE CASCADE
      )
    ''');

    // ── Phase 2: Flashcards table ──
    await _createFlashcardTables(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createFlashcardTables(db);
    }
    if (oldVersion < 3) {
      // CE-9: Add verse-level tracking columns
      await db.execute('ALTER TABLE page_progress ADD COLUMN lastVerseLearned INTEGER');
      await db.execute('ALTER TABLE page_progress ADD COLUMN totalVersesOnPage INTEGER');
      await db.execute('ALTER TABLE daily_plans ADD COLUMN sabaqStartVerse INTEGER');
    }
  }

  Future<void> _createFlashcardTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS flashcards (
        id TEXT PRIMARY KEY,
        type INTEGER NOT NULL,
        profile_id TEXT NOT NULL,
        verse_key TEXT NOT NULL,
        question_data TEXT DEFAULT '{}',
        answer_data TEXT DEFAULT '{}',
        interval REAL DEFAULT 1.0,
        ease_factor REAL DEFAULT 2.5,
        due_date TEXT NOT NULL,
        last_reviewed_at TEXT,
        review_count INTEGER DEFAULT 0,
        FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS flashcard_reviews (
        id TEXT PRIMARY KEY,
        card_id TEXT NOT NULL,
        rating INTEGER NOT NULL,
        reviewed_at TEXT NOT NULL,
        FOREIGN KEY (card_id) REFERENCES flashcards(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS mutashabihat_groups (
        group_id TEXT PRIMARY KEY,
        source_verse_key TEXT NOT NULL,
        source_text TEXT DEFAULT '',
        similar_verses TEXT DEFAULT '[]',
        unique_words TEXT DEFAULT '{}',
        category INTEGER DEFAULT 0,
        difficulty TEXT DEFAULT 'medium',
        needs_context INTEGER DEFAULT 0,
        user_status INTEGER DEFAULT 0
      )
    ''');
  }

  // ════════════════════════════════════════════
  // PROFILE OPERATIONS
  // ════════════════════════════════════════════

  /// Create a new profile. Deactivates other profiles first.
  Future<void> createProfile(MemoryProfile profile) async {
    final db = await database;
    // Deactivate all other profiles
    await db.update('profiles', {'isActive': 0});
    await db.insert('profiles', profile.toMap());
    // Initialize streak data
    await db.insert('streak_data', {
      'profileId': profile.id,
      'totalActiveDays': 0,
      'lastActiveDate': null,
    });
  }

  /// Get the currently active profile, or null if none.
  Future<MemoryProfile?> getActiveProfile() async {
    final db = await database;
    final results = await db.query(
      'profiles',
      where: 'isActive = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return MemoryProfile.fromMap(results.first);
  }

  /// Get all profiles.
  Future<List<MemoryProfile>> getAllProfiles() async {
    final db = await database;
    final results = await db.query('profiles', orderBy: 'createdAt DESC');
    return results.map(MemoryProfile.fromMap).toList();
  }

  /// Switch to a different profile.
  Future<void> switchProfile(String profileId) async {
    final db = await database;
    await db.update('profiles', {'isActive': 0});
    await db.update(
      'profiles',
      {'isActive': 1},
      where: 'id = ?',
      whereArgs: [profileId],
    );
  }

  /// Update a profile.
  Future<void> updateProfile(MemoryProfile profile) async {
    final db = await database;
    await db.update(
      'profiles',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  /// Delete a profile and all associated data (cascade).
  Future<void> deleteProfile(String profileId) async {
    await resetProgress(profileId);
    final db = await database;
    await db.delete('profiles', where: 'id = ?', whereArgs: [profileId]);
    await db.delete('streak_data', where: 'profileId = ?', whereArgs: [profileId]);
    await db.delete('manzil_rotation', where: 'profileId = ?', whereArgs: [profileId]);
  }

  // ════════════════════════════════════════════
  // PAGE PROGRESS
  // ════════════════════════════════════════════

  /// Save or update a page's progress.
  Future<void> savePageProgress(PageProgress progress) async {
    final db = await database;
    await db.insert(
      'page_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get progress for all pages of a profile.
  Future<Map<int, PageProgress>> getAllPageProgress(String profileId) async {
    final db = await database;
    final results = await db.query(
      'page_progress',
      where: 'profileId = ?',
      whereArgs: [profileId],
    );
    final map = <int, PageProgress>{};
    for (final row in results) {
      final p = PageProgress.fromMap(row);
      map[p.pageNumber] = p;
    }
    return map;
  }

  /// Get progress for pages in a specific juz (by page range).
  Future<List<PageProgress>> getProgressForJuz(
    String profileId,
    int juzStartPage,
    int juzEndPage,
  ) async {
    final db = await database;
    final results = await db.query(
      'page_progress',
      where: 'profileId = ? AND pageNumber >= ? AND pageNumber <= ?',
      whereArgs: [profileId, juzStartPage, juzEndPage],
    );
    return results.map(PageProgress.fromMap).toList();
  }

  /// Count pages by status for a profile.
  Future<Map<PageStatus, int>> getPageStatusCounts(String profileId) async {
    final db = await database;
    final results = await db.rawQuery(
      'SELECT status, COUNT(*) as count FROM page_progress WHERE profileId = ? GROUP BY status',
      [profileId],
    );
    final counts = <PageStatus, int>{};
    for (final row in results) {
      final status = PageStatus.values[row['status'] as int];
      counts[status] = row['count'] as int;
    }
    return counts;
  }

  // ════════════════════════════════════════════
  // DAILY PLANS
  // ════════════════════════════════════════════

  /// Save a daily plan.
  Future<void> saveDailyPlan(DailyPlan plan) async {
    final db = await database;
    await db.insert(
      'daily_plans',
      plan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get today's plan for a profile, if it exists.
  Future<DailyPlan?> getTodayPlan(String profileId) async {
    final db = await database;
    final today = DateTime.now();
    final dateStr = DateTime(today.year, today.month, today.day).toIso8601String();
    final results = await db.query(
      'daily_plans',
      where: 'profileId = ? AND date = ?',
      whereArgs: [profileId, dateStr],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return DailyPlan.fromMap(results.first);
  }

  /// Update an existing plan (e.g., mark offline, override).
  Future<void> updateDailyPlan(DailyPlan plan) async {
    final db = await database;
    await db.update(
      'daily_plans',
      plan.toMap(),
      where: 'id = ?',
      whereArgs: [plan.id],
    );
  }

  // ════════════════════════════════════════════
  // SESSION HISTORY
  // ════════════════════════════════════════════

  /// Save a completed session.
  Future<void> saveSessionRecord(SessionRecord record) async {
    final db = await database;
    await db.insert('session_history', record.toMap());
  }

  /// Get session history for a profile (most recent first).
  Future<List<SessionRecord>> getSessionHistory(
    String profileId, {
    int limit = 30,
  }) async {
    final db = await database;
    final results = await db.query(
      'session_history',
      where: 'profileId = ?',
      whereArgs: [profileId],
      orderBy: 'date DESC',
      limit: limit,
    );
    return results.map(SessionRecord.fromMap).toList();
  }

  /// Get the last session for a profile.
  Future<SessionRecord?> getLastSession(String profileId) async {
    final sessions = await getSessionHistory(profileId, limit: 1);
    return sessions.isNotEmpty ? sessions.first : null;
  }

  /// Count sessions for a given date (CE-2: multi-session tracking).
  Future<int> getSessionCountForDate(String profileId, DateTime date) async {
    final db = await database;
    final dateStart = DateTime(date.year, date.month, date.day);
    final dateEnd = dateStart.add(const Duration(days: 1));
    final results = await db.rawQuery(
      'SELECT COUNT(*) as count FROM session_history WHERE profileId = ? AND date >= ? AND date < ?',
      [profileId, dateStart.toIso8601String(), dateEnd.toIso8601String()],
    );
    return results.isNotEmpty ? (results.first['count'] as int? ?? 0) : 0;
  }

  // ════════════════════════════════════════════
  // STREAK
  // ════════════════════════════════════════════

  /// Get streak data for a profile.
  Future<StreakData> getStreak(String profileId) async {
    final db = await database;
    final results = await db.query(
      'streak_data',
      where: 'profileId = ?',
      whereArgs: [profileId],
      limit: 1,
    );
    if (results.isEmpty) {
      return const StreakData();
    }
    final row = results.first;
    return StreakData(
      totalActiveDays: row['totalActiveDays'] as int? ?? 0,
      lastActiveDate: row['lastActiveDate'] != null
          ? DateTime.parse(row['lastActiveDate'] as String)
          : null,
    );
  }

  /// Record today as an active day (increments total, doesn't double-count).
  Future<void> recordActiveDay(String profileId) async {
    final db = await database;
    final streak = await getStreak(profileId);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    if (streak.lastActiveDate != null) {
      final lastDate = DateTime(
        streak.lastActiveDate!.year,
        streak.lastActiveDate!.month,
        streak.lastActiveDate!.day,
      );
      if (todayDate.isAtSameMomentAs(lastDate)) return; // Already counted
    }

    await db.insert(
      'streak_data',
      {
        'profileId': profileId,
        'totalActiveDays': streak.totalActiveDays + 1,
        'lastActiveDate': todayDate.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get the number of missed days since last activity.
  Future<int> getMissedDays(String profileId) async {
    final streak = await getStreak(profileId);
    if (streak.lastActiveDate == null) return 0;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastDate = DateTime(
      streak.lastActiveDate!.year,
      streak.lastActiveDate!.month,
      streak.lastActiveDate!.day,
    );
    return todayDate.difference(lastDate).inDays;
  }

  // ════════════════════════════════════════════
  // MANZIL ROTATION
  // ════════════════════════════════════════════

  /// Add a juz to the manzil rotation.
  Future<void> addJuzToRotation(String profileId, int juzNumber) async {
    final db = await database;
    await db.insert(
      'manzil_rotation',
      {
        'profileId': profileId,
        'juzNumber': juzNumber,
        'isInRotation': 1,
        'currentDay': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all juz in the rotation for a profile.
  Future<List<int>> getRotationJuz(String profileId) async {
    final db = await database;
    final results = await db.query(
      'manzil_rotation',
      where: 'profileId = ? AND isInRotation = 1',
      whereArgs: [profileId],
      orderBy: 'juzNumber ASC',
    );
    return results.map((r) => r['juzNumber'] as int).toList();
  }

  /// Remove a juz from the rotation.
  Future<void> removeJuzFromRotation(String profileId, int juzNumber) async {
    final db = await database;
    await db.update(
      'manzil_rotation',
      {'isInRotation': 0},
      where: 'profileId = ? AND juzNumber = ?',
      whereArgs: [profileId, juzNumber],
    );
  }

  // ════════════════════════════════════════════
  // FLASHCARDS
  // ════════════════════════════════════════════

  /// Save a flashcard (insert or replace).
  Future<void> saveFlashcard(Flashcard card) async {
    final db = await database;
    await db.insert(
      'flashcards',
      card.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Save multiple flashcards in a batch.
  Future<void> saveFlashcardsBatch(List<Flashcard> cards) async {
    final db = await database;
    final batch = db.batch();
    for (final card in cards) {
      batch.insert('flashcards', card.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Get all due cards for a profile (due_date <= now), ordered by priority.
  Future<List<Flashcard>> getDueFlashcards(String profileId,
      {int limit = 25}) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final results = await db.query(
      'flashcards',
      where: 'profile_id = ? AND due_date <= ?',
      whereArgs: [profileId, now],
      orderBy: 'due_date ASC',
      limit: limit,
    );
    return results.map(Flashcard.fromMap).toList();
  }

  /// Get total and due card counts for a profile.
  Future<Map<String, int>> getFlashcardStats(String profileId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM flashcards WHERE profile_id = ?',
      [profileId],
    );
    final dueResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM flashcards WHERE profile_id = ? AND due_date <= ?',
      [profileId, now],
    );

    return {
      'total': totalResult.first['count'] as int? ?? 0,
      'due': dueResult.first['count'] as int? ?? 0,
    };
  }

  /// Get due cards filtered by type. If type is null, returns all types (mixed).
  Future<List<Flashcard>> getDueFlashcardsByType(
    String profileId,
    FlashcardType? type, {
    int limit = 25,
  }) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    if (type == null) {
      return getDueFlashcards(profileId, limit: limit);
    }
    final results = await db.query(
      'flashcards',
      where: 'profile_id = ? AND due_date <= ? AND type = ?',
      whereArgs: [profileId, now, type.index],
      orderBy: 'due_date ASC',
      limit: limit,
    );
    return results.map(Flashcard.fromMap).toList();
  }

  /// Get per-type due counts for a profile. Returns {FlashcardType: {total, due}}.
  Future<Map<int, Map<String, int>>> getFlashcardStatsByType(
      String profileId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    final totalByType = await db.rawQuery(
      'SELECT type, COUNT(*) as count FROM flashcards WHERE profile_id = ? GROUP BY type',
      [profileId],
    );
    final dueByType = await db.rawQuery(
      'SELECT type, COUNT(*) as count FROM flashcards WHERE profile_id = ? AND due_date <= ? GROUP BY type',
      [profileId, now],
    );

    final result = <int, Map<String, int>>{};
    for (final row in totalByType) {
      final type = row['type'] as int;
      result[type] = {'total': row['count'] as int? ?? 0, 'due': 0};
    }
    for (final row in dueByType) {
      final type = row['type'] as int;
      result.putIfAbsent(type, () => {'total': 0, 'due': 0});
      result[type]!['due'] = row['count'] as int? ?? 0;
    }
    return result;
  }

  /// Update a flashcard after review (new SRS state).
  Future<void> updateFlashcard(Flashcard card) async {
    final db = await database;
    await db.update(
      'flashcards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  /// Save a flashcard review event.
  Future<void> saveFlashcardReview(FlashcardReview review) async {
    final db = await database;
    await db.insert('flashcard_reviews', review.toMap());
  }

  /// Get recent review history for analytics.
  Future<List<FlashcardReview>> getRecentReviews(String profileId,
      {int limit = 100}) async {
    final db = await database;
    final results = await db.rawQuery(
      '''SELECT fr.* FROM flashcard_reviews fr
         JOIN flashcards f ON fr.card_id = f.id
         WHERE f.profile_id = ?
         ORDER BY fr.reviewed_at DESC LIMIT ?''',
      [profileId, limit],
    );
    return results.map(FlashcardReview.fromMap).toList();
  }

  /// Get accuracy stats (percentage of strong+ok vs total reviews).
  Future<Map<String, dynamic>> getFlashcardAccuracy(String profileId) async {
    final db = await database;
    final results = await db.rawQuery(
      '''SELECT fr.rating, COUNT(*) as count FROM flashcard_reviews fr
         JOIN flashcards f ON fr.card_id = f.id
         WHERE f.profile_id = ?
         GROUP BY fr.rating''',
      [profileId],
    );

    int total = 0;
    int correct = 0;
    for (final row in results) {
      final count = row['count'] as int;
      total += count;
      final rating = FlashcardRating.values[row['rating'] as int];
      if (rating == FlashcardRating.strong || rating == FlashcardRating.ok) {
        correct += count;
      }
    }

    return {
      'total': total,
      'correct': correct,
      'accuracy': total > 0 ? (correct / total * 100).round() : 0,
    };
  }

  /// Delete all flashcards for a profile.
  Future<void> deleteFlashcardsForProfile(String profileId) async {
    final db = await database;
    // Delete reviews first (no cascade on sqflite by default)
    await db.rawDelete(
      'DELETE FROM flashcard_reviews WHERE card_id IN (SELECT id FROM flashcards WHERE profile_id = ?)',
      [profileId],
    );
    await db.delete('flashcards',
        where: 'profile_id = ?', whereArgs: [profileId]);
  }

  /// Check if a flashcard already exists for a given verse + type + profile.
  Future<bool> flashcardExists(
      String profileId, String verseKey, FlashcardType type) async {
    final db = await database;
    final results = await db.query(
      'flashcards',
      where: 'profile_id = ? AND verse_key = ? AND type = ?',
      whereArgs: [profileId, verseKey, type.index],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  // ════════════════════════════════════════════
  // MUTASHABIHAT
  // ════════════════════════════════════════════

  /// Import mutashabihat groups in batch (initial dataset load).
  Future<void> importMutashabihatBatch(List<MutashabihatGroup> groups) async {
    final db = await database;
    final batch = db.batch();
    for (final group in groups) {
      batch.insert('mutashabihat_groups', group.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  /// Get all mutashabihat groups.
  Future<List<MutashabihatGroup>> getAllMutashabihat() async {
    final db = await database;
    final results = await db.query('mutashabihat_groups',
        orderBy: 'source_verse_key ASC');
    return results.map(MutashabihatGroup.fromMap).toList();
  }

  /// Get mutashabihat groups by user status.
  Future<List<MutashabihatGroup>> getMutashabihatByStatus(
      MutashabihatStatus status) async {
    final db = await database;
    final results = await db.query(
      'mutashabihat_groups',
      where: 'user_status = ?',
      whereArgs: [status.index],
    );
    return results.map(MutashabihatGroup.fromMap).toList();
  }

  /// Update a mutashabihat group's user status.
  Future<void> updateMutashabihatStatus(
      String groupId, MutashabihatStatus status) async {
    final db = await database;
    await db.update(
      'mutashabihat_groups',
      {'user_status': status.index},
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }

  /// Get total count of imported mutashabihat groups.
  Future<int> getMutashabihatCount() async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM mutashabihat_groups');
    return result.first['count'] as int? ?? 0;
  }

  /// Clear all imported mutashabihat data (for re-import with corrected data).
  Future<void> clearMutashabihat() async {
    final db = await database;
    await db.delete('mutashabihat_groups');
  }

  /// Get mutashabihat groups that involve a specific verse.
  Future<List<MutashabihatGroup>> getMutashabihatForVerse(
      String verseKey) async {
    final db = await database;
    final results = await db.query(
      'mutashabihat_groups',
      where: 'source_verse_key = ? OR similar_verses LIKE ?',
      whereArgs: [verseKey, '%$verseKey%'],
    );
    return results.map(MutashabihatGroup.fromMap).toList();
  }

  /// Reset all progress for a profile (keeps the profile itself).
  /// Erases: page_progress, session_history, daily_plans, flashcards, streak data.
  Future<void> resetProgress(String profileId) async {
    final db = await database;
    await db.delete('page_progress', where: 'profileId = ?', whereArgs: [profileId]);
    await db.delete('session_history', where: 'profileId = ?', whereArgs: [profileId]);
    await db.delete('daily_plans', where: 'profileId = ?', whereArgs: [profileId]);
    // flashcard_reviews has no profileId — delete reviews for cards owned by this profile
    await db.rawDelete(
      'DELETE FROM flashcard_reviews WHERE card_id IN (SELECT id FROM flashcards WHERE profile_id = ?)',
      [profileId],
    );
    await db.delete('flashcards', where: 'profile_id = ?', whereArgs: [profileId]);
    // Reset streak
    await db.delete('streak_data', where: 'profileId = ?', whereArgs: [profileId]);
  }

  /// Close the database.
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
