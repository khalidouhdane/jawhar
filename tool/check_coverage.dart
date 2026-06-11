import 'dart:io';

/// Enforces a minimum line-coverage percentage over an lcov file.
///
/// Per-package gates (roadmap §10) point this at each package's own lcov
/// output with its own floor, e.g.:
///
///   dart run tool/check_coverage.dart coverage/lcov.info 5
///   dart run tool/check_coverage.dart packages/hifz_core/coverage/lcov.info 80
///
/// The optional third argument restricts the gate to source files whose
/// (normalized, `/`-separated) path contains the given prefix — useful when
/// one combined lcov holds records for several workspace packages:
///
///   dart run tool/check_coverage.dart coverage/lcov.info 80 packages/hifz_core/lib
void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.length > 3) {
    stderr.writeln(
      'Usage: dart run tool/check_coverage.dart '
      '<lcov-file> [minimum-percent] [source-path-filter]',
    );
    exitCode = 64;
    return;
  }

  final coverageFile = File(arguments.first);
  final minimumPercent = arguments.length >= 2
      ? double.tryParse(arguments[1])
      : 5.0;
  final sourceFilter = arguments.length == 3
      ? arguments[2].replaceAll('\\', '/')
      : null;

  if (!coverageFile.existsSync()) {
    stderr.writeln('Coverage file not found: ${coverageFile.path}');
    exitCode = 66;
    return;
  }
  if (minimumPercent == null || minimumPercent < 0 || minimumPercent > 100) {
    stderr.writeln('Minimum coverage must be between 0 and 100.');
    exitCode = 64;
    return;
  }

  var foundLines = 0;
  var hitLines = 0;
  // Whether the current lcov record (SF: ... end_of_record) passes the
  // source filter. With no filter every record counts.
  var includeRecord = sourceFilter == null;
  for (final line in coverageFile.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      includeRecord =
          sourceFilter == null ||
          line.substring(3).replaceAll('\\', '/').contains(sourceFilter);
    } else if (!includeRecord) {
      continue;
    } else if (line.startsWith('LF:')) {
      foundLines += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hitLines += int.parse(line.substring(3));
    }
  }

  if (foundLines == 0) {
    stderr.writeln(
      sourceFilter == null
          ? 'Coverage file contains no executable lines.'
          : 'Coverage file contains no executable lines matching '
                '"$sourceFilter".',
    );
    exitCode = 65;
    return;
  }

  final percent = hitLines * 100 / foundLines;
  stdout.writeln(
    'Line coverage${sourceFilter == null ? '' : ' (under $sourceFilter)'}: '
    '${percent.toStringAsFixed(2)}% '
    '($hitLines/$foundLines), required: '
    '${minimumPercent.toStringAsFixed(2)}%',
  );

  if (percent < minimumPercent) {
    stderr.writeln('Coverage is below the required threshold.');
    exitCode = 1;
  }
}
