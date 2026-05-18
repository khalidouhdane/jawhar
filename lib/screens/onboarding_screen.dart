import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/locale_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/screens/app_shell.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/services/qf_user_auth_service.dart';
import 'package:quran_app/theme/geist_tokens.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/widgets/geist_button.dart';

/// First-launch onboarding — Vercel/Geist Design System, dark-mode first.
///
/// 4 steps:
/// 0. Welcome — brand statement
/// 1. Language — English / العربية
/// 2. Rewaya — Hafs / Warsh
/// 3. Account — QF OAuth sign-in (optional)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const _totalSteps = 4;

  // Step 1: Language
  String _selectedLang = 'en';

  // Step 2: Rewaya
  int _selectedRewaya = 1; // 1 = Hafs, 2 = Warsh

  // Step 3: Account
  bool _isSigningIn = false;
  String? _signInError;

  // Entrance animation
  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
    // Auto-detect language
    final systemLang = ui.PlatformDispatcher.instance.locale.languageCode;
    _selectedLang = systemLang == 'ar' ? 'ar' : 'en';

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _entranceOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0.0, 0.05), end: Offset.zero).animate(
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

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      // Apply language when leaving step 1
      if (_currentStep == 1) {
        context.read<LocaleProvider>().setLocale(Locale(_selectedLang));
      }
      _goToStep(_currentStep + 1);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  void _completeOnboarding() {
    final storage = context.read<LocalStorageService>();
    final reading = context.read<QuranReadingProvider>();

    // Apply language
    context.read<LocaleProvider>().setLocale(Locale(_selectedLang));

    // Apply rewaya
    reading.setRewaya(_selectedRewaya);
    storage.setOnboardingComplete();

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
  }

  Future<void> _signIn() async {
    setState(() {
      _isSigningIn = true;
      _signInError = null;
    });

    try {
      final qfAuth = context.read<QfUserAuthService>();
      final success = await qfAuth.signIn();
      if (mounted) {
        if (success) {
          // Brief success moment, then complete
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) _completeOnboarding();
        } else {
          setState(() {
            _isSigningIn = false;
            _signInError = 'Sign-in was cancelled';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
          _signInError = 'Could not connect. Try again later.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GeistTokens.darkScaffold,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entranceOpacity,
          child: SlideTransition(
            position: _entranceSlide,
            child: Column(
              children: [
                // ── Back button (steps 1-3) ──
                SizedBox(
                  height: 56,
                  child: _currentStep > 0
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: GeistButton.icon(
                            onPressed: _back,
                            icon: const Icon(LucideIcons.arrowLeft),
                            type: GeistButtonType.tertiary,
                            size: GeistButtonSize.large,
                          ),
                        )
                      : null,
                ),

                // ── Page content ──
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentStep = i),
                    children: [
                      _buildWelcomeStep(),
                      _buildLanguageStep(),
                      _buildRewayaStep(),
                      _buildAccountStep(),
                    ],
                  ),
                ),

                // ── Step indicators ──
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalSteps, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _currentStep ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentStep
                              ? GeistTokens.darkPrimary
                              : GeistTokens.darkDivider,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Step 0: Welcome
  // ═══════════════════════════════════════════
  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 3),

          // Diamond icon
          Image.asset(
            'assets/images/diamond_logo.png',
            width: 64,
            height: 64,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 20),

          // App name
          Text(
            'jawhar',
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: GeistTokens.darkPrimary,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Brand statement
          Text(
            'We believe memorization without\nunderstanding is incomplete.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: GeistTokens.darkSecondary,
              height: 1.6,
            ),
          ),

          const Spacer(flex: 4),

          // CTA
          _buildPrimaryButton(label: 'Begin', onTap: _next),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Step 1: Language
  // ═══════════════════════════════════════════
  Widget _buildLanguageStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),

          const Icon(
            LucideIcons.globe,
            size: 32,
            color: GeistTokens.darkSecondary,
          ),
          const SizedBox(height: 16),

          Text(
            'Choose your language',
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: GeistTokens.darkPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can change this later in settings',
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 14,
              color: GeistTokens.darkMuted,
            ),
          ),

          const Spacer(flex: 2),

          _buildOptionCard(
            label: 'English',
            subtitle: 'Continue in English',
            icon: LucideIcons.globe,
            isSelected: _selectedLang == 'en',
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedLang = 'en');
            },
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            label: 'العربية',
            subtitle: 'المتابعة بالعربية',
            icon: LucideIcons.languages,
            isSelected: _selectedLang == 'ar',
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedLang = 'ar');
            },
          ),

          const Spacer(flex: 3),

          _buildPrimaryButton(label: 'Continue', onTap: _next),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Step 2: Rewaya
  // ═══════════════════════════════════════════
  Widget _buildRewayaStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),

          const Icon(
            LucideIcons.bookOpen,
            size: 32,
            color: GeistTokens.darkSecondary,
          ),
          const SizedBox(height: 16),

          Text(
            'اختر القراءة',
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: GeistTokens.darkPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your Quranic recitation',
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 14,
              color: GeistTokens.darkMuted,
            ),
          ),

          const Spacer(flex: 2),

          _buildOptionCard(
            label: 'حفص عن عاصم',
            subtitle: 'Hafs · Most widely used',
            icon: LucideIcons.bookOpen,
            isSelected: _selectedRewaya == 1,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedRewaya = 1);
            },
          ),
          const SizedBox(height: 12),
          _buildOptionCard(
            label: 'ورش عن نافع',
            subtitle: 'Warsh · North & West Africa',
            icon: LucideIcons.bookOpen,
            isSelected: _selectedRewaya == 2,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedRewaya = 2);
            },
          ),

          const Spacer(flex: 3),

          _buildPrimaryButton(label: 'Continue', onTap: _next),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Step 3: Account (QF OAuth)
  // ═══════════════════════════════════════════
  Widget _buildAccountStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),

          const Icon(
            LucideIcons.cloud,
            size: 32,
            color: GeistTokens.darkSecondary,
          ),
          const SizedBox(height: 16),

          Text(
            'Sync your progress',
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: GeistTokens.darkPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to sync across devices.\nYour data stays on your device otherwise.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 14,
              color: GeistTokens.darkMuted,
              height: 1.5,
            ),
          ),

          const Spacer(flex: 2),

          // Sign-in button
          if (_isSigningIn)
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: GeistTokens.darkDivider,
                borderRadius: BorderRadius.circular(GeistTokens.radiusLg),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: GeistTokens.darkPrimary,
                  ),
                ),
              ),
            )
          else
            _buildPrimaryButton(
              label: 'Sign in with Quran.com',
              icon: LucideIcons.logIn,
              onTap: _signIn,
            ),

          // Error message
          if (_signInError != null) ...[
            const SizedBox(height: 12),
            Text(
              _signInError!,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 13,
                color: Color(0xFFFF6369), // Red-400
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _signIn,
              child: Text(
                'Try again',
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: GeistTokens.darkPrimary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],

          const Spacer(flex: 3),

          // Skip button — always prominent
          SizedBox(
            width: double.infinity,
            height: 52,
            child: GeistButton(
              label: 'Skip for now',
              type: GeistButtonType.secondary,
              size: GeistButtonSize.large,
              isDisabled: _isSigningIn,
              onPressed: _completeOnboarding,
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Shared Components
  // ═══════════════════════════════════════════

  /// Geist-style primary button: white bg, black text (dark mode CTA).
  Widget _buildPrimaryButton({
    required String label,
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: GeistButton(
        label: label,
        prefix: icon != null ? Icon(icon) : null,
        type: GeistButtonType.primary,
        size: GeistButtonSize.large,
        onPressed: onTap,
      ),
    );
  }

  /// Geist-style selection card — dark surface, white border on select.
  Widget _buildOptionCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.06)
              : GeistTokens.darkSurface,
          borderRadius: BorderRadius.circular(GeistTokens.radiusXl),
          border: Border.all(
            color: isSelected
                ? GeistTokens.darkPrimary
                : GeistTokens.darkDivider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(GeistTokens.radiusLg),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? GeistTokens.darkPrimary
                    : GeistTokens.darkMuted,
              ),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? GeistTokens.darkPrimary
                          : const Color(0xFFCCCCCC),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isSelected
                          ? GeistTokens.darkSecondary
                          : GeistTokens.darkMuted,
                    ),
                  ),
                ],
              ),
            ),

            // Selection indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? GeistTokens.darkPrimary
                      : GeistTokens.darkDivider,
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
