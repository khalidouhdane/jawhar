import 'dart:convert';

import 'package:hifz_core/hifz_core.dart';
import 'package:shelf/shelf.dart';

import '../gateway/firestore_gateway.dart';
import '../middleware/auth.dart';
import '../store/legacy_docs.dart';

/// `PUT /v1/me/profiles/{profileId}` (authenticated) — roadmap §5 #7:
/// MemoryProfile upsert, LWW on `updatedAt`, plural-keyed from day one.
///
/// This endpoint is what makes the §5 plural-safe contract REAL for
/// multi-profile devices (Phase 5): the facts fold and `GET /v1/me/plan`
/// resolve non-root profiles from `users/{uid}/profiles/{profileId}` —
/// without an upserted profile doc, a second profile's session facts fall
/// back to the lossless path (logged, no derivation).
///
/// ⚠ PINNED GAP (Phase 8 runbook precondition — see
/// `docs/PHASE8_LOCKDOWN_RUNBOOK.md`): lossless-path facts that PRE-DATE
/// the profile upsert are NOT folded retroactively by anything yet —
/// replays short-circuit on the dedup log, so even a reconcile re-enqueue
/// answers `applied:false` without deriving, and the profile's plan would
/// generate from empty plural progress. A refold step (query the facts log
/// for this profileId's session facts, fold chronologically) MUST exist
/// before any client wires this endpoint. No client calls it today.
///
/// Wire shape: the body IS the legacy `MemoryProfile.toMap()` map (the
/// exact shape the root mirror doc already uses), plus an optional
/// `updatedAt` ISO-8601 UTC instant (defaults to the server clock). The
/// body's `id` must equal the path's `{profileId}`.
///
/// Semantics:
/// - **LWW**: if the stored plural doc carries a STRICTLY newer
///   `updatedAt`, the incoming snapshot loses — `applied:false` plus the
///   canonical stored profile, which the client adopts (same posture as
///   plan-claim reconciliation: losing is not an error).
/// - **Dual-window root mirror**: when the upserted profile IS the
///   mirrored root profile (root doc parses and ids match), the root doc
///   is updated in the same transaction so the legacy pull path and the
///   facts fold (which read the root doc first) see the same data.
///   The endpoint never CREATES the root doc — which local profile is the
///   device's active one is client state, not derivable here.
Future<Response> Function(Request, String) profilePutHandler({
  required FirestoreGateway gateway,
  DateTime Function()? nowUtc,
}) {
  final now = nowUtc ?? _utcNow;
  return (Request request, String profileId) async {
    if (!WireCodec.isSafeId(profileId)) {
      return _error(
        422,
        'invalid-argument',
        'profileId must be 1-64 chars of [A-Za-z0-9_:.-].',
      );
    }

    final Object? parsed;
    try {
      parsed = jsonDecode(await request.readAsString());
    } on FormatException {
      return _error(400, 'invalid-argument', 'Request body must be JSON.');
    }
    if (parsed is! Map<String, dynamic>) {
      return _error(
        400,
        'invalid-argument',
        'Request body must be a JSON object (MemoryProfile map).',
      );
    }

    final MemoryProfile profile;
    try {
      profile = MemoryProfile.fromMap(parsed);
    } on Object catch (e) {
      return _error(422, 'invalid-argument', 'Invalid profile payload: $e');
    }
    if (profile.id != profileId) {
      return _error(
        422,
        'invalid-argument',
        'Body id "${profile.id}" does not match path profileId '
        '"$profileId".',
      );
    }

    DateTime incomingUpdatedAt;
    final rawUpdatedAt = parsed['updatedAt'];
    if (rawUpdatedAt == null) {
      incomingUpdatedAt = now().toUtc();
    } else {
      try {
        incomingUpdatedAt = WireCodec.requireUtcInstant(parsed, 'updatedAt');
      } on FormatException catch (e) {
        return _error(422, 'invalid-argument', e.message);
      }
    }

    final uid = request.uid;
    final pluralPath = UserPaths.profileDoc(uid, profileId);

    final outcome = await gateway.runTransaction<
        ({bool applied, Map<String, dynamic> canonical})>((tx) async {
      final existing = await tx.get(pluralPath);
      final rootDoc = await tx.get(UserPaths.userDoc(uid));

      final existingUpdatedAt = _instantOf(existing?['updatedAt']);
      if (existing != null &&
          existingUpdatedAt != null &&
          existingUpdatedAt.isAfter(incomingUpdatedAt)) {
        // Stored copy is newer — LWW keeps it; re-write verbatim so the
        // transaction is never read-only (0.5.x commit defect).
        tx.set(pluralPath, existing);
        return (applied: false, canonical: existing);
      }

      final doc = <String, dynamic>{
        ...profile.toMap(),
        'updatedAt': WireCodec.encodeUtcInstant(incomingUpdatedAt),
      };
      tx.set(pluralPath, doc);

      // Dual-window: keep the legacy root mirror coherent when this IS the
      // root profile.
      if (rootDoc != null) {
        MemoryProfile? rootProfile;
        try {
          rootProfile = MemoryProfile.fromMap(rootDoc);
        } on Object {
          rootProfile = null;
        }
        if (rootProfile != null && rootProfile.id == profileId) {
          tx.set(UserPaths.userDoc(uid), doc);
        }
      }
      return (applied: true, canonical: doc);
    });

    return Response.ok(
      jsonEncode({
        'profileId': profileId,
        'applied': outcome.applied,
        'profile': outcome.canonical,
      }),
      headers: const {'content-type': 'application/json'},
    );
  };
}

/// Tolerant instant parse for stored `updatedAt` fields: ISO strings from
/// this endpoint, Firestore Timestamps (exposing `toDate()`) from legacy
/// client writes.
DateTime? _instantOf(Object? raw) {
  if (raw is DateTime) return raw.toUtc();
  if (raw is String) return DateTime.tryParse(raw)?.toUtc();
  try {
    final date = (raw as dynamic).toDate();
    if (date is DateTime) return date.toUtc();
  } on Object {
    // fall through
  }
  return null;
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
