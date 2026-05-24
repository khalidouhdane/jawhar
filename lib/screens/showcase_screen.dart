import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/setup_screen.dart';
import 'package:quran_app/theme/geist_tokens.dart';
import 'package:quran_app/theme/geist_typography.dart';

/// Onboarding showcase — 3 swipeable slides with interactive screenshot mock-ups.
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
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.04), end: Offset.zero).animate(
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
    final l10n = AppLocalizations.of(context)!;

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
                        l10n.onboardingSkip,
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
                        title: l10n.onboardingReadTitle,
                        subtitle: l10n.onboardingReadDesc,
                        mockupStack: const ScreenshotMockupStack(
                          foregroundImg: 'assets/images/screenshots/mushaf_audio_playing.png',
                          backgroundImg: 'assets/images/screenshots/read_index_home.png',
                        ),
                      ),
                      _ShowcaseSlide(
                        icon: LucideIcons.lightbulb,
                        iconColor: const Color(0xFFF59E0B),
                        title: l10n.onboardingUnderstandTitle,
                        subtitle: l10n.onboardingUnderstandDesc,
                        mockupStack: const ScreenshotMockupStack(
                          foregroundImg: 'assets/images/screenshots/tafsir_sheet_brief.png',
                          backgroundImg: 'assets/images/screenshots/understand_index_home.png',
                        ),
                      ),
                      _ShowcaseSlide(
                        icon: LucideIcons.brain,
                        iconColor: const Color(0xFF8B5CF6),
                        title: l10n.onboardingMemorizeTitle,
                        subtitle: l10n.onboardingMemorizeDesc,
                        mockupStack: const ScreenshotMockupStack(
                          foregroundImg: 'assets/images/screenshots/hifz_dashboard_today_plan.png',
                          backgroundImg: 'assets/images/screenshots/practice_home_flashcards.png',
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Page indicators + CTA ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
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
                                GeistTokens.radiusXl,
                              ),
                            ),
                          ),
                          child: Text(
                            _currentPage == _totalPages - 1
                                ? l10n.werdGetStarted
                                : l10n.actionContinue,
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
  final Widget mockupStack;

  const _ShowcaseSlide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.mockupStack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // ── Overlapping mock-up stack ──
          mockupStack,

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
                fontSize: 14,
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
// Screenshot Mockup Stack Widget
// ══════════════════════════════════════════════

class ScreenshotMockupStack extends StatefulWidget {
  final String foregroundImg;
  final String backgroundImg;

  const ScreenshotMockupStack({
    super.key,
    required this.foregroundImg,
    required this.backgroundImg,
  });

  @override
  State<ScreenshotMockupStack> createState() => _ScreenshotMockupStackState();
}

class _ScreenshotMockupStackState extends State<ScreenshotMockupStack> {
  bool _isSwapped = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = context.watch<ThemeProvider>();
    
    // Calculate responsive stack dimensions to fit well inside the slide view
    final stackWidth = size.width * 0.75;
    final stackHeight = size.height * 0.40;
    final cardWidth = stackWidth * 0.65;
    final cardHeight = stackHeight * 0.85;

    final cardA = AnimatedPositioned(
      key: const ValueKey('cardA'),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      left: _isSwapped ? stackWidth * 0.05 : stackWidth * 0.28,
      top: _isSwapped ? stackHeight * 0.12 : stackHeight * 0.02,
      child: AnimatedScale(
        scale: _isSwapped ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _isSwapped ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: _buildCard(widget.foregroundImg, cardWidth, cardHeight, isForeground: !_isSwapped, theme: theme),
        ),
      ),
    );

    final cardB = AnimatedPositioned(
      key: const ValueKey('cardB'),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      left: _isSwapped ? stackWidth * 0.28 : stackWidth * 0.05,
      top: _isSwapped ? stackHeight * 0.02 : stackHeight * 0.12,
      child: AnimatedScale(
        scale: _isSwapped ? 1.0 : 0.85,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _isSwapped ? 1.0 : 0.6,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: _buildCard(widget.backgroundImg, cardWidth, cardHeight, isForeground: _isSwapped, theme: theme),
        ),
      ),
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          _isSwapped = !_isSwapped;
        });
      },
      child: SizedBox(
        width: stackWidth,
        height: stackHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: _isSwapped ? [cardA, cardB] : [cardB, cardA],
        ),
      ),
    );
  }

  Widget _buildCard(String assetPath, double width, double height, {required bool isForeground, required ThemeProvider theme}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.isDark 
              ? Colors.white.withValues(alpha: isForeground ? 0.15 : 0.08)
              : Colors.black.withValues(alpha: isForeground ? 0.12 : 0.06),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isForeground ? 0.35 : 0.15),
            blurRadius: isForeground ? 20 : 10,
            offset: Offset(0, isForeground ? 10 : 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
