import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Runs before every test in this suite.
///
/// Widget tests render with a placeholder font by default, so any golden would
/// come out as tofu boxes — useless for reviewing Arabic script, which is most
/// of this app's surface. Load the real bundled faces instead, and stop
/// google_fonts from reaching for the network in a sandbox that has no business
/// making HTTP calls mid-test.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  final fontsDir = Directory('assets/fonts');
  if (fontsDir.existsSync()) {
    // Amiri-Regular.ttf -> family "Amiri"; GeistMono-Bold.ttf -> "GeistMono".
    final byFamily = <String, List<File>>{};
    for (final entity in fontsDir.listSync()) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.ttf')) {
        continue;
      }
      final base = entity.uri.pathSegments.last.split('.').first;
      byFamily.putIfAbsent(base.split('-').first, () => []).add(entity);
    }

    for (final entry in byFamily.entries) {
      final loader = FontLoader(entry.key);
      for (final file in entry.value) {
        loader.addFont(
          Future.value(file.readAsBytesSync().buffer.asByteData()),
        );
      }
      await loader.load();
    }
  }

  await testMain();
}
