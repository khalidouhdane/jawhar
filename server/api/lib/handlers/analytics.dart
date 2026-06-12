import 'dart:convert';

import 'package:hifz_core/hifz_core.dart';
import 'package:shelf/shelf.dart';

import '../gateway/firestore_gateway.dart';
import '../middleware/auth.dart';
import '../store/legacy_docs.dart';
import 'plan_get.dart' show PlanDateError, resolvePlanDate;

/// `GET /v1/me/analytics/snapshot` (authenticated; `/v1/me/analytics` is an
/// alias) — roadmap §5 #10 / §8 Phase 6 task 1.
///
/// Weekly snapshot computed on demand with the shared `hifz_core`
/// [AnalyticsCalculators] (the same numbers the device computes — golden
/// parity fixtures in `packages/hifz_core/test/fixtures/analytics/`),
/// cached in a 24h SERVER-ONLY doc (`users/{uid}/analytics/...` — no rules
/// path, so clients can neither read nor poison it). No scheduler.
///
/// Dual-window inputs (R2): sessions/plans/progress are read from the
/// legacy mirror collections, which the facts write path ALSO writes — so
/// during Phases 4–6 the snapshot covers legacy-writer history and
/// facts-writer history alike.
///
/// Query parameters:
/// - `profileId` — defaults to the mirrored profile (root doc); any other
///   value is 404 until Phase 5 plural hydration.
/// - `start`/`end` (`YYYY-MM-DD`, inclusive) — explicit window, end
///   defaults to start+6; window is capped at 31 days.
/// - else `date`/`tzOffsetMinutes` resolve the client-local day exactly as
///   `GET /v1/me/plan` does, and the window is the trailing 7 days.
Handler analyticsHandler({
  required FirestoreGateway gateway,
  DateTime Function()? nowUtc,
}) {
  final now = nowUtc ?? _utcNow;
  return (Request request) async {
    final params = request.url.queryParameters;

    // ── Resolve the window ──
    DateTime start;
    DateTime end;
    try {
      final rawStart = params['start'];
      if (rawStart != null) {
        start = _parseIsoDay('start', rawStart);
        final rawEnd = params['end'];
        end = rawEnd != null
            ? _parseIsoDay('end', rawEnd)
            : start.add(const Duration(days: 6));
      } else {
        end = resolvePlanDate(
          date: params['date'],
          tzOffsetMinutes: params['tzOffsetMinutes'],
          nowUtc: now(),
        );
        start = end.subtract(const Duration(days: 6));
      }
    } on PlanDateError catch (e) {
      return _error(400, 'invalid-argument', e.message);
    }
    if (end.isBefore(start)) {
      return _error(400, 'invalid-argument', 'end must not precede start.');
    }
    if (end.difference(start).inDays > 31) {
      return _error(400, 'invalid-argument', 'Window is capped at 31 days.');
    }

    final uid = request.uid;

    // ── Profile (legacy mirror root doc — same rules as plan GET) ──
    final profileDoc = await gateway.getDoc(UserPaths.userDoc(uid));
    MemoryProfile? profile;
    if (profileDoc != null) {
      try {
        profile = MemoryProfile.fromMap(profileDoc);
      } on Object {
        profile = null;
      }
    }
    if (profile == null) {
      return _error(
        404,
        'not-found',
        'No profile is mirrored in Firestore for this account yet — '
        'sign in on a device and let it sync first.',
      );
    }
    final requestedProfileId = params['profileId'];
    if (requestedProfileId != null && !WireCodec.isSafeId(requestedProfileId)) {
      // The id is interpolated into the cache doc path — charset-gate it
      // (a `/` would change the Firestore path depth).
      return _error(
        400,
        'invalid-argument',
        'profileId must be 1-64 chars of [A-Za-z0-9_:.-].',
      );
    }
    if (requestedProfileId != null && requestedProfileId != profile.id) {
      return _error(
        404,
        'not-found',
        'Profile "$requestedProfileId" is not mirrored for this account.',
      );
    }

    final startIso = _isoDay(start);
    final endIso = _isoDay(end);
    // The mirrored profile id is client-written (legacy rules) — if it is
    // not path-safe, skip the cache rather than build a broken doc path.
    final cachePath = WireCodec.isSafeId(profile.id)
        ? UserPaths.analyticsCacheDoc(uid, profile.id, startIso, endIso)
        : null;

    // ── 24h cache ──
    final cached = cachePath == null ? null : await gateway.getDoc(cachePath);
    if (cached != null) {
      final computedAt = DateTime.tryParse(cached['computedAtUtc'] as String? ?? '');
      final payload = cached['payload'];
      if (computedAt != null &&
          payload is Map<String, dynamic> &&
          now().difference(computedAt) < const Duration(hours: 24)) {
        return Response.ok(
          jsonEncode(payload),
          headers: const {'content-type': 'application/json'},
        );
      }
    }

    // ── Compute from the legacy mirror (facts-written docs included) ──
    final sessions = <SessionRecord>[];
    for (final row in await gateway.query(UserPaths.sessionsCollection(uid))) {
      try {
        sessions.add(SessionRecord.fromMap(row.data));
      } on Object {
        // One bad doc must not take the endpoint down.
      }
    }
    final plans = <DailyPlan>[];
    for (final row in await gateway.query(UserPaths.plansCollection(uid))) {
      try {
        plans.add(DailyPlan.fromMap(row.data));
      } on Object {
        // Skip malformed rows.
      }
    }
    final progress = <PageProgress>[];
    for (final row in await gateway.query(UserPaths.progressCollection(uid))) {
      try {
        progress.add(LegacyDocs.progressFromDoc(row.data));
      } on Object {
        // Skip malformed rows.
      }
    }

    final snapshot = AnalyticsCalculators.weeklySnapshot(
      profileId: profile.id,
      startDate: start,
      endDate: end,
      sessions: sessions,
      plans: plans,
      progress: progress,
    );

    final computedAtUtc = now().toIso8601String();
    final payload = <String, dynamic>{
      'profileId': profile.id,
      'startDate': startIso,
      'endDate': endIso,
      'computedAtUtc': computedAtUtc,
      'snapshot': _snapshotToJson(snapshot),
    };
    if (cachePath != null) {
      await gateway.setDoc(cachePath, {
        'computedAtUtc': computedAtUtc,
        'payload': payload,
      });
    }

    return Response.ok(
      jsonEncode(payload),
      headers: const {'content-type': 'application/json'},
    );
  };
}

Map<String, dynamic> _snapshotToJson(WeeklySnapshot s) => {
      'startDate': _isoDay(s.startDate),
      'endDate': _isoDay(s.endDate),
      'totalSessions': s.totalSessions,
      'totalDurationMinutes': s.totalDurationMinutes,
      'avgDurationMinutes': s.avgDurationMinutes,
      'sessionsPerDay': {
        for (final e in s.sessionsPerDay.entries) '${e.key}': e.value,
      },
      'plannedDays': s.plannedDays,
      'completedDays': s.completedDays,
      'completionRate': s.completionRate,
      'strongCount': s.strongCount,
      'okayCount': s.okayCount,
      'needsWorkCount': s.needsWorkCount,
      'pagesMemorized': s.pagesMemorized,
      'pagesReviewed': s.pagesReviewed,
      'pagesPerWeek': s.pagesPerWeek,
      'hasEnoughData': s.hasEnoughData,
    };

final RegExp _isoDayPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

DateTime _parseIsoDay(String field, String raw) {
  final parsed = _isoDayPattern.hasMatch(raw) ? DateTime.tryParse(raw) : null;
  if (parsed == null || _isoDay(parsed) != raw) {
    throw PlanDateError('$field must be a valid YYYY-MM-DD calendar date.');
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String _isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime _utcNow() => DateTime.now().toUtc();

Response _error(
  int status,
  String code,
  String message, {
  bool retryable = false,
}) {
  return Response(
    status,
    body: jsonEncode({
      'error': {'code': code, 'message': message, 'retryable': retryable},
    }),
    headers: const {'content-type': 'application/json'},
  );
}
