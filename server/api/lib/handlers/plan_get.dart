import 'dart:convert';

import 'package:hifz_core/hifz_core.dart';
import 'package:shelf/shelf.dart';

import '../gateway/firestore_gateway.dart';
import '../middleware/auth.dart';

/// `GET /v1/me/plan?profileId=…&date=YYYY-MM-DD&tzOffsetMinutes=…`
/// (authenticated) — roadmap §5 #3 / §8 Phase 3 task 2.
///
/// Get-or-create, **fast and deterministic — never calls Vertex inline**
/// (the client's ~3s timeout is safe; AI lives in `POST /v1/me/plan:enhance`):
///
/// 1. Returns the highest-revision stored plan for `(profileId, date)` from
///    `users/{uid}/plans` — the composite index `(profileId, date,
///    revision DESC)` in firestore.indexes.json backs this query in prod.
///    Legacy mirror docs (synced by today's clients: `plan.toMap()` +
///    `createdAt`, no `revision`) are invisible to that orderBy, so the
///    deterministic doc id `'${profileId}_${isoDate}'` is also read directly
///    and treated as revision 0 — an existing client plan (possibly
///    AI-enhanced) is returned, never clobbered.
/// 2. Otherwise generates via the shared `hifz_core` [PlanGenerator] from
///    the LEGACY Firestore mirror — `users/{uid}` root doc = profile fields,
///    `users/{uid}/progress/*` = page progress (the documented dual-window
///    input source until Phase 4 facts exist) — persists it at the
///    deterministic id with `revision: 0`, and returns it. The persist runs
///    in a transaction whose in-tx read makes concurrent first-GETs and
///    racing legacy writers safe: first writer wins, the loser's copy is
///    returned (deterministic generation makes both byte-identical anyway).
///
/// Date semantics (§5 "Date semantics"): the **client-local** date keys the
/// plan. `?date=YYYY-MM-DD` is canonical when present; else
/// `?tzOffsetMinutes` shifts server UTC time to the client's local calendar
/// day (its midnight day-boundary, the same rule the SRS engine uses); else
/// the server's UTC date is used — a documented caveat: near the client's
/// midnight that can be off by one day, accepted at tester scale (R5) and
/// avoided entirely by clients sending `date`.
///
/// Phase 3 resolutions (documented, revisit in later phases):
/// - `revision` on first creation is 0, not a legacy-mirror session count:
///   facts don't exist until Phase 4, and whenever a session was completed
///   today the client has already mirrored today's plan, so the read path —
///   not the generator — serves it.
/// - `rotationJuz` is `[]`: manzil rotation is device-local SQLite until
///   Phase 5 task 4 moves it under `users/{uid}/meta/`; the generator's time
///   redistribution handles the empty manzil phase.
/// - `?recovery` is accepted and ignored: recovery mode only changes the AI
///   preamble, which lives in `plan:enhance`.
/// - `?profileId` defaults to the mirrored profile's id; any other value is
///   404 — the legacy root-doc mirror holds exactly one profile.
Handler planGetHandler({
  required FirestoreGateway gateway,
  DateTime Function()? nowUtc,
}) {
  final now = nowUtc ?? _utcNow;
  return (Request request) async {
    final params = request.url.queryParameters;

    final DateTime day;
    try {
      day = resolvePlanDate(
        date: params['date'],
        tzOffsetMinutes: params['tzOffsetMinutes'],
        nowUtc: now(),
      );
    } on PlanDateError catch (e) {
      return _error(400, 'invalid-argument', e.message);
    }

    final uid = request.uid;

    // ── Profile (legacy mirror root doc) ──
    final profileDoc = await gateway.getDoc('users/$uid');
    MemoryProfile? profile;
    if (profileDoc != null) {
      try {
        profile = MemoryProfile.fromMap(profileDoc);
      } catch (_) {
        // A root doc that does not parse as a profile is not a usable
        // mirror; same outcome as no doc at all.
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
    if (requestedProfileId != null && requestedProfileId != profile.id) {
      return _error(
        404,
        'not-found',
        'Profile "$requestedProfileId" is not mirrored for this account.',
      );
    }

    final dateIso = day.toIso8601String();
    final plansPath = 'users/$uid/plans';
    final planDocPath = '$plansPath/${profile.id}_$dateIso';

    // ── Read: highest revision for (profileId, date), §5 semantics ──
    final stored = await gateway.query(
      plansPath,
      whereEquals: {'profileId': profile.id, 'date': dateIso},
      orderBy: 'revision',
      descending: true,
      limit: 1,
    );
    if (stored.isNotEmpty) return _planResponse(stored.first.data, day);

    // Legacy revision-less doc at the deterministic id (today's clients).
    final legacy = await gateway.getDoc(planDocPath);
    if (legacy != null) return _planResponse(legacy, day);

    // ── Create: deterministic generation from the legacy mirror ──
    final progressDocs = await gateway.query(
      'users/$uid/progress',
      whereEquals: {'profileId': profile.id},
    );
    final progress = <int, PageProgress>{};
    for (final doc in progressDocs) {
      try {
        final page = PageProgress.fromMap(doc.data);
        progress[page.pageNumber] = page;
      } catch (_) {
        // Skip malformed rows, mirroring CloudSyncService._mergeData's
        // tolerance — one bad doc must not take the endpoint down.
      }
    }

    final plan = PlanGenerator.generate(
      profile: profile,
      progress: progress,
      rotationJuz: const [], // device-local until Phase 5 — see header.
      now: day,
    );
    // `day` as the recipe clock keeps recipe ids deterministic per
    // (plan, date) — identical across replays and racing instances.
    final recipes = PlanGenerator.generateDefaultRecipes(plan, profile, day);

    final createdAt = now().toIso8601String();
    final planDoc = <String, dynamic>{
      // Legacy-compatible field set first (DailyPlan.toMap) so current
      // clients' pull path (DailyPlan.fromMap) keeps parsing these docs;
      // the extra server fields below are ignored by it.
      ...plan.toMap(),
      'revision': 0,
      'source': 'server-deterministic',
      'recipes': [for (final r in recipes) r.toMap()],
      'createdAt': createdAt,
      'updatedAt': createdAt,
    };

    final persisted = await gateway.runTransaction<Map<String, dynamic>>(
      (tx) async {
        final existing = await tx.get(planDocPath);
        if (existing != null) return existing; // lost the race — never clobber
        tx.set(planDocPath, planDoc);
        return planDoc;
      },
    );
    return _planResponse(persisted, day);
  };
}

DateTime _utcNow() => DateTime.now().toUtc();

/// Error thrown by [resolvePlanDate] for malformed `date`/`tzOffsetMinutes`.
class PlanDateError implements Exception {
  PlanDateError(this.message);

  final String message;

  @override
  String toString() => 'PlanDateError: $message';
}

/// Real-world UTC offsets span UTC-12:00 (Baker Island) to UTC+14:00
/// (Kiritimati) — anything outside is a client bug, not a timezone.
const int _minTzOffsetMinutes = -12 * 60;
const int _maxTzOffsetMinutes = 14 * 60;

final RegExp _isoDayPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Resolves the client-local calendar day the plan is keyed on (§5 date
/// semantics; see [planGetHandler] header). Returns a naive local-midnight
/// [DateTime] — exactly the `today` the client-side generator computes.
/// Throws [PlanDateError] on malformed input (handler maps it to 400).
DateTime resolvePlanDate({
  String? date,
  String? tzOffsetMinutes,
  required DateTime nowUtc,
}) {
  int? offset;
  if (tzOffsetMinutes != null) {
    offset = int.tryParse(tzOffsetMinutes);
    if (offset == null ||
        offset < _minTzOffsetMinutes ||
        offset > _maxTzOffsetMinutes) {
      throw PlanDateError(
        'tzOffsetMinutes must be an integer between $_minTzOffsetMinutes '
        'and $_maxTzOffsetMinutes.',
      );
    }
  }

  if (date != null) {
    final parsed = _isoDayPattern.hasMatch(date) ? DateTime.tryParse(date) : null;
    if (parsed == null || _isoDay(parsed) != date) {
      throw PlanDateError('date must be a valid YYYY-MM-DD calendar date.');
    }
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  if (offset != null) {
    // The client's local wall clock = UTC now + its zone offset; its
    // calendar fields give the client-local day (local-midnight boundary).
    final local = nowUtc.add(Duration(minutes: offset));
    return DateTime(local.year, local.month, local.day);
  }

  // Documented caveat: without date/tzOffsetMinutes the server's UTC day is
  // assumed, which mis-keys requests near the client's local midnight.
  return DateTime(nowUtc.year, nowUtc.month, nowUtc.day);
}

String _isoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Builds the §5 #3 response from a stored plan doc:
/// `{id, profileId, date, revision, source, plan, sessionRecipes}`.
///
/// `plan` is the legacy-shaped DailyPlan map (client `DailyPlan.fromMap`
/// compatible). For docs written by this server, `revision`/`source`/
/// `recipes` are present; for legacy client-mirrored docs they default to
/// `0` / `client-legacy` / `[]` (`client-legacy` is an honest extension of
/// §5's `server-deterministic|server-ai` — the plan was generated by a
/// client and only mirrored here; claiming a server source would be wrong).
Response _planResponse(Map<String, dynamic> doc, DateTime day) {
  final plan = {...doc}
    ..remove('revision')
    ..remove('source')
    ..remove('recipes')
    // createdAt is a Firestore server timestamp on legacy docs — not JSON.
    ..remove('createdAt')
    ..remove('updatedAt');
  return Response.ok(
    jsonEncode({
      'id': plan['id'],
      'profileId': plan['profileId'],
      'date': _isoDay(day),
      'revision': doc['revision'] as int? ?? 0,
      'source': doc['source'] as String? ?? 'client-legacy',
      'plan': plan,
      'sessionRecipes': doc['recipes'] as List<dynamic>? ?? const <dynamic>[],
    }),
    headers: const {'content-type': 'application/json'},
  );
}

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
