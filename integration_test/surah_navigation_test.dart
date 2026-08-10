import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/widgets/surah_list_tile.dart';

/// Integration tests run against a real engine (a browser here, a device in
/// CI), so they catch what the widget-test harness cannot: real layout, real
/// hit testing, real gesture arenas.
///
/// These mount screens directly rather than booting main(). The app's entry
/// point calls Firebase.initializeApp, which needs credentials this sandbox
/// deliberately does not carry — see the .env note in the session-start hook.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget harness({required Widget child, Locale locale = const Locale('en')}) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );
  }

  testWidgets('tapping a surah tile fires its callback exactly once', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      harness(
        child: SurahListTile(
          number: 12,
          nameSimple: 'Yusuf',
          nameArabic: 'يوسف',
          versesCount: 111,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SurahListTile));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('the whole tile is tappable, not just the label', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      harness(
        child: SurahListTile(
          number: 1,
          nameSimple: 'Al-Fatihah',
          nameArabic: 'الفاتحة',
          versesCount: 7,
          onTap: () => taps++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // HitTestBehavior.opaque is what makes the padded gutter tappable; a
    // regression there is invisible to a finder-based tap on the text.
    final box = tester.getRect(find.byType(SurahListTile));
    await tester.tapAt(Offset(box.left + 8, box.center.dy));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('renders right-to-left under an Arabic locale', (tester) async {
    await tester.pumpWidget(
      harness(
        locale: const Locale('ar'),
        child: SurahListTile(
          number: 12,
          nameSimple: 'Yusuf',
          nameArabic: 'يوسف',
          versesCount: 111,
          onTap: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(Directionality.of(tester.element(find.byType(SurahListTile))),
        TextDirection.rtl);
  });
}
