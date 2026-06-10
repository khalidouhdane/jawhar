import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/widgets/hifz/session_spotlight_mask.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockThemeProvider extends ThemeProvider {
  @override
  bool get isDark => false;

  @override
  Color get scaffoldBackground => Colors.white;
}

void main() {
  group('SessionSpotlightMask Widget Tests', () {
    late Widget testWidget;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      testWidget = ChangeNotifierProvider<ThemeProvider>(
        create: (_) => MockThemeProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: SessionSpotlightMask(
              isActive: true,
              child: const SizedBox.expand(child: Text('Quran Text')),
            ),
          ),
        ),
      );
    });

    testWidgets('Should render child and mask when active', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testWidget);

      expect(find.text('Quran Text'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is MaskPainter,
        ),
        findsOneWidget,
      );
    });

    testWidgets('Should only render child when inactive', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => MockThemeProvider(),
          child: const MaterialApp(
            home: Scaffold(
              body: SessionSpotlightMask(
                isActive: false,
                child: SizedBox.expand(child: Text('Quran Text')),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Quran Text'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is MaskPainter,
        ),
        findsNothing,
      );
    });

    testWidgets(
      'Should handle touch gesture, update painter offset, and clear on release',
      (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);

        // 1. Initial touch down
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.touch,
        );
        await gesture.down(const Offset(100, 100));
        await tester.pump(); // Starts grow animation

        CustomPaint customPaint = tester.widget<CustomPaint>(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is MaskPainter,
          ),
        );
        MaskPainter painter = customPaint.painter as MaskPainter;

        expect(painter.pointerOffset, const Offset(100, 100));
        expect(painter.pressure, 0.5); // Default fallback for touch size 0.0

        // 2. Let grow animation complete (150ms duration)
        await tester.pump(const Duration(milliseconds: 150));

        customPaint = tester.widget<CustomPaint>(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is MaskPainter,
          ),
        );
        painter = customPaint.painter as MaskPainter;
        expect(painter.revealFactor, closeTo(1.0, 0.01));

        // 3. Drag/Move gesture
        await gesture.moveTo(const Offset(150, 200));
        await tester.pump();

        customPaint = tester.widget<CustomPaint>(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is MaskPainter,
          ),
        );
        painter = customPaint.painter as MaskPainter;
        expect(painter.pointerOffset, const Offset(150, 200));

        // 4. Release gesture (Starts reverse animation)
        await gesture.up();
        await tester.pump();

        // Mid-way through fade-out animation (e.g. 175ms of 350ms reverse duration)
        await tester.pump(const Duration(milliseconds: 175));
        customPaint = tester.widget<CustomPaint>(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is MaskPainter,
          ),
        );
        painter = customPaint.painter as MaskPainter;
        expect(
          painter.pointerOffset,
          const Offset(150, 200),
        ); // Still preserved during fade-out
        expect(painter.revealFactor, lessThan(1.0));
        expect(painter.revealFactor, greaterThan(0.0));

        // Let animation dismiss fully
        await tester.pump(const Duration(milliseconds: 200));
        await tester
            .pump(); // Process the setState from AnimationStatus.dismissed
        customPaint = tester.widget<CustomPaint>(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is MaskPainter,
          ),
        );
        painter = customPaint.painter as MaskPainter;
        expect(painter.pointerOffset, isNull); // Reset to null after dismissal
      },
    );

    testWidgets('Should handle stylus pressure and clamp it correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testWidget);

      // Send a stylus event with high pressure (0.8)
      await tester.sendEventToBinding(
        const PointerDownEvent(
          pointer: 1,
          kind: PointerDeviceKind.stylus,
          position: Offset(100, 100),
          pressure: 0.8,
        ),
      );
      await tester.pump();

      CustomPaint customPaint = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is MaskPainter,
        ),
      );
      MaskPainter painter = customPaint.painter as MaskPainter;
      expect(painter.pressure, 0.8);

      // Send a stylus event exceeding upper limit (1.2)
      await tester.sendEventToBinding(
        const PointerMoveEvent(
          pointer: 1,
          kind: PointerDeviceKind.stylus,
          position: Offset(120, 120),
          pressure: 1.2,
        ),
      );
      await tester.pump();

      customPaint = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is MaskPainter,
        ),
      );
      painter = customPaint.painter as MaskPainter;
      expect(painter.pressure, 1.0); // Clamped to 1.0

      // Send a stylus event below lower limit (0.05)
      await tester.sendEventToBinding(
        const PointerMoveEvent(
          pointer: 1,
          kind: PointerDeviceKind.stylus,
          position: Offset(130, 130),
          pressure: 0.05,
        ),
      );
      await tester.pump();

      customPaint = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is MaskPainter,
        ),
      );
      painter = customPaint.painter as MaskPainter;
      expect(painter.pressure, 0.1); // Clamped to 0.1
    });

    testWidgets(
      'Should scale pressure based on touch contact size when available',
      (WidgetTester tester) async {
        await tester.pumpWidget(testWidget);

        await tester.sendEventToBinding(
          const PointerDownEvent(
            pointer: 2,
            kind: PointerDeviceKind.touch,
            position: Offset(100, 100),
            size: 0.3,
          ),
        );
        await tester.pump();

        CustomPaint customPaint = tester.widget<CustomPaint>(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is MaskPainter,
          ),
        );
        MaskPainter painter = customPaint.painter as MaskPainter;
        expect(painter.pressure, 0.3); // Scales to size
      },
    );

    testWidgets('Should fall back to 0.5 when mouse reports binary pressure', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(testWidget);

      await tester.sendEventToBinding(
        const PointerDownEvent(
          pointer: 3,
          kind: PointerDeviceKind.mouse,
          position: Offset(100, 100),
          pressure: 1.0,
        ),
      );
      await tester.pump();

      CustomPaint customPaint = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is MaskPainter,
        ),
      );
      MaskPainter painter = customPaint.painter as MaskPainter;
      expect(painter.pressure, 0.5); // Default fallback applied
    });

    testWidgets(
      'Should respect and apply custom Spotlight settings from ThemeProvider',
      (WidgetTester tester) async {
        final customTheme = MockThemeProvider();
        customTheme.setSpotlightMinRadius(30.0);
        customTheme.setSpotlightMidRadius(150.0);
        customTheme.setSpotlightMaskOpacity(0.85);
        customTheme.setSpotlightFeathering(0.4);
        customTheme.setSpotlightCurveType(SpotlightCurveType.dualZone);

        await tester.pumpWidget(
          ChangeNotifierProvider<ThemeProvider>.value(
            value: customTheme,
            child: MaterialApp(
              home: Scaffold(
                body: SessionSpotlightMask(
                  isActive: true,
                  child: const SizedBox.expand(child: Text('Quran Text')),
                ),
              ),
            ),
          ),
        );

        // Send touch event
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.touch,
        );
        await gesture.down(const Offset(100, 100));
        await tester.pump(); // Starts animation

        final CustomPaint customPaint = tester.widget<CustomPaint>(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is MaskPainter,
          ),
        );
        final MaskPainter painter = customPaint.painter as MaskPainter;

        expect(painter.minRadius, 30.0);
        expect(painter.midRadius, 150.0);
        expect(painter.maskOpacity, 0.85);
        expect(painter.feathering, 0.4);
        expect(painter.curveType, SpotlightCurveType.dualZone);

        await gesture.up();
        await tester.pump();
      },
    );

    testWidgets('Should detect quick tap gestures and trigger onTap callback', (
      WidgetTester tester,
    ) async {
      int tapCount = 0;
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => MockThemeProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: SessionSpotlightMask(
                isActive: true,
                onTap: () => tapCount++,
                child: const SizedBox.expand(child: Text('Quran Text')),
              ),
            ),
          ),
        ),
      );

      // 1. Perform a quick tap (touch down and immediate up, duration 50ms, distance 0px)
      await tester.sendEventToBinding(
        const PointerDownEvent(
          pointer: 10,
          kind: PointerDeviceKind.touch,
          position: Offset(100, 100),
          timeStamp: Duration.zero,
        ),
      );
      await tester.pump();
      await tester.sendEventToBinding(
        const PointerUpEvent(
          pointer: 10,
          kind: PointerDeviceKind.touch,
          position: Offset(100, 100),
          timeStamp: Duration(milliseconds: 50),
        ),
      );
      await tester.pump();

      expect(tapCount, 1);

      // 2. Perform a long touch reveal (holds for 500ms)
      await tester.sendEventToBinding(
        const PointerDownEvent(
          pointer: 11,
          kind: PointerDeviceKind.touch,
          position: Offset(100, 100),
          timeStamp: Duration.zero,
        ),
      );
      await tester.pump();
      await tester.sendEventToBinding(
        const PointerUpEvent(
          pointer: 11,
          kind: PointerDeviceKind.touch,
          position: Offset(100, 100),
          timeStamp: Duration(milliseconds: 500),
        ),
      );
      await tester.pump();

      // Tap count should still be 1 (not incremented because the duration exceeded the tap threshold)
      expect(tapCount, 1);

      // 2b. Perform a medium tap (holds for 350ms, moves 18px)
      await tester.sendEventToBinding(
        const PointerDownEvent(
          pointer: 15,
          kind: PointerDeviceKind.touch,
          position: Offset(100, 100),
          timeStamp: Duration.zero,
        ),
      );
      await tester.pump();
      await tester.sendEventToBinding(
        const PointerMoveEvent(
          pointer: 15,
          kind: PointerDeviceKind.touch,
          position: Offset(118, 100),
          timeStamp: Duration(milliseconds: 150),
        ),
      );
      await tester.pump();
      await tester.sendEventToBinding(
        const PointerUpEvent(
          pointer: 15,
          kind: PointerDeviceKind.touch,
          position: Offset(118, 100),
          timeStamp: Duration(milliseconds: 350),
        ),
      );
      await tester.pump();

      // Tap count should now be 2 because 350ms < 500ms and 18px < 25px
      expect(tapCount, 2);

      // 3. Perform a drag gesture (moves 50px, duration 50ms)
      await tester.sendEventToBinding(
        const PointerDownEvent(
          pointer: 12,
          kind: PointerDeviceKind.touch,
          position: Offset(100, 100),
          timeStamp: Duration.zero,
        ),
      );
      await tester.pump();
      await tester.sendEventToBinding(
        const PointerMoveEvent(
          pointer: 12,
          kind: PointerDeviceKind.touch,
          position: Offset(150, 100),
          timeStamp: Duration(milliseconds: 25),
        ),
      );
      await tester.pump();
      await tester.sendEventToBinding(
        const PointerUpEvent(
          pointer: 12,
          kind: PointerDeviceKind.touch,
          position: Offset(150, 100),
          timeStamp: Duration(milliseconds: 50),
        ),
      );
      await tester.pump();

      // Tap count should still be 2 (not incremented because the distance exceeded the tap threshold)
      expect(tapCount, 2);
    });
  });
}
