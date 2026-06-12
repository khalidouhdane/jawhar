/// Fact DTOs for `POST /v1/me/facts` (roadmap §5 fact shapes).
///
/// Facts are append-only, UUID-keyed client writes; the server upserts on
/// `(uid, fact.id)` so a replay is never an error. All parsing here is
/// strict and bounds-checked: a malformed fact throws [FormatException]
/// (→ outbox row poisoned / HTTP 422), it is never silently coerced.
///
/// Wire conventions (decided here, shared by both tiers):
/// - `*Utc` instants: ISO-8601 with explicit `Z`; naive values rejected.
/// - `date`: client-local `YYYY-MM-DD` string — canonical for plan keying
///   and streak derivation (§5 date semantics).
/// - enums: integer indices matching today's `firestore.rules` bounds
///   (rating 0–3, assessment 0–2, card type 0–5); `planOrigin` is a name
///   string (`server`|`client`).
/// - `tzOffsetMinutes`: bounded to real-world offsets [-720, 840]
///   (UTC-12:00 … UTC+14:00).
library;

import 'dart:convert';

import '../models/flashcard_models.dart';
import '../models/hifz_models.dart';
import 'wire_codec.dart';

/// Where the plan a session ran against was generated.
enum PlanOrigin { server, client }

/// Bounds shared by fact validation (mirroring `firestore.rules`).
abstract final class FactBounds {
  static const int minPage = 1;
  static const int maxPage = 604;
  static const int minJuz = 1;
  static const int maxJuz = 30;
  static const int minTzOffsetMinutes = -720; // UTC-12:00
  static const int maxTzOffsetMinutes = 840; // UTC+14:00
  static const int maxDurationMinutes = 100000; // SessionRecord.fromMap clamp
  static const int maxRepCount = 100000;
  static const int maxRevision = 100000;
  static const int maxVerseNumber = 300; // loose per-page verse ceiling

  /// Per-list page-count cap (sabqi/manzil/actualPagesCovered). Real
  /// sessions cover ~20 pages at most; 150 is far above any legitimate use
  /// while keeping the server's per-fact transaction safely below
  /// Firestore's 500-mutation commit limit (3 lists x 150 + overhead).
  static const int maxPagesPerList = 150;

  /// Card question/answer blob cap (chars). Firestore documents top out at
  /// ~1 MiB; an oversize blob must become a poisoned row, not a
  /// permanently-retrying "internal" failure.
  static const int maxCardBlobLength = 262144; // 256 KiB

  /// `DailyPlan.aiReasoning` cap (chars) on embedded plan payloads.
  static const int maxAiReasoningLength = 16384;
}

/// Base type of every fact in a `POST /v1/me/facts` batch.
sealed class Fact {
  /// Idempotency key — RFC-4122 UUID, unique per fact, upsert key with uid.
  final String id;

  /// `hifz_core` semver the emitting client was compiled with (skew
  /// telemetry only; derived state is recomputed from facts).
  final String coreVersion;

  const Fact({required this.id, required this.coreVersion});

  /// Wire discriminator: `session` | `review` | `cardCreated` |
  /// `planGenerated` | `rotationChanged`.
  String get kind;

  Map<String, dynamic> toJson();

  /// Dispatches on `kind`. Unknown kinds are a [FormatException] — the
  /// server rejects (poisons) facts it cannot interpret rather than
  /// guessing.
  static Fact fromJson(Map<String, dynamic> json) {
    final kind = WireCodec.requireString(json, 'kind');
    switch (kind) {
      case SessionFact.kindValue:
        return SessionFact.fromJson(json);
      case ReviewFact.kindValue:
        return ReviewFact.fromJson(json);
      case CardCreatedFact.kindValue:
        return CardCreatedFact.fromJson(json);
      case PlanGeneratedFact.kindValue:
        return PlanGeneratedFact.fromJson(json);
      case RotationChangedFact.kindValue:
        return RotationChangedFact.fromJson(json);
      default:
        throw FormatException('Unknown fact kind "$kind"');
    }
  }
}

/// Sabaq (new memorization) outcome on a session fact:
/// `{"completed": true, "assessment": 2, "page": 134}`.
final class SabaqOutcome {
  final bool completed;
  final SelfAssessment? assessment;
  final int? page;

  const SabaqOutcome({required this.completed, this.assessment, this.page});

  factory SabaqOutcome.fromJson(Map<String, dynamic> json) => SabaqOutcome(
    completed: WireCodec.requireBool(json, 'completed'),
    assessment: WireCodec.optionalEnumIndex(
      json,
      'assessment',
      SelfAssessment.values,
    ),
    page: WireCodec.optionalInt(
      json,
      'page',
      min: FactBounds.minPage,
      max: FactBounds.maxPage,
    ),
  );

  Map<String, dynamic> toJson() => {
    'completed': completed,
    'assessment': assessment?.index,
    'page': page,
  };
}

/// Sabqi / manzil outcome on a session fact:
/// `{"completed": true, "assessment": 1, "pages": [130,131]}`.
final class PhaseOutcome {
  final bool completed;
  final SelfAssessment? assessment;
  final List<int> pages;

  const PhaseOutcome({
    required this.completed,
    this.assessment,
    this.pages = const [],
  });

  factory PhaseOutcome.fromJson(Map<String, dynamic> json) => PhaseOutcome(
    completed: WireCodec.requireBool(json, 'completed'),
    assessment: WireCodec.optionalEnumIndex(
      json,
      'assessment',
      SelfAssessment.values,
    ),
    pages: WireCodec.requireIntList(
      json,
      'pages',
      min: FactBounds.minPage,
      max: FactBounds.maxPage,
      maxLength: FactBounds.maxPagesPerList,
      allowMissing: true,
    ),
  );

  Map<String, dynamic> toJson() => {
    'completed': completed,
    'assessment': assessment?.index,
    'pages': pages,
  };
}

/// A completed study session (§5). Carries everything the server needs to
/// derive progress promotion byte-identically to the client's
/// `completeSession` (multi-page `actualPagesCovered`, verse carry-over),
/// plus the client-local `date` + `tzOffsetMinutes` that drive plan keying
/// and streak derivation.
final class SessionFact extends Fact {
  static const String kindValue = 'session';

  final String profileId;

  /// Client-local calendar date (`YYYY-MM-DD`) — canonical for plan keying
  /// and streak derivation.
  final String date;
  final int tzOffsetMinutes;
  final int durationMinutes;
  final int repCount;
  final SabaqOutcome sabaq;
  final PhaseOutcome sabqi;
  final PhaseOutcome manzil;

  /// The list `completeSession` really promotes from. Empty → fall back to
  /// `[sabaq.page]`, exactly like the client
  /// (`session_provider.dart` `completeSession`).
  final List<int> actualPagesCovered;
  final int? lastVerseLearned;
  final int? totalVersesOnPage;
  final String planId;
  final int planRevision;
  final PlanOrigin planOrigin;

  /// UTC instant the session was recorded — drives fold ordering and the
  /// derived progress timestamps; never used for day bucketing.
  final DateTime recordedAtUtc;

  const SessionFact({
    required super.id,
    required super.coreVersion,
    required this.profileId,
    required this.date,
    required this.tzOffsetMinutes,
    required this.durationMinutes,
    required this.repCount,
    required this.sabaq,
    required this.sabqi,
    required this.manzil,
    this.actualPagesCovered = const [],
    this.lastVerseLearned,
    this.totalVersesOnPage,
    required this.planId,
    required this.planRevision,
    required this.planOrigin,
    required this.recordedAtUtc,
  });

  @override
  String get kind => kindValue;

  factory SessionFact.fromJson(Map<String, dynamic> json) => SessionFact(
    id: WireCodec.requireUuid(json, 'id'),
    coreVersion: WireCodec.requireString(json, 'coreVersion'),
    profileId: WireCodec.requireId(json, 'profileId'),
    date: WireCodec.requireLocalDate(json, 'date'),
    tzOffsetMinutes: WireCodec.requireInt(
      json,
      'tzOffsetMinutes',
      min: FactBounds.minTzOffsetMinutes,
      max: FactBounds.maxTzOffsetMinutes,
    ),
    durationMinutes: WireCodec.requireInt(
      json,
      'durationMinutes',
      min: 0,
      max: FactBounds.maxDurationMinutes,
    ),
    repCount: WireCodec.requireInt(
      json,
      'repCount',
      min: 0,
      max: FactBounds.maxRepCount,
    ),
    sabaq: SabaqOutcome.fromJson(WireCodec.requireMap(json, 'sabaq')),
    sabqi: PhaseOutcome.fromJson(WireCodec.requireMap(json, 'sabqi')),
    manzil: PhaseOutcome.fromJson(WireCodec.requireMap(json, 'manzil')),
    actualPagesCovered: WireCodec.requireIntList(
      json,
      'actualPagesCovered',
      min: FactBounds.minPage,
      max: FactBounds.maxPage,
      maxLength: FactBounds.maxPagesPerList,
      allowMissing: true,
    ),
    lastVerseLearned: WireCodec.optionalInt(
      json,
      'lastVerseLearned',
      min: 1,
      max: FactBounds.maxVerseNumber,
    ),
    totalVersesOnPage: WireCodec.optionalInt(
      json,
      'totalVersesOnPage',
      min: 1,
      max: FactBounds.maxVerseNumber,
    ),
    planId: WireCodec.requireString(json, 'planId'),
    planRevision: WireCodec.requireInt(
      json,
      'planRevision',
      min: 0,
      max: FactBounds.maxRevision,
    ),
    planOrigin: switch (WireCodec.requireString(json, 'planOrigin')) {
      'server' => PlanOrigin.server,
      'client' => PlanOrigin.client,
      final other => throw FormatException(
        'Invalid "planOrigin": expected server|client, got "$other"',
      ),
    },
    recordedAtUtc: WireCodec.requireUtcInstant(json, 'recordedAtUtc'),
  );

  @override
  Map<String, dynamic> toJson() => {
    'kind': kindValue,
    'id': id,
    'coreVersion': coreVersion,
    'profileId': profileId,
    'date': date,
    'tzOffsetMinutes': tzOffsetMinutes,
    'durationMinutes': durationMinutes,
    'repCount': repCount,
    'sabaq': sabaq.toJson(),
    'sabqi': sabqi.toJson(),
    'manzil': manzil.toJson(),
    'actualPagesCovered': actualPagesCovered,
    'lastVerseLearned': lastVerseLearned,
    'totalVersesOnPage': totalVersesOnPage,
    'planId': planId,
    'planRevision': planRevision,
    'planOrigin': planOrigin.name,
    'recordedAtUtc': WireCodec.encodeUtcInstant(recordedAtUtc),
  };
}

/// Client-computed SRS state on a review fact — advisory telemetry only;
/// the server's fold is canonical.
final class ClientComputedSrs {
  final double interval;
  final double easeFactor;

  const ClientComputedSrs({required this.interval, required this.easeFactor});

  factory ClientComputedSrs.fromJson(Map<String, dynamic> json) =>
      ClientComputedSrs(
        interval: WireCodec.requireDouble(json, 'interval', min: 0),
        easeFactor: WireCodec.requireDouble(json, 'easeFactor', min: 0),
      );

  Map<String, dynamic> toJson() => {
    'interval': interval,
    'easeFactor': easeFactor,
  };
}

/// A flashcard review event (§5). The EVENT syncs, not the computed state;
/// the server folds reviews ordered by `reviewedAtUtc` with the due-date
/// day boundary from `tzOffsetMinutes`. Reviews for unknown `cardId`s are
/// accepted (placeholder SRS state — unknown-card tolerance, §5).
final class ReviewFact extends Fact {
  static const String kindValue = 'review';

  final String cardId;
  final FlashcardRating rating;
  final DateTime reviewedAtUtc;
  final int tzOffsetMinutes;
  final ClientComputedSrs? clientComputed;

  const ReviewFact({
    required super.id,
    required super.coreVersion,
    required this.cardId,
    required this.rating,
    required this.reviewedAtUtc,
    required this.tzOffsetMinutes,
    this.clientComputed,
  });

  @override
  String get kind => kindValue;

  factory ReviewFact.fromJson(Map<String, dynamic> json) => ReviewFact(
    id: WireCodec.requireUuid(json, 'id'),
    coreVersion: WireCodec.requireString(json, 'coreVersion'),
    // cardId becomes a Firestore doc-path segment server-side
    // (flashcards/{cardId}, srs_placeholders/{cardId}) — charset-validated
    // so a `/` can never change path depth into a stuck retrying row.
    cardId: WireCodec.requireId(json, 'cardId'),
    rating: WireCodec.requireEnumIndex(json, 'rating', FlashcardRating.values),
    reviewedAtUtc: WireCodec.requireUtcInstant(json, 'reviewedAtUtc'),
    tzOffsetMinutes: WireCodec.requireInt(
      json,
      'tzOffsetMinutes',
      min: FactBounds.minTzOffsetMinutes,
      max: FactBounds.maxTzOffsetMinutes,
    ),
    clientComputed: json['clientComputed'] == null
        ? null
        : ClientComputedSrs.fromJson(
            WireCodec.requireMap(json, 'clientComputed'),
          ),
  );

  @override
  Map<String, dynamic> toJson() => {
    'kind': kindValue,
    'id': id,
    'coreVersion': coreVersion,
    'cardId': cardId,
    'rating': rating.index,
    'reviewedAtUtc': WireCodec.encodeUtcInstant(reviewedAtUtc),
    'tzOffsetMinutes': tzOffsetMinutes,
    if (clientComputed != null) 'clientComputed': clientComputed!.toJson(),
  };
}

/// A new flashcard created on-device (§5). `questionData`/`answerData` are
/// opaque JSON-string blobs, kept only while rules-shape rollback compat is
/// needed (Phases 4–6).
final class CardCreatedFact extends Fact {
  static const String kindValue = 'cardCreated';

  final String profileId;
  final FlashcardType type;
  final String verseKey;
  final String questionData;
  final String answerData;
  final DateTime createdAtUtc;

  const CardCreatedFact({
    required super.id,
    required super.coreVersion,
    required this.profileId,
    required this.type,
    required this.verseKey,
    required this.questionData,
    required this.answerData,
    required this.createdAtUtc,
  });

  @override
  String get kind => kindValue;

  static final RegExp _verseKeyPattern = RegExp(r'^\d{1,3}:\d{1,3}$');

  factory CardCreatedFact.fromJson(Map<String, dynamic> json) {
    final verseKey = WireCodec.requireString(json, 'verseKey');
    if (!_verseKeyPattern.hasMatch(verseKey)) {
      throw FormatException(
        'Invalid "verseKey": expected surah:ayah, got "$verseKey"',
      );
    }
    for (final blobField in const ['questionData', 'answerData']) {
      final blob = WireCodec.requireString(
        json,
        blobField,
        allowEmpty: true,
        maxLength: FactBounds.maxCardBlobLength,
      );
      try {
        jsonDecode(blob.isEmpty ? '{}' : blob);
      } on FormatException {
        throw FormatException('Invalid "$blobField": not valid JSON');
      }
    }
    return CardCreatedFact(
      id: WireCodec.requireUuid(json, 'id'),
      coreVersion: WireCodec.requireString(json, 'coreVersion'),
      profileId: WireCodec.requireId(json, 'profileId'),
      type: WireCodec.requireEnumIndex(json, 'type', FlashcardType.values),
      verseKey: verseKey,
      questionData: WireCodec.requireString(
        json,
        'questionData',
        allowEmpty: true,
      ),
      answerData: WireCodec.requireString(json, 'answerData', allowEmpty: true),
      createdAtUtc: WireCodec.requireUtcInstant(json, 'createdAtUtc'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'kind': kindValue,
    'id': id,
    'coreVersion': coreVersion,
    'profileId': profileId,
    'type': type.index,
    'verseKey': verseKey,
    'questionData': questionData,
    'answerData': answerData,
    'createdAtUtc': WireCodec.encodeUtcInstant(createdAtUtc),
  };
}

/// An offline plan claim (§5 plan revision semantics). Reconciliation is
/// highest-revision-wins per `(profileId, date)`; ties go to the server
/// copy. Completion never rides on the plan — it rides on session facts —
/// so the embedded plan payload strips the `*DoneOffline` flags and
/// `isCompleted`.
final class PlanGeneratedFact extends Fact {
  static const String kindValue = 'planGenerated';

  final String profileId;

  /// Client-local calendar date (`YYYY-MM-DD`) the plan is keyed by.
  final String date;
  final int revision;
  final DailyPlan plan;

  const PlanGeneratedFact({
    required super.id,
    required super.coreVersion,
    required this.profileId,
    required this.date,
    required this.revision,
    required this.plan,
  });

  @override
  String get kind => kindValue;

  factory PlanGeneratedFact.fromJson(Map<String, dynamic> json) {
    final planJson = WireCodec.requireMap(json, 'plan');
    final DailyPlan plan;
    try {
      plan = DailyPlan.fromMap(planJson);
    } on Object catch (e) {
      throw FormatException('Invalid "plan": $e');
    }
    if ((plan.aiReasoning?.length ?? 0) > FactBounds.maxAiReasoningLength) {
      throw const FormatException(
        'Invalid "plan": aiReasoning exceeds '
        '${FactBounds.maxAiReasoningLength} characters',
      );
    }
    return PlanGeneratedFact(
      id: WireCodec.requireUuid(json, 'id'),
      coreVersion: WireCodec.requireString(json, 'coreVersion'),
      profileId: WireCodec.requireId(json, 'profileId'),
      date: WireCodec.requireLocalDate(json, 'date'),
      revision: WireCodec.requireInt(
        json,
        'revision',
        min: 0,
        max: FactBounds.maxRevision,
      ),
      plan: plan,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'kind': kindValue,
    'id': id,
    'coreVersion': coreVersion,
    'profileId': profileId,
    'date': date,
    'revision': revision,
    'plan': encodePlanPayload(plan),
  };

  /// Canonical wire payload for an embedded [DailyPlan]: the model's map
  /// codec minus the completion-tracking flags (`*DoneOffline`,
  /// `isCompleted`), which are NOT a sync surface (§5 — completion lives on
  /// session facts). `DailyPlan.fromMap` tolerates their absence.
  static Map<String, dynamic> encodePlanPayload(DailyPlan plan) => plan.toMap()
    ..remove('sabaqDoneOffline')
    ..remove('sabqiDoneOffline')
    ..remove('manzilDoneOffline')
    ..remove('isCompleted');
}

/// A manzil-rotation edit (roadmap §8 Phase 5 task 4). The rotation list
/// moves from device-local SQLite (`manzil_rotation` table) into
/// server-owned state under `users/{uid}/meta/manzil_rotation`, keyed by
/// `profileId`.
///
/// Transport decision (documented per the Phase 5 mandate): §5 prescribes
/// PUT snapshots only for settings/profiles and is silent on the rotation's
/// transport, so rotation edits ride the FACTS route — they queue offline
/// like everything else, replay for free under the `(uid, fact.id)` upsert,
/// and stay auditable in the durable facts log.
///
/// Semantics: the fact carries the FULL rotation list for one profile
/// (snapshot, not add/remove deltas — order matters: the generator
/// round-robins `rotationJuz[dayIndex % length]`). Reconciliation is
/// last-write-wins per `profileId` ordered by (`changedAtUtc`, `id`) — see
/// `RotationDerivation.fold`. A rotation change deliberately does NOT
/// regenerate the current plan revision: on-device, `getRotationJuz` is
/// read at generation time only, so the next generation (tomorrow's
/// get-or-create or the post-session regeneration) picks it up — the
/// server matches that exactly.
final class RotationChangedFact extends Fact {
  static const String kindValue = 'rotationChanged';

  final String profileId;

  /// The full rotation list (juz numbers 1–30, distinct, order preserved).
  /// Empty means "rotation cleared".
  final List<int> juz;

  /// UTC instant of the edit — the LWW ordering key.
  final DateTime changedAtUtc;

  const RotationChangedFact({
    required super.id,
    required super.coreVersion,
    required this.profileId,
    required this.juz,
    required this.changedAtUtc,
  });

  @override
  String get kind => kindValue;

  factory RotationChangedFact.fromJson(Map<String, dynamic> json) {
    final juz = WireCodec.requireIntList(
      json,
      'juz',
      min: FactBounds.minJuz,
      max: FactBounds.maxJuz,
      maxLength: FactBounds.maxJuz,
    );
    if (juz.toSet().length != juz.length) {
      throw const FormatException(
        'Invalid "juz": rotation entries must be distinct',
      );
    }
    return RotationChangedFact(
      id: WireCodec.requireUuid(json, 'id'),
      coreVersion: WireCodec.requireString(json, 'coreVersion'),
      profileId: WireCodec.requireId(json, 'profileId'),
      juz: juz,
      changedAtUtc: WireCodec.requireUtcInstant(json, 'changedAtUtc'),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'kind': kindValue,
    'id': id,
    'coreVersion': coreVersion,
    'profileId': profileId,
    'juz': juz,
    'changedAtUtc': WireCodec.encodeUtcInstant(changedAtUtc),
  };
}

/// The `POST /v1/me/facts` request body: `{"facts": [...]}` in outbox
/// `seq` order.
final class FactBatch {
  final List<Fact> facts;

  const FactBatch(this.facts);

  factory FactBatch.fromJson(Map<String, dynamic> json) {
    final raw = json['facts'];
    if (raw is! List) {
      throw const FormatException('Invalid "facts": expected an array');
    }
    return FactBatch([
      for (var i = 0; i < raw.length; i++)
        () {
          final item = raw[i];
          if (item is! Map) {
            throw FormatException('Invalid "facts[$i]": expected an object');
          }
          return Fact.fromJson(item.cast<String, dynamic>());
        }(),
    ]);
  }

  Map<String, dynamic> toJson() => {
    'facts': [for (final fact in facts) fact.toJson()],
  };
}
