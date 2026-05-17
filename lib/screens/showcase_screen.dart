import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/setup_screen.dart';
import 'package:quran_app/theme/geist_tokens.dart';
import 'package:quran_app/theme/geist_typography.dart';

/// Onboarding showcase — 3 swipeable slides with programmatic phone frames.
///
/// Shows the "Three Beats" of Jawhar:
/// 1. Read & Listen
/// 2. Understand
/// 3. Memorize
///
/// After the last slide (or skip), navigates to SetupScreen.
class ShowcaseScreen extends StatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const _totalPages = 3;

  // Entrance animation
  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _entranceSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.04),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToSetup();
    }
  }

  void _navigateToSetup() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const SetupScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entranceOpacity,
          child: SlideTransition(
            position: _entranceSlide,
            child: Column(
              children: [
                // ── Skip button ──
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 16),
                    child: TextButton(
                      onPressed: _navigateToSetup,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontFamily: GeistTypography.primaryFontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: theme.mutedText,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Slides ──
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _ShowcaseSlide(
                        icon: LucideIcons.bookOpen,
                        iconColor: const Color(0xFF3B82F6),
                        title: 'Read & Listen',
                        subtitle:
                            'Beautiful Mushaf pages with verse-synced audio from 40+ reciters.',
                        phoneContent: _ReadPhoneContent(theme: theme),
                      ),
                      _ShowcaseSlide(
                        icon: LucideIcons.lightbulb,
                        iconColor: const Color(0xFFF59E0B),
                        title: 'Understand',
                        subtitle:
                            'Translations, tafsir, and reasons of revelation — context at your fingertips.',
                        phoneContent: _UnderstandPhoneContent(theme: theme),
                      ),
                      _ShowcaseSlide(
                        icon: LucideIcons.brain,
                        iconColor: const Color(0xFF8B5CF6),
                        title: 'Memorize',
                        subtitle:
                            'AI-powered plans, structured sessions, and spaced repetition flashcards.',
                        phoneContent: _MemorizePhoneContent(theme: theme),
                      ),
                    ],
                  ),
                ),

                // ── Page indicators + CTA ──
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    children: [
                      // Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_totalPages, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _currentPage ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _currentPage
                                  ? theme.primaryText
                                  : theme.dividerColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 24),

                      // CTA
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: _next,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.primaryText,
                            foregroundColor: theme.scaffoldBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  GeistTokens.radiusXl),
                            ),
                          ),
                          child: Text(
                            _currentPage == _totalPages - 1
                                ? 'Get Started'
                                : 'Next',
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
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

// ══════════════════════════════════════════════
// Showcase Slide
// ══════════════════════════════════════════════

class _ShowcaseSlide extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget phoneContent;

  const _ShowcaseSlide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.phoneContent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // ── Phone frame ──
          _PhoneFrame(child: phoneContent),

          const SizedBox(height: 32),

          // ── Icon badge ──
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(GeistTokens.radiusLg),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),

          const SizedBox(height: 16),

          // ── Title ──
          Text(
            title,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 8),

          // ── Subtitle ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: theme.secondaryText,
                height: 1.5,
              ),
            ),
          ),

          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Programmatic Phone Frame
// ══════════════════════════════════════════════

class _PhoneFrame extends StatelessWidget {
  final Widget child;

  const _PhoneFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    // Phone frame dimensions (9:19.5 aspect ratio, like modern phones)
    const frameWidth = 200.0;
    const frameHeight = 420.0;
    const bezelRadius = 32.0;
    const screenRadius = 28.0;
    const bezelWidth = 4.0;

    return Container(
      width: frameWidth,
      height: frameHeight,
      decoration: BoxDecoration(
        color: theme.isDark
            ? const Color(0xFF1A1A1A)
            : const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(bezelRadius),
        border: Border.all(
          color: theme.isDark
              ? const Color(0xFF333333)
              : const Color(0xFF3A3A3C),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 60,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(bezelWidth),
        child: Column(
          children: [
            // ── Notch / Dynamic Island ──
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 6),
              width: 72,
              height: 22,
              decoration: BoxDecoration(
                color: theme.isDark
                    ? const Color(0xFF111111)
                    : const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            // ── Screen content ──
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(screenRadius - bezelWidth),
                child: Container(
                  color: theme.scaffoldBackground,
                  child: child,
                ),
              ),
            ),

            // ── Home indicator ──
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: theme.isDark
                    ? const Color(0xFF555555)
                    : const Color(0xFF48484A),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Phone Screen Content — Read & Listen
// ══════════════════════════════════════════════

class _ReadPhoneContent extends StatelessWidget {
  final ThemeProvider theme;
  const _ReadPhoneContent({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        children: [
          // Mini top bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Al-Fatiha',
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryText,
                ),
              ),
              Icon(LucideIcons.volume2,
                  size: 12, color: theme.mutedText),
            ],
          ),
          const SizedBox(height: 10),

          // Arabic verse lines
          ..._buildVerseLines([
            'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
            'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَـٰلَمِينَ',
            'ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
            'مَـٰلِكِ يَوْمِ ٱلدِّينِ',
            'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ',
            'ٱهْدِنَا ٱلصِّرَٰطَ ٱلْمُسْتَقِيمَ',
          ]),

          const Spacer(),

          // Mini audio player bar
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: theme.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: theme.shadowRing,
            ),
            child: Row(
              children: [
                Icon(LucideIcons.play,
                    size: 12, color: theme.primaryText),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.35,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.primaryText,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '1:23',
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 8,
                    color: theme.mutedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVerseLines(List<String> verses) {
    return verses.map((v) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          v,
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 13,
            height: 1.8,
            color: theme.primaryText,
          ),
        ),
      );
    }).toList();
  }
}

// ══════════════════════════════════════════════
// Phone Screen Content — Understand
// ══════════════════════════════════════════════

class _UnderstandPhoneContent extends StatelessWidget {
  final ThemeProvider theme;
  const _UnderstandPhoneContent({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verse
          Text(
            'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 15,
              height: 1.8,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 12),

          // Translation card
          _MiniCard(
            theme: theme,
            label: 'Translation',
            icon: LucideIcons.languages,
            content: 'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
          ),

          const SizedBox(height: 8),

          // Tafsir card
          _MiniCard(
            theme: theme,
            label: 'Tafsir al-Muyassar',
            icon: LucideIcons.bookOpen,
            content:
                'The Basmalah is the opening formula recited at the beginning of every surah...',
          ),

          const SizedBox(height: 8),

          // Asbab card
          _MiniCard(
            theme: theme,
            label: 'Revelation Context',
            icon: LucideIcons.clock,
            content: 'Revealed in Mecca · 7 verses',
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final ThemeProvider theme;
  final String label;
  final IconData icon;
  final String content;

  const _MiniCard({
    required this.theme,
    required this.label,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: theme.shadowRing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: theme.mutedText),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  color: theme.mutedText,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 9,
              color: theme.secondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Phone Screen Content — Memorize
// ══════════════════════════════════════════════

class _MemorizePhoneContent extends StatelessWidget {
  final ThemeProvider theme;
  const _MemorizePhoneContent({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mini dashboard header
          Text(
            'Today\'s Plan',
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
          ),
          const SizedBox(height: 8),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Progress',
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 8,
                      color: theme.mutedText,
                    ),
                  ),
                  Text(
                    '12%',
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Session phases
          _PhaseRow(
              theme: theme,
              label: 'New Lesson',
              pages: 'p.305-306',
              color: const Color(0xFF3B82F6)),
          const SizedBox(height: 4),
          _PhaseRow(
              theme: theme,
              label: 'Recent Review',
              pages: 'p.303-304',
              color: const Color(0xFFF59E0B)),
          const SizedBox(height: 4),
          _PhaseRow(
              theme: theme,
              label: 'Old Review',
              pages: 'p.1-10',
              color: const Color(0xFF22C55E)),

          const Spacer(),

          // Start session CTA
          Container(
            width: double.infinity,
            height: 28,
            decoration: BoxDecoration(
              color: theme.primaryText,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'Start Session',
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: theme.scaffoldBackground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseRow extends StatelessWidget {
  final ThemeProvider theme;
  final String label;
  final String pages;
  final Color color;

  const _PhaseRow({
    required this.theme,
    required this.label,
    required this.pages,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(6),
        boxShadow: theme.shadowRing,
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: theme.primaryText,
              ),
            ),
          ),
          Text(
            pages,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 8,
              color: theme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
