import 'dart:convert';
import 'dart:math' as math;

import 'package:shelf/shelf.dart';

import 'auth.dart';

/// Per-uid token-bucket rate limiter (roadmap §8 Phase 2 task 3).
///
/// KNOWN LIMITATION (accepted at tester scale, documented per the roadmap):
/// state is in-memory PER INSTANCE. Cloud Run with min-instances=0 and a
/// couple of instances means a determined client gets `capacity × instances`
/// burst and loses its bucket on scale-to-zero. That is fine for ≤25 testers —
/// the limiter's job is to cap CPU/Firestore/Vertex burn from junk or looping
/// traffic, not to be a distributed quota (the DAILY AI quota in
/// `quota/ai_quota.dart` is Firestore-backed and instance-independent).
class TokenBucketRateLimiter {
  TokenBucketRateLimiter({
    required this.capacity,
    required this.refillPerMinute,
    DateTime Function()? now,
  })  : assert(capacity > 0),
        assert(refillPerMinute > 0),
        _now = now ?? DateTime.now;

  /// Maximum burst (bucket size).
  final int capacity;

  /// Tokens restored per minute.
  final double refillPerMinute;

  final DateTime Function() _now;
  final Map<String, _Bucket> _buckets = {};

  /// Consumes one token for [uid]; returns false when the bucket is empty.
  bool allow(String uid) {
    final now = _now();
    final bucket = _buckets[uid] ?? _Bucket(capacity.toDouble(), now);
    final elapsedMs = now.difference(bucket.lastRefill).inMilliseconds;
    final refilled = math.min(
      capacity.toDouble(),
      bucket.tokens + elapsedMs / 60000.0 * refillPerMinute,
    );
    if (refilled < 1.0) {
      _buckets[uid] = _Bucket(refilled, now);
      return false;
    }
    _buckets[uid] = _Bucket(refilled - 1.0, now);
    // Bound memory: full buckets are indistinguishable from absent ones.
    if (_buckets.length > _pruneThreshold) _prune(now);
    return true;
  }

  static const _pruneThreshold = 10000;

  void _prune(DateTime now) {
    _buckets.removeWhere((_, b) {
      final elapsedMs = now.difference(b.lastRefill).inMilliseconds;
      return b.tokens + elapsedMs / 60000.0 * refillPerMinute >=
          capacity.toDouble();
    });
  }
}

class _Bucket {
  _Bucket(this.tokens, this.lastRefill);
  final double tokens;
  final DateTime lastRefill;
}

/// Shelf middleware applying [limiter] per verified uid. Must sit INSIDE
/// `firebaseAuthMiddleware` (it reads `request.uid`) so unauthenticated junk
/// is already rejected with 401 before it can touch any bucket.
Middleware perUidRateLimit(TokenBucketRateLimiter limiter) {
  return (Handler inner) {
    return (Request request) {
      if (!limiter.allow(request.uid)) {
        return Response(
          429,
          body: jsonEncode({
            'error': {
              'code': 'rate-limited',
              'message': 'Too many requests — slow down and retry.',
              'retryable': true,
            },
          }),
          headers: const {
            'content-type': 'application/json',
            'retry-after': '30',
          },
        );
      }
      return inner(request);
    };
  };
}
