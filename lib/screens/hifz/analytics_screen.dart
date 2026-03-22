import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/providers/analytics_provider.dart';
import 'package:quran_app/providers/hifz_profile_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/widgets/hifz/suggestion_card.dart';
import 'package:quran_app/widgets/hifz/weekly_report.dart';

/// Analytics screen — weekly/monthly performance reports and suggestions.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.week;
  WeeklySnapshot? _monthlySnapshot;
  bool _monthlyLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final profileProvider = context.read<HifzProfileProvider>();
    final analytics = context.read<AnalyticsProvider>();
    if (profileProvider.hasActiveProfile) {
      await analytics.loadAnalytics(profileProvider.activeProfile!);
    }
  }

  Future<void> _loadMonthly() async {
    if (_monthlySnapshot != null) return;
    setState(() => _monthlyLoading = true);
    final profile = context.read<HifzProfileProvider>().activeProfile;
    if (profile != null) {
      final analytics = context.read<AnalyticsProvider>();
      _monthlySnapshot =
          await analytics.generateMonthlySnapshot(profile.id);
    }
    if (mounted) setState(() => _monthlyLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final analytics = context.watch<AnalyticsProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackground,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Icon(LucideIcons.arrowLeft, color: theme.primaryText),
        ),
        title: Text(
          'Analytics',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: theme.primaryText,
          ),
        ),
        centerTitle: true,
      ),
      body: analytics.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.accentColor,
                strokeWidth: 2,
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Period Toggle ──
                  _buildPeriodToggle(theme),
                  const SizedBox(height: 20),

                  // ── Report Content ──
                  if (_selectedPeriod == AnalyticsPeriod.week) ...[
                    _buildWeeklyContent(theme, analytics),
                  ] else ...[
                    _buildMonthlyContent(theme, analytics),
                  ],

                  // ── Active Suggestions ──
                  if (analytics.hasSuggestions) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Suggestions',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...analytics.activeSuggestions.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SuggestionCard(
                            suggestion: s,
                            theme: theme,
                            onAccept: () =>
                                analytics.acceptSuggestion(s.id),
                            onDismiss: () =>
                                analytics.dismissSuggestion(s.id),
                            onRemindLater: () =>
                                analytics.remindLater(s.id),
                          ),
                        )),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodToggle(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          _buildToggleButton(
            'Weekly',
            AnalyticsPeriod.week,
            theme,
          ),
          _buildToggleButton(
            'Monthly',
            AnalyticsPeriod.month,
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    String label,
    AnalyticsPeriod period,
    ThemeProvider theme,
  ) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPeriod = period);
          if (period == AnalyticsPeriod.month) {
            _loadMonthly();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? theme.accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : theme.secondaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeeklyContent(
    ThemeProvider theme,
    AnalyticsProvider analytics,
  ) {
    final snapshot = analytics.currentWeek;
    if (snapshot == null) {
      return _buildEmptyState(theme, 'No data this week yet');
    }

    if (!snapshot.hasEnoughData) {
      return _buildEmptyState(
        theme,
        'Complete a few more sessions to see your weekly report',
      );
    }

    return WeeklyReportWidget(
      snapshot: snapshot,
      previousSnapshot: analytics.previousWeek,
      paceData: analytics.paceData,
      theme: theme,
    );
  }

  Widget _buildMonthlyContent(
    ThemeProvider theme,
    AnalyticsProvider analytics,
  ) {
    if (_monthlyLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: CircularProgressIndicator(
            color: theme.accentColor,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_monthlySnapshot == null) {
      return _buildEmptyState(theme, 'No data this month yet');
    }

    if (!_monthlySnapshot!.hasEnoughData) {
      return _buildEmptyState(
        theme,
        'Complete a few more sessions to see your monthly report',
      );
    }

    return WeeklyReportWidget(
      snapshot: _monthlySnapshot!,
      paceData: analytics.paceData,
      theme: theme,
    );
  }

  Widget _buildEmptyState(ThemeProvider theme, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.barChart2,
            size: 40,
            color: theme.mutedText,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: theme.secondaryText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
