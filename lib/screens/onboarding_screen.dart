import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/locale_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/screens/app_shell.dart';
import 'package:quran_app/services/local_storage_service.dart';

/// First-launch onboarding screen.
/// Collects language preference and rewaya (Hafs/Warsh).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0; // 0 = language, 1 = rewaya
  String _selectedLang = 'en';
  int _selectedRewaya = 1; // 1 = Hafs, 2 = Warsh

  @override
  void initState() {
    super.initState();
    // Auto-detect phone language: Arabic if phone is Arabic, else English
    final systemLang = ui.PlatformDispatcher.instance.locale.languageCode;
    _selectedLang = systemLang == 'ar' ? 'ar' : 'en';
  }

  void _proceed() {
    if (_step == 0) {
      // Apply language
      context.read<LocaleProvider>().setLocale(Locale(_selectedLang));
      setState(() => _step = 1);
    } else {
      // Apply rewaya, mark onboarding complete, navigate
      final storage = context.read<LocalStorageService>();
      final reading = context.read<QuranReadingProvider>();

      reading.setRewaya(_selectedRewaya);
      storage.setOnboardingComplete();

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use a dark teal colour scheme that matches the app branding
    const bgColor = Color(0xFF0A1E24);
    const accentColor = Color(0xFF4DB6AC);
    const textColor = Colors.white;
    const mutedColor = Color(0xFF8A9FA5);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── App branding ──
              Text(
                'بِسْمِ ٱللَّهِ',
                style: GoogleFonts.amiriQuran(
                  fontSize: 28,
                  color: accentColor,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Le Quran',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _step == 0 ? 'Choose your preferred language' : 'اختر القراءة',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: mutedColor,
                ),
              ),

              const Spacer(flex: 2),

              // ── Selection cards ──
              if (_step == 0) ...[
                _buildOptionCard(
                  label: 'English',
                  subtitle: 'Continue in English',
                  emoji: '🇬🇧',
                  isSelected: _selectedLang == 'en',
                  onTap: () => setState(() => _selectedLang = 'en'),
                  accentColor: accentColor,
                  bgColor: bgColor,
                ),
                const SizedBox(height: 12),
                _buildOptionCard(
                  label: 'العربية',
                  subtitle: 'المتابعة بالعربية',
                  emoji: '🇸🇦',
                  isSelected: _selectedLang == 'ar',
                  onTap: () => setState(() => _selectedLang = 'ar'),
                  accentColor: accentColor,
                  bgColor: bgColor,
                ),
              ] else ...[
                _buildOptionCard(
                  label: 'حفص عن عاصم',
                  subtitle: 'Hafs · Most widely used',
                  emoji: '',
                  icon: LucideIcons.bookOpen,
                  isSelected: _selectedRewaya == 1,
                  onTap: () => setState(() => _selectedRewaya = 1),
                  accentColor: accentColor,
                  bgColor: bgColor,
                ),
                const SizedBox(height: 12),
                _buildOptionCard(
                  label: 'ورش عن نافع',
                  subtitle: 'Warsh · North & West Africa',
                  emoji: '',
                  icon: LucideIcons.bookOpen,
                  isSelected: _selectedRewaya == 2,
                  onTap: () => setState(() => _selectedRewaya = 2),
                  accentColor: accentColor,
                  bgColor: bgColor,
                ),
              ],

              const Spacer(flex: 3),

              // ── Continue button ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _proceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: bgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _step == 0 ? 'Continue' : 'Start Reading',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(LucideIcons.arrowRight, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Step indicator ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _stepDot(isActive: _step == 0, color: accentColor),
                  const SizedBox(width: 8),
                  _stepDot(isActive: _step == 1, color: accentColor),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String label,
    required String subtitle,
    required String emoji,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color accentColor,
    required Color bgColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (emoji.isNotEmpty)
              Text(emoji, style: const TextStyle(fontSize: 28))
            else if (icon != null)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? accentColor : const Color(0xFF8A9FA5),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? accentColor : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.7)
                          : const Color(0xFF8A9FA5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(LucideIcons.checkCircle2, size: 20, color: accentColor)
            else
              Icon(
                LucideIcons.circle,
                size: 20,
                color: Colors.white.withValues(alpha: 0.15),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stepDot({required bool isActive, required Color color}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? color : color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
