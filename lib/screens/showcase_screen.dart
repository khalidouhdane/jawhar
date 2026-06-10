import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/setup_screen.dart';
import 'package:quran_app/theme/geist_tokens.dart';
import 'package:quran_app/theme/geist_typography.dart';

/// Onboarding showcase — 3 swipeable slides with interactive realistic phone mock-ups.
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

  Widget _getTopIcon(int page, ThemeProvider theme) {
    IconData icon;
    Color color;
    switch (page) {
      case 0:
        icon = LucideIcons.bookOpen;
        color = const Color(0xFF3B82F6);
        break;
      case 1:
        icon = LucideIcons.lightbulb;
        color = const Color(0xFFF59E0B);
        break;
      case 2:
      default:
        icon = LucideIcons.brain;
        color = const Color(0xFF8B5CF6);
        break;
    }

    return Container(
      key: ValueKey(page),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GeistTokens.radiusLg),
      ),
      child: Icon(icon, size: 18, color: color),
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
                // ── Top Bar (Icon Left + Skip Right) ──
                Padding(
                  padding: const EdgeInsets.only(left: 24, right: 16, top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Left: Section Icon
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _getTopIcon(_currentPage, theme),
                      ),
                      // Top Right: Skip Button
                      TextButton(
                        onPressed: _navigateToSetup,
                        child: Text(
                          l10n.onboardingSkip,
                          style: TextStyle(
                            fontFamily: GeistTypography.primaryFontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Main Page Content ──
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _ShowcaseSlide(
                        title: l10n.onboardingReadTitle,
                        subtitle: l10n.onboardingReadDesc,
                        mockupStack: const ScreenshotMockupStack(
                          foregroundImg:
                              'assets/images/screenshots/mushaf_audio_playing.png',
                          backgroundImg:
                              'assets/images/screenshots/read_index_home.png',
                        ),
                      ),
                      _ShowcaseSlide(
                        title: l10n.onboardingUnderstandTitle,
                        subtitle: l10n.onboardingUnderstandDesc,
                        mockupStack: const ScreenshotMockupStack(
                          foregroundImg:
                              'assets/images/screenshots/tafsir_sheet_brief.png',
                          backgroundImg:
                              'assets/images/screenshots/understand_index_home.png',
                        ),
                      ),
                      _ShowcaseSlide(
                        title: l10n.onboardingMemorizeTitle,
                        subtitle: l10n.onboardingMemorizeDesc,
                        mockupStack: const ScreenshotMockupStack(
                          foregroundImg:
                              'assets/images/screenshots/hifz_dashboard_today_plan.png',
                          backgroundImg:
                              'assets/images/screenshots/practice_home_flashcards.png',
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Pinned Bottom Bar (Dots + Next) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page Indicators
                      Row(
                        children: List.generate(_totalPages, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _currentPage ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _currentPage
                                  ? theme.primaryText
                                  : theme.dividerColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),

                      // Next Button
                      SizedBox(
                        height: 42,
                        child: FilledButton(
                          onPressed: _next,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.primaryText,
                            foregroundColor: theme.scaffoldBackground,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                GeistTokens.radiusLg,
                              ),
                            ),
                          ),
                          child: Text(
                            _currentPage == _totalPages - 1
                                ? l10n.werdGetStarted
                                : l10n.actionContinue,
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 14,
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
  final String title;
  final String subtitle;
  final Widget mockupStack;

  const _ShowcaseSlide({
    required this.title,
    required this.subtitle,
    required this.mockupStack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          // ── Responsive Mockup Area ──
          Expanded(child: Center(child: mockupStack)),

          const SizedBox(height: 24),

          // ── Text Content ──
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: theme.secondaryText,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Programmatic Realistic Phone Bezel Frame
// ══════════════════════════════════════════════

class PhoneFrame extends StatelessWidget {
  final Widget child;

  const PhoneFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1F) : const Color(0xFF2E2F30),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2D2E) : const Color(0xFF4E4F50),
          width: 3.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(
        6.0,
      ), // Elegant, uniform inner bezel padding
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: const Color(0xFF121212), // Default premium dark display base
          child: child,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Interactive Depth-Swapping Mockup Stack Widget
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

    // Maximize height based on screen size while reserving spacing
    final stackWidth = size.width * 0.8;
    final stackHeight = size.height * 0.46;

    // We want the inner viewport (screen) to match the screenshot aspect ratio (600 / 1298 ≈ 0.46225).
    // The PhoneFrame has a border of 3.5 on each side and padding of 6.0 on each side.
    // Total horizontal reduction = 2 * (3.5 + 6.0) = 19.0.
    // Total vertical reduction = 2 * (3.5 + 6.0) = 19.0.
    // Inner screenshot aspect ratio = (cardWidth - 19.0) / (cardHeight - 19.0) = 0.46225.

    // Constraints:
    final maxCardHeight = stackHeight * 0.95;
    final maxCardWidth =
        stackWidth * 0.75; // Leave 25% for stack offset and padding

    // 1. Estimate cardHeight based on height constraint
    double cardHeight = maxCardHeight;
    double cardWidth = 0.46225 * (cardHeight - 19.0) + 19.0;

    // 2. Adjust if it exceeds width constraint to maintain aspect ratio
    if (cardWidth > maxCardWidth) {
      cardWidth = maxCardWidth;
      cardHeight = (cardWidth - 19.0) / 0.46225 + 19.0;
    }

    // Calculate margins to center the offset stack within the container
    final double stackSpan = cardWidth + stackWidth * 0.22;
    final double horizontalPadding = ((stackWidth - stackSpan) / 2).clamp(
      0.0,
      stackWidth,
    );

    final leftOffsetForeground =
        horizontalPadding + (_isSwapped ? 0.0 : stackWidth * 0.22);
    final leftOffsetBackground =
        horizontalPadding + (_isSwapped ? stackWidth * 0.22 : 0.0);

    final topOffsetForeground = stackHeight * 0.02;
    final topOffsetBackground = stackHeight * 0.12;

    final cardA = AnimatedPositioned(
      key: const ValueKey('cardA'),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      left: leftOffsetForeground,
      top: _isSwapped ? topOffsetBackground : topOffsetForeground,
      child: AnimatedScale(
        scale: _isSwapped ? 0.86 : 1.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _isSwapped ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: _buildCard(
            widget.foregroundImg,
            cardWidth,
            cardHeight,
            isForeground: !_isSwapped,
            theme: theme,
          ),
        ),
      ),
    );

    final cardB = AnimatedPositioned(
      key: const ValueKey('cardB'),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      left: leftOffsetBackground,
      top: _isSwapped ? topOffsetForeground : topOffsetBackground,
      child: AnimatedScale(
        scale: _isSwapped ? 1.0 : 0.86,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: AnimatedOpacity(
          opacity: _isSwapped ? 1.0 : 0.6,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: _buildCard(
            widget.backgroundImg,
            cardWidth,
            cardHeight,
            isForeground: _isSwapped,
            theme: theme,
          ),
        ),
      ),
    );

    return GestureDetector(
      onTap: () {
        setState(() {
          _isSwapped = !_isSwapped;
        });
      },
      child: Container(
        color: Colors.transparent, // expand gesture area
        width: stackWidth,
        height: stackHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: _isSwapped ? [cardA, cardB] : [cardB, cardA],
        ),
      ),
    );
  }

  Widget _buildCard(
    String assetPath,
    double width,
    double height, {
    required bool isForeground,
    required ThemeProvider theme,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: PhoneFrame(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
