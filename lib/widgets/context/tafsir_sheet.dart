import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/context_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/services/tafsir_service.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom sheet that shows tafsir (exegesis) for a selected verse.
///
/// Supports three views:
/// - **Brief** — Simplified tafsir (language-aware)
/// - **Detailed** — Full scholarly tafsir (language-aware)
/// - **Occasion** — Asbab al-nuzul (Arabic only for now)
void showTafsirSheet(
  BuildContext context, {
  required String verseKey,
  String? surahName,
}) {
  final theme = context.read<ThemeProvider>();
  // Capture the provider ONCE before opening the sheet.
  // This avoids any context.watch inside the sheet tree.
  final contextProvider = context.read<ContextProvider>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TafsirSheetContent(
      verseKey: verseKey,
      surahName: surahName,
      theme: theme,
      contextProvider: contextProvider,
    ),
  );
}

class _TafsirSheetContent extends StatefulWidget {
  final String verseKey;
  final String? surahName;
  final ThemeProvider theme;
  final ContextProvider contextProvider;

  const _TafsirSheetContent({
    required this.verseKey,
    this.surahName,
    required this.theme,
    required this.contextProvider,
  });

  @override
  State<_TafsirSheetContent> createState() => _TafsirSheetContentState();
}

class _TafsirSheetContentState extends State<_TafsirSheetContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Local state — populated by listening to the provider manually
  VerseText? _briefTafsir;
  VerseText? _detailedTafsir;
  List<String>? _occasions;
  bool _isLoadingBrief = false;
  bool _isLoadingDetailed = false;
  bool _isArabic = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isArabic = widget.contextProvider.locale == 'ar';

    // Listen to provider changes manually — no context.watch needed
    widget.contextProvider.addListener(_onProviderChanged);

    // Load brief tafsir + asbab immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.contextProvider.loadBriefTafsir(widget.verseKey);
      widget.contextProvider.loadAsbabNuzul(widget.verseKey);
    });

    // Load detailed tafsir on demand
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.index == 1 && _detailedTafsir == null && !_isLoadingDetailed) {
        widget.contextProvider.loadDetailedTafsir(widget.verseKey);
      }
    });
  }

  void _onProviderChanged() {
    if (!mounted) return;
    setState(() {
      _briefTafsir = widget.contextProvider.activeBriefTafsir;
      _detailedTafsir = widget.contextProvider.activeDetailedTafsir;
      _occasions = widget.contextProvider.activeAsbabNuzul;
      _isLoadingBrief = widget.contextProvider.isLoadingBriefTafsir;
      _isLoadingDetailed = widget.contextProvider.isLoadingDetailedTafsir;
    });
  }

  @override
  void dispose() {
    widget.contextProvider.removeListener(_onProviderChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            color: theme.sheetBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor,
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.sheetDragHandle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.accentLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 20,
                        color: theme.accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tafsir — ${widget.verseKey}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: theme.primaryText,
                            ),
                          ),
                          if (widget.surahName != null)
                            Text(
                              widget.surahName!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: theme.secondaryText,
                              ),
                            ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        size: 22,
                        color: theme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Tab bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: theme.pillBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: theme.accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: theme.chipSelectedText,
                  unselectedLabelColor: theme.secondaryText,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'Brief'),
                    Tab(text: 'Detailed'),
                    Tab(text: 'Occasion'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Content — all data passed as constructor args, NO context.watch
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _TafsirTextView(
                      text: _briefTafsir?.text,
                      isLoading: _isLoadingBrief,
                      isArabic: _isArabic,
                      emptyMessage: 'No brief tafsir available for this verse.',
                      theme: theme,
                    ),
                    _TafsirTextView(
                      text: _detailedTafsir?.text,
                      isLoading: _isLoadingDetailed,
                      isArabic: _isArabic,
                      emptyMessage: 'Tap the Detailed tab to load.',
                      theme: theme,
                    ),
                    _OccasionView(
                      occasions: _occasions,
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Reusable tafsir text view — NO context.watch, all data via constructor.
class _TafsirTextView extends StatelessWidget {
  final String? text;
  final bool isLoading;
  final bool isArabic;
  final String emptyMessage;
  final ThemeProvider theme;

  const _TafsirTextView({
    required this.text,
    required this.isLoading,
    required this.isArabic,
    required this.emptyMessage,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildLoading();
    if (text == null || text!.isEmpty) return _buildEmpty();
    return _buildText();
  }

  Widget _buildText() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: ExcludeSemantics(
        child: Text(
          text!,
          style: isArabic
              ? GoogleFonts.amiri(
                  fontSize: 18, height: 2.0, color: theme.primaryText)
              : GoogleFonts.inter(
                  fontSize: 15, height: 1.8, color: theme.primaryText),
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 40, color: theme.mutedText),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: GoogleFonts.inter(fontSize: 14, color: theme.secondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Occasion view — NO context.watch, all data via constructor.
class _OccasionView extends StatelessWidget {
  final List<String>? occasions;
  final ThemeProvider theme;

  const _OccasionView({
    required this.occasions,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (occasions == null || occasions!.isEmpty) return _buildEmpty();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.history_edu, size: 16, color: theme.accentColor),
                const SizedBox(width: 8),
                Text(
                  'سبب النزول',
                  style: GoogleFonts.amiri(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.accentColor,
                  ),
                ),
                const Spacer(),
                Text(
                  '${occasions!.length} ${occasions!.length == 1 ? 'narration' : 'narrations'}',
                  style: GoogleFonts.inter(
                    fontSize: 11, color: theme.secondaryText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Narrations
          ...occasions!.asMap().entries.map((entry) {
            final index = entry.key;
            final text = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (occasions!.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'الرواية ${index + 1}',
                      style: GoogleFonts.amiri(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: theme.accentColor,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ExcludeSemantics(
                  child: Text(
                    text,
                    style: GoogleFonts.amiri(
                      fontSize: 17, height: 2.0, color: theme.primaryText),
                    textDirection: TextDirection.rtl,
                  ),
                ),
                if (index < occasions!.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_edu, size: 40, color: theme.mutedText),
            const SizedBox(height: 12),
            Text(
              'No occasion of revelation recorded\nfor this verse.',
              style: GoogleFonts.inter(fontSize: 14, color: theme.secondaryText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
