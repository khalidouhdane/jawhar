/// Pure Dart domain core shared by the Jawhar app and the jawhar-api server.
///
/// Contains the SM-2 SRS engine, the deterministic daily-plan generator,
/// the AI plan validator, the shared domain models, and vendored Quran
/// page/juz metadata. This package must never import Flutter, sqflite,
/// or Firebase — it runs unchanged on the client and on Cloud Run.
library;

export 'src/analytics/analytics_calculators.dart';
export 'src/derivation/plan_derivation.dart';
export 'src/derivation/progress_derivation.dart';
export 'src/derivation/rotation_derivation.dart';
export 'src/derivation/srs_fold.dart';
export 'src/derivation/streak_derivation.dart';
export 'src/dto/api_error.dart';
export 'src/dto/dataset_epoch.dart';
export 'src/dto/fact_results.dart';
export 'src/dto/facts.dart';
export 'src/dto/wire_codec.dart';
export 'src/models/flashcard_models.dart';
export 'src/models/hifz_models.dart';
export 'src/models/session_recipe_models.dart';
export 'src/parsing/id_generator.dart';
export 'src/parsing/persisted_data_parser.dart';
export 'src/planning/ai_plan_validator.dart';
export 'src/planning/plan_generator.dart';
export 'src/quran_meta/quran_meta.dart';
export 'src/srs/srs_engine.dart';
export 'src/version.dart';
