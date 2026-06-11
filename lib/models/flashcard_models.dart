// ── Flashcard & Mutashabihat Data Models ──
// Moved to packages/hifz_core (shared with the jawhar-api server).
// This shim keeps every existing
// `package:quran_app/models/flashcard_models.dart` import working unchanged.

export 'package:hifz_core/hifz_core.dart'
    show
        FlashcardType,
        FlashcardRating,
        MutashabihatStatus,
        MutashabihatCategory,
        Flashcard,
        FlashcardReview,
        MutashabihatGroup,
        MutashabihatVerse;
