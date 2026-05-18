import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran_app/data/quran_topics.dart';
import 'package:quran_app/data/surah_metadata.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/plan_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/context_provider.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/widgets/understand/today_context_card.dart';
import 'package:quran_app/widgets/understand/topic_carousel.dart';
import 'package:quran_app/widgets/understand/surah_detail_sheet.dart';
import 'package:quran_app/widgets/app_header.dart';

/// Understand tab — Study Hub for exploring Quran context.
///
/// Always shows a searchable 114-surah browser.
/// When the user has memorization progress + an active plan,
/// a contextual header card surfaces relevant tafsir/asbab.
class UnderstandScreen extends StatefulWidget {
  const UnderstandScreen({super.key});

  @override
  State<UnderstandScreen> createState() => _UnderstandScreenState();
}

class _UnderstandScreenState extends State<UnderstandScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Ensure asbab dataset is loaded for surah detail sheets
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContextProvider>().asbabService.importIfNeeded();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<SurahInfo> get _filteredSurahs {
    final rewaya = context.read<QuranReadingProvider>().selectedRewaya;
    final surahs = getAllSurahs(rewaya: rewaya);
    if (_searchQuery.isEmpty) return surahs;
    final q = _searchQuery.toLowerCase();
    return surahs.where((s) {
      return s.nameSimple.toLowerCase().contains(q) ||
          s.nameArabic.contains(q) ||
          s.id.toString() == q;
    }).toList();
  }

  void _openSurahDetail(SurahInfo surah) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        builder: (_, controller) => SurahDetailSheet(surah: surah),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final profile = context.watch<HifzProfileProvider>();
    final plan = context.watch<PlanProvider>();
    final l10n = AppLocalizations.of(context)!;

    // Watch rewaya so the surah list rebuilds when user switches rewaya
    context.watch<QuranReadingProvider>();

    // Show contextual card only when user has active plan with sabaq
    final showContextCard =
        profile.hasActiveProfile &&
        plan.todayPlan != null &&
        (plan.todayPlan!.sabaqPage) > 0;

    final filtered = _filteredSurahs;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 16,
                ),
                child: AppHeader(
                  title: l10n.navUnderstand,
                  subtitle: l10n.undExploreDeeper,
                ),
              ),
            ),

            // ── Contextual Header Card ──
            if (showContextCard)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: const TodayContextCard(),
                ),
              ),

            // ── Stories Carousel ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TopicCarousel(
                  sectionTitle: l10n.undStories,
                  topics: prophetStories,
                ),
              ),
            ),

            // ── Themes Carousel ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TopicCarousel(
                  sectionTitle: l10n.undThemes,
                  topics: quranThemes,
                ),
              ),
            ),

            // ── Search Bar ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(theme.radiusXl),
                    border: Border.all(color: theme.dividerColor, width: 1),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 14,
                      color: theme.primaryText,
                    ),
                    decoration: InputDecoration(
                      hintText: l10n.undSearchSurahs,
                      hintStyle: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 14,
                        color: theme.mutedText,
                      ),
                      prefixIcon: Icon(
                        LucideIcons.search,
                        size: 16,
                        color: theme.mutedText,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                                _searchFocusNode.unfocus();
                              },
                              child: Icon(
                                LucideIcons.x,
                                size: 16,
                                color: theme.mutedText,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Section Label ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  _searchQuery.isEmpty
                      ? l10n.undAllSurahs
                      : '${filtered.length} ${l10n.undResults}',
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.mutedText,
                  ),
                ),
              ),
            ),

            // ── Surah List ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final surah = filtered[index];
                  return _SurahTile(
                    surah: surah,
                    theme: theme,
                    onTap: () => _openSurahDetail(surah),
                  );
                }, childCount: filtered.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single surah row in the list.
class _SurahTile extends StatelessWidget {
  final SurahInfo surah;
  final ThemeProvider theme;
  final VoidCallback onTap;

  const _SurahTile({
    required this.surah,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // Surah number — shadow-as-border instead of Border.all
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(theme.radiusLg),
                  border: Border.all(color: theme.dividerColor, width: 1),
                ),
                child: Center(
                  child: Text(
                    '${surah.id}',
                    style: TextStyle(
                      fontFamily: GeistTypography.primaryFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.secondaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name + info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.localeName == 'ar' ? surah.nameArabic : surah.nameSimple,
                      style: AppLocalizations.of(context)!.localeName == 'ar'
                          ? GoogleFonts.amiri(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: theme.primaryText,
                            )
                          : TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryText,
                            ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.surahSubtitle(
                        surah.isMeccan ? l10n.meccan : l10n.medinan,
                        surah.versesCount,
                        surah.startPage,
                      ),
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        fontSize: 12,
                        color: theme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),

              // Secondary name
              if (AppLocalizations.of(context)!.localeName != 'ar')
                ExcludeSemantics(
                  child: Text(
                    surah.nameArabic,
                    style: GoogleFonts.amiri(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: theme.secondaryText,
                    ),
                  ),
                ),

              const SizedBox(width: 8),
              Icon(LucideIcons.chevronRight, size: 16, color: theme.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}
