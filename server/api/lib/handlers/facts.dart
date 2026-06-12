import 'dart:convert';

import 'package:hifz_core/hifz_core.dart';
import 'package:shelf/shelf.dart';

import '../config.dart';
import '../gateway/firestore_gateway.dart';
import '../middleware/auth.dart';
import '../store/legacy_docs.dart';

/// `POST /v1/me/facts` — THE single write path (roadmap §5 #5 / §8 Phase 4b)
/// — and `POST /v1/me/backfill`, which is the SAME handler: a backfill is an
/// outbox flush of history, and the `(uid, fact.id)` dedup machinery makes
/// over-enqueueing free (§7.3). Backfills should arrive in chronological
/// batches so the streak fold counts every historical day (the hifz_core
/// streak rule skips dates at-or-before the stored `lastActiveDate`).
///
/// Contract highlights (all contract-tested against the emulator):
/// - **Idempotent per fact id**: the durable `users/{uid}/facts/{factId}`
///   log doc is read inside the SAME transaction that applies the fact's
///   derived state — a replay returns `200` with `applied:false` and the
///   CURRENT canonical derived state, byte-identical when nothing changed
///   in between. A kill-mid-drain double flush therefore never
///   double-counts.
/// - **uid from the token only** — the §7.2 A/B-switch scenario: a batch
///   flushed under account B lands entirely under `users/B`, whatever ids
///   or profile ids the body claims.
/// - **One poisoned item never blocks the queue**: each fact parses and
///   applies independently; malformed facts get a per-item
///   `invalid-argument` (`retryable:false` → outbox poison), transient
///   failures get `internal` (`retryable:true` → backoff).
/// - **Dual-window derivation (R2)**: priors are read from the LEGACY
///   mirror docs (which the facts path also writes), so legacy-writer and
///   facts-writer devices fold into the same state.
/// - **datasetEpoch guard**: a client MAY send `X-Dataset-Epoch`; a
///   mismatch is refused wholesale with `409 dataset-epoch-mismatch`
///   (`retryable:false`, body carries the CURRENT epoch for adoption) so a
///   stale outbox can never flush into a new server data generation (§5
///   reset arbitration). Responses always carry the current epoch.
/// - **Clock-skew guards**: session/planGenerated facts dated beyond the
///   client-local tomorrow (server clock + the fact's tz offset + 1 day)
///   are rejected as poison — one far-future date would freeze the streak
///   fold for years; future `recordedAtUtc` values are clamped to the
///   server clock before derivation (mirroring the SrsFold review clamp).
/// - **Multi-profile keyspace rule (§5 plural-safe contract, Phase 5)**:
///   the mirrored ROOT profile derives into the legacy keyspace
///   (`progress/{page}`, singleton `meta/streak`) for dual-window pull
///   compat. A NON-root profile known to the plural keyspace
///   (`users/{uid}/profiles/{profileId}`, upserted via
///   `PUT /v1/me/profiles/{profileId}`) derives its OWN progress (plural
///   subcollection) and regenerates ITS OWN plan (`plans/{profileId_date}`
///   is plural-keyed already) — never the root's. Its facts do NOT touch
///   the singleton streak doc (it mirrors the root profile's streak).
///   A non-root profile UNKNOWN to the plural keyspace falls back to the
///   lossless behavior: logged + mirrored as a session doc, derive nothing.
/// - **Manzil rotation (Phase 5 task 4)**: plan regeneration reads the
///   server-persisted rotation (`users/{uid}/meta/manzil_rotation`, keyed
///   by profileId) instead of the old hard-coded `[]`; `rotationChanged`
///   facts fold into that doc LWW per profile. A rotation edit does NOT
///   regenerate the current plan revision — exactly like the device, where
///   the rotation is read at generation time only.
///
/// Application order inside a batch (input order never matters, mirroring
/// the hifz_core fold contracts): `cardCreated` (identity first), then
/// `review` by (`reviewedAtUtc`, id), then `rotationChanged` by
/// (`changedAtUtc`, id) (so a same-batch session regenerates with the new
/// rotation), then `planGenerated` by (`revision`, id), then `session` by
/// (`recordedAtUtc`, id). Results are emitted in INPUT order; duplicate ids
/// inside one batch apply once and every duplicate position reports that
/// single outcome.
Handler factsHandler({
  required FirestoreGateway gateway,
  required Config config,
  DateTime Function()? nowUtc,
}) {
  final now = nowUtc ?? _utcNow;
  final applier = FactApplier(gateway: gateway, nowUtc: now);

  return (Request request) async {
    final epochMismatch = _epochGuard(request, config);
    if (epochMismatch != null) return epochMismatch;

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
        'Request body must be a JSON object.',
      );
    }
    final rawFacts = parsed['facts'];
    if (rawFacts is! List) {
      return _error(
        400,
        'invalid-argument',
        'Request body must carry a "facts" array.',
      );
    }
    if (rawFacts.length > maxBatchSize) {
      return _error(
        400,
        'invalid-argument',
        'Batch too large (${rawFacts.length} > $maxBatchSize) — '
        'split the flush into chunks.',
      );
    }

    final uid = request.uid;

    // ── Parse each item independently (poison isolation) ──
    final parsedFacts = <Fact>[];
    final parseFailures = <String, ApiError>{}; // result-id -> error
    final inputIds = <String>[]; // result id per input position
    for (var i = 0; i < rawFacts.length; i++) {
      final item = rawFacts[i];
      final fallbackId = (item is Map && item['id'] is String)
          ? item['id'] as String
          : '#$i';
      try {
        if (item is! Map) {
          throw const FormatException('expected an object');
        }
        final fact = Fact.fromJson(item.cast<String, dynamic>());
        parsedFacts.add(fact);
        inputIds.add(fact.id);
      } on FormatException catch (e) {
        inputIds.add(fallbackId);
        parseFailures[fallbackId] = ApiError(
          code: 'invalid-argument',
          message: e.message,
          retryable: false,
        );
      }
    }

    // ── Apply, deterministically ordered, one transaction per fact ──
    final outcomes = <String, FactOutcome>{};
    for (final fact in _applicationOrder(parsedFacts)) {
      if (outcomes.containsKey(fact.id)) continue; // in-batch duplicate

      // Clock-skew guard (the f342e80 class, ported to session-dated
      // facts): a fact claiming a far-future client-local `date` would
      // advance `lastActiveDate` years ahead and freeze the streak for
      // every real day after it. Rejected as poison — EXCEPT when the fact
      // was already applied before this guard existed: the dedup-log
      // short-circuit must keep replays answering `applied:false`.
      final dateError = _futureDateError(fact, now());
      if (dateError != null) {
        final alreadyApplied =
            await gateway.getDoc(UserPaths.factDoc(uid, fact.id)) != null;
        if (!alreadyApplied) {
          outcomes[fact.id] = FactOutcome(
            result: FactResult(id: fact.id, applied: false, error: dateError),
          );
          continue;
        }
      }

      FactOutcome outcome;
      try {
        outcome = await applier.apply(uid, fact);
      } on Object catch (e) {
        // Deterministic store rejections (oversize doc, >500 mutations,
        // malformed path) can never succeed on retry — poison them instead
        // of looping the client's backoff forever.
        final permanent = _isPermanentStoreError(e);
        outcome = FactOutcome(
          result: FactResult(
            id: fact.id,
            applied: false,
            error: ApiError(
              code: permanent ? 'invalid-argument' : 'internal',
              message: 'Failed to apply fact: $e',
              retryable: !permanent,
            ),
          ),
        );
      }
      outcomes[fact.id] = outcome;
    }

    // ── Assemble: results in INPUT order, deltas keyed last-write-wins ──
    final results = <FactResult>[];
    final progress = <String, ProgressDelta>{};
    final cards = <String, CardSrsDelta>{};
    final plans = <String, PlanDelta>{};
    final rotations = <String, RotationDelta>{};
    StreakDelta? streak;
    final emitted = <String>{};
    for (final id in inputIds) {
      final failure = parseFailures[id];
      if (failure != null) {
        results.add(FactResult(id: id, applied: false, error: failure));
        continue;
      }
      final outcome = outcomes[id]!;
      results.add(outcome.result);
      if (!emitted.add(id)) continue; // merge deltas once per unique fact
      for (final delta in outcome.progress) {
        progress['${delta.profileId}|${delta.pageNumber}'] = delta;
      }
      for (final delta in outcome.cards) {
        cards[delta.id] = delta;
      }
      for (final delta in outcome.plans) {
        plans[delta.id] = delta;
      }
      for (final delta in outcome.rotations) {
        rotations[delta.profileId] = delta;
      }
      streak = outcome.streak ?? streak;
    }

    final response = FactsResponse(
      datasetEpoch: DatasetEpoch(config.datasetEpoch),
      results: results,
      derived: DerivedState(
        progress: progress.values.toList(),
        cards: cards.values.toList(),
        streak: streak,
        plans: plans.values.toList(),
        rotations: rotations.values.toList(),
      ),
    );
    return Response.ok(
      jsonEncode(response.toJson()),
      headers: const {'content-type': 'application/json'},
    );
  };
}

/// Hard cap per batch; clients chunk above it (an outbox flush or a
/// backfill is free to span several requests — dedup makes that safe).
const int maxBatchSize = 1000;

/// Header through which a client can assert the data generation its outbox
/// belongs to (§5 datasetEpoch arbitration).
const String datasetEpochHeader = 'x-dataset-epoch';

Response? _epochGuard(Request request, Config config) {
  final claimed = request.headers[datasetEpochHeader];
  if (claimed == null || claimed == config.datasetEpoch) return null;
  // The current epoch rides along at the top level so the refused client
  // can adopt it directly while executing the reset policy (its outbox is
  // about to be wiped — it may not get another 200 to learn it from).
  return Response(
    409,
    body: jsonEncode({
      'datasetEpoch': config.datasetEpoch,
      'error': {
        'code': 'dataset-epoch-mismatch',
        'message':
            'Client dataset epoch "$claimed" does not match the server '
            'epoch "${config.datasetEpoch}" — execute the announced reset '
            'policy (wipe local cache + outbox, or wipe-then-rebackfill) '
            'before syncing.',
        'retryable': false,
      },
    }),
    headers: const {'content-type': 'application/json'},
  );
}

/// Validates the client-local `date` on session/planGenerated facts against
/// the server clock: the date may not be later than "tomorrow" on the
/// client's own clock (server now + the fact's `tzOffsetMinutes`, plus one
/// day of grace for modest skew). `planGenerated` carries no tz offset, so
/// it gets the most permissive real-world offset (UTC+14).
///
/// R5 accepts near-midnight mis-bucketing; a device with a years-wrong
/// clock is a different class — one such fact freezes the streak fold
/// account-wide and stickily (no legacy push heals facts-writePath users).
ApiError? _futureDateError(Fact fact, DateTime nowUtc) {
  final (String date, int tzOffsetMinutes) = switch (fact) {
    final SessionFact f => (f.date, f.tzOffsetMinutes),
    final PlanGeneratedFact f => (f.date, FactBounds.maxTzOffsetMinutes),
    _ => ('', 0),
  };
  if (date.isEmpty) return null;
  final parsed = DateTime.parse(date); // already format-validated by the DTO
  final factDay = DateTime.utc(parsed.year, parsed.month, parsed.day);
  final clientNow = nowUtc.toUtc().add(Duration(minutes: tzOffsetMinutes));
  final clientToday =
      DateTime.utc(clientNow.year, clientNow.month, clientNow.day);
  if (!factDay.isAfter(clientToday.add(const Duration(days: 1)))) return null;
  return ApiError(
    code: 'invalid-argument',
    message: 'Fact date "$date" is in the future (client-local today is '
        '${clientToday.toIso8601String().substring(0, 10)}) — '
        'check the device clock.',
    retryable: false,
  );
}

/// Deterministic Firestore/SDK rejections that retrying can never fix.
/// Deliberately EXCLUDES the masked 0.5.x "transaction is invalid" commit
/// defect (see `FirestoreGateway.runTransaction`), which IS transient.
bool _isPermanentStoreError(Object e) {
  final s = e.toString().toLowerCase();
  if (s.contains('transaction is invalid')) return false;
  return s.contains('invalid_argument') ||
      s.contains('invalid argument') ||
      s.contains('maximum allowed size') ||
      s.contains('exceeds the maximum') ||
      s.contains('too many writes');
}

/// Deterministic application order — see [factsHandler] docs.
List<Fact> _applicationOrder(List<Fact> facts) {
  int kindRank(Fact f) => switch (f) {
        CardCreatedFact() => 0,
        ReviewFact() => 1,
        RotationChangedFact() => 2,
        PlanGeneratedFact() => 3,
        SessionFact() => 4,
      };
  // Comparable primary key within each kind group.
  int compare(Fact a, Fact b) {
    final byKind = kindRank(a).compareTo(kindRank(b));
    if (byKind != 0) return byKind;
    final byKey = switch ((a, b)) {
      (final CardCreatedFact x, final CardCreatedFact y) =>
        x.createdAtUtc.compareTo(y.createdAtUtc),
      (final ReviewFact x, final ReviewFact y) =>
        x.reviewedAtUtc.compareTo(y.reviewedAtUtc),
      (final RotationChangedFact x, final RotationChangedFact y) =>
        x.changedAtUtc.compareTo(y.changedAtUtc),
      (final PlanGeneratedFact x, final PlanGeneratedFact y) =>
        x.revision.compareTo(y.revision),
      (final SessionFact x, final SessionFact y) =>
        x.recordedAtUtc.compareTo(y.recordedAtUtc),
      _ => 0,
    };
    if (byKey != 0) return byKey;
    return a.id.compareTo(b.id);
  }

  return [...facts]..sort(compare);
}

/// What applying one fact produced: the per-item result plus the §5 derived
/// deltas it contributed (current canonical state for replays).
class FactOutcome {
  const FactOutcome({
    required this.result,
    this.progress = const [],
    this.cards = const [],
    this.plans = const [],
    this.rotations = const [],
    this.streak,
  });

  final FactResult result;
  final List<ProgressDelta> progress;
  final List<CardSrsDelta> cards;
  final List<PlanDelta> plans;
  final List<RotationDelta> rotations;
  final StreakDelta? streak;
}

/// Applies one fact inside one Firestore transaction (roadmap §8 Phase 4b
/// task 1: "the server handler applies each fact in a Firestore
/// transaction" — this is what finally makes progress/streak/plan
/// transactional with the session record).
///
/// Transaction boundaries:
/// - **session fact** — atomic unit: dedup-log doc + legacy session doc +
///   every promoted progress doc (legacy keyspace for the root profile,
///   plural subcollection for a known non-root profile) + streak doc
///   (root/no-profile facts only) + the regenerated next-revision plan doc.
/// - **review fact** — atomic unit: dedup-log doc + legacy review-event
///   doc + the folded card SRS state (real card or placeholder).
/// - **cardCreated fact** — atomic unit: dedup-log doc + flashcard doc
///   (+ placeholder deletion when identity attaches late).
/// - **planGenerated fact** — atomic unit: dedup-log doc + the plan doc
///   when the claim wins (highest-revision-wins, ties → incumbent).
/// - **rotationChanged fact** — atomic unit: dedup-log doc + the rotation
///   doc (LWW fold; a losing edit is consumed and answered with the
///   canonical rotation).
///
/// The 0.5.x read-only-transaction commit defect (see `quota/ai_quota.dart`)
/// means every code path must write: replays re-write the dedup-log doc
/// verbatim.
class FactApplier {
  FactApplier({required this.gateway, required this.nowUtc});

  final FirestoreGateway gateway;
  final DateTime Function() nowUtc;

  Future<FactOutcome> apply(String uid, Fact fact) => switch (fact) {
        final SessionFact f => _applySession(uid, f),
        final ReviewFact f => _applyReview(uid, f),
        final CardCreatedFact f => _applyCardCreated(uid, f),
        final PlanGeneratedFact f => _applyPlanGenerated(uid, f),
        final RotationChangedFact f => _applyRotationChanged(uid, f),
      };

  Map<String, dynamic> _factLogDoc(Fact fact) => {
        'kind': fact.kind,
        'coreVersion': fact.coreVersion,
        'appliedAtUtc': WireCodec.encodeUtcInstant(nowUtc()),
        'fact': fact.toJson(),
      };

  // ── session ──────────────────────────────────────────────────────────

  Future<FactOutcome> _applySession(String uid, SessionFact originalFact) {
    return gateway.runTransaction<FactOutcome>((tx) async {
      // Clock-skew clamp (the review-fold guard, ported): a future
      // `recordedAtUtc` would stamp progress `updatedAt` fields in the
      // future (poisoning Phase 5 `?since=` delta pulls) and drive plan
      // regeneration "now". Derivation and legacy-doc writes use the
      // clamped instant; the dedup log keeps the client's original fact.
      final nowInstant = nowUtc();
      final fact = originalFact.recordedAtUtc.isAfter(nowInstant)
          ? _withRecordedAtUtc(originalFact, nowInstant)
          : originalFact;

      final factPath = UserPaths.factDoc(uid, fact.id);
      final planId = PlanIdentity.idFor(fact.profileId, fact.date);
      final planPath = UserPaths.planDoc(uid, planId);

      // Pages this fact promotes — mirrors ProgressDerivation's write set.
      final covered = fact.actualPagesCovered.isNotEmpty
          ? fact.actualPagesCovered
          : [if (fact.sabaq.page != null) fact.sabaq.page!];
      final affected = <int>{
        if (fact.sabaq.completed) ...covered,
        if (fact.sabqi.completed) ...fact.sabqi.pages,
        if (fact.manzil.completed) ...fact.manzil.pages,
      }.toList()
        ..sort();

      // ── Reads (all before writes — Firestore transaction rule) ──
      final existingLog = await tx.get(factPath);
      final profileDoc = await tx.get(UserPaths.userDoc(uid));
      MemoryProfile? rootProfile;
      if (profileDoc != null) {
        try {
          rootProfile = MemoryProfile.fromMap(profileDoc);
        } on Object {
          rootProfile = null;
        }
      }
      // Multi-profile keyspace resolution (§5 plural-safe contract):
      // - ROOT fact (root mirror parses and ids match) → legacy keyspace,
      //   full derivation incl. regeneration (dual-window pull compat).
      // - NON-root fact whose profile exists in the PLURAL keyspace
      //   (`users/{uid}/profiles/{profileId}`) → derive ITS progress into
      //   its own subcollection and regenerate ITS plan (`plans/` ids are
      //   profileId-keyed already); the singleton streak doc mirrors the
      //   root profile and is never touched by non-root facts.
      // - NON-root fact with NO plural profile → lossless fallback: logged
      //   + session doc only (re-derivable once the profile is upserted).
      // - NO profile mirrored anywhere → historical behavior: promote the
      //   affected pages + streak in the legacy keyspace (nothing to
      //   clobber), no regeneration (no profile to generate from).
      final isRootFact =
          rootProfile != null && rootProfile.id == fact.profileId;
      MemoryProfile? pluralProfile;
      if (!isRootFact) {
        final pluralDoc =
            await tx.get(UserPaths.profileDoc(uid, fact.profileId));
        if (pluralDoc != null) {
          try {
            final parsed = MemoryProfile.fromMap(pluralDoc);
            if (parsed.id == fact.profileId) pluralProfile = parsed;
          } on Object {
            pluralProfile = null;
          }
        }
      }
      final isForeignDerived = !isRootFact && pluralProfile != null;
      final isLossless =
          !isRootFact && !isForeignDerived && rootProfile != null;
      final canRegenerate = isRootFact || isForeignDerived;
      final profile = isRootFact ? rootProfile : pluralProfile;

      // Progress keyspace for this fact's profile (see resolution above).
      String progressPath(int page) => isForeignDerived
          ? UserPaths.profileProgressDoc(uid, fact.profileId, page)
          : UserPaths.progressDoc(uid, page);

      // Server-persisted manzil rotation (Phase 5 task 4) — regeneration
      // input, profile-scoped.
      var rotationJuz = const <int>[];
      if (canRegenerate) {
        final rotationDoc = await tx.get(UserPaths.rotationDoc(uid));
        rotationJuz = LegacyDocs.rotationStatesFromDoc(
              rotationDoc,
            )[fact.profileId]?.juz ??
            const <int>[];
      }

      if (existingLog != null) {
        if (isLossless) {
          // Same (empty) delta set as the original application.
          tx.set(factPath, existingLog); // keep the tx non-read-only
          return FactOutcome(result: FactResult(id: fact.id, applied: false));
        }
        // Replay: current canonical state for the same entity set.
        final progressDeltas = <ProgressDelta>[];
        for (final page in affected) {
          final doc = await tx.get(progressPath(page));
          final delta = _progressDeltaFromDoc(doc, fact.recordedAtUtc);
          if (delta != null && delta.profileId == fact.profileId) {
            progressDeltas.add(delta);
          }
        }
        StreakDelta? streakDelta;
        if (!isForeignDerived) {
          final streakDoc = await tx.get(UserPaths.streakDoc(uid));
          streakDelta =
              LegacyDocs.streakDelta(LegacyDocs.streakFromDoc(streakDoc));
        }
        final planDoc = await tx.get(planPath);
        tx.set(factPath, existingLog); // keep the tx non-read-only
        return FactOutcome(
          result: FactResult(id: fact.id, applied: false),
          progress: progressDeltas,
          streak: streakDelta,
          plans: [
            ?LegacyDocs.planDeltaFromDoc(planId, planDoc),
          ],
        );
      }

      if (isLossless) {
        // Log + legacy session doc only (atomic with the dedup mark).
        tx.set(factPath, _factLogDoc(originalFact));
        tx.set(
          UserPaths.sessionDoc(uid, fact.id),
          LegacyDocs.sessionDocFromFact(fact),
        );
        return FactOutcome(result: FactResult(id: fact.id, applied: true));
      }

      final priorProgress = <int, PageProgress>{};
      if (isRootFact) {
        // The generator scans the FULL progress map (next sabaq page,
        // sabqi candidates) — transactional query, profile-scoped.
        final rows = await tx.query(
          UserPaths.progressCollection(uid),
          whereEquals: {'profileId': fact.profileId},
        );
        for (final row in rows) {
          try {
            final page = LegacyDocs.progressFromDoc(row.data);
            priorProgress[page.pageNumber] = page;
          } on Object {
            // Skip malformed rows (CloudSyncService tolerance).
          }
        }
      } else if (isForeignDerived) {
        // The plural subcollection is already profile-scoped.
        final rows = await tx.query(
          UserPaths.profileProgressCollection(uid, fact.profileId),
        );
        for (final row in rows) {
          try {
            final page = LegacyDocs.progressFromDoc(row.data);
            if (page.profileId == fact.profileId) {
              priorProgress[page.pageNumber] = page;
            }
          } on Object {
            // Skip malformed rows.
          }
        }
      } else {
        for (final page in affected) {
          final doc = await tx.get(UserPaths.progressDoc(uid, page));
          if (doc == null) continue;
          try {
            final parsed = LegacyDocs.progressFromDoc(doc);
            if (parsed.profileId == fact.profileId) {
              priorProgress[parsed.pageNumber] = parsed;
            }
          } on Object {
            // Skip malformed rows.
          }
        }
      }

      final planDoc = await tx.get(planPath);
      Map<String, dynamic>? streakDoc;
      if (!isForeignDerived) {
        streakDoc = await tx.get(UserPaths.streakDoc(uid));
      }

      // ── Derive (pure hifz_core folds) ──
      Map<int, PageProgress> newProgress;
      PlanRevisionState? newPlanState;
      if (canRegenerate) {
        final incumbent = LegacyDocs.planStateFromDoc(planDoc);
        // foldSessions applies the progress promotion internally and
        // regenerates the next revision — never double-apply.
        final fold = PlanDerivation.foldSessions(
          priorPlans: {if (incumbent != null) planId: incumbent.state},
          priorProgress: priorProgress,
          facts: [fact],
          // `canRegenerate` promotes `profile` to non-null here.
          profile: profile!,
          rotationJuz: rotationJuz,
        );
        newProgress = fold.progress;
        newPlanState = fold.plans[planId];
      } else {
        newProgress = ProgressDerivation.applySessionFact(
          prior: priorProgress,
          fact: fact,
        );
      }
      StreakData? newStreak;
      if (!isForeignDerived) {
        newStreak = StreakDerivation.fold(
          prior: LegacyDocs.streakFromDoc(streakDoc),
          sessions: [fact],
        );
      }

      // ── Writes (atomic with the dedup-log mark) ──
      tx.set(factPath, _factLogDoc(originalFact));
      tx.set(
        UserPaths.sessionDoc(uid, fact.id),
        LegacyDocs.sessionDocFromFact(fact),
      );
      final progressDeltas = <ProgressDelta>[];
      for (final page in affected) {
        final state = newProgress[page];
        if (state == null) continue;
        tx.set(
          progressPath(page),
          LegacyDocs.progressToDoc(state, fact.recordedAtUtc),
        );
        progressDeltas.add(
          ProgressDelta.fromPageProgress(
            state,
            updatedAtUtc: fact.recordedAtUtc.toUtc(),
          ),
        );
      }
      if (newStreak != null) {
        tx.set(
          UserPaths.streakDoc(uid),
          LegacyDocs.streakToDoc(newStreak, fact.recordedAtUtc),
        );
      }
      final planDeltas = <PlanDelta>[];
      if (newPlanState != null) {
        // Recipes travel with the plan; the fact's instant keys recipe ids
        // so replays and racing instances generate identical docs.
        final recipes = PlanGenerator.generateDefaultRecipes(
          newPlanState.plan,
          profile,
          fact.recordedAtUtc.toUtc(),
        );
        tx.set(
          planPath,
          LegacyDocs.planToDoc(
            plan: newPlanState.plan,
            revision: newPlanState.revision,
            source: 'server-deterministic',
            recipes: [for (final r in recipes) r.toMap()],
            updatedAtUtc: fact.recordedAtUtc,
          ),
        );
        planDeltas.add(PlanDelta(
          id: planId,
          revision: newPlanState.revision,
          isCompleted: newPlanState.isCompleted,
          plan: newPlanState.plan,
        ));
      }

      return FactOutcome(
        result: FactResult(id: fact.id, applied: true),
        progress: progressDeltas,
        streak: newStreak == null ? null : LegacyDocs.streakDelta(newStreak),
        plans: planDeltas,
      );
    });
  }

  /// Copy of [fact] with `recordedAtUtc` replaced (the clock-skew clamp).
  static SessionFact _withRecordedAtUtc(SessionFact fact, DateTime instant) =>
      SessionFact(
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
        recordedAtUtc: instant.toUtc(),
      );

  // ── review ───────────────────────────────────────────────────────────

  Future<FactOutcome> _applyReview(String uid, ReviewFact fact) {
    return gateway.runTransaction<FactOutcome>((tx) async {
      final factPath = UserPaths.factDoc(uid, fact.id);
      final cardPath = UserPaths.flashcardDoc(uid, fact.cardId);
      final placeholderPath = UserPaths.placeholderDoc(uid, fact.cardId);

      final existingLog = await tx.get(factPath);
      final cardDoc = await tx.get(cardPath);
      final placeholderDoc =
          cardDoc == null ? await tx.get(placeholderPath) : null;

      if (existingLog != null) {
        tx.set(factPath, existingLog);
        final delta = _cardDeltaFromDocs(cardDoc, placeholderDoc);
        return FactOutcome(
          result: FactResult(id: fact.id, applied: false),
          cards: [?delta],
        );
      }

      Flashcard? prior;
      try {
        if (cardDoc != null) {
          prior = LegacyDocs.flashcardFromDoc(cardDoc);
        } else if (placeholderDoc != null) {
          prior = LegacyDocs.flashcardFromDoc(placeholderDoc);
        }
      } on Object {
        prior = null; // corrupt doc → fold from placeholder state
      }

      final fold = SrsFold.fold(
        priorCards: {fact.cardId: ?prior},
        reviews: [fact],
        priorPlaceholderIds: {
          if (cardDoc == null && placeholderDoc != null) fact.cardId,
        },
        nowUtc: nowUtc(),
      );
      final newCard = fold.cards[fact.cardId]!;
      // A review can never turn a real card into a placeholder; it stays a
      // placeholder only while no real card doc exists.
      final isPlaceholder = cardDoc == null;
      final stamp = newCard.lastReviewedAt?.toUtc() ?? fact.reviewedAtUtc;

      tx.set(factPath, _factLogDoc(fact));
      tx.set(
        UserPaths.reviewDoc(uid, fact.id),
        LegacyDocs.reviewDocFromFact(fact),
      );
      if (isPlaceholder) {
        tx.set(placeholderPath, {
          ...LegacyDocs.flashcardToDoc(newCard, stamp),
          'isPlaceholder': true,
        });
      } else {
        tx.set(cardPath, LegacyDocs.flashcardToDoc(newCard, stamp));
      }

      return FactOutcome(
        result: FactResult(id: fact.id, applied: true),
        cards: [LegacyDocs.cardDelta(newCard, isPlaceholder: isPlaceholder)],
      );
    });
  }

  // ── cardCreated ──────────────────────────────────────────────────────

  Future<FactOutcome> _applyCardCreated(String uid, CardCreatedFact fact) {
    return gateway.runTransaction<FactOutcome>((tx) async {
      final factPath = UserPaths.factDoc(uid, fact.id);
      final cardPath = UserPaths.flashcardDoc(uid, fact.id);
      final placeholderPath = UserPaths.placeholderDoc(uid, fact.id);

      final existingLog = await tx.get(factPath);
      final cardDoc = await tx.get(cardPath);
      final placeholderDoc = await tx.get(placeholderPath);

      if (existingLog != null) {
        tx.set(factPath, existingLog);
        final delta = _cardDeltaFromDocs(cardDoc, placeholderDoc);
        return FactOutcome(
          result: FactResult(id: fact.id, applied: false),
          cards: [?delta],
        );
      }

      tx.set(factPath, _factLogDoc(fact));

      if (cardDoc != null) {
        // Dual window: a legacy device already pushed this card (backfill
        // overlap). Its synced SRS state is at least as fresh as creation
        // defaults — never clobber it; just record the fact.
        final delta = _cardDeltaFromDocs(cardDoc, null);
        return FactOutcome(
          result: FactResult(id: fact.id, applied: true),
          cards: [?delta],
        );
      }

      Flashcard newCard;
      if (placeholderDoc != null) {
        // Late identity attach (§5 unknown-card tolerance): folded SRS
        // state survives — those reviews already happened.
        Flashcard placeholder;
        try {
          placeholder = LegacyDocs.flashcardFromDoc(placeholderDoc);
        } on Object {
          placeholder = SrsFold.fromCardCreated(fact);
        }
        newCard = placeholder.id == fact.id
            ? SrsFold.attachIdentity(placeholder, fact)
            : SrsFold.fromCardCreated(fact);
        tx.delete(placeholderPath);
      } else {
        newCard = SrsFold.fromCardCreated(fact);
      }

      tx.set(
        cardPath,
        LegacyDocs.flashcardToDoc(
          newCard,
          fact.createdAtUtc,
          // The fact's raw blobs ride along verbatim (rules-shape compat).
          questionData: fact.questionData,
          answerData: fact.answerData,
        ),
      );

      return FactOutcome(
        result: FactResult(id: fact.id, applied: true),
        cards: [LegacyDocs.cardDelta(newCard, isPlaceholder: false)],
      );
    });
  }

  // ── planGenerated ────────────────────────────────────────────────────

  Future<FactOutcome> _applyPlanGenerated(String uid, PlanGeneratedFact fact) {
    return gateway.runTransaction<FactOutcome>((tx) async {
      final factPath = UserPaths.factDoc(uid, fact.id);
      final planId = PlanIdentity.idFor(fact.profileId, fact.date);
      final planPath = UserPaths.planDoc(uid, planId);

      final existingLog = await tx.get(factPath);
      final planDoc = await tx.get(planPath);

      if (existingLog != null) {
        tx.set(factPath, existingLog);
        final delta = LegacyDocs.planDeltaFromDoc(planId, planDoc) ??
            PlanDelta(
              id: planId,
              revision: fact.revision,
              isCompleted: false,
              plan: fact.plan,
            );
        return FactOutcome(
          result: FactResult(id: fact.id, applied: false),
          plans: [delta],
        );
      }

      final incumbent = LegacyDocs.planStateFromDoc(planDoc);
      final reconciled = PlanDerivation.reconcileClaims(
        current: {if (incumbent != null) planId: incumbent.state},
        claims: [fact],
      );
      final winner = reconciled[planId]!;
      final claimWon =
          incumbent == null || fact.revision > incumbent.state.revision;

      tx.set(factPath, _factLogDoc(fact));
      if (claimWon) {
        // Claims carry no recipes (they don't ride the fact) — GET
        // /v1/me/plan serves [] for adopted offline plans, like legacy
        // client-mirrored docs.
        tx.set(
          planPath,
          LegacyDocs.planToDoc(
            plan: winner.plan,
            revision: winner.revision,
            source: 'client-offline',
            recipes: const [],
            updatedAtUtc: nowUtc(),
          ),
        );
      }

      // A losing claim is still CONSUMED (`applied:true` — it will never
      // retry); the canonical plan in `derived.plans` is how the client
      // adopts the winner (§5: no work lost, completion rides on sessions).
      return FactOutcome(
        result: FactResult(id: fact.id, applied: true),
        plans: [
          PlanDelta(
            id: planId,
            revision: winner.revision,
            isCompleted: winner.isCompleted,
            plan: winner.plan,
          ),
        ],
      );
    });
  }

  // ── rotationChanged ──────────────────────────────────────────────────

  /// Applies one rotation edit (Phase 5 task 4): LWW fold per profileId
  /// into `users/{uid}/meta/manzil_rotation`. A losing (older) edit is
  /// still CONSUMED (`applied:true` — it will never retry); the canonical
  /// rotation in `derived.rotations` is how the client adopts the winner.
  ///
  /// Deliberately does NOT regenerate the plan: on-device a rotation edit
  /// takes effect at the NEXT generation (get-or-create or post-session
  /// regeneration), and the server matches that semantics exactly.
  Future<FactOutcome> _applyRotationChanged(
    String uid,
    RotationChangedFact originalFact,
  ) {
    return gateway.runTransaction<FactOutcome>((tx) async {
      // Clock-skew clamp (the recordedAtUtc clamp, ported): a far-future
      // `changedAtUtc` would win LWW against every legitimate edit until
      // that instant passes — the rotation would be stuck for years.
      final nowInstant = nowUtc();
      final fact = originalFact.changedAtUtc.isAfter(nowInstant)
          ? RotationChangedFact(
              id: originalFact.id,
              coreVersion: originalFact.coreVersion,
              profileId: originalFact.profileId,
              juz: originalFact.juz,
              changedAtUtc: nowInstant.toUtc(),
            )
          : originalFact;

      final factPath = UserPaths.factDoc(uid, fact.id);
      final rotationPath = UserPaths.rotationDoc(uid);

      final existingLog = await tx.get(factPath);
      final rotationDoc = await tx.get(rotationPath);
      final states = LegacyDocs.rotationStatesFromDoc(rotationDoc);

      if (existingLog != null) {
        // Replay: current canonical rotation for this profile.
        tx.set(factPath, existingLog); // keep the tx non-read-only
        final state = states[fact.profileId];
        return FactOutcome(
          result: FactResult(id: fact.id, applied: false),
          rotations: [
            if (state != null)
              LegacyDocs.rotationDelta(fact.profileId, state),
          ],
        );
      }

      final folded = RotationDerivation.fold(prior: states, facts: [fact]);
      tx.set(factPath, _factLogDoc(originalFact));
      tx.set(rotationPath, LegacyDocs.rotationStatesToDoc(folded));

      return FactOutcome(
        result: FactResult(id: fact.id, applied: true),
        rotations: [
          LegacyDocs.rotationDelta(fact.profileId, folded[fact.profileId]!),
        ],
      );
    });
  }

  // ── shared helpers ───────────────────────────────────────────────────

  ProgressDelta? _progressDeltaFromDoc(
    Map<String, dynamic>? doc,
    DateTime fallbackUpdatedAt,
  ) {
    if (doc == null) return null;
    try {
      final progress = LegacyDocs.progressFromDoc(doc);
      return ProgressDelta.fromPageProgress(
        progress,
        updatedAtUtc: _parseInstant(doc['updatedAt'], fallbackUpdatedAt),
      );
    } on Object {
      return null;
    }
  }

  CardSrsDelta? _cardDeltaFromDocs(
    Map<String, dynamic>? cardDoc,
    Map<String, dynamic>? placeholderDoc,
  ) {
    final doc = cardDoc ?? placeholderDoc;
    if (doc == null) return null;
    try {
      return LegacyDocs.cardDelta(
        LegacyDocs.flashcardFromDoc(doc),
        isPlaceholder: cardDoc == null,
      );
    } on Object {
      return null;
    }
  }

  /// Tolerant instant parse: fact-written docs hold ISO strings; legacy
  /// client docs hold Firestore Timestamps (which expose `toDate()`).
  static DateTime _parseInstant(Object? raw, DateTime fallback) {
    if (raw is DateTime) return raw.toUtc();
    if (raw is String) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed.toUtc();
    }
    try {
      final date = (raw as dynamic).toDate();
      if (date is DateTime) return date.toUtc();
    } on Object {
      // fall through
    }
    return fallback.toUtc();
  }
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
