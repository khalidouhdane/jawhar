import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/services/sync_worker.dart';

/// §5 force-update gate, UI half: wraps the whole app (mounted in
/// `MaterialApp.builder`, so it overlays every route) and pins a
/// NON-DISMISSABLE banner to the top while the running build is below the
/// server's `minSupportedBuild`.
///
/// Deliberately a banner and not a blocking screen: the §5 rule is BLOCK
/// SYNC ONLY — the offline core loop must keep working, so the app behind
/// the banner stays fully interactive. Sync (outbox drain + legacy pushes)
/// is paused by [SyncWorker]/CloudSyncService, not by this widget; the
/// banner is just the explanation. There is no close affordance on purpose.
class UpdateRequiredGate extends StatelessWidget {
  final Widget? child;

  const UpdateRequiredGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final updateRequired = context.select<SyncWorker, bool>(
      (worker) => worker.updateRequired,
    );
    return UpdateRequiredOverlay(
      updateRequired: updateRequired,
      child: child,
    );
  }
}

/// Pure presentation half of [UpdateRequiredGate] (testable without a
/// [SyncWorker]): shows [child] as-is when [updateRequired] is false,
/// lays the banner out ABOVE the app when true.
///
/// Laid out, not overlaid: a `Positioned(top: 0)` strip in a Stack covers
/// the top ~70px of every route — exactly where AppBars put back/menu
/// buttons — and on platforms with no system back gesture (Windows
/// desktop) screens whose only exit is the AppBar back button become hard
/// to leave. A Column with the content in an [Expanded] shifts every route
/// down instead, so nothing is occluded and the app stays fully
/// interactive. The banner absorbs the top safe-area inset itself, so the
/// content's MediaQuery top padding is removed (otherwise every Scaffold
/// would re-apply the status-bar inset below the banner).
class UpdateRequiredOverlay extends StatelessWidget {
  final bool updateRequired;
  final Widget? child;

  const UpdateRequiredOverlay({
    super.key,
    required this.updateRequired,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    if (!updateRequired) return content;

    final isArabic = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';
    final title = isArabic ? 'يلزم تحديث التطبيق' : 'Update required';
    final message = isArabic
        ? 'توقفت المزامنة حتى تُحدِّث التطبيق. بياناتك آمنة ويواصل '
              'التطبيق العمل دون اتصال.'
        : 'Syncing is paused until you update the app. Your data is safe '
              'and the app keeps working offline.';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        children: [
          Material(
            color: const Color(0xFFB45309), // amber-700: warning, not error
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.system_update,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            // The banner's SafeArea consumed the status-bar inset; without
            // this removal every Scaffold below would pad for it again.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}
