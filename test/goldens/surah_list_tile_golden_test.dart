import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/providers/theme_provider.dart';
import 'package:quran_app/widgets/surah_list_tile.dart';

/// Renders a widget at a fixed size so the golden is stable across machines.
Widget _harness({required Widget child, required Locale locale}) {
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
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: SizedBox(width: 420, child: child)),
      ),
    ),
  );
}

void main() {
  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('SurahListTile renders in ${locale.languageCode}', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          locale: locale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SurahListTile(
                number: 12,
                nameSimple: 'Yusuf',
                nameArabic: 'يوسف',
                versesCount: 111,
                onTap: () {},
              ),
              SurahListTile(
                number: 1,
                nameSimple: 'Al-Fatihah',
                nameArabic: 'الفاتحة',
                versesCount: 7,
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(Column).first,
        matchesGoldenFile('surah_list_tile_${locale.languageCode}.png'),
      );
    });
  }
}
