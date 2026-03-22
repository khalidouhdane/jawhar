import 'package:flutter/material.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/sharing_service.dart';
import 'package:quran_app/services/hifz_database_service.dart';

/// Provider for social/sharing features.
/// Manages progress report generation and milestone sharing.
class SocialProvider extends ChangeNotifier {
  final SharingService _sharingService;
  final HifzDatabaseService _db;

  bool _isGenerating = false;
  String? _error;

  SocialProvider(this._sharingService, this._db);

  // ── Getters ──

  bool get isGenerating => _isGenerating;
  String? get error => _error;

  // ── Progress Sharing ──

  /// Share a plain text progress summary.
  Future<void> shareProgressText({
    required MemoryProfile profile,
    required StreakData streak,
  }) async {
    _setGenerating(true);
    try {
      final statusCounts = await _db.getPageStatusCounts(profile.id);
      final pagesMemorized = statusCounts[PageStatus.memorized] ?? 0;

      final text = _sharingService.generateProgressText(
        profile: profile,
        streak: streak,
        pagesMemorized: pagesMemorized,
        totalPages: 604,
      );

      await _sharingService.shareText(text);
      _error = null;
    } catch (e) {
      _error = 'Failed to share progress: $e';
    } finally {
      _setGenerating(false);
    }
  }

  /// Generate and share a PDF progress report.
  Future<void> shareProgressPdf({
    required MemoryProfile profile,
    required StreakData streak,
  }) async {
    _setGenerating(true);
    try {
      final statusCounts = await _db.getPageStatusCounts(profile.id);
      final pagesMemorized = statusCounts[PageStatus.memorized] ?? 0;

      final sessions = await _db.getSessionHistory(profile.id, limit: 10);

      final path = await _sharingService.generateProgressPdf(
        profile: profile,
        streak: streak,
        pagesMemorized: pagesMemorized,
        totalPages: 604,
        recentSessions: sessions,
      );

      await _sharingService.shareFile(
        path,
        subject: 'Hifz Progress Report — ${profile.name}',
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to generate PDF: $e';
    } finally {
      _setGenerating(false);
    }
  }

  // ── Milestone Sharing ──

  /// Share a juz completion milestone.
  Future<void> shareJuzMilestone({
    required String profileName,
    required int juzNumber,
  }) async {
    final text = _sharingService.generateMilestoneText(
      type: MilestoneType.juzComplete,
      profileName: profileName,
      juzNumber: juzNumber,
    );
    await _sharingService.shareText(text);
  }

  /// Share a khatm (full Quran) completion milestone.
  Future<void> shareKhatmMilestone({
    required String profileName,
  }) async {
    final text = _sharingService.generateMilestoneText(
      type: MilestoneType.khatmComplete,
      profileName: profileName,
    );
    await _sharingService.shareText(text);
  }

  /// Share a streak milestone.
  Future<void> shareStreakMilestone({
    required String profileName,
    required int streakDays,
  }) async {
    final text = _sharingService.generateMilestoneText(
      type: MilestoneType.streakMilestone,
      profileName: profileName,
      streakDays: streakDays,
    );
    await _sharingService.shareText(text);
  }

  // ── Private ──

  void _setGenerating(bool value) {
    _isGenerating = value;
    notifyListeners();
  }
}
