import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

/// Pure-fold tests for [RotationDerivation] (roadmap §8 Phase 5 task 4):
/// LWW per profileId on (`changedAtUtc`, fact id), replay idempotence,
/// input-order independence.
void main() {
  const u1 = 'a1111111-1111-4111-8111-111111111111';
  const u2 = 'a2222222-2222-4222-8222-222222222222';
  const u3 = 'a3333333-3333-4333-8333-333333333333';

  RotationChangedFact fact(
    String id,
    String profileId,
    List<int> juz,
    DateTime changedAtUtc,
  ) => RotationChangedFact(
    id: id,
    coreVersion: hifzCoreVersion,
    profileId: profileId,
    juz: juz,
    changedAtUtc: changedAtUtc,
  );

  test('latest changedAtUtc wins per profile; profiles are independent', () {
    final result = RotationDerivation.fold(
      prior: const {},
      facts: [
        fact(u1, 'p1', [1, 2], DateTime.utc(2026, 6, 10, 10)),
        fact(u2, 'p1', [3], DateTime.utc(2026, 6, 10, 12)),
        fact(u3, 'p2', [29, 30], DateTime.utc(2026, 6, 9)),
      ],
    );
    expect(result['p1']!.juz, [3]);
    expect(result['p1']!.factId, u2);
    expect(result['p2']!.juz, [29, 30]);
  });

  test('an older edit never beats the incumbent', () {
    final prior = {
      'p1': RotationState(
        juz: const [5],
        changedAtUtc: DateTime.utc(2026, 6, 10, 12),
        factId: u2,
      ),
    };
    final result = RotationDerivation.fold(
      prior: prior,
      facts: [
        fact(u1, 'p1', [1, 2], DateTime.utc(2026, 6, 10, 10)),
      ],
    );
    expect(result['p1']!.juz, [5], reason: 'older edit loses LWW');
    expect(result['p1']!.factId, u2);
  });

  test('replaying the winning fact is a no-op (equal LWW pair loses)', () {
    final prior = {
      'p1': RotationState(
        juz: const [3],
        changedAtUtc: DateTime.utc(2026, 6, 10, 12),
        factId: u2,
      ),
    };
    final result = RotationDerivation.fold(
      prior: prior,
      facts: [
        fact(u2, 'p1', [3], DateTime.utc(2026, 6, 10, 12)),
      ],
    );
    expect(result['p1']!.juz, [3]);
    expect(result['p1']!.factId, u2);
  });

  test('equal instants tie-break on fact id, deterministically', () {
    final instant = DateTime.utc(2026, 6, 10, 12);
    final facts = [
      fact(u1, 'p1', [1], instant),
      fact(u3, 'p1', [9], instant),
      fact(u2, 'p1', [5], instant),
    ];
    final forward = RotationDerivation.fold(prior: const {}, facts: facts);
    final backward = RotationDerivation.fold(
      prior: const {},
      facts: facts.reversed.toList(),
    );
    expect(forward['p1']!.factId, u3, reason: 'highest id wins the tie');
    expect(forward['p1']!.juz, [9]);
    expect(backward['p1']!.juz, forward['p1']!.juz);
    expect(backward['p1']!.factId, forward['p1']!.factId);
  });

  test('input order never matters', () {
    final facts = [
      fact(u1, 'p1', [1, 2], DateTime.utc(2026, 6, 10, 10)),
      fact(u2, 'p1', [3], DateTime.utc(2026, 6, 10, 12)),
      fact(u3, 'p1', [], DateTime.utc(2026, 6, 10, 11)),
    ];
    final forward = RotationDerivation.fold(prior: const {}, facts: facts);
    final backward = RotationDerivation.fold(
      prior: const {},
      facts: facts.reversed.toList(),
    );
    expect(forward['p1']!.juz, [3]);
    expect(backward['p1']!.juz, [3]);
  });

  test('an empty list is a real state (rotation cleared), not a no-op', () {
    final prior = {
      'p1': RotationState(
        juz: const [1, 2, 3],
        changedAtUtc: DateTime.utc(2026, 6, 10, 10),
        factId: u1,
      ),
    };
    final result = RotationDerivation.fold(
      prior: prior,
      facts: [fact(u2, 'p1', [], DateTime.utc(2026, 6, 10, 11))],
    );
    expect(result['p1']!.juz, isEmpty);
  });

  test('duplicate fact ids in one batch fold once', () {
    final result = RotationDerivation.fold(
      prior: const {},
      facts: [
        fact(u1, 'p1', [1], DateTime.utc(2026, 6, 10, 10)),
        fact(u1, 'p1', [1], DateTime.utc(2026, 6, 10, 10)),
      ],
    );
    expect(result['p1']!.juz, [1]);
  });

  test('prior map is never mutated', () {
    final prior = <String, RotationState>{};
    RotationDerivation.fold(
      prior: prior,
      facts: [fact(u1, 'p1', [1], DateTime.utc(2026, 6, 10))],
    );
    expect(prior, isEmpty);
  });
}
