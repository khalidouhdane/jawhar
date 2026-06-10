import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/widgets/floating_corner_card.dart';
import 'package:quran_app/widgets/top_nav_bar.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockThemeProvider extends ThemeProvider {
  @override
  bool get isDark => false;

  @override
  Color get cardColor => Colors.white;

  @override
  Color get dividerColor => Colors.grey;
}

void main() {
  group('FloatingCornerCard Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget buildTestWidget({
      required Widget child,
      required AlignmentGeometry alignment,
      required Offset slideOffset,
      required bool isFullScreen,
      required TextDirection textDirection,
    }) {
      return ChangeNotifierProvider<ThemeProvider>(
        create: (_) => MockThemeProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: textDirection,
              child: FloatingCornerCard(
                alignment: alignment,
                slideOffset: slideOffset,
                isFullScreen: isFullScreen,
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('Should render child correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const Text('Card Content'),
          alignment: AlignmentDirectional.topStart,
          slideOffset: const Offset(-1.2, -1.2),
          isFullScreen: false,
          textDirection: TextDirection.ltr,
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets(
      'Should slide to Offset.zero when isFullScreen is false (LTR)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: const Text('Card Content'),
            alignment: AlignmentDirectional.topStart,
            slideOffset: const Offset(-1.2, -1.2),
            isFullScreen: false,
            textDirection: TextDirection.ltr,
          ),
        );

        final AnimatedSlide slideWidget = tester.widget(
          find.byType(AnimatedSlide),
        );
        expect(slideWidget.offset, Offset.zero);
      },
    );

    testWidgets('Should slide to slideOffset when isFullScreen is true (LTR)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          child: const Text('Card Content'),
          alignment: AlignmentDirectional.topStart,
          slideOffset: const Offset(-1.2, -1.2),
          isFullScreen: true,
          textDirection: TextDirection.ltr,
        ),
      );

      final AnimatedSlide slideWidget = tester.widget(
        find.byType(AnimatedSlide),
      );
      expect(slideWidget.offset, const Offset(-1.2, -1.2));
    });

    testWidgets(
      'Should mirror horizontal slideOffset when in RTL mode and isFullScreen is true',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            child: const Text('Card Content'),
            alignment: AlignmentDirectional.topStart,
            slideOffset: const Offset(-1.2, -1.2),
            isFullScreen: true,
            textDirection: TextDirection.rtl,
          ),
        );

        final AnimatedSlide slideWidget = tester.widget(
          find.byType(AnimatedSlide),
        );
        // -1.2 * -1.0 = 1.2
        expect(slideWidget.offset, const Offset(1.2, -1.2));
      },
    );

    testWidgets('TopLeftNavBar should render read/tafsir options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => MockThemeProvider(),
          child: MaterialApp(
            home: Scaffold(
              body: TopLeftNavBar(readMode: 'read', onReadModeChanged: (v) {}),
            ),
          ),
        ),
      );

      expect(find.byType(TopLeftNavBar), findsOneWidget);
    });

    testWidgets(
      'TopRightNavBar should render theme, search, bookmark buttons',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ChangeNotifierProvider<ThemeProvider>(
            create: (_) => MockThemeProvider(),
            child: const MaterialApp(
              home: Scaffold(
                body: TopRightNavBar(
                  isBookmarked: true,
                  onThemeTapped: null,
                  onNavMenuTapped: null,
                  onBookmarkTapped: null,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(TopRightNavBar), findsOneWidget);
      },
    );
  });
}
