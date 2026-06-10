import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/models/hifz_models.dart';
import 'package:quran_app/utils/persisted_data_parser.dart';

void main() {
  test('enum values fall back when persisted index is out of bounds', () {
    expect(
      PersistedDataParser.enumValue(
        PageStatus.values,
        999,
        fallback: PageStatus.notStarted,
      ),
      PageStatus.notStarted,
    );
  });

  test('integer lists discard malformed and out-of-range values', () {
    expect(
      PersistedDataParser.intList(
        '1,nope,0,604,605,1',
        minimum: 1,
        maximum: 604,
      ),
      [1, 604],
    );
  });

  test('required persisted dates reject malformed input', () {
    expect(
      () => PersistedDataParser.requiredDate('not-a-date', field: 'test.date'),
      throwsFormatException,
    );
  });
}
