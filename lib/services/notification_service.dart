import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/services/analytics_service.dart';

/// Smart notification logic for the Hifz program.
/// Generates in-app notification-style suggestions based on
/// neglected content, struggle patterns, and review gaps.
class NotificationService {
  final AnalyticsService _analytics;

  NotificationService(this._analytics);

  /// Generate smart notifications based on current data patterns.
  /// Returns notifications as Suggestion objects for consistency with
  /// the dashboard card system.
  Future<List<Suggestion>> generateSmartNotifications(
    String profileId,
  ) async {
    final notifications = <Suggestion>[];
    final now = DateTime.now();

    // ── Neglected Juz notifications ──
    final neglectedJuz = await _analytics.getNeglectedJuz(
      profileId,
      thresholdDays: 5,
    );

    for (final juz in neglectedJuz) {
      final juzNum = juz['juz'] as int;
      final pageCount = juz['pageCount'] as int;
      notifications.add(Suggestion(
        id: 'neglected_juz_${juzNum}_${now.millisecondsSinceEpoch}',
        type: SuggestionType.neglectedJuz,
        emoji: '📚',
        title: 'Juz $juzNum needs attention',
        message: pageCount == 1
            ? 'You have 1 page in Juz $juzNum that hasn\'t been reviewed recently. A quick review session can help!'
            : 'You have $pageCount pages in Juz $juzNum that haven\'t been reviewed recently. A quick review session can help!',
        createdAt: now,
        data: {'juz': juzNum, 'pageCount': pageCount},
      ));
    }

    // ── Struggle page notifications ──
    final strugglePages = await _analytics.detectStrugglePages(profileId);

    if (strugglePages.isNotEmpty) {
      notifications.add(Suggestion(
        id: 'struggle_${now.millisecondsSinceEpoch}',
        type: SuggestionType.strugglePage,
        emoji: '🌱',
        title: 'Some pages need extra care',
        message: strugglePages.length == 1
            ? 'Page ${strugglePages.first} has been challenging. Extra flashcard practice has been added to help strengthen it.'
            : '${strugglePages.length} pages have been challenging. Extra flashcard practice can help strengthen them.',
        createdAt: now,
        data: {'pages': strugglePages},
      ));
    }

    return notifications;
  }
}
