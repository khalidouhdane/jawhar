import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/models/flashcard_models.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sync status for UI display.
enum SyncStatus { idle, syncing, synced, error }

/// Cloud sync service — bridges local SQLite ↔ Cloud Firestore.
///
/// Architecture: SQLite is the source of truth. Firestore is the sync layer.
/// All writes go to SQLite first, then pushed to Firestore in the background.
/// On new device login, Firestore data is pulled into SQLite.
///
/// Extends ChangeNotifier so UI can react to sync status changes.
class CloudSyncService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final HifzDatabaseService _db;

  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;

  SyncStatus get status => _status;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;
  bool get isSyncing => _status == SyncStatus.syncing;

  CloudSyncService(this._db);

  /// Reference to the user's root document.
  DocumentReference _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  void _setStatus(SyncStatus s) {
    _status = s;
    notifyListeners();
  }

  // ════════════════════════════════════════════
  // INITIAL SYNC (First Login)
  // ════════════════════════════════════════════

  /// Perform initial sync when user signs in for the first time on this device.
  ///
  /// Strategy:
  /// 1. Check if cloud data exists
  /// 2. If yes: pull cloud → populate local SQLite (cloud wins)
  /// 3. If no: push local SQLite → Firestore
  /// 4. If both exist: cloud wins for profile/settings, merge progress
  Future<void> performInitialSync(String uid) async {
    if (isSyncing) return;
    _setStatus(SyncStatus.syncing);
    _lastError = null;

    try {
      debugPrint('[SYNC] Starting initial sync for $uid');

      // Check if cloud profile exists
      final cloudProfile = await _userDoc(uid).get();
      final hasCloudData = cloudProfile.exists;

      // Check if local profile exists
      final localProfile = await _db.getActiveProfile();
      final hasLocalData = localProfile != null;

      if (hasCloudData && !hasLocalData) {
        // New device: pull everything from cloud
        debugPrint('[SYNC] New device detected — pulling from cloud');
        await _pullAllFromCloud(uid);
      } else if (!hasCloudData && hasLocalData) {
        // First login ever: push local data to cloud
        debugPrint('[SYNC] First login — pushing local data to cloud');
        await _pushAllToCloud(uid, localProfile);
      } else if (hasCloudData && hasLocalData) {
        // Both exist: merge strategy
        debugPrint('[SYNC] Both local and cloud data exist — merging');
        await _mergeData(uid, localProfile);
      } else {
        // No data anywhere — fresh user
        debugPrint('[SYNC] No data found locally or in cloud');
      }

      _lastSyncTime = DateTime.now();
      _setStatus(SyncStatus.synced);
      debugPrint('[SYNC] Initial sync complete');
    } catch (e) {
      debugPrint('[SYNC] Initial sync error: $e');
      _lastError = e.toString();
      _setStatus(SyncStatus.error);
    }
  }

  /// Manual full sync with retry — pushes everything to cloud.
  Future<void> syncAll(String uid) async {
    if (isSyncing) return;
    _setStatus(SyncStatus.syncing);
    _lastError = null;

    try {
      final profile = await _db.getActiveProfile();
      if (profile == null) {
        _setStatus(SyncStatus.idle);
        return;
      }

      await _withRetry(() => _pushAllToCloud(uid, profile));
      _lastSyncTime = DateTime.now();
      _setStatus(SyncStatus.synced);
      debugPrint('[SYNC] Full sync complete');
    } catch (e) {
      debugPrint('[SYNC] Full sync error: $e');
      _lastError = e.toString();
      _setStatus(SyncStatus.error);
    }
  }

  /// Retry wrapper with exponential backoff (3 attempts, 1s → 2s → 4s).
  Future<T> _withRetry<T>(Future<T> Function() fn, {int maxAttempts = 3}) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        final delay = Duration(seconds: 1 << (attempt - 1)); // 1s, 2s, 4s
        debugPrint('[SYNC] Retry $attempt/$maxAttempts after ${delay.inSeconds}s');
        await Future.delayed(delay);
      }
    }
  }

  // ════════════════════════════════════════════
  // PUSH: Local → Cloud (fire-and-forget)
  // ════════════════════════════════════════════

  /// Push the full local profile to Firestore.
  Future<void> syncProfile(String uid, MemoryProfile profile) async {
    try {
      await _userDoc(uid).set({
        ...profile.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('[SYNC] Profile pushed');
    } catch (e) {
      debugPrint('[SYNC] Profile push error: $e');
    }
  }

  /// Push settings (SharedPreferences values) to Firestore.
  Future<void> syncSettings(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      final settings = <String, dynamic>{
        'rewaya': storage.savedRewaya,
        'readingMode': storage.savedReadingMode,
        'centerLock': storage.savedCenterLock,
        'autoScrollSpeed': storage.savedAutoScrollSpeed,
        'lastReadPage': prefs.getInt('last_read_page'),
        'lastReadSurah': prefs.getString('last_read_surah'),
        'lastReadVerseKey': prefs.getString('last_read_verse_key'),
        'onboardingComplete': storage.hasCompletedOnboarding,
        'bookmarks': storage.getBookmarks(),
        'bookmarkCollections': storage.getCollections(),
        'werdConfig': prefs.getString('werd_config'),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _userDoc(uid).collection('meta').doc('settings').set(
            settings,
            SetOptions(merge: true),
          );
      debugPrint('[SYNC] Settings pushed');
    } catch (e) {
      debugPrint('[SYNC] Settings push error: $e');
    }
  }

  /// Push a single page progress update.
  Future<void> syncProgress(String uid, int pageNumber,
      Map<String, dynamic> progressData) async {
    try {
      await _userDoc(uid)
          .collection('progress')
          .doc('$pageNumber')
          .set({
        ...progressData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SYNC] Progress push error for page $pageNumber: $e');
    }
  }

  /// Push a session record (append-only).
  Future<void> syncSession(String uid, SessionRecord session) async {
    try {
      await _userDoc(uid)
          .collection('sessions')
          .doc(session.id)
          .set({
        ...session.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[SYNC] Session push error: $e');
    }
  }

  /// Push a daily plan (append-only).
  Future<void> syncPlan(String uid, DailyPlan plan) async {
    try {
      await _userDoc(uid)
          .collection('plans')
          .doc(plan.id)
          .set({
        ...plan.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[SYNC] Plan push error: $e');
    }
  }

  /// Push streak data.
  Future<void> syncStreak(String uid, StreakData streak) async {
    try {
      await _userDoc(uid).collection('meta').doc('streak').set({
        'totalActiveDays': streak.totalActiveDays,
        'lastActiveDate': streak.lastActiveDate?.toIso8601String(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SYNC] Streak push error: $e');
    }
  }

  // ════════════════════════════════════════════
  // PULL: Cloud → Local
  // ════════════════════════════════════════════

  /// Pull all data from Firestore and populate local SQLite.
  Future<void> _pullAllFromCloud(String uid) async {
    // 1. Pull profile
    final profileDoc = await _userDoc(uid).get();
    if (profileDoc.exists) {
      final data = profileDoc.data() as Map<String, dynamic>;
      // Remove Firestore-specific fields
      data.remove('updatedAt');
      final profile = MemoryProfile.fromMap(data);
      await _db.createProfile(profile);
      debugPrint('[SYNC] Profile pulled from cloud');
    }

    // 2. Pull settings
    final settingsDoc =
        await _userDoc(uid).collection('meta').doc('settings').get();
    if (settingsDoc.exists) {
      final data = settingsDoc.data()!;
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      if (data['rewaya'] != null) storage.saveRewaya(data['rewaya'] as int);
      if (data['readingMode'] != null) {
        storage.saveReadingMode(data['readingMode'] as String);
      }
      if (data['centerLock'] != null) {
        storage.saveCenterLock(data['centerLock'] as bool);
      }
      if (data['autoScrollSpeed'] != null) {
        storage.saveAutoScrollSpeed(
            (data['autoScrollSpeed'] as num).toDouble());
      }
      if (data['bookmarks'] != null) {
        storage.saveBookmarks(data['bookmarks'] as String);
      }
      if (data['bookmarkCollections'] != null) {
        storage.saveCollections(data['bookmarkCollections'] as String);
      }
      if (data['werdConfig'] != null) {
        prefs.setString('werd_config', data['werdConfig'] as String);
      }
      if (data['onboardingComplete'] == true) {
        storage.setOnboardingComplete();
      }
      if (data['lastReadPage'] != null) {
        storage.saveLastRead(
          page: data['lastReadPage'] as int,
          surahName: data['lastReadSurah'] as String? ?? '',
          verseKey: data['lastReadVerseKey'] as String?,
        );
      }
      debugPrint('[SYNC] Settings pulled from cloud');
    }

    // 3. Pull streak
    final streakDoc =
        await _userDoc(uid).collection('meta').doc('streak').get();
    if (streakDoc.exists) {
      final data = streakDoc.data()!;
      final db = await _db.database;
      final profileDoc2 = await _userDoc(uid).get();
      if (profileDoc2.exists) {
        final profileId = (profileDoc2.data() as Map<String, dynamic>)['id'];
        await db.insert('streak_data', {
          'profileId': profileId,
          'totalActiveDays': data['totalActiveDays'] ?? 0,
          'lastActiveDate': data['lastActiveDate'],
        });
      }
      debugPrint('[SYNC] Streak pulled from cloud');
    }

    // 4. Pull page progress
    final progressSnap =
        await _userDoc(uid).collection('progress').get();
    for (final doc in progressSnap.docs) {
      final data = doc.data();
      data.remove('updatedAt');
      final db = await _db.database;
      await db.insert('page_progress', data,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    debugPrint('[SYNC] Pulled ${progressSnap.docs.length} progress records');

    // 5. Pull session history
    final sessionsSnap =
        await _userDoc(uid).collection('sessions').get();
    for (final doc in sessionsSnap.docs) {
      final data = doc.data();
      data.remove('createdAt');
      final db = await _db.database;
      await db.insert('session_history', data,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    debugPrint('[SYNC] Pulled ${sessionsSnap.docs.length} session records');

    // 6. Pull daily plans
    final plansSnap =
        await _userDoc(uid).collection('plans').get();
    for (final doc in plansSnap.docs) {
      final data = doc.data();
      data.remove('createdAt');
      final db = await _db.database;
      await db.insert('daily_plans', data,
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    debugPrint('[SYNC] Pulled ${plansSnap.docs.length} plan records');
  }

  /// Push all local data to Firestore.
  Future<void> _pushAllToCloud(String uid, MemoryProfile profile) async {
    // 1. Push profile
    await syncProfile(uid, profile);

    // 2. Push settings
    await syncSettings(uid);

    // 3. Push streak
    final streak = await _db.getStreak(profile.id);
    await syncStreak(uid, streak);

    // 4. Push all page progress
    final db = await _db.database;
    final progressRows = await db.query('page_progress',
        where: 'profileId = ?', whereArgs: [profile.id]);
    for (final row in progressRows) {
      await _userDoc(uid)
          .collection('progress')
          .doc('${row['pageNumber']}')
          .set({
        ...row,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('[SYNC] Pushed ${progressRows.length} progress records');

    // 5. Push all session history
    final sessionRows = await db.query('session_history',
        where: 'profileId = ?', whereArgs: [profile.id]);
    for (final row in sessionRows) {
      await _userDoc(uid)
          .collection('sessions')
          .doc(row['id'] as String)
          .set({
        ...row,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('[SYNC] Pushed ${sessionRows.length} session records');

    // 6. Push all daily plans
    final planRows = await db.query('daily_plans',
        where: 'profileId = ?', whereArgs: [profile.id]);
    for (final row in planRows) {
      await _userDoc(uid)
          .collection('plans')
          .doc(row['id'] as String)
          .set({
        ...row,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('[SYNC] Pushed ${planRows.length} plan records');

    // 7. Push all flashcards
    final cardRows = await db.query('flashcards',
        where: 'profile_id = ?', whereArgs: [profile.id]);
    for (final row in cardRows) {
      await _userDoc(uid)
          .collection('flashcards')
          .doc(row['id'] as String)
          .set({
        ...row,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    debugPrint('[SYNC] Pushed ${cardRows.length} flashcard records');

    // 8. Push flashcard reviews
    final reviewRows = await db.query('flashcard_reviews');
    // Filter reviews for cards belonging to this profile
    final profileCardIds = cardRows.map((r) => r['id']).toSet();
    final profileReviews = reviewRows.where((r) => profileCardIds.contains(r['card_id'])).toList();
    for (final row in profileReviews) {
      final reviewId = '${row['card_id']}_${row['reviewed_at']}';
      await _userDoc(uid)
          .collection('flashcard_reviews')
          .doc(reviewId)
          .set({
        ...row,
        'syncedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    debugPrint('[SYNC] Pushed ${profileReviews.length} flashcard review records');
  }

  /// Merge local and cloud data.
  ///
  /// Strategy: cloud wins for profile/settings, merge progress additively.
  Future<void> _mergeData(String uid, MemoryProfile localProfile) async {
    // Pull profile from cloud (cloud wins)
    final cloudProfileDoc = await _userDoc(uid).get();
    if (cloudProfileDoc.exists) {
      final cloudData = cloudProfileDoc.data() as Map<String, dynamic>;
      cloudData.remove('updatedAt');
      try {
        final cloudProfile = MemoryProfile.fromMap(cloudData);
        // Update local with cloud profile
        await _db.updateProfile(cloudProfile);
        debugPrint('[SYNC] Profile merged (cloud wins)');
      } catch (e) {
        debugPrint('[SYNC] Cloud profile parse error, keeping local: $e');
        // If cloud data is corrupted, push local
        await syncProfile(uid, localProfile);
      }
    }

    // Pull settings (cloud wins)
    final cloudSettings =
        await _userDoc(uid).collection('meta').doc('settings').get();
    if (cloudSettings.exists) {
      // Apply cloud settings locally
      final data = cloudSettings.data()!;
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);
      if (data['rewaya'] != null) storage.saveRewaya(data['rewaya'] as int);
      if (data['bookmarks'] != null) {
        storage.saveBookmarks(data['bookmarks'] as String);
      }
      if (data['bookmarkCollections'] != null) {
        storage.saveCollections(data['bookmarkCollections'] as String);
      }
      debugPrint('[SYNC] Settings merged (cloud wins)');
    } else {
      // No cloud settings — push local
      await syncSettings(uid);
    }

    // Merge progress: higher status wins, sum review counts
    final cloudProgress =
        await _userDoc(uid).collection('progress').get();
    final db = await _db.database;

    for (final doc in cloudProgress.docs) {
      final cloudData = doc.data();
      final pageNum = int.tryParse(doc.id);
      if (pageNum == null) continue;

      final localRows = await db.query('page_progress',
          where: 'pageNumber = ? AND profileId = ?',
          whereArgs: [pageNum, localProfile.id]);

      if (localRows.isEmpty) {
        // Cloud has it, local doesn't — insert
        cloudData.remove('updatedAt');
        await db.insert('page_progress', cloudData,
            conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        // Both have it — take higher status, max review count
        final local = localRows.first;
        final cloudStatus = cloudData['status'] as int? ?? 0;
        final localStatus = local['status'] as int? ?? 0;
        final cloudReviews = cloudData['reviewCount'] as int? ?? 0;
        final localReviews = local['reviewCount'] as int? ?? 0;

        final merged = {
          ...local,
          'status': cloudStatus > localStatus ? cloudStatus : localStatus,
          'reviewCount':
              cloudReviews > localReviews ? cloudReviews : localReviews,
          'memorizedAt': cloudData['memorizedAt'] ?? local['memorizedAt'],
        };

        await db.update('page_progress', merged,
            where: 'pageNumber = ? AND profileId = ?',
            whereArgs: [pageNum, localProfile.id]);
      }
    }
    debugPrint(
        '[SYNC] Progress merged (${cloudProgress.docs.length} cloud records)');

    // Push merged local progress back to cloud
    final allProgress = await db.query('page_progress',
        where: 'profileId = ?', whereArgs: [localProfile.id]);
    for (final row in allProgress) {
      await _userDoc(uid)
          .collection('progress')
          .doc('${row['pageNumber']}')
          .set({
        ...row,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Push local sessions that cloud might not have
    final localSessions = await db.query('session_history',
        where: 'profileId = ?', whereArgs: [localProfile.id]);
    for (final row in localSessions) {
      await _userDoc(uid)
          .collection('sessions')
          .doc(row['id'] as String)
          .set({
        ...row,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Streak: take max
    final localStreak = await _db.getStreak(localProfile.id);
    final cloudStreak =
        await _userDoc(uid).collection('meta').doc('streak').get();
    if (cloudStreak.exists) {
      final cloudDays = cloudStreak.data()!['totalActiveDays'] as int? ?? 0;
      final maxDays = localStreak.totalActiveDays > cloudDays
          ? localStreak.totalActiveDays
          : cloudDays;
      final mergedStreak = StreakData(
        totalActiveDays: maxDays,
        lastActiveDate: localStreak.lastActiveDate,
      );
      await syncStreak(uid, mergedStreak);
    } else {
      await syncStreak(uid, localStreak);
    }
  }

  // ════════════════════════════════════════════
  // ACCOUNT DELETION
  // ════════════════════════════════════════════

  /// Delete all user data from Firestore and Firebase Auth.
  ///
  /// Use when user wants to completely remove their cloud account.
  Future<void> deleteAccount(String uid) async {
    _setStatus(SyncStatus.syncing);
    try {
      // Delete all subcollections
      for (final collection in [
        'progress',
        'sessions',
        'plans',
        'flashcards',
        'flashcard_reviews',
        'meta',
      ]) {
        final snap = await _userDoc(uid).collection(collection).get();
        for (final doc in snap.docs) {
          await doc.reference.delete();
        }
      }
      // Delete user root document
      await _userDoc(uid).delete();
      debugPrint('[SYNC] All cloud data deleted for $uid');

      // Delete Firebase Auth user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
        debugPrint('[SYNC] Firebase Auth user deleted');
      }

      _setStatus(SyncStatus.idle);
    } catch (e) {
      debugPrint('[SYNC] Account deletion error: $e');
      _lastError = e.toString();
      _setStatus(SyncStatus.error);
      rethrow;
    }
  }

  /// Push a single flashcard update.
  Future<void> syncFlashcard(String uid, Flashcard card) async {
    try {
      await _userDoc(uid)
          .collection('flashcards')
          .doc(card.id)
          .set({
        ...card.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[SYNC] Flashcard push error: $e');
    }
  }

  /// Push a flashcard review.
  Future<void> syncFlashcardReview(String uid, FlashcardReview review) async {
    try {
      final reviewId = '${review.cardId}_${review.reviewedAt.toIso8601String()}';
      await _userDoc(uid)
          .collection('flashcard_reviews')
          .doc(reviewId)
          .set({
        ...review.toMap(),
        'syncedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[SYNC] Flashcard review push error: $e');
    }
  }
}
