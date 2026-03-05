import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/navigation_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/reading_screen.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/widgets/werd_card.dart';
import 'package:quran_app/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Ayah of the Day — fetched once per session
  String? _ayahText;
  String? _ayahRef;
  bool _ayahLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAyahOfTheDay();
  }

  Future<void> _loadAyahOfTheDay() async {
    try {
      final provider = context.read<QuranReadingProvider>();
      // Pick a random page (1-604) and get the first verse
      final randomPage = Random().nextInt(604) + 1;
      final verses = await provider.getPageVerses(randomPage);
      if (verses.isNotEmpty && mounted) {
        // Find a verse with actual word text
        final verse = verses[Random().nextInt(verses.length)];
        final arabicText = verse.words
            .where((w) => w.charTypeName == 'word')
            .map((w) => w.textUthmani)
            .join(' ');
        setState(() {
          _ayahText = arabicText;
          _ayahRef = 'Surah ${verse.verseKey}';
          _ayahLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _ayahLoading = false);
    }
  }

  void _openReadingScreen(int page) {
    final nav = context.read<NavigationProvider>();
    nav.enterReadingView();
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => ReadingScreen(initialPage: page)),
        )
        .then((_) {
          nav.exitReadingView();
          // Refresh state when coming back from reading
          if (mounted) setState(() {});
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final l = AppLocalizations.of(context);
    final storage = context.read<LocalStorageService>();
    final lastRead = storage.getLastRead();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // ── Greeting Header ──
              _buildGreeting(theme, l),
              const SizedBox(height: 24),

              // ── Resume Your Journey ──
              _buildHeroCard(theme, lastRead, l),
              const SizedBox(height: 20),

              // ── Quick Access Row ──
              _buildQuickAccess(theme, l),
              const SizedBox(height: 24),

              // ── Daily Werd ──
              WerdCard(onStartReading: (page) => _openReadingScreen(page)),
              const SizedBox(height: 24),

              // ── Ayah of the Day ──
              _buildAyahOfTheDay(theme, l),
              const SizedBox(height: 24),

              // ── Hifz Placeholder ──
              _buildHifzPlaceholder(theme, l),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Greeting ──
  Widget _buildGreeting(ThemeProvider theme, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.t('home_greeting'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formattedDate(),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: theme.secondaryText,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  // ── Hero Card ──
  Widget _buildHeroCard(
    ThemeProvider theme,
    LastReadPosition? lastRead,
    AppLocalizations l,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.accentColor,
            theme.accentColor.withValues(alpha: 0.85),
            theme.accentColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.accentColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative geometric pattern
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              LucideIcons.bookOpen,
              size: 140,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lastRead != null
                            ? lastRead.timeAgoLocalized(l)
                            : l.t('home_welcome'),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  lastRead != null
                      ? l.t('home_resume_title')
                      : l.t('home_resume_title'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lastRead != null
                      ? '${lastRead.surahName} — ${l.t('home_page')} ${lastRead.page}'
                      : l.t('home_no_history'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Continue Reading button
                    GestureDetector(
                      onTap: () {
                        final page = lastRead?.page ?? 1;
                        _openReadingScreen(page);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              lastRead != null
                                  ? LucideIcons.bookOpen
                                  : LucideIcons.book,
                              size: 16,
                              color: theme.accentColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              lastRead != null
                                  ? l.t('home_continue')
                                  : l.t('home_continue'),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: theme.accentColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Play button
                    if (lastRead != null)
                      GestureDetector(
                        onTap: () => _openReadingScreen(lastRead.page),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.play,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick Access ──
  Widget _buildQuickAccess(ThemeProvider theme, AppLocalizations l) {
    return Row(
      children: [
        _quickAccessItem(
          theme,
          icon: LucideIcons.bookmark,
          label: l.t('home_bookmarks'),
          onTap: () {}, // Phase 5
        ),
        const SizedBox(width: 12),
        _quickAccessItem(
          theme,
          icon: LucideIcons.bookOpen,
          label: l.t('home_read'),
          onTap: () {
            context.read<NavigationProvider>().setTab(1);
          },
        ),
        const SizedBox(width: 12),
        _quickAccessItem(
          theme,
          icon: LucideIcons.shuffle,
          label: l.t('home_random'),
          onTap: () {
            final randomPage = Random().nextInt(604) + 1;
            _openReadingScreen(randomPage);
          },
        ),
      ],
    );
  }

  Widget _quickAccessItem(
    ThemeProvider theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor, width: 1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: theme.accentColor),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Ayah of the Day ──
  Widget _buildAyahOfTheDay(ThemeProvider theme, AppLocalizations l) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 16, color: theme.accentColor),
              const SizedBox(width: 8),
              Text(
                l.t('home_ayah_title'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.accentColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_ayahLoading)
            Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.accentColor,
                ),
              ),
            )
          else if (_ayahText != null) ...[
            Text(
              _ayahText!,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'KFGQPC HAFS Uthmanic Script',
                fontSize: 22,
                height: 2.0,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _ayahRef ?? '',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.mutedText,
              ),
            ),
          ] else
            Text(
              'Could not load verse',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: theme.mutedText,
              ),
            ),
        ],
      ),
    );
  }

  // ── Hifz Placeholder ──
  Widget _buildHifzPlaceholder(ThemeProvider theme, AppLocalizations l) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.brain,
                size: 16,
                color: theme.accentColor.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                l.t('home_hifz_title'),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.accentColor.withValues(alpha: 0.5),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Three placeholder progress rings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _hifzRingPlaceholder(theme, l.t('hifz_sabaq'), 0.0),
              _hifzRingPlaceholder(theme, l.t('hifz_sabqi'), 0.0),
              _hifzRingPlaceholder(theme, l.t('hifz_manzil'), 0.0),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: theme.pillBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l.t('home_coming_soon'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hifzRingPlaceholder(
    ThemeProvider theme,
    String label,
    double progress,
  ) {
    return Column(
      children: [
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: theme.dividerColor,
                color: theme.accentColor.withValues(alpha: 0.3),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: theme.mutedText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: theme.mutedText,
          ),
        ),
      ],
    );
  }
}
