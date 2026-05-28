import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/models/session_recipe_models.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/theme/icon_resolver.dart';
import 'package:quran_app/l10n/app_localizations.dart';

/// Dashboard card showing today's Hifz plan.
///
/// Layout (matching reference design):
///   [Header: "Today's Plan"]
///   [Phase Cards Row: Sabaq | Sabqi | Manzil]
///   [Method Pills Row: Listen | Read | Recite]
///   [CTA Button: Start Session]
class PlanCard extends StatefulWidget {
  final DailyPlan plan;
  final ThemeProvider theme;
  final VoidCallback onStartSession;
  final MemoryProfile? profile;
  final List<SessionRecipe> recipes;
  final int sessionCount;
  final bool showStartSessionCta;

  const PlanCard({
    super.key,
    required this.plan,
    required this.theme,
    required this.onStartSession,
    this.profile,
    this.recipes = const [],
    this.sessionCount = 0,
    this.showStartSessionCta = true,
  });

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard> {
  bool _showReasoning = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final theme = widget.theme;
    final l = AppLocalizations.of(context)!;

    // Determine which phases are active (not skipped / not empty)
    final hasSabqi = plan.sabqiPages.isNotEmpty;
    final hasManzil = plan.manzilPages.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusXl),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          _buildHeader(theme, plan, l),
          const SizedBox(height: 14),

          // ── Phase Cards Row ──
          _buildPhaseCardsRow(theme, plan, l, hasSabqi, hasManzil),
          const SizedBox(height: 10),

          // ── Method Pills Row (from recipes) ──
          if (widget.recipes.isNotEmpty) ...[
            _buildMethodPills(theme),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 4),

          // ── AI Reasoning (collapsible) ──
          if (plan.isAiGenerated &&
              plan.aiReasoning != null &&
              plan.aiReasoning!.isNotEmpty) ...[
            _buildReasoningSection(theme, plan, l),
            const SizedBox(height: 12),
          ],

          // ── CTA Button ──
          if (widget.showStartSessionCta) _buildCTA(theme, plan, l),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(ThemeProvider theme, DailyPlan plan, AppLocalizations l) {
    return Row(
      children: [
        Text(
          widget.sessionCount > 0
              ? l.planExtraSession(widget.sessionCount + 1)
              : l.planTodaysPlan,
          style: TextStyle(
            fontFamily: GeistTypography.primaryFontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.primaryText,
          ),
        ),
        if (plan.isAiGenerated) ...[
          const SizedBox(width: 8),
          Icon(LucideIcons.sparkles, size: 14, color: theme.mutedText),
        ],
        const Spacer(),
        // Total time pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(theme.radiusPill),
            border: Border.all(color: theme.dividerColor, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.clock, size: 11, color: theme.secondaryText),
              const SizedBox(width: 4),
              Text(
                '~${l.planMinDuration(plan.estimatedMinutes)}',
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE CARDS ROW
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPhaseCardsRow(
    ThemeProvider theme,
    DailyPlan plan,
    AppLocalizations l,
    bool hasSabqi,
    bool hasManzil,
  ) {
    final cards = <Widget>[];

    // Sabaq (always present)
    cards.add(
      Expanded(
        child: _PhaseCard(
          theme: theme,
          title: l.planSabaqNew,
          timeMinutes: plan.sabaqTargetMinutes,
          pageInfo: _sabaqPageInfo(plan, l),
          isDone: plan.sabaqDoneOffline,
          l10n: l,
        ),
      ),
    );

    // Sabqi
    if (hasSabqi) {
      cards.add(const SizedBox(width: 8));
      cards.add(
        Expanded(
          child: _PhaseCard(
            theme: theme,
            title: l.planSabqiReview,
            timeMinutes: plan.sabqiTargetMinutes,
            pageInfo: _formatPageList(plan.sabqiPages, l),
            isDone: plan.sabqiDoneOffline,
            l10n: l,
          ),
        ),
      );
    }

    // Manzil
    if (hasManzil) {
      cards.add(const SizedBox(width: 8));
      cards.add(
        Expanded(
          child: _PhaseCard(
            theme: theme,
            title: l.planManzilRevision,
            timeMinutes: plan.manzilTargetMinutes,
            pageInfo: l.planJuzPages(plan.manzilJuz, plan.manzilPages.length),
            isDone: plan.manzilDoneOffline,
            l10n: l,
          ),
        ),
      );
    }

    return Row(children: cards);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // METHOD PILLS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMethodPills(ThemeProvider theme) {
    // Extract sabaq recipe steps (the primary session recipe)
    final sabaqRecipe = widget.recipes
        .where((r) => r.phase == 'sabaq')
        .toList();
    if (sabaqRecipe.isEmpty || sabaqRecipe.first.isEmpty) {
      return const SizedBox.shrink();
    }

    final steps = sabaqRecipe.first.steps;

    return Row(
      children: List.generate(steps.length, (i) {
        final step = steps[i];
        final isLast = i == steps.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 6),
            child: _MethodPill(
              theme: theme,
              icon: IconResolver.resolve(step.icon),
              label: step.action.label,
              count: step.unit == StepUnit.times
                  ? 'x${step.target}'
                  : '${step.target}m',
            ),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AI REASONING
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildReasoningSection(
    ThemeProvider theme,
    DailyPlan plan,
    AppLocalizations l,
  ) {
    return GestureDetector(
      onTap: () => setState(() => _showReasoning = !_showReasoning),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.radiusLg),
          border: Border.all(color: theme.dividerColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.lightbulb,
                  size: 12,
                  color: theme.secondaryText,
                ),
                const SizedBox(width: 6),
                Text(
                  l.planWhyThisPlan,
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.secondaryText,
                  ),
                ),
                const Spacer(),
                Icon(
                  _showReasoning
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  size: 14,
                  color: theme.mutedText,
                ),
              ],
            ),
            if (_showReasoning) ...[
              const SizedBox(height: 6),
              Text(
                plan.aiReasoning!,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 12,
                  color: theme.secondaryText,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CTA BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCTA(ThemeProvider theme, DailyPlan plan, AppLocalizations l) {
    final isCompleted = plan.isCompleted;

    return Material(
      color: isCompleted ? theme.cardColor : theme.foregroundColor,
      borderRadius: BorderRadius.circular(theme.radiusLg),
      child: InkWell(
        onTap: isCompleted ? null : widget.onStartSession,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isCompleted ? l.planCompleted : l.planStartSession,
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? theme.mutedText
                      : theme.scaffoldBackground,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isCompleted ? LucideIcons.check : LucideIcons.sparkles,
                size: 16,
                color: isCompleted ? theme.mutedText : theme.scaffoldBackground,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  String _sabaqPageInfo(DailyPlan plan, AppLocalizations l) {
    if (plan.sabaqStartVerse != null) {
      return l.planPageFromVerse(plan.sabaqPage, plan.sabaqStartVerse!);
    }
    return l.planPageLines(
      plan.sabaqPage,
      plan.sabaqLineStart,
      plan.sabaqLineEnd,
    );
  }

  String _formatPageList(List<int> pages, AppLocalizations l) {
    if (pages.isEmpty) return l.planNoReviewYet;
    if (pages.length <= 2) {
      return l.planPagesList(pages.join(', '));
    }
    // Show compact range if sequential
    final sorted = [...pages]..sort();
    if (sorted.last - sorted.first == sorted.length - 1) {
      return '${l.homePage} ${sorted.first}–${sorted.last}';
    }
    return l.planPagesListMore(pages.take(2).join(', '), pages.length - 2);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PHASE CARD — individual phase cell in the row
// ═══════════════════════════════════════════════════════════════════════════════

class _PhaseCard extends StatelessWidget {
  final ThemeProvider theme;
  final String title;
  final int timeMinutes;
  final String pageInfo;
  final bool isDone;

  final AppLocalizations l10n;

  const _PhaseCard({
    required this.theme,
    required this.title,
    required this.timeMinutes,
    required this.pageInfo,
    required this.isDone,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          // Time pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(theme.radiusPill),
              border: Border.all(color: theme.dividerColor, width: 1),
            ),
            child: Text(
              l10n.planMinDuration(timeMinutes),
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDone ? theme.mutedText : theme.secondaryText,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Phase title
          Text(
            _shortTitle(title),
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDone ? theme.mutedText : theme.primaryText,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),

          // Page info
          Text(
            pageInfo,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 11,
              color: isDone ? theme.dividerColor : theme.secondaryText,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Done checkmark
          if (isDone) ...[
            const SizedBox(height: 6),
            Icon(LucideIcons.check, size: 14, color: theme.mutedText),
          ],
        ],
      ),
    );
  }

  /// Extract just the phase name (e.g., "Sabaq · New" → "Sabaq")
  String _shortTitle(String fullTitle) {
    // Split on " · " separator if present
    final parts = fullTitle.split(' · ');
    return parts.first.trim();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// METHOD PILL — recipe step action pill
// ═══════════════════════════════════════════════════════════════════════════════

class _MethodPill extends StatelessWidget {
  final ThemeProvider theme;
  final IconData icon;
  final String label;
  final String count;

  const _MethodPill({
    required this.theme,
    required this.icon,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusLg),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.secondaryText),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.primaryText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            count,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}
