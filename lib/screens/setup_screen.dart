import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/locale_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/screens/app_shell.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/services/qf_user_auth_service.dart';
import 'package:quran_app/theme/geist_tokens.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/widgets/geist_button.dart';

/// Unified setup screen — Language + Rewaya + Theme in one screen.
///
/// Replaces the old multi-step onboarding PageView.
/// Theme defaults to system brightness, with light as fallback.
/// All changes preview in real-time.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  // Selections
  late String _selectedLang;
  int _selectedRewaya = 1; // 1 = Hafs, 2 = Warsh
  late AppTheme _selectedTheme;

  // Sign-in state
  bool _isSigningIn = false;
  String? _signInError;

  // Entrance animation
  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();

    // Detect system language
    final systemLang = ui.PlatformDispatcher.instance.locale.languageCode;
    _selectedLang = systemLang == 'ar' ? 'ar' : 'en';

    // Detect system theme — fallback to light
    try {
      final brightness = ui.PlatformDispatcher.instance.platformBrightness;
      _selectedTheme = brightness == Brightness.dark
          ? AppTheme.dark
          : AppTheme.light;
    } catch (_) {
      _selectedTheme = AppTheme.light;
    }

    // Entrance animation
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    _entranceController.dispose();
    super.dispose();
  }

  void _setTheme(AppTheme theme) {
    HapticFeedback.lightImpact();
    setState(() => _selectedTheme = theme);
    // Live preview — update the actual theme
    context.read<ThemeProvider>().setTheme(theme);
  }

  void _completeSetup() {
    final storage = context.read<LocalStorageService>();
    final reading = context.read<QuranReadingProvider>();
    final themeProvider = context.read<ThemeProvider>();

    // Apply language
    context.read<LocaleProvider>().setLocale(Locale(_selectedLang));

    // Apply rewaya
    reading.setRewaya(_selectedRewaya);

    // Apply theme (may already be set from live preview)
    themeProvider.setTheme(_selectedTheme);

    // Mark onboarding complete
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
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) _completeSetup();
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
    final theme = context.watch<ThemeProvider>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entranceOpacity,
          child: SlideTransition(
            position: _entranceSlide,
            child: Column(
              children: [
                // ── Scrollable content ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),

                        // ── Header ──
                        Center(
                          child: Image.asset(
                            'assets/images/diamond_logo.png',
                            width: 48,
                            height: 48,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'jawhar',
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: theme.primaryText,
                              letterSpacing: -1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'Let\'s set things up.',
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 15,
                              color: theme.secondaryText,
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // ═══ Section: Language ═══
                        _SectionHeader(
                          icon: LucideIcons.globe,
                          label: 'Language',
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ChoiceChip(
                                label: 'English',
                                isSelected: _selectedLang == 'en',
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _selectedLang = 'en');
                                },
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ChoiceChip(
                                label: 'العربية',
                                isSelected: _selectedLang == 'ar',
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() => _selectedLang = 'ar');
                                },
                                theme: theme,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ═══ Section: Recitation ═══
                        _SectionHeader(
                          icon: LucideIcons.bookOpen,
                          label: 'Recitation',
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        _OptionCard(
                          label: 'حفص عن عاصم',
                          subtitle: 'Hafs · Most widely used',
                          isSelected: _selectedRewaya == 1,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _selectedRewaya = 1);
                          },
                          theme: theme,
                        ),
                        const SizedBox(height: 8),
                        _OptionCard(
                          label: 'ورش عن نافع',
                          subtitle: 'Warsh · North & West Africa',
                          isSelected: _selectedRewaya == 2,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _selectedRewaya = 2);
                          },
                          theme: theme,
                        ),

                        const SizedBox(height: 28),

                        // ═══ Section: Appearance ═══
                        _SectionHeader(
                          icon: LucideIcons.palette,
                          label: 'Appearance',
                          theme: theme,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _ThemeCard(
                                icon: LucideIcons.sun,
                                label: 'Light',
                                isSelected: _selectedTheme == AppTheme.light,
                                onTap: () => _setTheme(AppTheme.light),
                                theme: theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ThemeCard(
                                icon: LucideIcons.moon,
                                label: 'Dark',
                                isSelected: _selectedTheme == AppTheme.dark,
                                onTap: () => _setTheme(AppTheme.dark),
                                theme: theme,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Matched to your system preference',
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 12,
                              color: theme.mutedText,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // ── Bottom actions (pinned) ──
                Container(
                  padding: EdgeInsets.fromLTRB(28, 12, 28, 16 + bottomPadding),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackground,
                    border: Border(
                      top: BorderSide(color: theme.dividerColor, width: 0.5),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: GeistButton(
                          label: 'Continue',
                          type: GeistButtonType.primary,
                          size: GeistButtonSize.large,
                          onPressed: _completeSetup,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Sign-in link
                      if (_isSigningIn)
                        SizedBox(
                          height: 32,
                          child: Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.primaryText,
                              ),
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _signIn,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.cloud,
                                  size: 14,
                                  color: theme.mutedText,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Sign in with Quran.com',
                                  style: TextStyle(
                                    fontFamily:
                                        GeistTypography.primaryFontFamily,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: theme.mutedText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Error
                      if (_signInError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _signInError!,
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 12,
                              color: const Color(0xFFFF6369),
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
// Section Header
// ══════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeProvider theme;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.mutedText),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: theme.mutedText,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// Choice Chip (Language)
// ══════════════════════════════════════════════

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeProvider theme;

  const _ChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryText.withValues(alpha: 0.08)
              : theme.surfaceColor,
          borderRadius: BorderRadius.circular(GeistTokens.radiusXl),
          border: Border.all(
            color: isSelected ? theme.primaryText : theme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? theme.primaryText : theme.secondaryText,
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════
// Option Card (Rewaya)
// ══════════════════════════════════════════════

class _OptionCard extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeProvider theme;

  const _OptionCard({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryText.withValues(alpha: 0.06)
              : theme.surfaceColor,
          borderRadius: BorderRadius.circular(GeistTokens.radiusXl),
          border: Border.all(
            color: isSelected ? theme.primaryText : theme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
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
                          ? theme.primaryText
                          : theme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 12,
                      color: theme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.primaryText : theme.dividerColor,
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

// ══════════════════════════════════════════════
// Theme Card (Appearance)
// ══════════════════════════════════════════════

class _ThemeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeProvider theme;

  const _ThemeCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 72,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryText.withValues(alpha: 0.08)
              : theme.surfaceColor,
          borderRadius: BorderRadius.circular(GeistTokens.radiusXl),
          border: Border.all(
            color: isSelected ? theme.primaryText : theme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? theme.primaryText : theme.mutedText,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? theme.primaryText : theme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
