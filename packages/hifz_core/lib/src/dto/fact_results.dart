/// Reply types for `POST /v1/me/facts` (roadmap §5).
///
/// A replay is never an error: it returns a byte-identical `200` with
/// `applied: false` and current canonical derived state. One poisoned item
/// never blocks the queue — it gets a per-item [ApiError] while the rest of
/// the batch applies.
library;

import '../models/hifz_models.dart';
import 'api_error.dart';
import 'dataset_epoch.dart';
import 'facts.dart';
import 'wire_codec.dart';

/// Per-fact outcome: `{"id": "uuid", "applied": true}` — `applied: false`
/// means either an idempotent replay (no [error]) or a poisoned item
/// ([error] present, outbox row kept for diagnostics, never retried when
/// `retryable` is false).
final class FactResult {
  final String id;
  final bool applied;
  final ApiError? error;

  const FactResult({required this.id, required this.applied, this.error});

  factory FactResult.fromJson(Map<String, dynamic> json) => FactResult(
    id: WireCodec.requireString(json, 'id'),
    applied: WireCodec.requireBool(json, 'applied'),
    error: json['error'] == null
        ? null
        : ApiError.fromJson(WireCodec.requireMap(json, 'error')),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'applied': applied,
    if (error != null) 'error': error!.toJson(),
  };
}

/// Canonical derived page progress, overwriting the client cache.
///
/// Carries `profileId` (the device-global SQLite cache keys progress by
/// `(pageNumber, profileId)`) and the server `updatedAtUtc` used by
/// `GET /v1/me/progress?since=`.
final class ProgressDelta {
  final String profileId;
  final int pageNumber;
  final PageStatus status;
  final int reviewCount;
  final int? lastVerseLearned;
  final int? totalVersesOnPage;
  final DateTime? lastReviewedAtUtc;
  final DateTime? memorizedAtUtc;
  final DateTime updatedAtUtc;

  const ProgressDelta({
    required this.profileId,
    required this.pageNumber,
    required this.status,
    required this.reviewCount,
    this.lastVerseLearned,
    this.totalVersesOnPage,
    this.lastReviewedAtUtc,
    this.memorizedAtUtc,
    required this.updatedAtUtc,
  });

  factory ProgressDelta.fromJson(Map<String, dynamic> json) => ProgressDelta(
    profileId: WireCodec.requireString(json, 'profileId'),
    pageNumber: WireCodec.requireInt(
      json,
      'pageNumber',
      min: FactBounds.minPage,
      max: FactBounds.maxPage,
    ),
    status: WireCodec.requireEnumIndex(json, 'status', PageStatus.values),
    reviewCount: WireCodec.requireInt(json, 'reviewCount', min: 0),
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
    lastReviewedAtUtc: json['lastReviewedAt'] == null
        ? null
        : WireCodec.requireUtcInstant(json, 'lastReviewedAt'),
    memorizedAtUtc: json['memorizedAt'] == null
        ? null
        : WireCodec.requireUtcInstant(json, 'memorizedAt'),
    updatedAtUtc: WireCodec.requireUtcInstant(json, 'updatedAt'),
  );

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'pageNumber': pageNumber,
    'status': status.index,
    'reviewCount': reviewCount,
    'lastVerseLearned': lastVerseLearned,
    'totalVersesOnPage': totalVersesOnPage,
    'lastReviewedAt': lastReviewedAtUtc == null
        ? null
        : WireCodec.encodeUtcInstant(lastReviewedAtUtc!),
    'memorizedAt': memorizedAtUtc == null
        ? null
        : WireCodec.encodeUtcInstant(memorizedAtUtc!),
    'updatedAt': WireCodec.encodeUtcInstant(updatedAtUtc),
  };

  /// The cache row this delta overwrites.
  PageProgress toPageProgress() => PageProgress(
    pageNumber: pageNumber,
    profileId: profileId,
    status: status,
    lastReviewedAt: lastReviewedAtUtc,
    reviewCount: reviewCount,
    memorizedAt: memorizedAtUtc,
    lastVerseLearned: lastVerseLearned,
    totalVersesOnPage: totalVersesOnPage,
  );

  /// Builds the delta from a derived [PageProgress] (server side).
  factory ProgressDelta.fromPageProgress(
    PageProgress progress, {
    required DateTime updatedAtUtc,
  }) => ProgressDelta(
    profileId: progress.profileId,
    pageNumber: progress.pageNumber,
    status: progress.status,
    reviewCount: progress.reviewCount,
    lastVerseLearned: progress.lastVerseLearned,
    totalVersesOnPage: progress.totalVersesOnPage,
    lastReviewedAtUtc: progress.lastReviewedAt?.toUtc(),
    memorizedAtUtc: progress.memorizedAt?.toUtc(),
    updatedAtUtc: updatedAtUtc,
  );
}

/// Canonical SRS state for one card, overwriting the client copy.
///
/// `dueDate` is the timezone-naive local-midnight-anchored value the SRS
/// engine produces (`SrsEngine.processReview`); it is serialized as a naive
/// ISO-8601 string (no `Z`) — it is a local-day concept, not an instant.
final class CardSrsDelta {
  final String id;
  final double interval;
  final double easeFactor;
  final DateTime dueDate;
  final int reviewCount;
  final DateTime? lastReviewedAtUtc;

  /// True when the server only knows this card from review facts
  /// (unknown-card placeholder, §5) — identity attaches when/if the
  /// `cardCreated` fact arrives.
  final bool isPlaceholder;

  const CardSrsDelta({
    required this.id,
    required this.interval,
    required this.easeFactor,
    required this.dueDate,
    required this.reviewCount,
    this.lastReviewedAtUtc,
    this.isPlaceholder = false,
  });

  factory CardSrsDelta.fromJson(Map<String, dynamic> json) {
    final dueRaw = WireCodec.requireString(json, 'dueDate');
    final due = DateTime.tryParse(dueRaw);
    if (due == null) {
      throw const FormatException('Invalid "dueDate": expected ISO-8601');
    }
    return CardSrsDelta(
      id: WireCodec.requireString(json, 'id'),
      interval: WireCodec.requireDouble(json, 'interval', min: 0),
      easeFactor: WireCodec.requireDouble(json, 'easeFactor', min: 0),
      dueDate: due.isUtc
          ? DateTime(
              due.year,
              due.month,
              due.day,
              due.hour,
              due.minute,
              due.second,
              due.millisecond,
            )
          : due,
      reviewCount: WireCodec.requireInt(json, 'reviewCount', min: 0),
      lastReviewedAtUtc: json['lastReviewedAt'] == null
          ? null
          : WireCodec.requireUtcInstant(json, 'lastReviewedAt'),
      isPlaceholder: json['isPlaceholder'] == null
          ? false
          : WireCodec.requireBool(json, 'isPlaceholder'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'interval': interval,
    'easeFactor': easeFactor,
    'dueDate': dueDate.toIso8601String(),
    'reviewCount': reviewCount,
    'lastReviewedAt': lastReviewedAtUtc == null
        ? null
        : WireCodec.encodeUtcInstant(lastReviewedAtUtc!),
    if (isPlaceholder) 'isPlaceholder': true,
  };
}

/// Canonical streak, derived server-side from session facts on client-local
/// dates: `{"totalActiveDays": 41, "lastActiveDate": "2026-06-10"}`.
final class StreakDelta {
  final int totalActiveDays;

  /// Client-local `YYYY-MM-DD`, or null when no active day exists yet.
  final String? lastActiveDate;

  const StreakDelta({required this.totalActiveDays, this.lastActiveDate});

  factory StreakDelta.fromJson(Map<String, dynamic> json) => StreakDelta(
    totalActiveDays: WireCodec.requireInt(json, 'totalActiveDays', min: 0),
    lastActiveDate: json['lastActiveDate'] == null
        ? null
        : WireCodec.requireLocalDate(json, 'lastActiveDate'),
  );

  Map<String, dynamic> toJson() => {
    'totalActiveDays': totalActiveDays,
    'lastActiveDate': lastActiveDate,
  };

  /// The cache value this delta overwrites (`lastActiveDate` becomes a
  /// local-naive midnight, matching `recordActiveDay`'s stored shape).
  StreakData toStreakData() => StreakData(
    totalActiveDays: totalActiveDays,
    lastActiveDate: lastActiveDate == null
        ? null
        : DateTime.parse(lastActiveDate!),
  );
}

/// Canonical plan revision (§5 plan semantics): after a session fact the
/// server regenerates the next-revision plan and returns it here.
final class PlanDelta {
  final String id;
  final int revision;
  final bool isCompleted;
  final DailyPlan plan;

  const PlanDelta({
    required this.id,
    required this.revision,
    required this.isCompleted,
    required this.plan,
  });

  factory PlanDelta.fromJson(Map<String, dynamic> json) {
    final planJson = WireCodec.requireMap(json, 'plan');
    final DailyPlan plan;
    try {
      plan = DailyPlan.fromMap(planJson);
    } on Object catch (e) {
      throw FormatException('Invalid "plan": $e');
    }
    return PlanDelta(
      id: WireCodec.requireString(json, 'id'),
      revision: WireCodec.requireInt(
        json,
        'revision',
        min: 0,
        max: FactBounds.maxRevision,
      ),
      isCompleted: WireCodec.requireBool(json, 'isCompleted'),
      plan: plan,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'revision': revision,
    'isCompleted': isCompleted,
    'plan': PlanGeneratedFact.encodePlanPayload(plan),
  };
}

/// Canonical manzil rotation for one profile (server-owned state under
/// `users/{uid}/meta/manzil_rotation`, roadmap §8 Phase 5 task 4), derived
/// from `rotationChanged` facts via LWW on (`changedAtUtc`, fact id).
final class RotationDelta {
  final String profileId;

  /// Juz numbers 1–30, distinct, order preserved (semantic: the generator
  /// round-robins by index).
  final List<int> juz;

  /// The winning edit's instant — the LWW key a client can compare its own
  /// pending edits against.
  final DateTime changedAtUtc;

  const RotationDelta({
    required this.profileId,
    required this.juz,
    required this.changedAtUtc,
  });

  factory RotationDelta.fromJson(Map<String, dynamic> json) => RotationDelta(
    profileId: WireCodec.requireString(json, 'profileId'),
    juz: WireCodec.requireIntList(
      json,
      'juz',
      min: FactBounds.minJuz,
      max: FactBounds.maxJuz,
      maxLength: FactBounds.maxJuz,
    ),
    changedAtUtc: WireCodec.requireUtcInstant(json, 'changedAtUtc'),
  );

  Map<String, dynamic> toJson() => {
    'profileId': profileId,
    'juz': juz,
    'changedAtUtc': WireCodec.encodeUtcInstant(changedAtUtc),
  };
}

/// The `derived` envelope on a facts response — canonical state that
/// overwrites the client cache.
final class DerivedState {
  final List<ProgressDelta> progress;
  final List<CardSrsDelta> cards;
  final StreakDelta? streak;
  final List<PlanDelta> plans;
  final List<RotationDelta> rotations;

  const DerivedState({
    this.progress = const [],
    this.cards = const [],
    this.streak,
    this.plans = const [],
    this.rotations = const [],
  });

  factory DerivedState.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(
      String field,
      T Function(Map<String, dynamic>) fromJson,
    ) {
      final raw = json[field];
      if (raw == null) return const [];
      if (raw is! List) {
        throw FormatException('Invalid "$field": expected an array');
      }
      return [
        for (var i = 0; i < raw.length; i++)
          () {
            final item = raw[i];
            if (item is! Map) {
              throw FormatException('Invalid "$field[$i]": expected an object');
            }
            return fromJson(item.cast<String, dynamic>());
          }(),
      ];
    }

    return DerivedState(
      progress: parseList('progress', ProgressDelta.fromJson),
      cards: parseList('cards', CardSrsDelta.fromJson),
      streak: json['streak'] == null
          ? null
          : StreakDelta.fromJson(WireCodec.requireMap(json, 'streak')),
      plans: parseList('plans', PlanDelta.fromJson),
      // Additive (Phase 5): absent on pre-rotation servers -> [].
      rotations: parseList('rotations', RotationDelta.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
    'progress': [for (final p in progress) p.toJson()],
    'cards': [for (final c in cards) c.toJson()],
    'streak': streak?.toJson(),
    'plans': [for (final p in plans) p.toJson()],
    'rotations': [for (final r in rotations) r.toJson()],
  };
}

/// The full `200` body of `POST /v1/me/facts`.
final class FactsResponse {
  final DatasetEpoch datasetEpoch;
  final List<FactResult> results;
  final DerivedState derived;

  const FactsResponse({
    required this.datasetEpoch,
    required this.results,
    required this.derived,
  });

  factory FactsResponse.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'];
    if (rawResults is! List) {
      throw const FormatException('Invalid "results": expected an array');
    }
    return FactsResponse(
      datasetEpoch: DatasetEpoch.parse(json['datasetEpoch']),
      results: [
        for (var i = 0; i < rawResults.length; i++)
          () {
            final item = rawResults[i];
            if (item is! Map) {
              throw FormatException(
                'Invalid "results[$i]": expected an object',
              );
            }
            return FactResult.fromJson(item.cast<String, dynamic>());
          }(),
      ],
      derived: json['derived'] == null
          ? const DerivedState()
          : DerivedState.fromJson(WireCodec.requireMap(json, 'derived')),
    );
  }

  Map<String, dynamic> toJson() => {
    'datasetEpoch': datasetEpoch.toJson(),
    'results': [for (final r in results) r.toJson()],
    'derived': derived.toJson(),
  };
}
