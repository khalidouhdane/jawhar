// SM-2 SRS engine — moved to packages/hifz_core (shared with the
// jawhar-api server, which folds review facts with the same code).
// This shim keeps every existing
// `package:quran_app/services/srs_engine.dart` import working unchanged.

export 'package:hifz_core/hifz_core.dart'
    show SrsEngine, Clock, LocalDayBoundary;
