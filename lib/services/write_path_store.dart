import 'package:shared_preferences/shared_preferences.dart';

/// Cached per-user sync flags from `GET /v1/me/bootstrap` plus the local
/// markers that drive the one-time backfill (roadmap §7.3 / §8 Phase 4).
///
/// - `writePath` is served per-user by the server (§8 Phase 4b task 4):
///   `legacy` = keep the direct-Firestore CloudSyncService pushes AND
///   enqueue facts (additive soak); `facts` = the outbox IS the write path
///   and the corresponding legacy pushes are skipped. The cached value is
///   read synchronously by the providers; **offline default is `legacy`**.
/// - `datasetEpoch` is the server data-generation id (§5). On mismatch the
///   client clears the outbox and its backfill markers so history is
///   re-submitted against the new epoch.
/// - `minSupportedBuild` backs the §5 force-update gate: builds below it
///   BLOCK SYNC ONLY (outbox drain + legacy CloudSyncService pushes pause)
///   while the offline core loop keeps working untouched — the §5 rule is
///   "never block the offline loop". See [updateRequired].
class WritePathStore {
  static const String legacy = 'legacy';
  static const String facts = 'facts';

  static const String _writePathPrefix = 'sync.writePath.';
  static const String _backfillPrefix = 'sync.backfillDone.';
  static const String _epochKey = 'sync.datasetEpoch';
  static const String _minBuildKey = 'sync.minSupportedBuild';

  final SharedPreferences _prefs;

  WritePathStore(this._prefs);

  /// The running app's build number (pubspec `+N`), set once at startup from
  /// `PackageInfo`. Null (e.g. before startup wiring, or an unparsable
  /// build string) disables the gate — fail-open, sync keeps working.
  int? currentBuildNumber;

  /// Last `minSupportedBuild` seen from the server (`/v1/me/bootstrap`);
  /// persisted so the gate survives restarts while offline. Default 0 =
  /// nothing blocked before first server contact.
  int get minSupportedBuild => _prefs.getInt(_minBuildKey) ?? 0;

  Future<void> setMinSupportedBuild(int value) =>
      _prefs.setInt(_minBuildKey, value);

  /// §5 force-update gate: true when this build is below the server's
  /// `minSupportedBuild`. While true, the SyncWorker skips drains and
  /// CloudSyncService skips its legacy pushes/pulls; enqueueing (and the
  /// whole offline core loop) continues unaffected, so nothing is lost —
  /// the outbox drains as soon as the updated build runs. Lifts without an
  /// app update if the server lowers `minSupportedBuild` (re-read on every
  /// bootstrap-meta refresh).
  bool get updateRequired {
    final build = currentBuildNumber;
    return build != null && build < minSupportedBuild;
  }

  /// The cached write path for [uid]; `legacy` when unknown/offline.
  String pathFor(String uid) =>
      _prefs.getString('$_writePathPrefix$uid') ?? legacy;

  /// Whether legacy CloudSyncService pushes should be SKIPPED for [uid].
  bool isFactsUser(String? uid) => uid != null && pathFor(uid) == facts;

  Future<void> setPathFor(String uid, String path) async {
    if (path != legacy && path != facts) path = legacy;
    await _prefs.setString('$_writePathPrefix$uid', path);
  }

  /// Last datasetEpoch seen from the server (null before first contact).
  String? get datasetEpoch => _prefs.getString(_epochKey);

  Future<void> setDatasetEpoch(String epoch) =>
      _prefs.setString(_epochKey, epoch);

  /// Forget the stored epoch (409 reset without a server-provided epoch):
  /// the next server contact adopts the current one silently.
  Future<void> clearDatasetEpoch() async {
    await _prefs.remove(_epochKey);
  }

  bool backfillDoneFor(String uid) =>
      _prefs.getBool('$_backfillPrefix$uid') ?? false;

  Future<void> markBackfillDone(String uid) =>
      _prefs.setBool('$_backfillPrefix$uid', true);

  Future<void> clearBackfillMarkerFor(String uid) async {
    await _prefs.remove('$_backfillPrefix$uid');
  }

  /// Epoch-reset policy support: forget every per-uid backfill marker so
  /// each account re-backfills against the new epoch.
  Future<void> clearAllBackfillMarkers() async {
    for (final key in _prefs.getKeys().toList()) {
      if (key.startsWith(_backfillPrefix)) {
        await _prefs.remove(key);
      }
    }
  }
}
