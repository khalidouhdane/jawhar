/// Firestore paths + codecs for the LEGACY document shapes (the ones
/// `firestore.rules` validates and today's CloudSyncService reads/writes).
///
/// Dual-window rule (roadmap §8 Phase 4b task 3 / R2): during Phases 4–6
/// the facts write path WRITES these exact legacy shapes and READS them as
/// its prior state. That makes the legacy mirror and the fact-derived state
/// one and the same storage — a legacy-writer device and a facts-writer
/// device fold into the same documents, so mixed fleets cannot drift.
/// Server-only state (the facts log, SRS placeholders, the per-user
/// `writePath` flag, analytics cache) lives in collections/doc-ids the
/// rules never allow clients to touch.
///
/// Determinism note: every timestamp written by the facts path comes from
/// the FACT (`recordedAtUtc` / `reviewedAtUtc` / fold output), never from
/// the wall clock, so a replayed fact reads back byte-identical state
/// (§5 idempotency). Wall-clock stamps appear only on diagnostics fields
/// (`appliedAtUtc` on the fact log) that never reach a response.
library;

import 'package:hifz_core/hifz_core.dart';

/// All Firestore paths the facts/analytics/bootstrap handlers touch.
abstract final class UserPaths {
  /// Root profile mirror (legacy: `MemoryProfile.toMap()` + `updatedAt`).
  static String userDoc(String uid) => 'users/$uid';

  /// Legacy page-progress mirror, one doc per page number.
  static String progressDoc(String uid, int page) =>
      'users/$uid/progress/$page';
  static String progressCollection(String uid) => 'users/$uid/progress';

  /// Legacy append-only session docs (`SessionRecord.toMap()` + `createdAt`).
  static String sessionDoc(String uid, String sessionId) =>
      'users/$uid/sessions/$sessionId';
  static String sessionsCollection(String uid) => 'users/$uid/sessions';

  /// Legacy plan docs at the deterministic id
  /// `'${profileId}_${localMidnightIso}'`. ONE doc per (profileId, date):
  /// the `revision` field bumps in place (highest-revision-wins is then a
  /// single monotonic doc, and legacy pull readers keep seeing exactly one
  /// plan per day — the shape they already understand).
  static String planDoc(String uid, String planId) =>
      'users/$uid/plans/$planId';
  static String plansCollection(String uid) => 'users/$uid/plans';

  /// Legacy flashcard docs (`Flashcard.toMap()` snake_case + `updatedAt`).
  static String flashcardDoc(String uid, String cardId) =>
      'users/$uid/flashcards/$cardId';

  /// Legacy review-event docs (`FlashcardReview.toMap()` + `syncedAt`).
  static String reviewDoc(String uid, String reviewId) =>
      'users/$uid/flashcard_reviews/$reviewId';

  /// Legacy streak mirror (rules: `users/{uid}/meta/streak`).
  static String streakDoc(String uid) => 'users/$uid/meta/streak';

  /// SERVER-ONLY: canonical manzil rotation, keyed by profileId inside the
  /// doc (roadmap §8 Phase 5 task 4 — "server-persisted plan context under
  /// users/{uid}/meta/"). Rules allow clients only `meta/settings` and
  /// `meta/streak`, so clients can never write this directly — edits flow
  /// exclusively through `rotationChanged` facts.
  /// Shape: `{profiles: {profileId: {juz: [...], changedAtUtc, factId}},
  /// updatedAt}` — `updatedAt` is the max winning `changedAtUtc`
  /// (deterministic, never the wall clock, §5 idempotency).
  static String rotationDoc(String uid) => 'users/$uid/meta/manzil_rotation';

  /// SERVER-ONLY: plural profile keyspace (§5 #7 — profiles keyed by
  /// profileId from day one). The legacy ROOT doc (`users/{uid}`) keeps
  /// mirroring the device's active profile for dual-window pull compat;
  /// this collection is what makes a SECOND profile's facts derivable.
  static String profileDoc(String uid, String profileId) =>
      'users/$uid/profiles/$profileId';

  /// SERVER-ONLY: plural-safe page progress for NON-root profiles. The
  /// legacy `users/{uid}/progress/{page}` keyspace is page-keyed for the
  /// whole account (one doc per page number), so a foreign profile's
  /// promotion writing there would clobber the root profile's docs — each
  /// non-root profile gets its own subcollection instead.
  static String profileProgressDoc(String uid, String profileId, int page) =>
      'users/$uid/profiles/$profileId/progress/$page';
  static String profileProgressCollection(String uid, String profileId) =>
      'users/$uid/profiles/$profileId/progress';

  /// SERVER-ONLY: the durable (uid, fact.id) log — both the idempotency
  /// memory (§5 upsert on `(uid, fact.id)`) and the re-derivation source
  /// (R2: corruption is re-derivable from facts). Clients cannot write here
  /// (no rules path matches).
  static String factDoc(String uid, String factId) =>
      'users/$uid/facts/$factId';

  /// SERVER-ONLY: SRS state for reviews that arrived before their
  /// `cardCreated` fact (§5 unknown-card tolerance). Kept OUT of
  /// `flashcards/` so legacy pull never hydrates an identity-less card
  /// into a device's deck.
  static String placeholderDoc(String uid, String cardId) =>
      'users/$uid/srs_placeholders/$cardId';

  /// SERVER-ONLY: per-user server config. `writePath: facts|legacy` lives
  /// here — rules allow clients only `meta/settings` and `meta/streak`, so
  /// a client can never flip its own flag.
  static String serverMetaDoc(String uid) => 'users/$uid/meta/server';

  /// SERVER-ONLY: 24h analytics snapshot cache (roadmap §5 #10).
  static String analyticsCacheDoc(
    String uid,
    String profileId,
    String startDate,
    String endDate,
  ) =>
      'users/$uid/analytics/${profileId}_${startDate}_$endDate';
}

/// Codecs between hifz_core models and the legacy doc shapes.
abstract final class LegacyDocs {
  /// `PageProgress` → legacy progress doc. [updatedAtUtc] is the FACT's
  /// instant (deterministic), encoded as an ISO string — legacy clients
  /// `remove('updatedAt')` before parsing, so the Timestamp→string type
  /// change is invisible to them.
  static Map<String, dynamic> progressToDoc(
    PageProgress progress,
    DateTime updatedAtUtc,
  ) =>
      {
        ...progress.toMap(),
        'updatedAt': WireCodec.encodeUtcInstant(updatedAtUtc),
      };

  /// Legacy progress doc → `PageProgress` (healing parser — one bad doc
  /// must not take a handler down; callers decide whether to skip).
  static PageProgress progressFromDoc(Map<String, dynamic> doc) =>
      PageProgress.fromMap(doc);

  /// Legacy streak doc → `StreakData`. Tolerates both the device's
  /// local-naive midnight ISO and date-only strings.
  static StreakData streakFromDoc(Map<String, dynamic>? doc) {
    if (doc == null) return const StreakData();
    final rawLast = doc['lastActiveDate'];
    DateTime? last;
    if (rawLast is String && rawLast.isNotEmpty) {
      final parsed = DateTime.tryParse(rawLast);
      if (parsed != null) {
        last = DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    final total = doc['totalActiveDays'];
    return StreakData(
      totalActiveDays: total is int && total >= 0 ? total : 0,
      lastActiveDate: last,
    );
  }

  /// `StreakData` → legacy streak doc (same shape `_writeStreak` produces:
  /// full local-naive midnight ISO, not a date-only string).
  static Map<String, dynamic> streakToDoc(
    StreakData streak,
    DateTime updatedAtUtc,
  ) =>
      {
        'totalActiveDays': streak.totalActiveDays,
        'lastActiveDate': streak.lastActiveDate?.toIso8601String(),
        'updatedAt': WireCodec.encodeUtcInstant(updatedAtUtc),
      };

  /// `StreakData` → the §5 wire delta (`lastActiveDate` as `YYYY-MM-DD`).
  static StreakDelta streakDelta(StreakData streak) => StreakDelta(
        totalActiveDays: streak.totalActiveDays,
        lastActiveDate: streak.lastActiveDate == null
            ? null
            : _isoDay(streak.lastActiveDate!),
      );

  /// Session fact → legacy session doc (`SessionRecord.toMap()` shape).
  /// The fact id IS the session id (the client already uses one UUID for
  /// both); `date` is the fact's `recordedAtUtc` — exactly the
  /// `DateTime.now().toUtc()` the device stores on a `SessionRecord`.
  static Map<String, dynamic> sessionDocFromFact(SessionFact fact) {
    final record = SessionRecord(
      id: fact.id,
      profileId: fact.profileId,
      date: fact.recordedAtUtc.toUtc(),
      durationMinutes: fact.durationMinutes,
      sabaqCompleted: fact.sabaq.completed,
      sabqiCompleted: fact.sabqi.completed,
      manzilCompleted: fact.manzil.completed,
      sabaqAssessment: fact.sabaq.assessment,
      sabqiAssessment: fact.sabqi.assessment,
      manzilAssessment: fact.manzil.assessment,
      sabaqPage: fact.sabaq.page,
      sabqiPages: fact.sabqi.pages,
      manzilPages: fact.manzil.pages,
      repCount: fact.repCount,
    );
    return {
      ...record.toMap(),
      'createdAt': WireCodec.encodeUtcInstant(fact.recordedAtUtc),
    };
  }

  /// Review fact → legacy review-event doc (`FlashcardReview.toMap()`
  /// shape + `syncedAt`). The fact id IS the review id.
  static Map<String, dynamic> reviewDocFromFact(ReviewFact fact) => {
        'id': fact.id,
        'card_id': fact.cardId,
        'rating': fact.rating.index,
        'reviewed_at': WireCodec.encodeUtcInstant(fact.reviewedAtUtc),
        'syncedAt': WireCodec.encodeUtcInstant(fact.reviewedAtUtc),
      };

  /// `Flashcard` → legacy flashcard doc. [questionData]/[answerData], when
  /// given, are the fact's raw JSON-string blobs (kept verbatim for
  /// rules-shape rollback compat) — otherwise the card's own maps encode.
  static Map<String, dynamic> flashcardToDoc(
    Flashcard card,
    DateTime updatedAtUtc, {
    String? questionData,
    String? answerData,
  }) {
    final map = card.toMap();
    if (questionData != null) map['question_data'] = questionData;
    if (answerData != null) map['answer_data'] = answerData;
    return {...map, 'updatedAt': WireCodec.encodeUtcInstant(updatedAtUtc)};
  }

  /// Legacy flashcard / placeholder doc → `Flashcard`.
  static Flashcard flashcardFromDoc(Map<String, dynamic> doc) =>
      Flashcard.fromMap(doc);

  /// Folded card state → the §5 wire delta. `dueDate` stays tz-naive
  /// (a local-day concept, never `.toUtc()` — hifz_core contract).
  static CardSrsDelta cardDelta(Flashcard card, {required bool isPlaceholder}) =>
      CardSrsDelta(
        id: card.id,
        interval: card.interval,
        easeFactor: card.easeFactor,
        dueDate: card.dueDate,
        reviewCount: card.reviewCount,
        lastReviewedAtUtc: card.lastReviewedAt?.toUtc(),
        isPlaceholder: isPlaceholder,
      );

  /// Plan + server fields → legacy-compatible plan doc (same recipe as
  /// `plan_get.dart`: `DailyPlan.toMap()` first so legacy `fromMap` pulls
  /// keep parsing, then the server fields legacy readers ignore).
  static Map<String, dynamic> planToDoc({
    required DailyPlan plan,
    required int revision,
    required String source,
    required List<Map<String, dynamic>> recipes,
    required DateTime updatedAtUtc,
  }) =>
      {
        ...plan.toMap(),
        'revision': revision,
        'source': source,
        'recipes': recipes,
        'createdAt': WireCodec.encodeUtcInstant(updatedAtUtc),
        'updatedAt': WireCodec.encodeUtcInstant(updatedAtUtc),
      };

  /// Stored plan doc → `(state, source)`; revision-less legacy mirror docs
  /// are revision 0 (`client-legacy`), matching `GET /v1/me/plan`.
  static ({PlanRevisionState state, String source})? planStateFromDoc(
    Map<String, dynamic>? doc,
  ) {
    if (doc == null) return null;
    final DailyPlan plan;
    try {
      plan = DailyPlan.fromMap(doc);
    } on Object {
      return null;
    }
    return (
      state: PlanRevisionState(
        plan: plan,
        revision: doc['revision'] as int? ?? 0,
        isCompleted: plan.isCompleted,
      ),
      source: doc['source'] as String? ?? 'client-legacy',
    );
  }

  /// Stored plan doc → the §5 wire delta (null when unparseable).
  static PlanDelta? planDeltaFromDoc(String planId, Map<String, dynamic>? doc) {
    final parsed = planStateFromDoc(doc);
    if (parsed == null) return null;
    return PlanDelta(
      id: planId,
      revision: parsed.state.revision,
      isCompleted: parsed.state.isCompleted,
      plan: parsed.state.plan,
    );
  }

  /// Rotation doc → profileId-keyed [RotationState] map (healing parser:
  /// malformed per-profile entries are skipped, never fatal).
  static Map<String, RotationState> rotationStatesFromDoc(
    Map<String, dynamic>? doc,
  ) {
    final raw = doc?['profiles'];
    if (raw is! Map) return const {};
    final result = <String, RotationState>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! Map) continue;
      final rawJuz = value['juz'];
      final rawInstant = value['changedAtUtc'];
      final rawFactId = value['factId'];
      if (rawJuz is! List || rawInstant is! String || rawFactId is! String) {
        continue;
      }
      final juz = <int>[];
      var bad = false;
      for (final element in rawJuz) {
        if (element is int &&
            element >= FactBounds.minJuz &&
            element <= FactBounds.maxJuz) {
          juz.add(element);
        } else {
          bad = true;
          break;
        }
      }
      final instant = DateTime.tryParse(rawInstant);
      if (bad || instant == null) continue;
      result[key] = RotationState(
        juz: juz,
        changedAtUtc: instant.toUtc(),
        factId: rawFactId,
      );
    }
    return result;
  }

  /// [RotationState] map → rotation doc. `updatedAt` is the max winning
  /// `changedAtUtc` — deterministic so a replayed fact reads back
  /// byte-identical state (§5 idempotency), never the wall clock.
  static Map<String, dynamic> rotationStatesToDoc(
    Map<String, RotationState> states,
  ) {
    DateTime? latest;
    for (final state in states.values) {
      if (latest == null || state.changedAtUtc.isAfter(latest)) {
        latest = state.changedAtUtc;
      }
    }
    return {
      'profiles': {
        for (final entry in states.entries)
          entry.key: {
            'juz': entry.value.juz,
            'changedAtUtc': WireCodec.encodeUtcInstant(entry.value.changedAtUtc),
            'factId': entry.value.factId,
          },
      },
      if (latest != null) 'updatedAt': WireCodec.encodeUtcInstant(latest),
    };
  }

  /// One profile's [RotationState] → the §5 wire delta.
  static RotationDelta rotationDelta(String profileId, RotationState state) =>
      RotationDelta(
        profileId: profileId,
        juz: state.juz,
        changedAtUtc: state.changedAtUtc,
      );

  static String _isoDay(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
