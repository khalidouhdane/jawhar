import 'package:flutter/material.dart';
import 'package:quran_app/widgets/app_header.dart';
import 'package:quran_app/widgets/hifz/hifz_cta_card.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/widgets/werd_card.dart';
import 'package:quran_app/providers/theme_provider.dart';

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

              // Werd Hero Card
              const WerdCard(),
              const SizedBox(height: 16),

              // Ayah of the day
              ayahCard,

              const SizedBox(height: 24),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SafeArea(
            top: false,
            child: HifzCtaCard(
              theme: context.watch<ThemeProvider>(),
              onTap: onStartJourney,
            ),
          ),
        ),
      ],
    );
  }
}
