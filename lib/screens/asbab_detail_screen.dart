import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/data/surah_metadata.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/bookmark_provider.dart';
import 'package:quran_app/providers/context_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/services/asbab_nuzul_service.dart';
import 'package:quran_app/theme/geist_tokens.dart';
import 'package:quran_app/theme/geist_typography.dart';

/// A premium full-screen view for a single asbab al-nuzul (reason of revelation) entry.
///
/// Displays the Arabic verse text followed by the historical occasion narrative in full.
/// Includes an action button to navigate directly to the verse in standard Mus'haf view.
class AsbabDetailScreen extends StatelessWidget {
  final AsbabNuzulEntry entry;
  final SurahInfo surah;

  const AsbabDetailScreen({
    super.key,
    required this.entry,
    required this.surah,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final l10n = AppLocalizations.of(context)!;
    final isArabic = l10n.localeName == 'ar';

    final verseRef = entry.ayahs.length == 1
        ? l10n.undSurahVerse(entry.ayahs.first)
        : l10n.undSurahVersesRange(entry.ayahs.first, entry.ayahs.last);

    final surahName = isArabic ? surah.nameArabic : surah.nameSimple;

    // Join all Arabic verses text with proper formatting
    final versesArabic = entry.ayahs
        .map((a) => '${quran.getVerse(surah.id, a)} ﴿${quran.getVerseEndSymbol(a)}﴾')
        .join(' ');

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
            color: theme.primaryText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$surahName — $verseRef',
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.primaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Quranic Verses Container ──
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.isDark 
                                ? theme.accentColor.withValues(alpha: 0.03) 
                                : theme.accentColor.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(GeistTokens.radiusLg),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.topicKeyVerses.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: GeistTypography.primaryFontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: theme.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  versesArabic,
                                  style: GoogleFonts.amiri(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: theme.primaryText,
                                    height: 2.0,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Historical Narrative Header ──
                        Text(
                          l10n.asbabNuzulTitle,
                          style: TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: theme.accentColor,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Occasion Narrative Stories ──
                        ...entry.occasions.map((occasion) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(GeistTokens.radiusMd),
                              border: Border.all(
                                color: theme.dividerColor.withValues(alpha: 0.5),
                              ),
                              boxShadow: theme.shadowCard,
                            ),
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                occasion,
                                style: GoogleFonts.amiri(
                                  fontSize: 16,
                                  height: 1.8,
                                  color: theme.primaryText,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // ── Read in Mushaf Button (Persistent Footer) ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackground,
                    border: Border(
                      top: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final startAyah = entry.ayahs.first;
                        final page = quran.getPageNumber(surah.id, startAyah);
                        final verseKey = '${surah.id}:$startAyah';

                        context.read<BookmarkProvider>().setHighlight(verseKey);
                        context.read<ContextProvider>().setHighlightVerse(verseKey);

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReadingScreen(
                              initialPage: page,
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        LucideIcons.bookOpen,
                        size: 16,
                        color: theme.accentColor,
                      ),
                      label: Text(
                        l10n.topicReadInMushaf,
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.accentColor,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(GeistTokens.radiusMd),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
