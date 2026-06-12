import 'dart:convert';

import 'package:hifz_core/hifz_core.dart';
import 'package:shelf/shelf.dart';

import '../config.dart';
import '../gateway/firestore_gateway.dart';
import '../middleware/auth.dart';
import '../store/legacy_docs.dart';
import 'bootstrap.dart';

/// `POST /v1/admin/users/{targetUid}/writePath` (authenticated ADMIN) —
/// the tiny admin guard behind the Phase 4 per-user rollback lever
/// (roadmap §8 Phase 4 task 4 / R2): flips a user's `writePath` between
/// `legacy` and `facts`, instantly and per-user.
///
/// Body: `{"writePath": "facts"}` (or `"legacy"`).
/// Guard: the CALLER's verified uid must be in `Config.adminUids`
/// (env ADMIN_UIDS, default empty = nobody). Non-admins get 403.
///
/// **Flip-to-facts reconcile pass** (roadmap §8 Phase 4b task 3): under
/// `writePath=legacy` the legacy pushes and the facts transactions
/// interleave on the same progress docs, so `reviewCount` oscillates by ±1;
/// whatever state is current at flip time would otherwise freeze in as a
/// permanent offset. Flipping to `facts` therefore re-derives the user's
/// progress + streak docs from the durable facts log (the R2 "corruption is
/// re-derivable from facts" promise), so the facts era starts from clean
/// derived state. The pass:
/// - folds ONLY the mirrored root profile's session facts (the multi-profile
///   keyspace guard in `facts.dart`); when no profile is mirrored, all
///   session facts fold (matching the apply path);
/// - clamps future `recordedAtUtc` values and DROPS future-dated facts from
///   the streak fold (healing pre-guard clock-skew victims);
/// - folds the streak from zero — order-independent over the full fact set,
///   healing pre-resequencing backfill-order victims;
/// - overwrites only pages the facts touch; legacy-only progress docs
///   (history that never became facts) are left alone. Legacy-only sessions
///   are expected to reach the facts log via the client backfill BEFORE a
///   user is flipped (§7.3) — flip after the user's devices have drained.
///
/// Console fallback (no deploy, no admin uid needed): in the Firebase
/// console open Firestore → `users/{uid}/meta/server` and set the string
/// field `writePath` to `facts` or `legacy` (create the doc if missing).
/// The next `GET /v1/me/bootstrap` serves the new value. NOTE: the console
/// path skips the reconcile pass — prefer the endpoint when flipping to
/// `facts`.
Future<Response> Function(Request, String) adminWritePathHandler({
  required FirestoreGateway gateway,
  required Config config,
  DateTime Function()? nowUtc,
}) {
  final now = nowUtc ?? _utcNow;
  return (Request request, String targetUid) async {
    if (!config.adminUids.contains(request.uid)) {
      return _error(
        403,
        'permission-denied',
        'This endpoint requires an admin uid.',
      );
    }
    if (targetUid.isEmpty) {
      return _error(400, 'invalid-argument', 'Target uid must not be empty.');
    }

    final Object? parsed;
    try {
      parsed = jsonDecode(await request.readAsString());
    } on FormatException {
      return _error(400, 'invalid-argument', 'Request body must be JSON.');
    }
    final writePath =
        parsed is Map<String, dynamic> ? parsed['writePath'] : null;
    if (writePath is! String || !kWritePaths.contains(writePath)) {
      return _error(
        400,
        'invalid-argument',
        'Body must be {"writePath": "facts"|"legacy"}.',
      );
    }

    Map<String, dynamic>? reconciled;
    if (writePath == 'facts') {
      reconciled = await _reconcileFromFacts(gateway, targetUid, now());
    }

    await gateway.setDoc(
      UserPaths.serverMetaDoc(targetUid),
      {
        'writePath': writePath,
        'updatedAt': now().toIso8601String(),
        'updatedBy': request.uid,
      },
      merge: true,
    );

    return Response.ok(
      jsonEncode({
        'uid': targetUid,
        'writePath': writePath,
        'reconciled': ?reconciled,
      }),
      headers: const {'content-type': 'application/json'},
    );
  };
}

/// Re-derives progress + streak from `users/{uid}/facts` (see handler docs).
/// Returns a small summary for the admin response.
Future<Map<String, dynamic>> _reconcileFromFacts(
  FirestoreGateway gateway,
  String uid,
  DateTime nowUtc,
) async {
  // Root profile mirror — the multi-profile keyspace guard's anchor.
  String? rootProfileId;
  final profileDoc = await gateway.getDoc(UserPaths.userDoc(uid));
  if (profileDoc != null) {
    try {
      rootProfileId = MemoryProfile.fromMap(profileDoc).id;
    } on Object {
      rootProfileId = null;
    }
  }

  final logDocs = await gateway.query('users/$uid/facts');
  final sessions = <SessionFact>[];
  var skipped = 0;
  for (final row in logDocs) {
    final raw = row.data['fact'];
    if (raw is! Map) continue;
    final Fact fact;
    try {
      fact = Fact.fromJson(raw.cast<String, dynamic>());
    } on Object {
      skipped++; // pre-guard log rows that no longer parse
      continue;
    }
    if (fact is! SessionFact) continue;
    if (rootProfileId != null && fact.profileId != rootProfileId) continue;
    sessions.add(
      // Clamp pre-guard future recordedAtUtc values, like the apply path.
      fact.recordedAtUtc.isAfter(nowUtc)
          ? SessionFact(
              id: fact.id,
              coreVersion: fact.coreVersion,
              profileId: fact.profileId,
              date: fact.date,
              tzOffsetMinutes: fact.tzOffsetMinutes,
              durationMinutes: fact.durationMinutes,
              repCount: fact.repCount,
              sabaq: fact.sabaq,
              sabqi: fact.sabqi,
              manzil: fact.manzil,
              actualPagesCovered: fact.actualPagesCovered,
              lastVerseLearned: fact.lastVerseLearned,
              totalVersesOnPage: fact.totalVersesOnPage,
              planId: fact.planId,
              planRevision: fact.planRevision,
              planOrigin: fact.planOrigin,
              recordedAtUtc: nowUtc,
            )
          : fact,
    );
  }

  if (sessions.isEmpty) {
    // Nothing to re-derive — never zero a legacy streak on an empty log.
    return {'sessionFacts': 0, 'progressPages': 0, 'skipped': skipped};
  }

  // Progress: clean re-derivation from EMPTY prior over the full fact set.
  final progress = ProgressDerivation.foldSessionFacts(
    prior: const {},
    facts: sessions,
  );
  for (final state in progress.values) {
    await gateway.setDoc(
      UserPaths.progressDoc(uid, state.pageNumber),
      LegacyDocs.progressToDoc(state, state.lastReviewedAt ?? nowUtc),
    );
  }

  // Streak: fold from zero (order-independent over the full set). Drop
  // future-dated facts — they are exactly the freeze the guard now rejects.
  final maxTomorrow = nowUtc
      .add(const Duration(minutes: FactBounds.maxTzOffsetMinutes))
      .add(const Duration(days: 1));
  final maxDay =
      DateTime.utc(maxTomorrow.year, maxTomorrow.month, maxTomorrow.day);
  bool dateOk(SessionFact f) {
    final p = DateTime.parse(f.date);
    return !DateTime.utc(p.year, p.month, p.day).isAfter(maxDay);
  }

  final streak = StreakDerivation.fold(
    prior: const StreakData(),
    sessions: sessions.where(dateOk),
  );
  await gateway.setDoc(
    UserPaths.streakDoc(uid),
    LegacyDocs.streakToDoc(streak, nowUtc),
  );

  return {
    'sessionFacts': sessions.length,
    'progressPages': progress.length,
    'skipped': skipped,
    'streak': {
      'totalActiveDays': streak.totalActiveDays,
      'lastActiveDate':
          streak.lastActiveDate?.toIso8601String().substring(0, 10),
    },
  };
}

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
