import 'package:flutter_test/flutter_test.dart';

// Standalone timing class matching the internal structure
class MockVerseTiming {
  final String verseKey;
  int timestampFrom;
  int timestampTo;
  int duration;
  int firstSegmentMs;

  MockVerseTiming({
    required this.verseKey,
    required this.timestampFrom,
    required this.timestampTo,
    required this.duration,
    required this.firstSegmentMs,
  });
}

// Function executing the exact logic of _applyBismillahCorrectionIfNeeded
List<MockVerseTiming> applyMockBismillahCorrection(
  List<MockVerseTiming> timings,
  Duration audioDuration,
) {
  if (timings.isEmpty) return timings;

  final lastVerse = timings.last;
  final expectedEndTime = lastVerse.timestampTo;
  final actualDurationMs = audioDuration.inMilliseconds;

  // Rule: If actual duration is shorter than expected end time by at least 1500ms
  if (actualDurationMs < (expectedEndTime - 1500)) {
    final firstVerse = timings.first;
    final bismillahGap = firstVerse.timestampFrom;

    final discrepancy = expectedEndTime - actualDurationMs;
    // Verification: discrepancy should be close to the first verse start (Bismillah gap)
    if ((discrepancy - bismillahGap).abs() < 1500) {
      final shift = -bismillahGap;

      return timings.map((t) {
        return MockVerseTiming(
          verseKey: t.verseKey,
          timestampFrom: (t.timestampFrom + shift).clamp(0, actualDurationMs),
          timestampTo: (t.timestampTo + shift).clamp(0, actualDurationMs),
          duration: t.duration,
          firstSegmentMs: (t.firstSegmentMs + shift).clamp(0, actualDurationMs),
        );
      }).toList();
    }
  }
  return timings;
}

void main() {
  group('Dynamic Bismillah Gap Correction Tests', () {
    test('Should apply correction when Bismillah is missing (Yasser al-Dosari case)', () {
      // Mock timings for Surah 2 (Yasser al-Dosari case)
      // first verse starts at 3080ms, expected end is 10776700ms
      final timings = [
        MockVerseTiming(
          verseKey: '2:1',
          timestampFrom: 3080,
          timestampTo: 12770,
          duration: 9690,
          firstSegmentMs: 3080,
        ),
        MockVerseTiming(
          verseKey: '2:2',
          timestampFrom: 13190,
          timestampTo: 20580,
          duration: 7390,
          firstSegmentMs: 13390,
        ),
        MockVerseTiming(
          verseKey: '2:286',
          timestampFrom: 10769300,
          timestampTo: 10776700,
          duration: 7400,
          firstSegmentMs: 10769300,
        ),
      ];

      // Actual audio duration of Yasser's Surah 2 is 10773620ms (which is expectedEndTime - 3080ms)
      final actualDuration = const Duration(milliseconds: 10773620);

      final corrected = applyMockBismillahCorrection(timings, actualDuration);

      // Verify that shift of -3080ms was applied to all timings
      expect(corrected.first.timestampFrom, equals(0)); // 3080 - 3080 = 0
      expect(corrected.first.timestampTo, equals(9690)); // 12770 - 3080 = 9690
      expect(corrected[1].timestampFrom, equals(10110)); // 13190 - 3080 = 10110
      expect(corrected.last.timestampTo, equals(10773620)); // 10776700 - 3080 = 10773620
    });

    test('Should NOT apply correction when Bismillah is present (Mishary Alafasy case)', () {
      // Mock timings for Mishary Alafasy case (starts with Bismillah, timings align correctly)
      final timings = [
        MockVerseTiming(
          verseKey: '2:1',
          timestampFrom: 5460,
          timestampTo: 14770,
          duration: 9310,
          firstSegmentMs: 5460,
        ),
        MockVerseTiming(
          verseKey: '2:286',
          timestampFrom: 10769300,
          timestampTo: 10776700,
          duration: 7400,
          firstSegmentMs: 10769300,
        ),
      ];

      // Actual audio duration matches the expected end time
      final actualDuration = const Duration(milliseconds: 10776700);

      final corrected = applyMockBismillahCorrection(timings, actualDuration);

      // Verify that no shift was applied
      expect(corrected.first.timestampFrom, equals(5460));
      expect(corrected.first.timestampTo, equals(14770));
      expect(corrected.last.timestampTo, equals(10776700));
    });

    test('Should NOT apply correction if discrepancy is unrelated to first verse Bismillah start', () {
      final timings = [
        MockVerseTiming(
          verseKey: '2:1',
          timestampFrom: 3080,
          timestampTo: 12770,
          duration: 9690,
          firstSegmentMs: 3080,
        ),
        MockVerseTiming(
          verseKey: '2:286',
          timestampFrom: 10769300,
          timestampTo: 10776700,
          duration: 7400,
          firstSegmentMs: 10769300,
        ),
      ];

      // Actual duration is shorter by 10000ms, which is completely different from the 3080ms gap
      final actualDuration = const Duration(milliseconds: 10766700);

      final corrected = applyMockBismillahCorrection(timings, actualDuration);

      // Verify that no shift was applied since the discrepancy doesn't match the Bismillah gap
      expect(corrected.first.timestampFrom, equals(3080));
      expect(corrected.first.timestampTo, equals(12770));
      expect(corrected.last.timestampTo, equals(10776700));
    });
  });
}
