import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/models/quran_models.dart';
import 'package:quran_app/providers/quran_reading_provider.dart';
import 'package:quran_app/providers/session_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/widgets/reading_canvas.dart';
import 'package:quran_app/widgets/hifz/session_overlay.dart';

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

  /// Optional callback to toggle pause.
  final VoidCallback? onTogglePause;

  const SessionReadingView({
    super.key,
    required this.pageNumber,
    required this.showOverlay,
    required this.session,
    required this.onRepTap,
    required this.onDone,
    this.onSkip,
    this.onTogglePause,
  });

  @override
  State<SessionReadingView> createState() => _SessionReadingViewState();
}

class _SessionReadingViewState extends State<SessionReadingView> {
  /// Verses for the assigned page, loaded once on init.
  List<Verse>? _verses;
  bool _isLoading = true;
  String? _error;
  bool _isFullScreen = false;

  /// Currently selected verse ID for the contextual menu.
  int? _selectedVerseId;

  @override
  void initState() {
    super.initState();
    _loadPageVerses();
  }

  @override
  void didUpdateWidget(SessionReadingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _loadPageVerses();
    }
  }

  Future<void> _loadPageVerses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final readingProvider = context.read<QuranReadingProvider>();
      final verses = await readingProvider.getPageVerses(widget.pageNumber);
      if (mounted) {
        setState(() {
          _verses = verses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load page ${widget.pageNumber}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    if (_isLoading) {
      return _buildLoadingState(theme);
    }

    if (_error != null || _verses == null || _verses!.isEmpty) {
      return _buildErrorState(theme);
    }

    return Stack(
      children: [
        // The Quran page — scoped to a single page, no PageView/swiping
        ReadingCanvas(
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
              'Loading page ${widget.pageNumber}…',
              style: TextStyle(
                fontFamily: 'Inter',
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
                fontFamily: 'Inter',
                fontSize: 14,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _loadPageVerses,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: 'Inter',
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
