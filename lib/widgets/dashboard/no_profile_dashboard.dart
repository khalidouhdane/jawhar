import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/widgets/app_header.dart';
import 'package:quran_app/widgets/hifz/hifz_cta_card.dart';
import 'package:quran_app/widgets/werd_card.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/widgets/hifz/plan_card.dart';
import 'package:quran_app/widgets/dashboard/progress_strip.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/l10n/app_localizations.dart';

class NoProfileDashboard extends StatelessWidget {
  final VoidCallback onAvatarTap;
  final VoidCallback onStartJourney;
  final Widget ayahCard;

  const NoProfileDashboard({
    super.key,
    required this.onAvatarTap,
    required this.onStartJourney,
    required this.ayahCard,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    final fakePlan = DailyPlan(
      id: 'fake_plan',
      profileId: 'fake_profile',
      date: DateTime.now(),
      sabaqPage: 582, // Surah An-Naba
      sabaqLineStart: 1,
      sabaqLineEnd: 15,
      sabaqTargetMinutes: 20,
      sabaqRepetitionTarget: 5,
      sabqiPages: const [583, 584],
      sabqiTargetMinutes: 10,
      manzilJuz: 30,
      manzilPages: const [585, 586, 587],
      manzilTargetMinutes: 15,
      isAiGenerated: true,
      aiReasoning: AppLocalizations.of(context)!.localeName == 'ar'
          ? 'تم تصميم هذه الخطة التجريبية لتحسين حفظك بناءً على جدولة التكرار المتباعد.'
          : 'This preview plan is designed to optimize your retention based on space-repetition scheduling.',
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  // Parent provides 16 horizontal padding, add 4 to reach 20 left/right.
                  padding: const EdgeInsets.only(
                    left: 4,
                    right: 4,
                    top: 20,
                    bottom: 16,
                  ),
                  child: AppHeader(onAvatarTap: onAvatarTap),
                ),
              ),

              // ── Fake Today's Plan Card ──
              PlanCard(
                plan: fakePlan,
                theme: theme,
                onStartSession: onStartJourney,
                showStartSessionCta: false,
              ),
              const SizedBox(height: 16),

              // ── Fake Progress Strip ──
              ProgressStrip(
                memorizedPages: 12,
                streakDays: 4,
                sessionCount: 8,
                onTap: onStartJourney,
              ),
              const SizedBox(height: 16),

              // ── Create Your Hifz Profile CTA Card ──
              HifzCtaCard(theme: theme, onTap: onStartJourney),
              const SizedBox(height: 20),

              // ── Continue Reading (Werd Card) ──
              const WerdCard(),
              const SizedBox(height: 16),

              // ── Ayah of the Day ──
              ayahCard,

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}
