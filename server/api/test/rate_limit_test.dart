import 'dart:convert';

import 'package:jawhar_api/middleware/rate_limit.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import 'support/test_app.dart';

void main() {
  group('TokenBucketRateLimiter', () {
    test('allows up to capacity, then rejects', () {
      final now = DateTime.utc(2026, 6, 11, 12);
      final limiter = TokenBucketRateLimiter(
        capacity: 3,
        refillPerMinute: 60,
        now: () => now,
      );
      expect(limiter.allow('u1'), isTrue);
      expect(limiter.allow('u1'), isTrue);
      expect(limiter.allow('u1'), isTrue);
      expect(limiter.allow('u1'), isFalse);
    });

    test('refills over time at refillPerMinute', () {
      var now = DateTime.utc(2026, 6, 11, 12);
      final limiter = TokenBucketRateLimiter(
        capacity: 2,
        refillPerMinute: 60, // 1 token/second
        now: () => now,
      );
      expect(limiter.allow('u1'), isTrue);
      expect(limiter.allow('u1'), isTrue);
      expect(limiter.allow('u1'), isFalse);

      now = now.add(const Duration(milliseconds: 1100));
      expect(limiter.allow('u1'), isTrue, reason: '~1.1 tokens refilled');
      expect(limiter.allow('u1'), isFalse);
    });

    test('never refills past capacity', () {
      var now = DateTime.utc(2026, 6, 11, 12);
      final limiter = TokenBucketRateLimiter(
        capacity: 2,
        refillPerMinute: 60,
        now: () => now,
      );
      expect(limiter.allow('u1'), isTrue);
      now = now.add(const Duration(hours: 1));
      expect(limiter.allow('u1'), isTrue);
      expect(limiter.allow('u1'), isTrue);
      expect(limiter.allow('u1'), isFalse, reason: 'capped at capacity=2');
    });

    test('buckets are per uid', () {
      final limiter = TokenBucketRateLimiter(
        capacity: 1,
        refillPerMinute: 1,
        now: () => DateTime.utc(2026, 6, 11, 12),
      );
      expect(limiter.allow('u1'), isTrue);
      expect(limiter.allow('u1'), isFalse);
      expect(limiter.allow('u2'), isTrue, reason: 'u2 has its own bucket');
    });
  });

  group('perUidRateLimit middleware (wired into the app)', () {
    test('drained bucket -> 429 envelope with retry-after', () async {
      final handler = buildTestHandler(
        rateLimiter: TokenBucketRateLimiter(
          capacity: 2,
          refillPerMinute: 0.0001, // effectively no refill within the test
        ),
      );
      Request req() => Request(
            'GET',
            Uri.parse('http://localhost/v1/me/whoami'),
            headers: {'authorization': 'Bearer $testToken'},
          );

      expect((await handler(req())).statusCode, 200);
      expect((await handler(req())).statusCode, 200);
      final limited = await handler(req());
      expect(limited.statusCode, 429);
      expect(limited.headers['retry-after'], isNotNull);
      final body =
          jsonDecode(await limited.readAsString()) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>;
      expect(error['code'], 'rate-limited');
      expect(error['retryable'], true);
    });

    test('unauthenticated requests are 401 BEFORE touching any bucket',
        () async {
      final limiter = TokenBucketRateLimiter(capacity: 1, refillPerMinute: 1);
      final handler = buildTestHandler(rateLimiter: limiter);
      final response = await handler(
        Request('GET', Uri.parse('http://localhost/v1/me/whoami')),
      );
      expect(response.statusCode, 401);
      // The single token is still there for the authenticated caller.
      final ok = await handler(Request(
        'GET',
        Uri.parse('http://localhost/v1/me/whoami'),
        headers: {'authorization': 'Bearer $testToken'},
      ));
      expect(ok.statusCode, 200);
    });
  });
}
