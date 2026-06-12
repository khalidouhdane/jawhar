// §5 force-update gate, UI half: the banner is shown if and only if the
// gate is engaged, is NON-dismissable (no close affordance), and the app
// behind it stays mounted and interactive — the offline core loop is never
// blocked by the gate.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/widgets/update_required_banner.dart';

void main() {
  Widget host({required bool updateRequired, Widget? child}) => MaterialApp(
    home: UpdateRequiredOverlay(
      updateRequired: updateRequired,
      child: child ?? const Scaffold(body: Text('app content')),
    ),
  );

  testWidgets('gate off -> no banner, child untouched', (tester) async {
    await tester.pumpWidget(host(updateRequired: false));

    expect(find.text('app content'), findsOneWidget);
    expect(find.text('Update required'), findsNothing);
    expect(find.byIcon(Icons.system_update), findsNothing);
  });

  testWidgets('gate on -> non-dismissable banner over a still-working app',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        updateRequired: true,
        child: Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => taps++,
              child: const Text('offline core loop'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Update required'), findsOneWidget);
    expect(
      find.textContaining('Syncing is paused'),
      findsOneWidget,
      reason: 'explains BLOCK SYNC ONLY semantics',
    );

    // Non-dismissable: no close affordance of any kind.
    expect(find.byType(IconButton), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);

    // The app behind the banner keeps working (§5: never block the
    // offline loop).
    expect(find.text('offline core loop'), findsOneWidget);
    await tester.tap(find.text('offline core loop'));
    expect(taps, 1);
  });

  testWidgets('banner is laid out, NOT overlaid: AppBar controls at the top '
      'of the route stay visible and tappable', (tester) async {
    // Regression: a Positioned(top:0) overlay covered the top ~70px of
    // every route — exactly where AppBars put back/menu buttons. On
    // Windows desktop there is no system back gesture, so an occluded
    // AppBar back button makes screens hard to leave.
    var backTaps = 0;
    await tester.pumpWidget(
      host(
        updateRequired: true,
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => backTaps++,
            ),
            title: const Text('screen title'),
          ),
          body: const Text('app content'),
        ),
      ),
    );

    // Content is shifted DOWN below the banner, not covered by it.
    final bannerBottom =
        tester.getBottomLeft(find.textContaining('Syncing is paused')).dy;
    final appBarTop = tester.getTopLeft(find.byType(AppBar)).dy;
    expect(appBarTop, greaterThanOrEqualTo(bannerBottom),
        reason: 'the AppBar must sit fully below the banner');

    await tester.tap(find.byIcon(Icons.arrow_back));
    expect(backTaps, 1, reason: 'the back button must not be tap-absorbed');
  });

  testWidgets('flipping the flag shows/hides the banner', (tester) async {
    await tester.pumpWidget(host(updateRequired: false));
    expect(find.text('Update required'), findsNothing);

    await tester.pumpWidget(host(updateRequired: true));
    expect(find.text('Update required'), findsOneWidget);

    await tester.pumpWidget(host(updateRequired: false));
    expect(find.text('Update required'), findsNothing);
  });
}
