import '../gateway/firestore_gateway.dart';

/// Outcome of an [AiQuota.tryConsume] attempt.
class QuotaDecision {
  const QuotaDecision({
    required this.allowed,
    required this.limit,
    required this.remaining,
  });

  /// Whether the call may proceed (a unit was consumed).
  final bool allowed;

  /// The configured daily limit.
  final int limit;

  /// Units left for the rest of the day AFTER this decision.
  final int remaining;
}

/// Per-uid DAILY AI quota (roadmap §5 #4/#9, §11's cost knob).
///
/// One shared daily bucket covers both AI endpoints (`plan:enhance` and
/// calibration) — the quota caps Vertex spend per user per day, not per
/// feature. A unit is consumed per ATTEMPT (before the Vertex call), so a
/// failing/retry-storming client cannot multiply spend past the cap.
abstract interface class AiQuota {
  /// Atomically consumes one unit of [uid]'s quota for [localDate]
  /// (a `YYYY-MM-DD` client-local date string — the same date semantics the
  /// roadmap §5 uses for plan keying and streaks).
  Future<QuotaDecision> tryConsume({
    required String uid,
    required String localDate,
  });
}

/// Firestore-backed [AiQuota]: one doc per uid at `aiQuota/{uid}` holding
/// `{date, count, updatedAt}`. The read-check-increment runs inside a
/// Firestore transaction, so concurrent calls cannot exceed the limit. A new
/// [localDate] resets the counter (stale rows from previous days are simply
/// overwritten — no cleanup job needed).
class FirestoreAiQuota implements AiQuota {
  FirestoreAiQuota(this._gateway, {required this.dailyLimit});

  final FirestoreGateway _gateway;

  /// Maximum AI calls per uid per client-local day (env AI_DAILY_QUOTA,
  /// default 10 — Config.aiDailyQuota).
  final int dailyLimit;

  static String docPath(String uid) => 'aiQuota/$uid';

  @override
  Future<QuotaDecision> tryConsume({
    required String uid,
    required String localDate,
  }) {
    return _gateway.runTransaction<QuotaDecision>((tx) async {
      final doc = await tx.get(docPath(uid));
      final sameDay = doc != null && doc['date'] == localDate;
      final used = sameDay ? (doc['count'] as int? ?? 0) : 0;
      final nowUtc = DateTime.now().toUtc().toIso8601String();
      if (used >= dailyLimit) {
        // Deliberately still a write: google_cloud_firestore 0.5.x fails the
        // commit/rollback of a READ-ONLY transaction ("Transaction is invalid
        // or expired", verified against the emulator), and the denial
        // timestamp is useful diagnostics anyway. `count` is preserved.
        tx.set(docPath(uid), {
          'date': localDate,
          'count': used,
          'updatedAt': nowUtc,
          'lastDeniedAt': nowUtc,
        });
        return QuotaDecision(allowed: false, limit: dailyLimit, remaining: 0);
      }
      tx.set(docPath(uid), {
        'date': localDate,
        'count': used + 1,
        'updatedAt': nowUtc,
      });
      return QuotaDecision(
        allowed: true,
        limit: dailyLimit,
        remaining: dailyLimit - used - 1,
      );
    });
  }
}
