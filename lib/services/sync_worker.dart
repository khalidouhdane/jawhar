import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:hifz_core/hifz_core.dart';
import 'package:quran_app/config/api_config.dart';
import 'package:quran_app/services/outbox_service.dart';
import 'package:quran_app/services/write_path_store.dart';
import 'package:quran_app/utils/app_logger.dart';

/// Outcome of the most recent drain attempt — surfaced on the debug screen.
class SyncDrainResult {
  final DateTime atUtc;
  final String trigger;
  final int sent;
  final int applied;
  final int skipped;
  final int poisoned;
  final int deferred;
  final String? error;

  const SyncDrainResult({
    required this.atUtc,
    required this.trigger,
    this.sent = 0,
    this.applied = 0,
    this.skipped = 0,
    this.poisoned = 0,
    this.deferred = 0,
    this.error,
  });

  bool get ok => error == null;

  @override
  String toString() =>
      '[$trigger] sent=$sent applied=$applied skipped=$skipped '
      'poisoned=$poisoned deferred=$deferred'
      '${error == null ? '' : ' error=$error'}';
}

/// Drains the uid-partitioned outbox to `POST /v1/me/facts` (roadmap §7).
///
/// Triggers: app start ([start]), sign-in (auth listener), app foreground
/// (lifecycle observer), connectivity regained (injected stream), every
/// enqueue (outbox listener, debounced — covers "post-session"), manual
/// ([reconcile] from the debug screen), and exponential-backoff retries
/// after retryable failures.
///
/// Correctness rules implemented here:
/// - rows are deleted ONLY on a per-fact `applied`/idempotent-skip
///   acknowledgment from the server; a kill mid-drain just re-sends the
///   same UUID-keyed facts, which the server's (uid, fact.id) upsert
///   answers with `applied:false` — no loss, no double-apply;
/// - per-item non-retryable errors poison exactly that row (one poisoned
///   item never blocks the queue, §5);
/// - every facts POST asserts the stored epoch via `X-Dataset-Epoch`, so a
///   stale outbox is refused server-side (409) BEFORE any write; the 409 —
///   like an epoch mismatch on ANY reply body — executes the reset policy:
///   clear the outbox + all backfill markers, adopt the new epoch, then
///   re-backfill and re-drain (§5 / §7.3);
/// - on a uid's first drain the whole pending set is re-sequenced into
///   fact-chronological order after the backfill enqueue, so history flushes
///   before today (server streak/SRS fold ordering contract);
/// - 403s are retried with a cap ([max403Attempts]) instead of immediately
///   poisoned — they can be environmental (App Check rollout, middleware
///   misconfig); 422/400 stay immediate poison;
/// - `writePath` is read from the bootstrap response and cached per uid in
///   [WritePathStore] (offline default `legacy`).
///
/// Derived-state deltas in facts responses are NOT yet applied to the
/// local cache — that is the Phase 5 "canonical server state overwrites on
/// ack" task; during the Phase 4 legacy soak the local writer remains
/// authoritative on-device.
class SyncWorker extends ChangeNotifier with WidgetsBindingObserver {
  final OutboxService _outbox;
  final WritePathStore _store;
  final Listenable _authChanges;
  final String? Function() _uidProvider;
  final Future<String?> Function({bool forceRefresh}) _idTokenProvider;
  final String _baseUrl;
  final http.Client? _injectedClient;
  final int _batchSize;
  final Duration _requestTimeout;
  final bool _observeAppLifecycle;

  StreamSubscription<dynamic>? _connectivitySub;
  Timer? _debounce;
  Timer? _retryTimer;
  final Random _jitter = Random();

  String? _lastSignedInUid;
  bool _draining = false;
  bool _drainQueued = false;
  int _failureStreak = 0;
  bool _disposed = false;

  SyncDrainResult? _lastDrainResult;
  DateTime? _lastBootstrapAtUtc;

  SyncWorker({
    required OutboxService outbox,
    required WritePathStore store,
    required Listenable authChanges,
    required String? Function() uidProvider,
    required Future<String?> Function({bool forceRefresh}) idTokenProvider,
    String? apiBaseUrl,
    http.Client? httpClient,
    Stream<dynamic>? connectivityChanges,
    bool observeAppLifecycle = true,
    int batchSize = 50,
    Duration requestTimeout = const Duration(seconds: 20),
  }) : _outbox = outbox,
       _store = store,
       _authChanges = authChanges,
       _uidProvider = uidProvider,
       _idTokenProvider = idTokenProvider,
       _baseUrl = _normalizeBase(apiBaseUrl ?? kJawharApiBaseUrl),
       _injectedClient = httpClient,
       _batchSize = batchSize,
       _requestTimeout = requestTimeout,
       _observeAppLifecycle = observeAppLifecycle {
    _authChanges.addListener(_handleAuthChanged);
    _outbox.addListener(_handleEnqueue);
    if (connectivityChanges != null) {
      _connectivitySub = connectivityChanges.listen(_handleConnectivity);
    }
    if (_observeAppLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  static String _normalizeBase(String raw) =>
      raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;

  // ── Debug-screen surface ──

  SyncDrainResult? get lastDrainResult => _lastDrainResult;
  DateTime? get lastBootstrapAtUtc => _lastBootstrapAtUtc;
  bool get isDraining => _draining;
  String? get datasetEpoch => _store.datasetEpoch;

  /// Cached write path for the signed-in user (`legacy` when signed out
  /// or unknown).
  String get currentWritePath {
    final uid = _uidProvider();
    return uid == null ? WritePathStore.legacy : _store.pathFor(uid);
  }

  // ── Triggers ──

  /// App-start trigger: refresh bootstrap meta, then drain.
  Future<void> start() async {
    await refreshBootstrapMeta();
    await _drain('app-start');
  }

  /// Manual reconcile (debug screen, §7.3): re-run the full backfill for
  /// the signed-in uid, refresh bootstrap meta, then drain.
  Future<void> reconcile() async {
    final uid = _uidProvider();
    if (uid == null) return;
    await _store.clearBackfillMarkerFor(uid);
    await refreshBootstrapMeta();
    await _drain('reconcile');
  }

  void _handleAuthChanged() {
    if (_disposed) return;
    final uid = _uidProvider();
    if (uid == null) {
      _lastSignedInUid = null;
      _retryTimer?.cancel();
      return;
    }
    if (uid == _lastSignedInUid) return;
    _lastSignedInUid = uid;
    _failureStreak = 0;
    unawaited(() async {
      await refreshBootstrapMeta();
      await _drain('sign-in');
    }());
  }

  void _handleEnqueue() {
    if (_disposed) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () {
      unawaited(_drain('enqueue'));
    });
  }

  void _handleConnectivity(dynamic event) {
    if (_disposed) return;
    final text = event.toString();
    // connectivity_plus emits List<ConnectivityResult>; "none" alone means
    // offline. Anything else is a (re)gained transport.
    if (text.contains('none') && !text.contains(',')) return;
    unawaited(_drain('connectivity'));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_drain('foreground'));
    }
  }

  // ── Bootstrap meta (writePath + datasetEpoch) ──

  /// Fetch `GET /v1/me/bootstrap` and cache `writePath` + check
  /// `datasetEpoch`. Lenient: a missing field or any failure leaves the
  /// cached values untouched (offline default stays `legacy`).
  Future<void> refreshBootstrapMeta() async {
    final uid = _uidProvider();
    if (uid == null || _baseUrl.isEmpty) return;
    final token = await _token();
    if (token == null) return;

    final client = _injectedClient ?? http.Client();
    try {
      final response = await client
          .get(Uri.parse('$_baseUrl/v1/me/bootstrap'), headers: _headers(token))
          .timeout(_requestTimeout);
      if (response.statusCode != 200) {
        AppLogger.warn(
          'Sync',
          'bootstrap meta HTTP ${response.statusCode}; keeping cache',
        );
        return;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return;
      final writePath = decoded['writePath'];
      if (writePath is String && writePath.isNotEmpty) {
        await _store.setPathFor(uid, writePath);
      }
      final epoch = decoded['datasetEpoch'];
      if (epoch is String && epoch.isNotEmpty) {
        await _handleEpoch(epoch);
      }
      _lastBootstrapAtUtc = DateTime.now().toUtc();
      notifyListeners();
    } catch (e) {
      AppLogger.warn('Sync', 'bootstrap meta fetch failed: $e');
    } finally {
      if (_injectedClient == null) client.close();
    }
  }

  /// Returns true when an epoch reset was executed.
  Future<bool> _handleEpoch(String serverEpoch) async {
    final stored = _store.datasetEpoch;
    if (stored == null) {
      await _store.setDatasetEpoch(serverEpoch);
      return false;
    }
    if (stored == serverEpoch) return false;
    AppLogger.warn(
      'Sync',
      'datasetEpoch mismatch (stored=$stored server=$serverEpoch) — '
          'executing reset policy',
    );
    await _executeEpochReset(serverEpoch);
    return true;
  }

  /// §5 reset policy: queued facts target a dead epoch — wipe the outbox
  /// and the backfill markers; local SQLite history stays and is
  /// re-enqueued by the next backfill run against the new epoch. With a
  /// null [newEpoch] (a 409 body without one) the stored epoch is cleared
  /// so the next server contact adopts the current one silently.
  Future<void> _executeEpochReset(String? newEpoch) async {
    await _outbox.clearAll();
    await _store.clearAllBackfillMarkers();
    if (newEpoch != null && newEpoch.isNotEmpty) {
      await _store.setDatasetEpoch(newEpoch);
    } else {
      await _store.clearDatasetEpoch();
    }
    notifyListeners();
  }

  // ── Drain ──

  /// Public manual trigger (also used by the debug screen).
  Future<void> requestDrain({String trigger = 'manual'}) => _drain(trigger);

  Future<void> _drain(String trigger) async {
    if (_disposed || _baseUrl.isEmpty) return;
    if (_draining) {
      _drainQueued = true;
      return;
    }
    _draining = true;
    notifyListeners();

    var sent = 0, applied = 0, skipped = 0, poisoned = 0, deferred = 0;
    String? failure;

    try {
      final uid = _uidProvider();
      if (uid == null) return;

      // Adoption + one-time backfill before any flush (§7.2 / §7.3).
      await _outbox.adoptOrphanRows(uid);
      if (!_store.backfillDoneFor(uid)) {
        await _outbox.enqueueBackfillForUid(uid);
        // Adopted/live rows enqueued before this first drain hold LOWER
        // seqs than the just-enqueued history; flushed in seq order,
        // today's session would land before months of history and the
        // server's streak fold (counts only dates after lastActiveDate)
        // would skip every historical day forever. Re-sequence the uid's
        // whole pending set into fact-chronological order first.
        await _outbox.resequencePendingForUid(uid);
        await _store.markBackfillDone(uid);
      }

      var oneByOne = false;
      while (!_disposed) {
        // A signed-out switch mid-drain stops the flush immediately.
        if (_uidProvider() != uid) break;
        final rows = await _outbox.pendingForUid(
          uid,
          limit: oneByOne ? 1 : _batchSize,
        );
        if (rows.isEmpty) break;

        final batch = await _decodeBatch(rows);
        poisoned += batch.poisonedCount;
        if (batch.rows.isEmpty) continue;

        sent += batch.rows.length;
        final outcome = await _postBatch(uid, batch);
        applied += outcome.applied;
        skipped += outcome.skipped;
        poisoned += outcome.poisoned;
        deferred += outcome.deferred;

        if (outcome.epochReset) {
          // Re-enter via a fresh drain: the wiped outbox will be
          // re-populated by the backfill on the next pass.
          _drainQueued = true;
          break;
        }
        if (outcome.splitBatch && !oneByOne && batch.rows.length > 1) {
          // Batch-level rejection: isolate the poison pill row by row.
          oneByOne = true;
          continue;
        }
        if (!outcome.continueDraining) {
          failure = outcome.error;
          _scheduleBackoffRetry();
          break;
        }
        if (outcome.deferred > 0) {
          // Retryable per-item errors stay pending; stop so the backoff
          // timer (not a hot loop) retries them.
          failure = 'retryable per-item errors';
          _scheduleBackoffRetry();
          break;
        }
      }

      if (failure == null) _failureStreak = 0;
    } catch (e) {
      failure = e.toString();
      _scheduleBackoffRetry();
    } finally {
      _lastDrainResult = SyncDrainResult(
        atUtc: DateTime.now().toUtc(),
        trigger: trigger,
        sent: sent,
        applied: applied,
        skipped: skipped,
        poisoned: poisoned,
        deferred: deferred,
        error: failure,
      );
      AppLogger.info('Sync', 'Outbox drain $_lastDrainResult');
      _draining = false;
      notifyListeners();
      if (_drainQueued && !_disposed) {
        _drainQueued = false;
        unawaited(_drain('requeued'));
      }
    }
  }

  Future<_DecodedBatch> _decodeBatch(List<OutboxRow> rows) async {
    final good = <OutboxRow>[];
    final payloads = <Map<String, dynamic>>[];
    var poisonedCount = 0;
    for (final row in rows) {
      try {
        final decoded = jsonDecode(row.payload);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('payload is not a JSON object');
        }
        payloads.add(decoded);
        good.add(row);
      } catch (e) {
        // Unparseable local payload can never succeed — poison, keep for
        // diagnostics (replaces today's silent drops).
        await _outbox.poisonRow(row.seq, 'local payload: $e');
        poisonedCount++;
      }
    }
    return _DecodedBatch(good, payloads, poisonedCount);
  }

  /// Poison cap for 403s — unlike 422/400, a 403 can be transient or
  /// environmental (App Check enforcement rollout, middleware misconfig,
  /// clock-skewed token), so rows survive [max403Attempts] retries before
  /// being poisoned instead of an entire backlog dying on one bad hour.
  static const int max403Attempts = 10;

  Future<_BatchOutcome> _postBatch(String uid, _DecodedBatch batch) async {
    var token = await _token();
    if (token == null) {
      return _BatchOutcome.fail('no Firebase ID token');
    }

    // §5 epoch arbitration, client half: assert the data generation this
    // outbox belongs to so the SERVER refuses a stale flush BEFORE any
    // write (the 200-body check alone learns of a bump only after up to a
    // full batch has already landed in the new generation).
    Map<String, String> factsHeaders(String token) {
      final stored = _store.datasetEpoch;
      return {
        ..._headers(token),
        if (stored != null && stored.isNotEmpty) 'X-Dataset-Epoch': stored,
      };
    }

    final body = jsonEncode({'facts': batch.payloads});
    final client = _injectedClient ?? http.Client();
    try {
      var response = await client
          .post(
            Uri.parse('$_baseUrl/v1/me/facts'),
            headers: factsHeaders(token),
            body: body,
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 401) {
        // Expired token: refresh once and retry once (§5 error rules).
        token = await _token(forceRefresh: true);
        if (token == null) return _BatchOutcome.fail('token refresh failed');
        response = await client
            .post(
              Uri.parse('$_baseUrl/v1/me/facts'),
              headers: factsHeaders(token),
              body: body,
            )
            .timeout(_requestTimeout);
      }

      if (response.statusCode == 200) {
        return _handleFactsResponse(batch, response.body);
      }

      if (response.statusCode == 409 &&
          _errorCode(response.body) == 'dataset-epoch-mismatch') {
        // The server refused the whole batch: our stored epoch is stale.
        // Execute the §5 reset policy NOW — this branch is the only path
        // when the guard fires, so without it the 409 would loop forever
        // in the retryable bucket below. The 409 body carries the current
        // epoch for direct adoption.
        AppLogger.warn(
          'Sync',
          'datasetEpoch refused by server (409) — executing reset policy',
        );
        await _executeEpochReset(_epochFromBody(response.body));
        return _BatchOutcome.epochResetOutcome();
      }

      if (response.statusCode == 422 || response.statusCode == 400) {
        // Deterministic batch-level rejection. With a single row we know
        // the culprit; otherwise ask the drain loop to retry row-by-row.
        if (batch.rows.length == 1) {
          await _outbox.poisonRow(
            batch.rows.single.seq,
            'HTTP ${response.statusCode}: ${_snippet(response.body)}',
          );
          return _BatchOutcome.poisonedOne();
        }
        return _BatchOutcome.split();
      }

      if (response.statusCode == 403) {
        // Retryable-with-cap (see [max403Attempts]).
        final reason = 'HTTP 403: ${_snippet(response.body)}';
        var cappedPoisoned = 0;
        final bumpSeqs = <int>[];
        for (final row in batch.rows) {
          if (row.attempts + 1 >= max403Attempts) {
            await _outbox.poisonRow(
              row.seq,
              '$reason (after ${row.attempts + 1} attempts)',
            );
            cappedPoisoned++;
          } else {
            bumpSeqs.add(row.seq);
          }
        }
        if (bumpSeqs.isNotEmpty) {
          await _outbox.bumpAttempts(bumpSeqs, reason);
        }
        return _BatchOutcome.fail(reason, poisoned: cappedPoisoned);
      }

      // 429 / 5xx → retryable.
      final reason = 'HTTP ${response.statusCode}';
      await _outbox.bumpAttempts([for (final r in batch.rows) r.seq], reason);
      return _BatchOutcome.fail(reason);
    } on Exception catch (e) {
      // Network / timeout → retryable, rows stay pending.
      await _outbox.bumpAttempts([
        for (final r in batch.rows) r.seq,
      ], e.toString());
      return _BatchOutcome.fail(e.toString());
    } finally {
      if (_injectedClient == null) client.close();
    }
  }

  /// `error.code` from a §5 error envelope; null when unparseable.
  static String? _errorCode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final code = error['code'];
          if (code is String) return code;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Top-level `datasetEpoch` from a response body; null when absent.
  static String? _epochFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final epoch = decoded['datasetEpoch'];
        if (epoch is String && epoch.isNotEmpty) return epoch;
      }
    } catch (_) {}
    return null;
  }

  Future<_BatchOutcome> _handleFactsResponse(
    _DecodedBatch batch,
    String body,
  ) async {
    FactsResponse parsed;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('response is not a JSON object');
      }
      parsed = FactsResponse.fromJson(decoded);
    } catch (e) {
      await _outbox.bumpAttempts([
        for (final r in batch.rows) r.seq,
      ], 'bad 200 body: $e');
      return _BatchOutcome.fail('unparseable facts response: $e');
    }

    if (await _handleEpoch(parsed.datasetEpoch.value)) {
      return _BatchOutcome.epochResetOutcome();
    }

    final resultsById = <String, FactResult>{
      for (final result in parsed.results) result.id: result,
    };

    var applied = 0, skipped = 0, poisoned = 0, deferred = 0;
    final ackedSeqs = <int>[];
    final retrySeqs = <int>[];
    String retryError = '';

    for (final row in batch.rows) {
      final result = resultsById[row.entityId];
      if (result == null) {
        // Server did not acknowledge this fact at all — keep it pending.
        deferred++;
        retrySeqs.add(row.seq);
        retryError = 'fact missing from results';
        continue;
      }
      final error = result.error;
      if (error == null) {
        // applied:true (new) or applied:false (idempotent replay) — both
        // are durable acknowledgments (§5: a replay is never an error).
        if (result.applied) {
          applied++;
        } else {
          skipped++;
        }
        ackedSeqs.add(row.seq);
      } else if (error.retryable) {
        deferred++;
        retrySeqs.add(row.seq);
        retryError = '${error.code}: ${error.message}';
      } else {
        await _outbox.poisonRow(row.seq, '${error.code}: ${error.message}');
        poisoned++;
      }
    }

    await _outbox.deleteRows(ackedSeqs);
    if (retrySeqs.isNotEmpty) {
      await _outbox.bumpAttempts(retrySeqs, retryError);
    }

    // NOTE: parsed.derived (progress/cards/streak/plans deltas) is
    // intentionally not applied to SQLite yet — Phase 5 task. See class
    // docs.
    return _BatchOutcome.ok(
      applied: applied,
      skipped: skipped,
      poisoned: poisoned,
      deferred: deferred,
    );
  }

  // ── Plumbing ──

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    'X-Client-Core-Version': hifzCoreVersion,
  };

  Future<String?> _token({bool forceRefresh = false}) async {
    try {
      final token = await _idTokenProvider(forceRefresh: forceRefresh);
      return (token == null || token.isEmpty) ? null : token;
    } catch (e) {
      AppLogger.warn('Sync', 'ID token fetch failed: $e');
      return null;
    }
  }

  void _scheduleBackoffRetry() {
    if (_disposed) return;
    _failureStreak = min(_failureStreak + 1, 6);
    final base = Duration(seconds: 30 * (1 << (_failureStreak - 1)));
    final capped = base > const Duration(minutes: 15)
        ? const Duration(minutes: 15)
        : base;
    final delay = capped + Duration(seconds: _jitter.nextInt(6));
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () => unawaited(_drain('backoff-retry')));
    AppLogger.info(
      'Sync',
      'Drain retry scheduled in ${delay.inSeconds}s (streak $_failureStreak)',
    );
  }

  static String _snippet(String body, [int max = 300]) =>
      body.length <= max ? body : body.substring(0, max);

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    _retryTimer?.cancel();
    unawaited(_connectivitySub?.cancel());
    _authChanges.removeListener(_handleAuthChanged);
    _outbox.removeListener(_handleEnqueue);
    if (_observeAppLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }
}

class _DecodedBatch {
  final List<OutboxRow> rows;
  final List<Map<String, dynamic>> payloads;
  final int poisonedCount;

  const _DecodedBatch(this.rows, this.payloads, this.poisonedCount);
}

class _BatchOutcome {
  final bool continueDraining;
  final bool splitBatch;
  final bool epochReset;
  final int applied;
  final int skipped;
  final int poisoned;
  final int deferred;
  final String? error;

  const _BatchOutcome._({
    required this.continueDraining,
    this.splitBatch = false,
    this.epochReset = false,
    this.applied = 0,
    this.skipped = 0,
    this.poisoned = 0,
    this.deferred = 0,
    this.error,
  });

  factory _BatchOutcome.ok({
    int applied = 0,
    int skipped = 0,
    int poisoned = 0,
    int deferred = 0,
  }) => _BatchOutcome._(
    continueDraining: true,
    applied: applied,
    skipped: skipped,
    poisoned: poisoned,
    deferred: deferred,
  );

  factory _BatchOutcome.fail(String error, {int poisoned = 0}) =>
      _BatchOutcome._(continueDraining: false, error: error, poisoned: poisoned);

  factory _BatchOutcome.split() =>
      const _BatchOutcome._(continueDraining: true, splitBatch: true);

  factory _BatchOutcome.poisonedOne() =>
      const _BatchOutcome._(continueDraining: true, poisoned: 1);

  factory _BatchOutcome.epochResetOutcome() =>
      const _BatchOutcome._(continueDraining: false, epochReset: true);
}
