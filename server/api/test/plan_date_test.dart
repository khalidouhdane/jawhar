// Pure unit tests for the §5 client-local date resolution behind
// GET /v1/me/plan (tz-aware day boundaries; no Firestore involved — the
// full endpoint behavior lives in plan_get_firestore_test.dart against the
// emulator).

import 'package:jawhar_api/handlers/plan_get.dart';
import 'package:test/test.dart';

void main() {
  // A fixed UTC instant late in the UTC day, so positive offsets cross
  // midnight forward and negative ones stay behind.
  final nowUtc = DateTime.utc(2026, 6, 10, 23, 30);

  group('resolvePlanDate', () {
    test('explicit date wins and is returned as local midnight', () {
      final day = resolvePlanDate(date: '2026-06-01', nowUtc: nowUtc);
      expect(day, DateTime(2026, 6, 1));
      expect(day.toIso8601String(), '2026-06-01T00:00:00.000');
    });

    test('explicit date wins even when tzOffsetMinutes is also sent', () {
      final day = resolvePlanDate(
        date: '2026-06-01',
        tzOffsetMinutes: '120',
        nowUtc: nowUtc,
      );
      expect(day, DateTime(2026, 6, 1));
    });

    test('tzOffsetMinutes shifts the UTC instant across the day boundary',
        () {
      // 23:30Z + 120min = 01:30 local on the NEXT day (e.g. Madrid summer).
      expect(
        resolvePlanDate(tzOffsetMinutes: '120', nowUtc: nowUtc),
        DateTime(2026, 6, 11),
      );
      // 23:30Z - 300min = 18:30 local, SAME day (e.g. New York).
      expect(
        resolvePlanDate(tzOffsetMinutes: '-300', nowUtc: nowUtc),
        DateTime(2026, 6, 10),
      );
      // Negative offset crossing backward: 00:30Z - 120min = previous day.
      expect(
        resolvePlanDate(
          tzOffsetMinutes: '-120',
          nowUtc: DateTime.utc(2026, 6, 11, 0, 30),
        ),
        DateTime(2026, 6, 10),
      );
    });

    test('defaults to the server UTC date when neither param is sent', () {
      expect(resolvePlanDate(nowUtc: nowUtc), DateTime(2026, 6, 10));
    });

    test('rejects malformed dates', () {
      for (final bad in [
        '2026-6-1', // not zero-padded
        '2026-06-01T00:00:00', // not a bare date
        '2026-02-31', // not a real calendar day
        '20260601',
        'today',
        '',
      ]) {
        expect(
          () => resolvePlanDate(date: bad, nowUtc: nowUtc),
          throwsA(isA<PlanDateError>()),
          reason: '"$bad" must be rejected',
        );
      }
    });

    test('rejects non-integer or impossible tz offsets', () {
      for (final bad in ['1.5', 'abc', '', '-721', '841', '1440']) {
        expect(
          () => resolvePlanDate(tzOffsetMinutes: bad, nowUtc: nowUtc),
          throwsA(isA<PlanDateError>()),
          reason: '"$bad" must be rejected',
        );
      }
      // The real-world extremes are valid (UTC-12:00 .. UTC+14:00).
      expect(
        resolvePlanDate(tzOffsetMinutes: '-720', nowUtc: nowUtc),
        DateTime(2026, 6, 10),
      );
      expect(
        resolvePlanDate(tzOffsetMinutes: '840', nowUtc: nowUtc),
        DateTime(2026, 6, 11),
      );
    });

    test('a malformed tz offset is rejected even when date is present', () {
      expect(
        () => resolvePlanDate(
          date: '2026-06-01',
          tzOffsetMinutes: 'abc',
          nowUtc: nowUtc,
        ),
        throwsA(isA<PlanDateError>()),
      );
    });
  });
}
