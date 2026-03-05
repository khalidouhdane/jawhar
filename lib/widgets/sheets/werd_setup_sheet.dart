import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/werd_models.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/providers/werd_provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';

/// Bottom sheet for creating or editing a daily werd configuration.
class WerdSetupSheet extends StatefulWidget {
  const WerdSetupSheet({super.key});

  @override
  State<WerdSetupSheet> createState() => _WerdSetupSheetState();
}

class _WerdSetupSheetState extends State<WerdSetupSheet> {
  WerdMode _mode = WerdMode.fixedRange;
  final _startController = TextEditingController(text: '1');
  final _endController = TextEditingController(text: '20');
  double _pagesPerDay = 5;

  @override
  void initState() {
    super.initState();
    // Pre-fill from existing config if editing
    final existing = context.read<WerdProvider>().config;
    if (existing != null) {
      _mode = existing.mode;
      _startController.text = existing.startPage.toString();
      _endController.text = existing.endPage.toString();
      _pagesPerDay = existing.pagesPerDay.toDouble();
    }
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final l = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.sheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.sheetDragHandle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Row(
                  children: [
                    Icon(
                      LucideIcons.calendarCheck,
                      size: 20,
                      color: theme.accentColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l.t('werd_setup_title'),
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.t('werd_setup_desc'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: theme.secondaryText,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Mode selector ──
                _buildModeSelector(theme, l),

                const SizedBox(height: 24),

                // ── Mode-specific inputs ──
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _mode == WerdMode.fixedRange
                      ? _buildFixedRangeInputs(theme, l)
                      : _buildDailyPagesInput(theme, l),
                ),

                const SizedBox(height: 20),

                // ── Summary preview ──
                _buildSummary(theme, l),

                const SizedBox(height: 24),

                // ── Action buttons ──
                Row(
                  children: [
                    // Delete / Reset button (only if editing)
                    if (context.read<WerdProvider>().hasWerd)
                      GestureDetector(
                        onTap: () {
                          context.read<WerdProvider>().resetWerd();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            LucideIcons.trash2,
                            size: 18,
                            color: Colors.red.shade400,
                          ),
                        ),
                      ),
                    if (context.read<WerdProvider>().hasWerd)
                      const SizedBox(width: 12),
                    // Save button
                    Expanded(
                      child: GestureDetector(
                        onTap: _save,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: theme.accentColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              l.t('werd_save'),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Mode Selector ───────────────────────────────────────────────────────

  Widget _buildModeSelector(ThemeProvider theme, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.pillBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _modeChip(
            theme,
            label: l.t('werd_fixed_range'),
            icon: LucideIcons.bookOpen,
            selected: _mode == WerdMode.fixedRange,
            onTap: () => setState(() => _mode = WerdMode.fixedRange),
          ),
          const SizedBox(width: 4),
          _modeChip(
            theme,
            label: l.t('werd_daily_pages'),
            icon: LucideIcons.layers,
            selected: _mode == WerdMode.dailyPages,
            onTap: () => setState(() => _mode = WerdMode.dailyPages),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(
    ThemeProvider theme, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? theme.accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : theme.secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : theme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Fixed Range Inputs ──────────────────────────────────────────────────

  Widget _buildFixedRangeInputs(ThemeProvider theme, AppLocalizations l) {
    return Column(
      key: const ValueKey('fixed'),
      children: [
        Row(
          children: [
            Expanded(
              child: _pageInput(
                theme,
                label: l.t('werd_from_page'),
                controller: _startController,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                LucideIcons.arrowRight,
                size: 18,
                color: theme.mutedText,
              ),
            ),
            Expanded(
              child: _pageInput(
                theme,
                label: l.t('werd_to_page'),
                controller: _endController,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pageInput(
    ThemeProvider theme, {
    required String label,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.secondaryText,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.inputFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor, width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _PageRangeFormatter(),
            ],
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.primaryText,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              hintText: '1',
              hintStyle: TextStyle(color: theme.mutedText),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    );
  }

  // ── Daily Pages Slider ──────────────────────────────────────────────────

  Widget _buildDailyPagesInput(ThemeProvider theme, AppLocalizations l) {
    return Column(
      key: const ValueKey('daily'),
      children: [
        Text(
          l.t('werd_pages_per_day'),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.secondaryText,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        // Large value display
        Text(
          '${_pagesPerDay.round()}',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: theme.primaryText,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.accentColor,
            inactiveTrackColor: theme.sliderInactive,
            thumbColor: theme.accentColor,
            overlayColor: theme.accentColor.withValues(alpha: 0.1),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _pagesPerDay,
            min: 1,
            max: 30,
            divisions: 29,
            onChanged: (v) => setState(() => _pagesPerDay = v),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.t('werd_1_page'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: theme.mutedText,
              ),
            ),
            Text(
              l.t('werd_30_pages'),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: theme.mutedText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Summary ─────────────────────────────────────────────────────────────

  Widget _buildSummary(ThemeProvider theme, AppLocalizations l) {
    final start = int.tryParse(_startController.text) ?? 1;
    final end = int.tryParse(_endController.text) ?? 20;

    String summary;
    if (_mode == WerdMode.fixedRange) {
      final pages = (end - start + 1).clamp(1, 604);
      summary = l
          .t('werd_summary_fixed')
          .replaceAll('{pages}', pages.toString())
          .replaceAll('{start}', start.toString())
          .replaceAll('{end}', end.toString());
    } else {
      final days = (604 / _pagesPerDay).ceil();
      summary = l
          .t('werd_summary_daily')
          .replaceAll('{pages}', _pagesPerDay.round().toString())
          .replaceAll('{days}', days.toString());
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 15, color: theme.accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summary,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.accentColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  void _save() {
    final start = (int.tryParse(_startController.text) ?? 1).clamp(1, 604);
    final end = (int.tryParse(_endController.text) ?? 20).clamp(1, 604);
    final pagesPerDay = _pagesPerDay.round().clamp(1, 30);

    // Validate range
    if (_mode == WerdMode.fixedRange && start > end) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).t('werd_error_range')),
        ),
      );
      return;
    }

    final config = WerdConfig(
      mode: _mode,
      startPage: start,
      endPage: _mode == WerdMode.fixedRange ? end : 604,
      pagesPerDay: _mode == WerdMode.dailyPages
          ? pagesPerDay
          : (end - start + 1).clamp(1, 604),
      pagesReadToday: 0,
      lastResetDate: DateTime.now(),
      isEnabled: true,
    );

    context.read<WerdProvider>().updateWerd(config);
    Navigator.pop(context);
  }
}

/// Ensures page numbers stay within 1–604.
class _PageRangeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final n = int.tryParse(newValue.text);
    if (n == null) return oldValue;
    if (n < 0) return oldValue;
    if (n > 604) {
      return const TextEditingValue(
        text: '604',
        selection: TextSelection.collapsed(offset: 3),
      );
    }
    return newValue;
  }
}
