// ── Hifz Program Data Models ──
// Moved to packages/hifz_core (shared with the jawhar-api server).
// This shim keeps every existing `package:quran_app/models/hifz_models.dart`
// import working unchanged (Phase 1 of the cloud-first migration).

export 'package:hifz_core/hifz_core.dart'
    show
        AgeGroup,
        PacePreference,
        HifzExperience,
        EncodingSpeed,
        RetentionStrength,
        LearningPreference,
        HifzGoal,
        StudyTimeOfDay,
        PageStatus,
        SessionPhase,
        SelfAssessment,
        ReciterSource,
        MemoryProfile,
        PageProgress,
        DailyPlan,
        SessionRecord,
        StreakData,
        SuggestionType,
        SuggestionAction,
        AnalyticsPeriod,
        Suggestion,
        WeeklySnapshot;
