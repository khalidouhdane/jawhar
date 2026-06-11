import 'package:hifz_core/hifz_core.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/utils/app_logger.dart';

/// Thin SQLite-reading adapter around the pure plan math in `hifz_core`.
///
/// The deterministic generation logic lives in [PlanGenerator]
/// (packages/hifz_core) so the jawhar-api server can run the exact same
/// code. This class owns only the database reads/writes and keeps the
/// historical public API so provider call-sites are unchanged.
class PlanGenerationService {
  final HifzDatabaseService _db;

  PlanGenerationService(this._db);

  /// Generate today's plan for the given profile.
  /// If [forceRegenerate] is true, replaces any existing plan for today
  /// (used after completing a session so the next page is assigned).
  Future<DailyPlan> generateTodayPlan(
    MemoryProfile profile, {
    bool forceRegenerate = false,
  }) async {
    // Check if plan already exists for today
    DailyPlan? previousPlan;
    if (!forceRegenerate) {
      final existing = await _db.getTodayPlan(profile.id);
      if (existing != null) return existing;
    } else {
      // When regenerating, grab the old plan to carry over line progress
      previousPlan = await _db.getTodayPlan(profile.id);
    }

    // Get progress data
    final allProgress = await _db.getAllPageProgress(profile.id);
    final rotationJuz = await _db.getRotationJuz(profile.id);

    // Pure, deterministic plan math (shared with the server via hifz_core)
    final plan = PlanGenerator.generate(
      profile: profile,
      progress: allProgress,
      rotationJuz: rotationJuz,
      previousPlan: previousPlan,
      log: (message) => AppLogger.info('PlanGen', message),
    );

    // When regenerating, delete old plan(s) for today so they don't
    // get returned by getTodayPlan on subsequent regenerations.
    if (forceRegenerate) {
      await _db.deleteTodayPlans(profile.id);
    }

    await _db.saveDailyPlan(plan);
    return plan;
  }

  /// Generate sensible default recipes for any deterministic plan.
  /// Delegates to the shared implementation in `hifz_core`.
  static List<SessionRecipe> generateDefaultRecipes(
    DailyPlan plan, [
    MemoryProfile? profile,
  ]) {
    return PlanGenerator.generateDefaultRecipes(plan, profile);
  }
}
