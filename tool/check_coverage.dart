import 'dart:io';

void main(List<String> arguments) {
  if (arguments.isEmpty || arguments.length > 2) {
    stderr.writeln(
      'Usage: dart run tool/check_coverage.dart <lcov-file> [minimum-percent]',
    );
    exitCode = 64;
    return;
  }

  final coverageFile = File(arguments.first);
  final minimumPercent = arguments.length == 2
      ? double.tryParse(arguments[1])
      : 5.0;

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
  for (final line in coverageFile.readAsLinesSync()) {
    if (line.startsWith('LF:')) {
      foundLines += int.parse(line.substring(3));
    } else if (line.startsWith('LH:')) {
      hitLines += int.parse(line.substring(3));
    }
  }

  if (foundLines == 0) {
    stderr.writeln('Coverage file contains no executable lines.');
    exitCode = 65;
    return;
  }

  final percent = hitLines * 100 / foundLines;
  stdout.writeln(
    'Line coverage: ${percent.toStringAsFixed(2)}% '
    '($hitLines/$foundLines), required: '
    '${minimumPercent.toStringAsFixed(2)}%',
  );

  if (percent < minimumPercent) {
    stderr.writeln('Coverage is below the required threshold.');
    exitCode = 1;
  }
}
