import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/update_provider.dart';

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
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: _buildCard(context, provider),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, UpdateProvider provider) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2A2F) : Colors.white;
    final cardBorder = isDark
        ? Border.all(color: Colors.white.withValues(alpha: 0.08))
        : Border.all(color: Colors.black.withValues(alpha: 0.06));

    return Container(
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: cardBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(context, provider, isDark, l),
          _body(context, provider, isDark, l),
          _footer(context, provider, isDark, l),
        ],
      ),
    );
  }

  Widget _header(
      BuildContext context, UpdateProvider provider, bool isDark, AppLocalizations l) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A454E), const Color(0xFF0F2B30)]
              : [const Color(0xFF1A454E), const Color(0xFF2D6A5F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.system_update_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.t('update_available'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          if (provider.updateInfo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'v${provider.updateInfo!.version}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _body(
      BuildContext context, UpdateProvider provider, bool isDark, AppLocalizations l) {
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final subtitleColor = isDark ? Colors.white38 : Colors.black45;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (provider.updateInfo != null &&
              provider.updateInfo!.releaseNotes.isNotEmpty) ...[
            Text(
              l.t('update_whats_new'),
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 140),
              child: SingleChildScrollView(
                child: Text(
                  provider.updateInfo!.releaseNotes,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
          // Download progress
          if (provider.status == UpdateStatus.downloading) ...[
            const SizedBox(height: 16),
            _downloadProgress(context, provider, isDark, l),
          ],
          // Error
          if (provider.status == UpdateStatus.error) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade300, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.t('update_error'),
                      style: TextStyle(
                        color: Colors.red.shade300,
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
      BuildContext context, UpdateProvider provider, bool isDark, AppLocalizations l) {
    final pct = (provider.downloadProgress * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.t('update_downloading'),
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: provider.downloadProgress,
            minHeight: 8,
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A454E)),
          ),
        ),
      ],
    );
  }

  Widget _footer(
      BuildContext context, UpdateProvider provider, bool isDark, AppLocalizations l) {
    final isDownloading = provider.status == UpdateStatus.downloading;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        children: [
          // Later button
          Expanded(
            child: TextButton(
              onPressed: isDownloading
                  ? null
                  : () {
                      provider.dismiss();
                      Navigator.of(context).pop();
                    },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Text(
                l.t('update_later'),
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Update Now button
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isDownloading
                  ? null
                  : () => provider.downloadAndInstall(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A454E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                isDownloading
                    ? l.t('update_downloading')
                    : l.t('update_now'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
