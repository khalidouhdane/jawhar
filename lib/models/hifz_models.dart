// ── Hifz Program Data Models ──
// All enums and data classes for the memorization framework.

// ── Enums ──

/// Age group — affects session length and UI tone.
enum AgeGroup {
  child,  // 7-12
  teen,   // 13-17
  adult,  // 18+
}

/// How quickly the user encodes new material — from assessment.
enum EncodingSpeed { fast, moderate, slow }

/// How well the user retains memorized material — from assessment.
enum RetentionStrength { strong, moderate, fragile }

/// Preferred learning modality — from assessment.
enum LearningPreference { visual, auditory, kinesthetic, repetition }

/// Goal scope for the hifz plan.
enum HifzGoal { fullQuran, specificJuz, specificSurahs }

/// Preferred study time of day.
enum StudyTimeOfDay { fajr, morning, afternoon, evening, night }

/// Status of a single page in the memorization journey.
enum PageStatus { notStarted, learning, reviewing, memorized }

/// Session phases in the Sabaq-Sabqi-Manzil framework.
enum SessionPhase { sabaq, sabqi, manzil, flashcards }

/// Self-assessment rating after each phase.
enum SelfAssessment { strong, okay, needsWork }

/// Source of the reciter (for cross-API compatibility).
enum ReciterSource { quranDotCom, mp3Quran }

// ── Data Classes ──

/// A user's personalized memorization profile.
class MemoryProfile {
  final String id;
  final String name;
  final int avatarIndex;
  final DateTime createdAt;
  final AgeGroup ageGroup;
  final EncodingSpeed encodingSpeed;
  final RetentionStrength retentionStrength;
  final LearningPreference learningPreference;
  final int dailyTimeMinutes;
  final StudyTimeOfDay preferredTimeOfDay;
  final HifzGoal goal;
  final List<int> goalDetails; // Juz numbers or Surah IDs
  final int defaultReciterId;
  final ReciterSource defaultReciterSource;
  final int startingPage;
  final DateTime startDate;
  final bool isActive;

  const MemoryProfile({
    required this.id,
    required this.name,
    this.avatarIndex = 0,
    required this.createdAt,
    this.ageGroup = AgeGroup.adult,
    this.encodingSpeed = EncodingSpeed.moderate,
    this.retentionStrength = RetentionStrength.moderate,
    this.learningPreference = LearningPreference.visual,
    this.dailyTimeMinutes = 30,
    this.preferredTimeOfDay = StudyTimeOfDay.fajr,
    this.goal = HifzGoal.fullQuran,
    this.goalDetails = const [],
    this.defaultReciterId = 7,
    this.defaultReciterSource = ReciterSource.quranDotCom,
    this.startingPage = 582, // Juz 30 start
    required this.startDate,
    this.isActive = true,
  });

  MemoryProfile copyWith({
    String? id,
    String? name,
    int? avatarIndex,
    DateTime? createdAt,
    AgeGroup? ageGroup,
    EncodingSpeed? encodingSpeed,
    RetentionStrength? retentionStrength,
    LearningPreference? learningPreference,
    int? dailyTimeMinutes,
    StudyTimeOfDay? preferredTimeOfDay,
    HifzGoal? goal,
    List<int>? goalDetails,
    int? defaultReciterId,
    ReciterSource? defaultReciterSource,
    int? startingPage,
    DateTime? startDate,
    bool? isActive,
  }) {
    return MemoryProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      createdAt: createdAt ?? this.createdAt,
      ageGroup: ageGroup ?? this.ageGroup,
      encodingSpeed: encodingSpeed ?? this.encodingSpeed,
      retentionStrength: retentionStrength ?? this.retentionStrength,
      learningPreference: learningPreference ?? this.learningPreference,
      dailyTimeMinutes: dailyTimeMinutes ?? this.dailyTimeMinutes,
      preferredTimeOfDay: preferredTimeOfDay ?? this.preferredTimeOfDay,
      goal: goal ?? this.goal,
      goalDetails: goalDetails ?? this.goalDetails,
      defaultReciterId: defaultReciterId ?? this.defaultReciterId,
      defaultReciterSource: defaultReciterSource ?? this.defaultReciterSource,
      startingPage: startingPage ?? this.startingPage,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convert to a Map for SQLite storage.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'avatarIndex': avatarIndex,
    'createdAt': createdAt.toIso8601String(),
    'ageGroup': ageGroup.index,
    'encodingSpeed': encodingSpeed.index,
    'retentionStrength': retentionStrength.index,
    'learningPreference': learningPreference.index,
    'dailyTimeMinutes': dailyTimeMinutes,
    'preferredTimeOfDay': preferredTimeOfDay.index,
    'goal': goal.index,
    'goalDetails': goalDetails.join(','),
    'defaultReciterId': defaultReciterId,
    'defaultReciterSource': defaultReciterSource.index,
    'startingPage': startingPage,
    'startDate': startDate.toIso8601String(),
    'isActive': isActive ? 1 : 0,
  };

  /// Create from a SQLite row.
  factory MemoryProfile.fromMap(Map<String, dynamic> map) {
    return MemoryProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      avatarIndex: map['avatarIndex'] as int? ?? 0,
      createdAt: DateTime.parse(map['createdAt'] as String),
      ageGroup: AgeGroup.values[(map['ageGroup'] as int?) ?? 2],
      encodingSpeed: EncodingSpeed.values[(map['encodingSpeed'] as int?) ?? 1],
      retentionStrength: RetentionStrength.values[(map['retentionStrength'] as int?) ?? 1],
      learningPreference: LearningPreference.values[(map['learningPreference'] as int?) ?? 0],
      dailyTimeMinutes: map['dailyTimeMinutes'] as int? ?? 30,
      preferredTimeOfDay: StudyTimeOfDay.values[(map['preferredTimeOfDay'] as int?) ?? 0],
      goal: HifzGoal.values[(map['goal'] as int?) ?? 0],
      goalDetails: (map['goalDetails'] as String?)?.isNotEmpty == true
          ? (map['goalDetails'] as String).split(',').map(int.parse).toList()
          : [],
      defaultReciterId: map['defaultReciterId'] as int? ?? 7,
      defaultReciterSource: ReciterSource.values[(map['defaultReciterSource'] as int?) ?? 0],
      startingPage: map['startingPage'] as int? ?? 582,
      startDate: DateTime.parse(map['startDate'] as String),
      isActive: (map['isActive'] as int?) == 1,
    );
  }
}

/// A single page's memorization progress record.
class PageProgress {
  final int pageNumber; // 1-604
  final String profileId;
  final PageStatus status;
  final DateTime? lastReviewedAt;
  final int reviewCount;
  final DateTime? memorizedAt;
  final int? lastVerseLearned;    // CE-9: last verse covered (null = full page)
  final int? totalVersesOnPage;   // CE-9: total verses on this page

  const PageProgress({
    required this.pageNumber,
    required this.profileId,
    this.status = PageStatus.notStarted,
    this.lastReviewedAt,
    this.reviewCount = 0,
    this.memorizedAt,
    this.lastVerseLearned,
    this.totalVersesOnPage,
  });

  Map<String, dynamic> toMap() => {
    'pageNumber': pageNumber,
    'profileId': profileId,
    'status': status.index,
    'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    'reviewCount': reviewCount,
    'memorizedAt': memorizedAt?.toIso8601String(),
    'lastVerseLearned': lastVerseLearned,
    'totalVersesOnPage': totalVersesOnPage,
  };

  factory PageProgress.fromMap(Map<String, dynamic> map) {
    return PageProgress(
      pageNumber: map['pageNumber'] as int,
      profileId: map['profileId'] as String,
      status: PageStatus.values[(map['status'] as int?) ?? 0],
      lastReviewedAt: map['lastReviewedAt'] != null
          ? DateTime.parse(map['lastReviewedAt'] as String)
          : null,
      reviewCount: map['reviewCount'] as int? ?? 0,
      memorizedAt: map['memorizedAt'] != null
          ? DateTime.parse(map['memorizedAt'] as String)
          : null,
      lastVerseLearned: map['lastVerseLearned'] as int?,
      totalVersesOnPage: map['totalVersesOnPage'] as int?,
    );
  }

  PageProgress copyWith({
    PageStatus? status,
    DateTime? lastReviewedAt,
    int? reviewCount,
    DateTime? memorizedAt,
    int? lastVerseLearned,
    int? totalVersesOnPage,
  }) {
    return PageProgress(
      pageNumber: pageNumber,
      profileId: profileId,
      status: status ?? this.status,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      memorizedAt: memorizedAt ?? this.memorizedAt,
      lastVerseLearned: lastVerseLearned ?? this.lastVerseLearned,
      totalVersesOnPage: totalVersesOnPage ?? this.totalVersesOnPage,
    );
  }
}

/// The generated daily plan for a specific profile.
class DailyPlan {
  final String id;
  final String profileId;
  final DateTime date;

  // Sabaq: new memorization
  final int sabaqPage;
  final int sabaqLineStart;
  final int sabaqLineEnd;
  final int sabaqTargetMinutes;
  final int sabaqRepetitionTarget;
  final int? sabaqStartVerse; // CE-9: resume from this verse (partial page carry-over)

  // Sabqi: recent review
  final List<int> sabqiPages; // page numbers from last 7-10 days
  final int sabqiTargetMinutes;

  // Manzil: long-term review
  final int manzilJuz;
  final List<int> manzilPages;
  final int manzilRotationDay;
  final int manzilTargetMinutes;

  // Status
  final bool sabaqDoneOffline;
  final bool sabqiDoneOffline;
  final bool manzilDoneOffline;
  final bool isCompleted;

  const DailyPlan({
    required this.id,
    required this.profileId,
    required this.date,
    required this.sabaqPage,
    this.sabaqLineStart = 1,
    this.sabaqLineEnd = 15,
    this.sabaqTargetMinutes = 25,
    this.sabaqRepetitionTarget = 10,
    this.sabaqStartVerse,
    this.sabqiPages = const [],
    this.sabqiTargetMinutes = 15,
    this.manzilJuz = 30,
    this.manzilPages = const [],
    this.manzilRotationDay = 1,
    this.manzilTargetMinutes = 15,
    this.sabaqDoneOffline = false,
    this.sabqiDoneOffline = false,
    this.manzilDoneOffline = false,
    this.isCompleted = false,
  });

  /// Estimated total session time in minutes.
  int get estimatedMinutes =>
      sabaqTargetMinutes + sabqiTargetMinutes + manzilTargetMinutes;

  DailyPlan copyWith({
    bool? sabaqDoneOffline,
    bool? sabqiDoneOffline,
    bool? manzilDoneOffline,
    bool? isCompleted,
    int? sabaqPage,
    int? sabaqStartVerse,
    List<int>? sabqiPages,
    List<int>? manzilPages,
    int? sabaqTargetMinutes,
    int? sabqiTargetMinutes,
    int? manzilTargetMinutes,
    int? sabaqRepetitionTarget,
  }) {
    return DailyPlan(
      id: id,
      profileId: profileId,
      date: date,
      sabaqPage: sabaqPage ?? this.sabaqPage,
      sabaqLineStart: sabaqLineStart,
      sabaqLineEnd: sabaqLineEnd,
      sabaqTargetMinutes: sabaqTargetMinutes ?? this.sabaqTargetMinutes,
      sabaqRepetitionTarget: sabaqRepetitionTarget ?? this.sabaqRepetitionTarget,
      sabaqStartVerse: sabaqStartVerse ?? this.sabaqStartVerse,
      sabqiPages: sabqiPages ?? this.sabqiPages,
      sabqiTargetMinutes: sabqiTargetMinutes ?? this.sabqiTargetMinutes,
      manzilJuz: manzilJuz,
      manzilPages: manzilPages ?? this.manzilPages,
      manzilRotationDay: manzilRotationDay,
      manzilTargetMinutes: manzilTargetMinutes ?? this.manzilTargetMinutes,
      sabaqDoneOffline: sabaqDoneOffline ?? this.sabaqDoneOffline,
      sabqiDoneOffline: sabqiDoneOffline ?? this.sabqiDoneOffline,
      manzilDoneOffline: manzilDoneOffline ?? this.manzilDoneOffline,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'profileId': profileId,
    'date': date.toIso8601String(),
    'sabaqPage': sabaqPage,
    'sabaqLineStart': sabaqLineStart,
    'sabaqLineEnd': sabaqLineEnd,
    'sabaqTargetMinutes': sabaqTargetMinutes,
    'sabaqRepetitionTarget': sabaqRepetitionTarget,
    'sabaqStartVerse': sabaqStartVerse,
    'sabqiPages': sabqiPages.join(','),
    'sabqiTargetMinutes': sabqiTargetMinutes,
    'manzilJuz': manzilJuz,
    'manzilPages': manzilPages.join(','),
    'manzilRotationDay': manzilRotationDay,
    'manzilTargetMinutes': manzilTargetMinutes,
    'sabaqDoneOffline': sabaqDoneOffline ? 1 : 0,
    'sabqiDoneOffline': sabqiDoneOffline ? 1 : 0,
    'manzilDoneOffline': manzilDoneOffline ? 1 : 0,
    'isCompleted': isCompleted ? 1 : 0,
  };

  factory DailyPlan.fromMap(Map<String, dynamic> map) {
    return DailyPlan(
      id: map['id'] as String,
      profileId: map['profileId'] as String,
      date: DateTime.parse(map['date'] as String),
      sabaqPage: map['sabaqPage'] as int,
      sabaqLineStart: map['sabaqLineStart'] as int? ?? 1,
      sabaqLineEnd: map['sabaqLineEnd'] as int? ?? 15,
      sabaqTargetMinutes: map['sabaqTargetMinutes'] as int? ?? 25,
      sabaqRepetitionTarget: map['sabaqRepetitionTarget'] as int? ?? 10,
      sabaqStartVerse: map['sabaqStartVerse'] as int?,
      sabqiPages: (map['sabqiPages'] as String?)?.isNotEmpty == true
          ? (map['sabqiPages'] as String).split(',').map(int.parse).toList()
          : [],
      sabqiTargetMinutes: map['sabqiTargetMinutes'] as int? ?? 15,
      manzilJuz: map['manzilJuz'] as int? ?? 30,
      manzilPages: (map['manzilPages'] as String?)?.isNotEmpty == true
          ? (map['manzilPages'] as String).split(',').map(int.parse).toList()
          : [],
      manzilRotationDay: map['manzilRotationDay'] as int? ?? 1,
      manzilTargetMinutes: map['manzilTargetMinutes'] as int? ?? 15,
      sabaqDoneOffline: (map['sabaqDoneOffline'] as int?) == 1,
      sabqiDoneOffline: (map['sabqiDoneOffline'] as int?) == 1,
      manzilDoneOffline: (map['manzilDoneOffline'] as int?) == 1,
      isCompleted: (map['isCompleted'] as int?) == 1,
    );
  }
}

/// A completed session record saved to history.
class SessionRecord {
  final String id;
  final String profileId;
  final DateTime date;
  final int durationMinutes;

  // Which phases were completed
  final bool sabaqCompleted;
  final bool sabqiCompleted;
  final bool manzilCompleted;

  // Self-assessments per phase
  final SelfAssessment? sabaqAssessment;
  final SelfAssessment? sabqiAssessment;
  final SelfAssessment? manzilAssessment;

  // What was covered
  final int? sabaqPage;
  final List<int> sabqiPages;
  final List<int> manzilPages;
  final int repCount;

  const SessionRecord({
    required this.id,
    required this.profileId,
    required this.date,
    required this.durationMinutes,
    this.sabaqCompleted = false,
    this.sabqiCompleted = false,
    this.manzilCompleted = false,
    this.sabaqAssessment,
    this.sabqiAssessment,
    this.manzilAssessment,
    this.sabaqPage,
    this.sabqiPages = const [],
    this.manzilPages = const [],
    this.repCount = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'profileId': profileId,
    'date': date.toIso8601String(),
    'durationMinutes': durationMinutes,
    'sabaqCompleted': sabaqCompleted ? 1 : 0,
    'sabqiCompleted': sabqiCompleted ? 1 : 0,
    'manzilCompleted': manzilCompleted ? 1 : 0,
    'sabaqAssessment': sabaqAssessment?.index,
    'sabqiAssessment': sabqiAssessment?.index,
    'manzilAssessment': manzilAssessment?.index,
    'sabaqPage': sabaqPage,
    'sabqiPages': sabqiPages.join(','),
    'manzilPages': manzilPages.join(','),
    'repCount': repCount,
  };

  factory SessionRecord.fromMap(Map<String, dynamic> map) {
    return SessionRecord(
      id: map['id'] as String,
      profileId: map['profileId'] as String,
      date: DateTime.parse(map['date'] as String),
      durationMinutes: map['durationMinutes'] as int,
      sabaqCompleted: (map['sabaqCompleted'] as int?) == 1,
      sabqiCompleted: (map['sabqiCompleted'] as int?) == 1,
      manzilCompleted: (map['manzilCompleted'] as int?) == 1,
      sabaqAssessment: map['sabaqAssessment'] != null
          ? SelfAssessment.values[map['sabaqAssessment'] as int]
          : null,
      sabqiAssessment: map['sabqiAssessment'] != null
          ? SelfAssessment.values[map['sabqiAssessment'] as int]
          : null,
      manzilAssessment: map['manzilAssessment'] != null
          ? SelfAssessment.values[map['manzilAssessment'] as int]
          : null,
      sabaqPage: map['sabaqPage'] as int?,
      sabqiPages: (map['sabqiPages'] as String?)?.isNotEmpty == true
          ? (map['sabqiPages'] as String).split(',').map(int.parse).toList()
          : [],
      manzilPages: (map['manzilPages'] as String?)?.isNotEmpty == true
          ? (map['manzilPages'] as String).split(',').map(int.parse).toList()
          : [],
      repCount: map['repCount'] as int? ?? 0,
    );
  }
}

/// Streak tracking data for a profile.
class StreakData {
  final int totalActiveDays;
  final DateTime? lastActiveDate;

  const StreakData({
    this.totalActiveDays = 0,
    this.lastActiveDate,
  });
}

// ── Phase 5: Analytics & Adaptive Intelligence ──

/// Type of adaptive suggestion shown to the user.
enum SuggestionType {
  increaseLoad,    // Doing great → suggest more
  decreaseLoad,    // Struggling → suggest less
  moreReview,      // Weak assessments → more review time
  takeBreak,       // Missing sessions → lighter plan
  aheadOfSchedule, // Ahead → celebrate + optional extra review
  neglectedJuz,    // Juz not reviewed in N days
  strugglePage,    // Consistently weak section detected
}

/// User action on a suggestion.
enum SuggestionAction { pending, accepted, dismissed, remindLater }

/// Analytics time period.
enum AnalyticsPeriod { week, month }

/// An adaptive suggestion displayed as a card on the dashboard.
class Suggestion {
  final String id;
  final SuggestionType type;
  final String emoji;
  final String title;
  final String message;
  final SuggestionAction action;
  final DateTime createdAt;
  final Map<String, dynamic> data; // Context-specific payload (e.g., juz number)

  const Suggestion({
    required this.id,
    required this.type,
    required this.emoji,
    required this.title,
    required this.message,
    this.action = SuggestionAction.pending,
    required this.createdAt,
    this.data = const {},
  });

  Suggestion copyWith({SuggestionAction? action}) {
    return Suggestion(
      id: id,
      type: type,
      emoji: emoji,
      title: title,
      message: message,
      action: action ?? this.action,
      createdAt: createdAt,
      data: data,
    );
  }
}

/// A snapshot of analytics data for a time period (week or month).
class WeeklySnapshot {
  final DateTime startDate;
  final DateTime endDate;

  // Session metrics
  final int totalSessions;
  final int totalDurationMinutes;
  final double avgDurationMinutes;
  final Map<int, int> sessionsPerDay; // day-of-week (1=Mon) → count

  // Completion
  final int plannedDays;    // days with a plan
  final int completedDays;  // days plan was completed
  final double completionRate; // 0.0–1.0

  // Assessment distribution (across all sessions)
  final int strongCount;
  final int okayCount;
  final int needsWorkCount;

  // Progress
  final int pagesMemorized;    // new pages memorized this period
  final int pagesReviewed;     // pages reviewed this period
  final double pagesPerWeek;   // pace calculation

  const WeeklySnapshot({
    required this.startDate,
    required this.endDate,
    this.totalSessions = 0,
    this.totalDurationMinutes = 0,
    this.avgDurationMinutes = 0,
    this.sessionsPerDay = const {},
    this.plannedDays = 0,
    this.completedDays = 0,
    this.completionRate = 0,
    this.strongCount = 0,
    this.okayCount = 0,
    this.needsWorkCount = 0,
    this.pagesMemorized = 0,
    this.pagesReviewed = 0,
    this.pagesPerWeek = 0,
  });

  /// Total assessment count across all sessions.
  int get totalAssessments => strongCount + okayCount + needsWorkCount;

  /// Whether this snapshot has enough data for meaningful analysis.
  bool get hasEnoughData => totalSessions >= 3;
}
