import 'package:flutter/material.dart';
import 'package:quran_app/widgets/dashboard/dashboard_header.dart';
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
                child: DashboardHeader(onAvatarTap: onAvatarTap),
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
