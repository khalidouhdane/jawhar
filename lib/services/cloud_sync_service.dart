import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/models/flashcard_models.dart';
import 'package:quran_app/services/account_api.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/services/outbox_service.dart';
import 'package:quran_app/services/sync_worker.dart';
import 'package:quran_app/services/write_path_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran_app/utils/app_logger.dart';

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
  final WritePathStore? _writePathStore;
  final AccountApi? _accountApi;
  final SyncWorker? _syncWorker;
  final OutboxService? _outbox;

  SyncStatus _status = SyncStatus.idle;
  DateTime? _lastSyncTime;
  String? _lastError;
  bool _syncOperationActive = false;
  bool _disposed = false;

  SyncStatus get status => _status;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;
  bool get isSyncing => _status == SyncStatus.syncing;

  /// [writePathStore] backs the §5 force-update gate (see [_syncGated]);
  /// [accountApi] is the `DELETE /v1/me` client used by [deleteAccount]
  /// (API first, legacy client-side cascade as the unreachable-fallback).
  /// [syncWorker] + [outbox] are quiesced by [deleteAccount] BEFORE the
  /// API call — a drain racing the server-side tree deletion would
  /// recreate permanently orphaned docs under the deleted uid (the ID
  /// token outlives `auth.deleteUser`).
  CloudSyncService(
    this._db, {
    WritePathStore? writePathStore,
    AccountApi? accountApi,
    SyncWorker? syncWorker,
    OutboxService? outbox,
  }) : _writePathStore = writePathStore,
       _accountApi = accountApi,
       _syncWorker = syncWorker,
       _outbox = outbox;

  /// §5 force-update gate, legacy half: when the running build is below the
  /// server's `minSupportedBuild`, every legacy Firestore push/pull is a
  /// silent no-op (sync is blocked; the local SQLite write the caller
  /// already made — the offline core loop — is untouched, and the outbox
  /// keeps enqueueing for the post-update drain). [deleteAccount] is
  /// deliberately NOT gated: account deletion must always work.
  bool get _syncGated => _writePathStore?.updateRequired ?? false;

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
    if (_syncGated) {
      AppLogger.warn('Sync', '[SYNC] initial sync skipped: update required');
      return;
    }
    if (_syncOperationActive) return;
    _syncOperationActive = true;
    _setStatus(SyncStatus.syncing);
    _lastError = null;

    try {
      AppLogger.info('Sync', '[SYNC] Starting initial sync for $uid');

      // Check if cloud profile exists
      final cloudProfile = await _userDoc(uid).get();
      final hasCloudData = cloudProfile.exists;

      // Check if local profile exists
      final localProfile = await _db.getActiveProfile();
      final hasLocalData = localProfile != null;

      if (hasCloudData && !hasLocalData) {
        // New device: pull everything from cloud
        AppLogger.info(
          'Sync',
          '[SYNC] New device detected — pulling from cloud',
        );
        await _pullAllFromCloud(uid);
      } else if (!hasCloudData && hasLocalData) {
        // First login ever: push local data to cloud
        AppLogger.info(
          'Sync',
          '[SYNC] First login — pushing local data to cloud',
        );
        await _pushAllToCloud(uid, localProfile);
      } else if (hasCloudData && hasLocalData) {
        // Both exist: merge strategy
        AppLogger.info(
          'Sync',
          '[SYNC] Both local and cloud data exist — merging',
        );
        await _mergeData(uid, localProfile);
      } else {
        // No data anywhere — fresh user
        AppLogger.info('Sync', '[SYNC] No data found locally or in cloud');
      }

      _lastSyncTime = DateTime.now();
      _setStatus(SyncStatus.synced);
      AppLogger.info('Sync', '[SYNC] Initial sync complete');
    } catch (e) {
      AppLogger.info('Sync', '[SYNC] Initial sync error: $e');
      _lastError = e.toString();
      _setStatus(SyncStatus.error);
    } finally {
      _syncOperationActive = false;
    }
  }

  /// Manual full sync with retry — pushes everything to cloud.
  Future<void> syncAll(String uid) async {
    if (_syncGated) {
      AppLogger.warn('Sync', '[SYNC] full sync skipped: update required');
      return;
    }
    if (_syncOperationActive) return;
    _syncOperationActive = true;
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
      AppLogger.info('Sync', '[SYNC] Full sync complete');
    } catch (e) {
      AppLogger.info('Sync', '[SYNC] Full sync error: $e');
      _lastError = e.toString();
      _setStatus(SyncStatus.error);
    } finally {
      _syncOperationActive = false;
    }
  }

  /// Retry wrapper with exponential backoff (3 attempts, 1s → 2s → 4s).
  /// Non-recoverable errors are not retried.
  Future<T> _withRetry<T>(
    Future<T> Function() fn, {
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (!_isRecoverableError(e)) {
          AppLogger.info(
            'Sync',
            '[SYNC] Non-recoverable error, not retrying: ${e.runtimeType}',
          );
          rethrow; // Let the top-level catch handle status transition
        }
        if (attempt >= maxAttempts) rethrow;
        final delay = Duration(seconds: 1 << (attempt - 1)); // 1s, 2s, 4s
        AppLogger.info(
          'Sync',
          '[SYNC] Retry $attempt/$maxAttempts after ${delay.inSeconds}s',
        );
        await Future.delayed(delay);
      }
    }
  }

  /// Classifies whether an error is likely transient (retryable).
  bool _isRecoverableError(Object e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'unavailable':
        case 'deadline-exceeded':
        case 'resource-exhausted':
        case 'aborted':
        case 'internal':
          return true;
        default:
          return false;
      }
    }
    return e is TimeoutException;
  }

  // ════════════════════════════════════════════
  // PUSH: Local → Cloud (fire-and-forget)
  // ════════════════════════════════════════════

  /// Push the full local profile to Firestore.
  Future<void> syncProfile(String uid, MemoryProfile profile) async {
    if (_syncGated) return;
    try {
      await _writeProfile(uid, profile);
      AppLogger.info('Sync', '[SYNC] Profile pushed');
    } catch (e) {
      _recordBackgroundError('Profile push', e);
    }
  }

  /// Push settings (SharedPreferences values) to Firestore.
  Future<void> syncSettings(String uid) async {
    if (_syncGated) return;
    try {
      await _writeSettings(uid);
      AppLogger.info('Sync', '[SYNC] Settings pushed');
    } catch (e) {
      _recordBackgroundError('Settings push', e);
    }
  }

  /// Push a single page progress update.
  Future<void> syncProgress(
    String uid,
    int pageNumber,
    Map<String, dynamic> progressData,
  ) async {
    if (_syncGated) return;
    try {
      await _userDoc(uid).collection('progress').doc('$pageNumber').set({
        ...progressData,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _recordBackgroundError('Progress push for page $pageNumber', e);
    }
  }

  /// Push a session record (append-only).
  Future<void> syncSession(String uid, SessionRecord session) async {
    if (_syncGated) return;
    try {
      await _userDoc(uid).collection('sessions').doc(session.id).set({
        ...session.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _recordBackgroundError('Session push', e);
    }
  }

  /// Push a daily plan (append-only).
  Future<void> syncPlan(String uid, DailyPlan plan) async {
    if (_syncGated) return;
    try {
      await _userDoc(uid).collection('plans').doc(plan.id).set({
        ...plan.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _recordBackgroundError('Plan push', e);
    }
  }

  /// Push streak data.
  Future<void> syncStreak(String uid, StreakData streak) async {
    if (_syncGated) return;
    try {
      await _writeStreak(uid, streak);
    } catch (e) {
      _recordBackgroundError('Streak push', e);
    }
  }

  Future<void> _writeProfile(String uid, MemoryProfile profile) {
    return _userDoc(uid).set({
      ...profile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _writeSettings(String uid) async {
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
    await _userDoc(
      uid,
    ).collection('meta').doc('settings').set(settings, SetOptions(merge: true));
  }

  Future<void> _writeStreak(String uid, StreakData streak) {
    return _userDoc(uid).collection('meta').doc('streak').set({
      'totalActiveDays': streak.totalActiveDays,
      'lastActiveDate': streak.lastActiveDate?.toIso8601String(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _recordBackgroundError(String operation, Object error) {
    AppLogger.info('Sync', '[SYNC] $operation error: $error');
    _lastError = error.toString();
    _setStatus(SyncStatus.error);
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
      AppLogger.info('Sync', '[SYNC] Profile pulled from cloud');
    }

    // 2. Pull settings
    final settingsDoc = await _userDoc(
      uid,
    ).collection('meta').doc('settings').get();
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
          (data['autoScrollSpeed'] as num).toDouble(),
        );
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
      AppLogger.info('Sync', '[SYNC] Settings pulled from cloud');
    }

    // 3. Pull streak
    final streakDoc = await _userDoc(
      uid,
    ).collection('meta').doc('streak').get();
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
      AppLogger.info('Sync', '[SYNC] Streak pulled from cloud');
    }

    // 4. Pull page progress
    final progressSnap = await _userDoc(uid).collection('progress').get();
    for (final doc in progressSnap.docs) {
      final data = doc.data();
      data.remove('updatedAt');
      final db = await _db.database;
      try {
        // Validate/normalize through the model before persisting locally.
        final progress = PageProgress.fromMap(data);
        await db.insert(
          'page_progress',
          progress.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        AppLogger.warn(
          'Sync',
          '[SYNC] Skipping malformed progress record ${doc.id}: $e',
        );
      }
    }
    AppLogger.info(
      'Sync',
      '[SYNC] Pulled ${progressSnap.docs.length} progress records',
    );

    // 5. Pull session history
    final sessionsSnap = await _userDoc(uid).collection('sessions').get();
    for (final doc in sessionsSnap.docs) {
      final data = doc.data();
      data.remove('createdAt');
      final db = await _db.database;
      try {
        final session = SessionRecord.fromMap(data);
        await db.insert(
          'session_history',
          session.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (e) {
        AppLogger.warn(
          'Sync',
          '[SYNC] Skipping malformed session record ${doc.id}: $e',
        );
      }
    }
    AppLogger.info(
      'Sync',
      '[SYNC] Pulled ${sessionsSnap.docs.length} session records',
    );

    // 6. Pull daily plans
    final plansSnap = await _userDoc(uid).collection('plans').get();
    for (final doc in plansSnap.docs) {
      final data = doc.data();
      data.remove('createdAt');
      final db = await _db.database;
      try {
        final plan = DailyPlan.fromMap(data);
        await db.insert(
          'daily_plans',
          plan.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      } catch (e) {
        AppLogger.warn(
          'Sync',
          '[SYNC] Skipping malformed plan record ${doc.id}: $e',
        );
      }
    }
    AppLogger.info(
      'Sync',
      '[SYNC] Pulled ${plansSnap.docs.length} plan records',
    );
  }

  /// Push all local data to Firestore.
  Future<void> _pushAllToCloud(String uid, MemoryProfile profile) async {
    // 1. Push profile (direct write — propagates errors)
    await _writeProfile(uid, profile);

    // 2. Push settings (direct write — propagates errors)
    await _writeSettings(uid);

    // 3. Push streak (direct write — propagates errors)
    final streak = await _db.getStreak(profile.id);
    await _writeStreak(uid, streak);

    // 4. Push all page progress
    final db = await _db.database;
    final progressRows = await db.query(
      'page_progress',
      where: 'profileId = ?',
      whereArgs: [profile.id],
    );
    for (final row in progressRows) {
      await _userDoc(uid)
          .collection('progress')
          .doc('${row['pageNumber']}')
          .set({...row, 'updatedAt': FieldValue.serverTimestamp()});
    }
    AppLogger.info(
      'Sync',
      '[SYNC] Pushed ${progressRows.length} progress records',
    );

    // 5. Push all session history
    final sessionRows = await db.query(
      'session_history',
      where: 'profileId = ?',
      whereArgs: [profile.id],
    );
    for (final row in sessionRows) {
      await _userDoc(uid).collection('sessions').doc(row['id'] as String).set({
        ...row,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    AppLogger.info(
      'Sync',
      '[SYNC] Pushed ${sessionRows.length} session records',
    );

    // 6. Push all daily plans
    final planRows = await db.query(
      'daily_plans',
      where: 'profileId = ?',
      whereArgs: [profile.id],
    );
    for (final row in planRows) {
      await _userDoc(uid).collection('plans').doc(row['id'] as String).set({
        ...row,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    AppLogger.info('Sync', '[SYNC] Pushed ${planRows.length} plan records');

    // 7. Push all flashcards
    final cardRows = await db.query(
      'flashcards',
      where: 'profile_id = ?',
      whereArgs: [profile.id],
    );
    for (final row in cardRows) {
      await _userDoc(uid).collection('flashcards').doc(row['id'] as String).set(
        {...row, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
    AppLogger.info(
      'Sync',
      '[SYNC] Pushed ${cardRows.length} flashcard records',
    );

    // 8. Push flashcard reviews (parameterized query)
    if (cardRows.isNotEmpty) {
      final reviewRows = await db.rawQuery(
        '''
        SELECT reviews.*
        FROM flashcard_reviews AS reviews
        INNER JOIN flashcards AS cards ON cards.id = reviews.card_id
        WHERE cards.profile_id = ?
        ''',
        [profile.id],
      );
      for (final row in reviewRows) {
        final reviewId = row['id'] as String;
        await _userDoc(uid).collection('flashcard_reviews').doc(reviewId).set({
          ...row,
          'syncedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      AppLogger.info(
        'Sync',
        '[SYNC] Pushed ${reviewRows.length} flashcard review records',
      );
    }
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
        AppLogger.info('Sync', '[SYNC] Profile merged (cloud wins)');
      } catch (e) {
        AppLogger.info(
          'Sync',
          '[SYNC] Cloud profile parse error, keeping local: $e',
        );
        // If cloud data is corrupted, push local
        await _writeProfile(uid, localProfile);
      }
    }

    // Pull settings (cloud wins)
    final cloudSettings = await _userDoc(
      uid,
    ).collection('meta').doc('settings').get();
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
      AppLogger.info('Sync', '[SYNC] Settings merged (cloud wins)');
    } else {
      // No cloud settings — push local
      await _writeSettings(uid);
    }

    // Merge progress: higher status wins, sum review counts
    final cloudProgress = await _userDoc(uid).collection('progress').get();
    final db = await _db.database;

    for (final doc in cloudProgress.docs) {
      final cloudData = doc.data();
      final pageNum = int.tryParse(doc.id);
      if (pageNum == null) continue;

      final localRows = await db.query(
        'page_progress',
        where: 'pageNumber = ? AND profileId = ?',
        whereArgs: [pageNum, localProfile.id],
      );

      if (localRows.isEmpty) {
        // Cloud has it, local doesn't — insert
        cloudData.remove('updatedAt');
        await db.insert(
          'page_progress',
          cloudData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
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
          'reviewCount': cloudReviews > localReviews
              ? cloudReviews
              : localReviews,
          'memorizedAt': cloudData['memorizedAt'] ?? local['memorizedAt'],
        };

        await db.update(
          'page_progress',
          merged,
          where: 'pageNumber = ? AND profileId = ?',
          whereArgs: [pageNum, localProfile.id],
        );
      }
    }
    AppLogger.info(
      'Sync',
      '[SYNC] Progress merged (${cloudProgress.docs.length} cloud records)',
    );

    // Push merged local progress back to cloud
    final allProgress = await db.query(
      'page_progress',
      where: 'profileId = ?',
      whereArgs: [localProfile.id],
    );
    for (final row in allProgress) {
      await _userDoc(
        uid,
      ).collection('progress').doc('${row['pageNumber']}').set({
        ...row,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Push local sessions that cloud might not have
    final localSessions = await db.query(
      'session_history',
      where: 'profileId = ?',
      whereArgs: [localProfile.id],
    );
    for (final row in localSessions) {
      await _userDoc(uid).collection('sessions').doc(row['id'] as String).set({
        ...row,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Streak: take max
    final localStreak = await _db.getStreak(localProfile.id);
    final cloudStreak = await _userDoc(
      uid,
    ).collection('meta').doc('streak').get();
    if (cloudStreak.exists) {
      final cloudDays = cloudStreak.data()!['totalActiveDays'] as int? ?? 0;
      final maxDays = localStreak.totalActiveDays > cloudDays
          ? localStreak.totalActiveDays
          : cloudDays;
      final mergedStreak = StreakData(
        totalActiveDays: maxDays,
        lastActiveDate: localStreak.lastActiveDate,
      );
      await _writeStreak(uid, mergedStreak);
    } else {
      await _writeStreak(uid, localStreak);
    }
  }

  // ════════════════════════════════════════════
  // ACCOUNT DELETION
  // ════════════════════════════════════════════

  /// Delete all user data from Firestore and Firebase Auth.
  ///
  /// Use when user wants to completely remove their cloud account.
  ///
  /// Path order (§5 #11 / §8 Phase 8 task 2):
  /// 1. **`DELETE /v1/me` first** — the server recursively deletes the whole
  ///    `users/{uid}` tree (including server-only docs the rules never let
  ///    this client see: facts log, SRS placeholders, plural profiles,
  ///    `meta/server`...) AND the Firebase Auth user via the Admin SDK.
  ///    This is the only path that survives the Phase 8 deny-all rules flip.
  /// 2. **Legacy client-side cascade as fallback** when the API is
  ///    unreachable/refuses — byte-for-byte the pre-§5#11 behavior.
  ///
  /// Deliberately NOT gated by [_syncGated]: account deletion must always
  /// work, force-update gate or not.
  Future<void> deleteAccount(String uid) async {
    _setStatus(SyncStatus.syncing);

    // Quiesce the facts write path FIRST (§5 #11): a drain in flight — or
    // one scheduled by the 2s enqueue debounce ("finish session, delete
    // account" is a realistic sequence) — could POST /v1/me/facts while
    // the server deletes the tree. The deletion is not transactional and
    // the ID token stays valid for its remaining lifetime even after
    // `auth.deleteUser`, so a late flush would recreate docs under the
    // deleted uid, permanently orphaned (no client can ever authenticate
    // as that uid again). Stop new drains, await any in-flight one, then
    // drop the uid's queued rows.
    await _syncWorker?.quiesceForAccountDeletion();
    await _outbox?.clearForUid(uid);

    var dataDeleted = false;
    try {
      final outcome = await _accountApi?.deleteAccount();
      if (outcome != null && outcome.deleted) {
        dataDeleted = true;
        AppLogger.info(
          'Sync',
          '[SYNC] Account deleted via DELETE /v1/me '
              '(authUserDeleted=${outcome.authUserDeleted})',
        );
        if (!outcome.authUserDeleted) {
          // Server deployment without the auth half — keep the original
          // client-side step two (its requires-recent-login error surfaces
          // to the caller exactly as before).
          try {
            await FirebaseAuth.instance.currentUser?.delete();
          } catch (e) {
            AppLogger.info('Sync', '[SYNC] Auth user deletion error: $e');
            _lastError = e.toString();
            _setStatus(SyncStatus.error);
            rethrow;
          }
        }
        _setStatus(SyncStatus.idle);
        return;
      }

      // Fallback: the API was unreachable (offline, outage, no token) —
      // legacy client-side cascade. It can only touch what the rules let
      // THIS client touch: server-only collections (facts,
      // srs_placeholders, plural profiles, meta/manzil_rotation,
      // meta/server) are denied and stay behind — only the API path is a
      // complete deletion (operator cleanup: docs/PHASE8_LOCKDOWN_RUNBOOK.md).
      AppLogger.info(
        'Sync',
        '[SYNC] DELETE /v1/me unavailable — falling back to client-side '
            'cascade deletion',
      );
      // Subcollections the rules allow this client to LIST. `meta` is NOT
      // listable at all ("rules are not filters": a collection query must
      // be provable for every possible doc, and meta reads are allowed
      // only for the ids 'settings'/'streak') — its two reachable docs
      // are deleted directly below. A permission-denied collection is
      // skipped, never fatal: `user.delete()` must always be reached.
      for (final collection in [
        'progress',
        'sessions',
        'plans',
        'flashcards',
        'flashcard_reviews',
      ]) {
        try {
          final snap = await _userDoc(uid).collection(collection).get();
          for (final doc in snap.docs) {
            await doc.reference.delete();
          }
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied') rethrow;
          AppLogger.warn(
            'Sync',
            '[SYNC] fallback cascade: "$collection" denied — skipped',
          );
        }
      }
      for (final docId in ['settings', 'streak']) {
        try {
          await _userDoc(uid).collection('meta').doc(docId).delete();
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied') rethrow;
        }
      }
      // Delete user root document.
      try {
        await _userDoc(uid).delete();
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
        AppLogger.warn('Sync', '[SYNC] fallback cascade: root doc denied');
      }
      AppLogger.info('Sync', '[SYNC] Client-deletable cloud data deleted '
          'for $uid');

      // Delete Firebase Auth user
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.delete();
        AppLogger.info('Sync', '[SYNC] Firebase Auth user deleted');
      }
      dataDeleted = true;

      _setStatus(SyncStatus.idle);
    } catch (e) {
      AppLogger.info('Sync', '[SYNC] Account deletion error: $e');
      _lastError = e.toString();
      _setStatus(SyncStatus.error);
      rethrow;
    } finally {
      // Deletion failed and the account survives → sync must come back.
      // On success the quiesce holds until sign-out clears it (the
      // profile-screen flow signs out immediately after).
      if (!dataDeleted) {
        _syncWorker?.resumeAfterFailedAccountDeletion();
      }
    }
  }

  /// Push a single flashcard update.
  Future<void> syncFlashcard(String uid, Flashcard card) async {
    if (_syncGated) return;
    try {
      await _userDoc(uid).collection('flashcards').doc(card.id).set({
        ...card.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _recordBackgroundError('Flashcard push', e);
    }
  }

  /// Push a flashcard review.
  Future<void> syncFlashcardReview(String uid, FlashcardReview review) async {
    if (_syncGated) return;
    try {
      final reviewId = review.id;
      await _userDoc(uid).collection('flashcard_reviews').doc(reviewId).set({
        ...review.toMap(),
        'syncedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _recordBackgroundError('Flashcard review push', e);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }
}
