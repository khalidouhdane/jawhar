import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/update_provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/theme/geist_typography.dart';
import 'package:quran_app/widgets/geist_button.dart';

/// Shows a premium update dialog when a new version is available.
class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  /// Call this to show the dialog from anywhere.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<UpdateProvider>(),
        child: const UpdateDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateProvider>(
      builder: (context, provider, _) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 40,
          ),
          child: _buildCard(context, provider),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, UpdateProvider provider) {
    final theme = context.watch<ThemeProvider>();
    final l = AppLocalizations.of(context)!;

    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(theme.radiusXl),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: theme.shadowCardFull,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(context, provider, theme, l),
          _body(context, provider, theme, l),
          _footer(context, provider, theme, l),
        ],
      ),
    );
  }

  Widget _header(
    BuildContext context,
    UpdateProvider provider,
    ThemeProvider theme,
    AppLocalizations l,
  ) {
    String title = l.updateAvailable;
    if (provider.status == UpdateStatus.readyToInstall) {
      title = l.updateReady;
    } else if (provider.status == UpdateStatus.downloading) {
      title = l.updateDownloading;
    } else if (provider.status == UpdateStatus.error) {
      title = l.updateError;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.cardColor, theme.accentLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(theme.radiusXl),
        ),
      ),
      child: Column(
        children: [
          // Custom spinning diamond loader
          _DiamondSpinner(
            progress: provider.downloadProgress,
            status: provider.status,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GeistTypography.primaryFontFamily,
              color: theme.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          if (provider.updateInfo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.pillBackground,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                'v${provider.updateInfo!.version}',
                style: TextStyle(
                  fontFamily: GeistTypography.primaryFontFamily,
                  color: theme.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    UpdateProvider provider,
    ThemeProvider theme,
    AppLocalizations l,
  ) {
    final showReleaseNotes =
        provider.updateInfo != null &&
        provider.updateInfo!.releaseNotes.isNotEmpty &&
        provider.status != UpdateStatus.downloading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showReleaseNotes) ...[
            Text(
              l.updateWhatsNew,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                color: theme.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: theme.accentLight,
                borderRadius: BorderRadius.circular(theme.radiusLg),
                border: Border.all(color: theme.dividerColor),
              ),
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  provider.updateInfo!.releaseNotes,
                  style: TextStyle(
                    fontFamily: GeistTypography.primaryFontFamily,
                    color: theme.secondaryText,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
          // Linear progress bar (only show while downloading)
          if (provider.status == UpdateStatus.downloading) ...[
            const SizedBox(height: 8),
            _downloadProgress(context, provider, theme, l),
          ],
          // Error details
          if (provider.status == UpdateStatus.error &&
              provider.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(theme.radiusMd),
                border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.alertTriangle,
                    color: Colors.red.shade400,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.errorMessage!,
                      style: TextStyle(
                        fontFamily: GeistTypography.primaryFontFamily,
                        color: Colors.red.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _downloadProgress(
    BuildContext context,
    UpdateProvider provider,
    ThemeProvider theme,
    AppLocalizations l,
  ) {
    final pct = (provider.downloadProgress * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.updateDownloading,
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                color: theme.secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontFamily: GeistTypography.primaryFontFamily,
                color: theme.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: provider.downloadProgress,
            minHeight: 6,
            backgroundColor: theme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryText),
          ),
        ),
      ],
    );
  }

  Widget _footer(
    BuildContext context,
    UpdateProvider provider,
    ThemeProvider theme,
    AppLocalizations l,
  ) {
    final isDownloading = provider.status == UpdateStatus.downloading;
    final isReadyToInstall = provider.status == UpdateStatus.readyToInstall;
    final isError = provider.status == UpdateStatus.error;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        children: [
          // Later button (hidden during download)
          if (!isDownloading)
            Expanded(
              child: GeistButton(
                onPressed: () {
                  provider.dismiss();
                  Navigator.of(context).pop();
                },
                label: l.updateLater,
                type: GeistButtonType.secondary,
                size: GeistButtonSize.large,
              ),
            ),
          if (!isDownloading) const SizedBox(width: 12),
          // Update / Install / Retry button
          Expanded(
            flex: isDownloading ? 1 : 2,
            child: GeistButton(
              onPressed: isDownloading
                  ? null
                  : () {
                      if (isError) {
                        provider.checkForUpdate(); // re-check/retry
                      } else {
                        provider.downloadAndInstall();
                      }
                    },
              label: isDownloading
                  ? l.updateDownloading
                  : isError
                  ? (AppLocalizations.of(context)?.retry ?? "Retry")
                  : (isReadyToInstall ? l.updateInstall : l.updateNow),
              type: GeistButtonType.primary,
              size: GeistButtonSize.large,
              isLoading: isDownloading,
            ),
          ),
        ],
      ),
    );
  }
}

/// A custom spinning diamond loader widget.
/// Rotates two concentric diamond outlines in opposite directions.
class _DiamondSpinner extends StatefulWidget {
  final double progress;
  final UpdateStatus status;

  const _DiamondSpinner({required this.progress, required this.status});

  @override
  State<_DiamondSpinner> createState() => _DiamondSpinnerState();
}

class _DiamondSpinnerState extends State<_DiamondSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final pct = (widget.progress * 100).toInt();

    final isDownloading = widget.status == UpdateStatus.downloading;
    final isReadyToInstall = widget.status == UpdateStatus.readyToInstall;
    final isError = widget.status == UpdateStatus.error;

    Widget centerWidget;
    if (isDownloading) {
      centerWidget = Text(
        '$pct%',
        style: TextStyle(
          fontFamily: GeistTypography.primaryFontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: theme.primaryText,
        ),
      );
    } else if (isReadyToInstall) {
      centerWidget = Icon(
        LucideIcons.check,
        color: theme.primaryText,
        size: 24,
      );
    } else if (isError) {
      centerWidget = Icon(
        LucideIcons.alertTriangle,
        color: Colors.red.shade400,
        size: 24,
      );
    } else {
      centerWidget = Icon(
        LucideIcons.download,
        color: theme.primaryText,
        size: 24,
      );
    }

    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer spinning diamond outline (clockwise)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * 3.141592653589793,
                child: Transform.rotate(
                  angle: 0.785398, // 45 degrees to start as a diamond
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.primaryText.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              );
            },
          ),
          // Inner spinning diamond outline (counter-clockwise)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_controller.value * 2 * 3.141592653589793,
                child: Transform.rotate(
                  angle: 0.785398, // 45 degrees to start as a diamond
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isError
                            ? Colors.red.shade400
                            : theme.primaryText,
                        width: 2.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            },
          ),
          // Static center content
          centerWidget,
        ],
      ),
    );
  }
}
