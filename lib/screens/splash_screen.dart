import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/screens/app_shell.dart';
import 'package:quran_app/screens/showcase_screen.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/services/local_storage_service.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/utils/app_logger.dart';
import 'package:quran_app/l10n/app_localizations.dart';

// ─── Sprite sheet config (must match the generated sheet) ───
const _kCols = 10;
const _kRows = 19;
const _kTotalFrames = 184;

/// Cinematic splash screen — center-origin diamond scale-up.
///
/// The diamond materializes small at dead center and smoothly scales up,
/// inspired by the EssenceFlowHero GSAP entrance animation.
/// Then text fades in below. All one continuous, fluid sequence.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Sprite sheet state ──
  ui.Image? _spriteSheet;
  bool _loaded = false;

  // ── Master timeline (0.0 → 1.0 over the entire duration) ──
  late final AnimationController _timeline;

  // ── Diamond entrance: scale from center ──
  late final Animation<double> _diamondScale;
  late final Animation<double> _diamondOpacity;

  // ── Text reveal ──
  late final Animation<double> _wordmarkOpacity;
  late final Animation<Offset> _wordmarkSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;

  // ── Ambient glow ──
  late final Animation<double> _glowOpacity;
  late final Animation<double> _glowScale;

  // ── Final fade-out to next screen ──
  late final AnimationController _fadeOutController;
  late final Animation<double> _fadeOut;

  // ── Rotation controller (separate, continuous) ──
  late final AnimationController _rotationController;

  bool _isFirstLaunch = true;

  @override
  void initState() {
    super.initState();

    final storage = context.read<LocalStorageService>();
    _isFirstLaunch = !storage.hasCompletedOnboarding;

    final totalDuration = _isFirstLaunch ? 3200 : 2000;

    // ── Master timeline ──
    _timeline = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDuration),
    );

    // Diamond starts at scale 0 at center, scales up to 1.0, then settles to 0.7
    _diamondScale = TweenSequence<double>([
      // Phase 1 (0%–10%): Appear — tiny dot materializes
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 0.15,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      // Phase 2 (10%–50%): Expand — smooth scale-up from center
      TweenSequenceItem(
        tween: Tween(
          begin: 0.15,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      // Phase 3 (50%–65%): Settle — slight overshoot bounce-back
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 0.7,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      // Phase 4 (65%–100%): Hold at final size
      TweenSequenceItem(tween: ConstantTween(0.7), weight: 35),
    ]).animate(_timeline);

    // Diamond fades in quickly at the start
    _diamondOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 8,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 92),
    ]).animate(_timeline);

    // Glow grows with the diamond, slightly delayed
    _glowOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 15),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 0.5,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.5,
          end: 0.3,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(0.3), weight: 35),
    ]).animate(_timeline);

    _glowScale = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.3), weight: 10),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.3,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
    ]).animate(_timeline);

    // ── Text appears after diamond settles (65%–85%) ──
    _wordmarkOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 63),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 22),
    ]).animate(_timeline);

    _wordmarkSlide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: ConstantTween(const Offset(0.0, 0.5)),
        weight: 63,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(0.0, 0.5),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 22),
    ]).animate(_timeline);

    _taglineOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 72),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 16),
    ]).animate(_timeline);

    _taglineSlide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: ConstantTween(const Offset(0.0, 0.5)),
        weight: 72,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: const Offset(0.0, 0.5),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 16),
    ]).animate(_timeline);

    // ── Fade-out controller ──
    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeOut = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeIn),
    );

    // ── Rotation controller (continuous, ~8s per revolution) ──
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7667), // 184 frames @ 24fps
    )..repeat(); // loops forever

    // Load sprite sheet, then start timeline
    _loadSpriteSheet();
  }

  Future<void> _loadSpriteSheet() async {
    try {
      final data = await DefaultAssetBundle.of(
        context,
      ).load('assets/images/diamond_spritesheet.webp');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _spriteSheet = frame.image;
          _loaded = true;
        });
        _runSequence();
      }
    } catch (e) {
      // Fallback: skip animation and go straight to next screen
      AppLogger.info('Splash', '[SPLASH] Failed to load sprite sheet: $e');
      if (mounted) _navigateToNext();
    }
  }

  Future<void> _runSequence() async {
    // Small delay for screen to settle
    await Future.delayed(const Duration(milliseconds: 150));

    // Play the full timeline
    await _timeline.forward();

    // Brief hold at the end
    await Future.delayed(Duration(milliseconds: _isFirstLaunch ? 500 : 200));

    // Fade out and navigate
    await _fadeOutController.forward();

    if (mounted) _navigateToNext();
  }

  void _navigateToNext() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          if (_isFirstLaunch) {
            return const ShowcaseScreen();
          }
          return const AppShell();
        },
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  void dispose() {
    _timeline.dispose();
    _fadeOutController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  /// Get the current frame index from the rotation controller.
  int _currentFrame() {
    return (_rotationController.value * (_kTotalFrames - 1)).round();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final screenSize = MediaQuery.of(context).size;
    final diamondBaseSize = screenSize.width * 0.35;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _timeline,
          _fadeOutController,
          _rotationController,
        ]),
        builder: (context, _) {
          if (!_loaded) {
            // Blank screen while loading
            return const SizedBox.expand();
          }

          final frame = _currentFrame();
          final scale = _diamondScale.value;
          final diamondSize = diamondBaseSize * scale;
          final glowSize = diamondBaseSize * 2.5 * _glowScale.value;

          return Opacity(
            opacity: _fadeOut.value,
            child: SizedBox.expand(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // ── Ambient glow (grows with diamond) ──
                  Opacity(
                    opacity: _glowOpacity.value,
                    child: Container(
                      width: glowSize,
                      height: glowSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            (theme.isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.06),
                            (theme.isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Diamond + Text (centered column) ──
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Rotating Diamond ──
                      Opacity(
                        opacity: _diamondOpacity.value,
                        child: SizedBox(
                          width: diamondSize,
                          height: diamondSize,
                          child: CustomPaint(
                            painter: _SpriteFramePainter(
                              spriteSheet: _spriteSheet!,
                              frame: frame,
                              cols: _kCols,
                              rows: _kRows,
                              totalFrames: _kTotalFrames,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Wordmark: "jawhar" ──
                      SlideTransition(
                        position: _wordmarkSlide,
                        child: Opacity(
                          opacity: _wordmarkOpacity.value,
                          child: Text(
                            l10n.appName,
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: theme.primaryText,
                              letterSpacing: -1.5,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Tagline: "Memorize with Meaning" ──
                      SlideTransition(
                        position: _taglineSlide,
                        child: Opacity(
                          opacity: _taglineOpacity.value,
                          child: Text(
                            l10n.appTagline,
                            style: TextStyle(
                              fontFamily: GeistTypography.primaryFontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: theme.secondaryText,
                              letterSpacing: 0.5,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// CustomPainter that draws one frame from the sprite sheet.
class _SpriteFramePainter extends CustomPainter {
  final ui.Image spriteSheet;
  final int frame;
  final int cols;
  final int rows;
  final int totalFrames;

  _SpriteFramePainter({
    required this.spriteSheet,
    required this.frame,
    required this.cols,
    required this.rows,
    required this.totalFrames,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clampedFrame = frame.clamp(0, totalFrames - 1);
    final frameW = spriteSheet.width / cols;
    final frameH = spriteSheet.height / rows;
    final col = clampedFrame % cols;
    final row = clampedFrame ~/ cols;

    final src = Rect.fromLTWH(col * frameW, row * frameH, frameW, frameH);
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(
      spriteSheet,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(_SpriteFramePainter oldDelegate) {
    return oldDelegate.frame != frame;
  }
}
