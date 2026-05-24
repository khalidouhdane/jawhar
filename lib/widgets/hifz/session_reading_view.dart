import 'package:flutter/material.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/session_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/widgets/reading_canvas.dart';
import 'package:quran_app/widgets/hifz/session_overlay.dart';
import 'package:quran_app/widgets/hifz/session_spotlight_mask.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/utils/tablet_layout_math.dart';

/// Scoped reading canvas for Hifz sessions (Phase 4 — Digital Session Mode).
///
/// Wraps the existing [ReadingCanvas] to display only the assigned page
/// during a session. No page swiping — the user can only view the
/// page assigned to the current phase.
///
/// Integration contract:
/// ```dart
/// SessionReadingView(
///   pageNumber: 45,
///   showOverlay: true,
///   session: sessionProvider,
///   onRepTap: () => session.countRep(),
///   onDone: () => session.finishPhase(),
/// )
/// ```
///
/// The Core Engine agent will add a toggle in [SessionScreen] that swaps
/// between the existing control panel and this widget.
class SessionReadingView extends StatefulWidget {
  /// Which Quran page to display.
  final int pageNumber;

  /// Whether to show floating session controls (timer, reps, phase, etc.).
  final bool showOverlay;

  /// The session provider instance to read timer, reps, and phase state from.
  final SessionProvider session;

  /// Callback to count a repetition (delegates to SessionProvider.countRep).
  final VoidCallback onRepTap;

  /// Callback to finish the current phase (delegates to SessionProvider.finishPhase).
  final VoidCallback onDone;

  /// Optional callback to skip the current phase.
  final VoidCallback? onSkip;
  final VoidCallback? onTogglePause;
  final VoidCallback onMinimize;
  final VoidCallback onExit;

  const SessionReadingView({
    super.key,
    required this.pageNumber,
    required this.showOverlay,
    required this.session,
    required this.onRepTap,
    required this.onDone,
    this.onSkip,
    this.onTogglePause,
    required this.onMinimize,
    required this.onExit,
  });

  @override
  State<SessionReadingView> createState() => _SessionReadingViewState();
}

class _SessionReadingViewState extends State<SessionReadingView> {
  /// Verses for the assigned page, loaded once on init.
  List<Verse>? _verses;
  List<Verse>? _leftPageVerses; // for tablet dual page layout
  int? _leftPageNumber;
  int? _rightPageNumber;
  bool _isLoading = true;
  String? _error;
  bool _isFullScreen = false;

  /// Currently selected verse ID for the contextual menu.
  int? _selectedVerseId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPageVerses();
  }

  @override
  void didUpdateWidget(SessionReadingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _loadPageVerses();
    }
  }

  void _loadPageVerses() {
    final readingProvider = context.read<QuranReadingProvider>();
    final isTablet = MediaQuery.sizeOf(context).width > 768;
    
    if (isTablet) {
      final spread = TabletLayoutMath.pageToSpread(widget.pageNumber);
      final rightPage = TabletLayoutMath.spreadToRightPage(spread);
      final leftPage = TabletLayoutMath.spreadToLeftPage(spread);
      
      setState(() {
        _rightPageNumber = rightPage;
        _verses = readingProvider.getPageVerses(rightPage);
        _leftPageNumber = leftPage;
        _leftPageVerses = readingProvider.getPageVerses(leftPage);
        _isLoading = false;
        _error = null;
      });
    } else {
      setState(() {
        _rightPageNumber = null;
        _verses = readingProvider.getPageVerses(widget.pageNumber);
        _leftPageNumber = null;
        _leftPageVerses = null;
        _isLoading = false;
        _error = null;
      });
    }
  }

  Widget _buildQuranContent(ThemeProvider theme) {
    final isTablet = _leftPageVerses != null && _leftPageNumber != null;
    
    if (!isTablet) {
      return ReadingCanvas(
        verses: _verses!,
        pageNumber: widget.pageNumber,
        selectedVerseId: _selectedVerseId,
        onVerseSelected: (id) => setState(() => _selectedVerseId = id),
        onCanvasTapped: () {
          if (_selectedVerseId != null) {
            setState(() => _selectedVerseId = null);
          } else {
            setState(() => _isFullScreen = !_isFullScreen);
          }
        },
      );
    }
    
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [
          // Left Page Canvas
          Expanded(
            child: ReadingCanvas(
              verses: _leftPageVerses!,
              pageNumber: _leftPageNumber!,
              selectedVerseId: _selectedVerseId,
              onVerseSelected: (id) => setState(() => _selectedVerseId = id),
              onCanvasTapped: () {
                if (_selectedVerseId != null) {
                  setState(() => _selectedVerseId = null);
                } else {
                  setState(() => _isFullScreen = !_isFullScreen);
                }
              },
            ),
          ),
          
          // Spine Divider
          _buildSpineDivider(theme),
          
          // Right Page Canvas
          Expanded(
            child: ReadingCanvas(
              verses: _verses!,
              pageNumber: _rightPageNumber ?? widget.pageNumber,
              selectedVerseId: _selectedVerseId,
              onVerseSelected: (id) => setState(() => _selectedVerseId = id),
              onCanvasTapped: () {
                if (_selectedVerseId != null) {
                  setState(() => _selectedVerseId = null);
                } else {
                  setState(() => _isFullScreen = !_isFullScreen);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpineDivider(ThemeProvider theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 12,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [
                Colors.black.withValues(alpha: theme.spineEffectIntensity * 0.15),
                Colors.black.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
        Container(
          width: 1.5,
          color: theme.dividerColor.withValues(alpha: 0.5),
        ),
        Container(
          width: 12,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withValues(alpha: theme.spineEffectIntensity * 0.15),
                Colors.black.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final sessionActive = context.select<SessionProvider, bool>((s) => s.isSpotlightActive);

    if (_isLoading) {
      return _buildLoadingState(theme);
    }

    if (_error != null || _verses == null || _verses!.isEmpty) {
      return _buildErrorState(theme);
    }

    return Stack(
      children: [
        // Wrap quran canvas with spotlight mask
        SessionSpotlightMask(
          isActive: sessionActive,
          child: _buildQuranContent(theme),
        ),

        // Floating session controls overlay
        if (widget.showOverlay)
          SessionOverlay(
            session: widget.session,
            pageNumber: widget.pageNumber,
            onRepTap: widget.onRepTap,
            onDone: widget.onDone,
            onSkip: widget.onSkip,
            onTogglePause: widget.onTogglePause,
            verses: _verses!,
            isFullScreen: _isFullScreen,
            onMinimize: widget.onMinimize,
            onExit: widget.onExit,
          ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeProvider theme) {
    return Container(
      color: theme.canvasBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: theme.accentColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.loadingPage(widget.pageNumber),
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 14,
                color: theme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeProvider theme) {
    return Container(
      color: theme.canvasBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.mutedText),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unable to load page',
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                fontSize: 14,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loadPageVerses,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
