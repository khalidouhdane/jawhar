import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/flashcard_models.dart';
import 'package:quran_app/services/hifz_database_service.dart';
import 'package:quran_app/services/mutashabihat_import_service.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';

/// Browsable collection of mutashabihat (similar verse) groups.
/// Filter by status (All/Needs Practice/Mastered/Not Studied).
class MutashabihatScreen extends StatefulWidget {
  const MutashabihatScreen({super.key});

  @override
  State<MutashabihatScreen> createState() => _MutashabihatScreenState();
}

class _MutashabihatScreenState extends State<MutashabihatScreen> {
  List<MutashabihatGroup> _groups = [];
  bool _isLoading = true;
  MutashabihatStatus? _filter; // null = all

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);
    try {
      final db = context.read<HifzDatabaseService>();
      if (_filter != null) {
        _groups = await db.getMutashabihatByStatus(_filter!);
      } else {
        _groups = await db.getAllMutashabihat();
      }
    } catch (e) {
      debugPrint('Failed to load mutashabihat: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// Parse "chapter:verse" to get the Arabic text from the quran package.
  String _getVerseText(String verseKey) {
    final parts = verseKey.split(':');
    if (parts.length != 2) return '';
    final surah = int.tryParse(parts[0]);
    final verse = int.tryParse(parts[1]);
    if (surah == null || verse == null) return '';
    try {
      return quran.getVerse(surah, verse);
    } catch (_) {
      return '';
    }
  }

  /// Parse "chapter:verse" and return the surah name.
  String _getSurahName(String verseKey) {
    final surah = int.tryParse(verseKey.split(':').first);
    if (surah == null) return '';
    try {
      return quran.getSurahNameArabic(surah);
    } catch (_) {
      return 'Surah $surah';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: theme.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mutashabihat',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refreshCw, color: theme.secondaryText, size: 18),
            tooltip: 'Re-import dataset',
            onPressed: () => _reimportDataset(theme),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip(theme, 'All', null),
                const SizedBox(width: 8),
                _filterChip(theme, 'Needs Practice',
                    MutashabihatStatus.needsPractice),
                const SizedBox(width: 8),
                _filterChip(theme, 'Mastered',
                    MutashabihatStatus.mastered),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: theme.accentColor))
                : _groups.isEmpty
                    ? _buildEmpty(theme)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _groups.length,
                        itemBuilder: (ctx, i) =>
                            _buildGroupCard(theme, _groups[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(ThemeProvider theme, String label,
      MutashabihatStatus? status) {
    final isActive = _filter == status;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = status);
        _loadGroups();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? theme.accentColor : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? theme.accentColor : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : theme.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(ThemeProvider theme, MutashabihatGroup group) {
    final srcText = _getVerseText(group.sourceVerseKey);
    final srcSurah = _getSurahName(group.sourceVerseKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: status badge + category
          Row(
            children: [
              _statusBadge(theme, group),
              const Spacer(),
              if (group.needsContext)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.info, size: 12,
                        color: Colors.amber.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Context needed',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: Colors.amber.shade600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),

          // SOURCE VERSE — with Arabic text
          _verseCard(
            theme,
            label: 'Source',
            verseKey: group.sourceVerseKey,
            surahName: srcSurah,
            verseText: srcText,
            color: theme.accentColor,
          ),

          const SizedBox(height: 8),

          // SIMILAR VERSES
          ...group.similarVerses.map((v) {
            final mutText = _getVerseText(v.verseKey);
            final mutSurah = _getSurahName(v.verseKey);
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _verseCard(
                theme,
                label: '↔ Similar',
                verseKey: v.verseKey,
                surahName: mutSurah,
                verseText: mutText,
                color: Colors.orange.shade700,
              ),
            );
          }),

          // Action buttons
          const SizedBox(height: 12),
          Row(
            children: [
              _actionButton(
                theme,
                group.userStatus == MutashabihatStatus.needsPractice
                    ? '🔄 Practicing'
                    : 'Mark for Practice',
                group.userStatus == MutashabihatStatus.needsPractice,
                () async {
                  final db = context.read<HifzDatabaseService>();
                  await db.updateMutashabihatStatus(
                      group.groupId, MutashabihatStatus.needsPractice);
                  _loadGroups();
                },
              ),
              const SizedBox(width: 8),
              _actionButton(
                theme,
                group.userStatus == MutashabihatStatus.mastered
                    ? '✅ Mastered'
                    : 'Mastered',
                group.userStatus == MutashabihatStatus.mastered,
                () async {
                  final db = context.read<HifzDatabaseService>();
                  await db.updateMutashabihatStatus(
                      group.groupId, MutashabihatStatus.mastered);
                  _loadGroups();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A card that shows a verse key, surah name, and actual Arabic text.
  Widget _verseCard(
    ThemeProvider theme, {
    required String label,
    required String verseKey,
    required String surahName,
    required String verseText,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row: label + verse key + surah name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                verseKey,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  surahName,
                  style: GoogleFonts.amiri(
                    fontSize: 13,
                    color: theme.secondaryText,
                  ),
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Arabic verse text
          if (verseText.isNotEmpty)
            ExcludeSemantics(
              child: Text(
                verseText,
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  height: 1.8,
                  color: theme.primaryText,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            Text(
              'Verse text not available',
              style: TextStyle(
                fontFamily: 'Inter', fontSize: 12,
                fontStyle: FontStyle.italic, color: theme.mutedText),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(ThemeProvider theme, MutashabihatGroup group) {
    String label;
    Color color;
    switch (group.userStatus) {
      case MutashabihatStatus.mastered:
        label = '✅ Mastered';
        color = Colors.green;
        break;
      case MutashabihatStatus.needsPractice:
        label = '🔄 Practice';
        color = Colors.orange;
        break;
      case MutashabihatStatus.notStudied:
        label = 'Not studied';
        color = theme.mutedText;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _actionButton(
      ThemeProvider theme, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? theme.accentColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? theme.accentColor : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? theme.accentColor : theme.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeProvider theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📿', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            _filter != null
                ? 'No groups with this status'
                : 'Mutashabihat data not imported yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _filter != null
                ? 'Try changing the filter'
                : 'Tap below to download the dataset',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: theme.mutedText,
            ),
          ),
          if (_filter == null) ...[
            const SizedBox(height: 16),
            _isLoading
                ? CircularProgressIndicator(color: theme.accentColor)
                : ElevatedButton.icon(
                    onPressed: () => _importDataset(theme),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download Dataset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Future<void> _importDataset(ThemeProvider theme) async {
    setState(() => _isLoading = true);
    try {
      final db = context.read<HifzDatabaseService>();
      final service = MutashabihatImportService(db);
      final count = await service.importIfNeeded();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              count > 0
                  ? 'Imported $count mutashabihat groups!'
                  : 'Dataset already imported',
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadGroups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Import failed: $e',
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  /// Clear old data and re-import with corrected offsets.
  Future<void> _reimportDataset(ThemeProvider theme) async {
    setState(() => _isLoading = true);
    try {
      final db = context.read<HifzDatabaseService>();
      await db.clearMutashabihat();
      debugPrint('Cleared old mutashabihat data');
      final service = MutashabihatImportService(db);
      final count = await service.importIfNeeded();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Re-imported $count mutashabihat groups!',
              style: const TextStyle(fontFamily: 'Inter'),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        _loadGroups();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Re-import failed: $e',
                style: const TextStyle(fontFamily: 'Inter')),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}
