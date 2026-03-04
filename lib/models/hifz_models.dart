/// Memorization status for a surah.
enum HifzStatus {
  /// Not started / not memorized
  none,

  /// Currently learning (Sabaq — new lesson)
  learning,

  /// Recently memorized, needs frequent review (Sabqi — recent review)
  reviewing,

  /// Solidly memorized, periodic maintenance (Manzil — long-term)
  memorized,
}

/// A single surah's memorization record.
class MemorizationRecord {
  final int surahId;
  final HifzStatus status;
  final DateTime? lastReviewed;
  final int reviewCount;

  const MemorizationRecord({
    required this.surahId,
    this.status = HifzStatus.none,
    this.lastReviewed,
    this.reviewCount = 0,
  });

  MemorizationRecord copyWith({
    HifzStatus? status,
    DateTime? lastReviewed,
    int? reviewCount,
  }) {
    return MemorizationRecord(
      surahId: surahId,
      status: status ?? this.status,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  /// Serialize to a simple string: "status|timestamp|count"
  String toStorageString() {
    return '${status.index}|${lastReviewed?.millisecondsSinceEpoch ?? 0}|$reviewCount';
  }

  /// Deserialize from storage string
  factory MemorizationRecord.fromStorageString(int surahId, String data) {
    final parts = data.split('|');
    if (parts.length < 3) {
      return MemorizationRecord(surahId: surahId);
    }
    final statusIdx = int.tryParse(parts[0]) ?? 0;
    final timestamp = int.tryParse(parts[1]) ?? 0;
    final count = int.tryParse(parts[2]) ?? 0;
    return MemorizationRecord(
      surahId: surahId,
      status:
          HifzStatus.values[statusIdx.clamp(0, HifzStatus.values.length - 1)],
      lastReviewed: timestamp > 0
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null,
      reviewCount: count,
    );
  }
}

/// Daily streak tracking data.
class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDay;

  const StreakData({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDay,
  });
}
