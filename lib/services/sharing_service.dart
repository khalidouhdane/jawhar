import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran_app/models/hifz_models.dart';

/// Service for generating and sharing progress reports and milestone cards.
/// Uses `pdf` package for PDF generation and `share_plus` for sharing.
/// No backend required — everything is local/shareable.
class SharingService {
  /// Generate a PDF progress report for the given profile and stats.
  /// Returns the file path of the generated PDF.
  Future<String> generateProgressPdf({
    required MemoryProfile profile,
    required StreakData streak,
    required int pagesMemorized,
    required int totalPages,
    required List<SessionRecord> recentSessions,
  }) async {
    final pdf = pw.Document();

    final percentage = totalPages > 0
        ? (pagesMemorized / totalPages * 100).toStringAsFixed(1)
        : '0.0';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Hifz Progress Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Le Quran',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 10),

          // Profile Info
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  profile.name,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Report generated on ${DateTime.now().toString().split(' ').first}',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Stats Grid
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildPdfStat('Pages Memorized', '$pagesMemorized / $totalPages'),
              _buildPdfStat('Progress', '$percentage%'),
              _buildPdfStat('Active Days', '${streak.totalActiveDays}'),
            ],
          ),

          pw.SizedBox(height: 20),

          // Profile Details
          pw.Header(level: 1, text: 'Profile Details'),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            data: [
              ['Setting', 'Value'],
              ['Daily Time', '${profile.dailyTimeMinutes} minutes'],
              ['Encoding Speed', profile.encodingSpeed.name],
              ['Retention', profile.retentionStrength.name],
              [
                'Goal',
                profile.goal == HifzGoal.fullQuran
                    ? 'Full Quran'
                    : profile.goal == HifzGoal.specificJuz
                        ? 'Specific Juz'
                        : 'Specific Surahs',
              ],
              ['Starting Page', '${profile.startingPage}'],
              [
                'Start Date',
                profile.startDate.toString().split(' ').first,
              ],
            ],
          ),

          pw.SizedBox(height: 20),

          // Recent Sessions
          if (recentSessions.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Recent Sessions'),
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.center,
              data: [
                ['Date', 'Duration', 'Sabaq', 'Sabqi', 'Manzil'],
                ...recentSessions.take(10).map((s) => [
                      s.date.toString().split(' ').first,
                      '${s.durationMinutes} min',
                      s.sabaqCompleted
                          ? (s.sabaqAssessment?.name ?? '✓')
                          : '—',
                      s.sabqiCompleted
                          ? (s.sabqiAssessment?.name ?? '✓')
                          : '—',
                      s.manzilCompleted
                          ? (s.manzilAssessment?.name ?? '✓')
                          : '—',
                    ]),
              ],
            ),
          ],

          pw.SizedBox(height: 30),

          // Footer
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated by Le Quran — Your Hifz Companion',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey500,
            ),
          ),
        ],
      ),
    );

    // Save to temp directory
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/hifz_progress_report.pdf');
    final bytes = await pdf.save();
    await file.writeAsBytes(bytes);

    return file.path;
  }

  /// Generate a plain text progress summary for sharing.
  String generateProgressText({
    required MemoryProfile profile,
    required StreakData streak,
    required int pagesMemorized,
    required int totalPages,
  }) {
    final percentage = totalPages > 0
        ? (pagesMemorized / totalPages * 100).toStringAsFixed(1)
        : '0.0';

    return '''📖 Hifz Progress Report — ${profile.name}

📊 Progress: $pagesMemorized / $totalPages pages ($percentage%)
🔥 Active Days: ${streak.totalActiveDays}
📅 Started: ${profile.startDate.toString().split(' ').first}
⏱ Daily Goal: ${profile.dailyTimeMinutes} minutes

Generated by Le Quran — Your Hifz Companion''';
  }

  /// Generate a milestone celebration text.
  String generateMilestoneText({
    required MilestoneType type,
    required String profileName,
    int? juzNumber,
    int? streakDays,
  }) {
    switch (type) {
      case MilestoneType.juzComplete:
        return '🎉 Alhamdulillah! $profileName completed Juz $juzNumber!\n\n'
            'One step closer to completing the Quran. May Allah make it easy. 🤲\n\n'
            '— Le Quran';
      case MilestoneType.khatmComplete:
        return '🏆✨ MashaAllah! $profileName completed the entire Quran!\n\n'
            'An incredible achievement. May Allah accept it and grant them its rewards. 🤲\n\n'
            '— Le Quran';
      case MilestoneType.streakMilestone:
        return '🔥 $profileName reached a ${streakDays}-day Hifz streak!\n\n'
            'Consistency is the key to memorization. Keep going! 💪\n\n'
            '— Le Quran';
    }
  }

  /// Share plain text via the system share sheet.
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }

  /// Share a file via the system share sheet.
  Future<void> shareFile(String filePath, {String? subject}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(filePath)],
        subject: subject,
      ),
    );
  }

  // ── Private helpers ──

  static pw.Widget _buildPdfStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }
}

/// Types of milestones that can be shared.
enum MilestoneType {
  juzComplete,
  khatmComplete,
  streakMilestone,
}
