import 'package:hifz_core/hifz_core.dart';
import 'package:test/test.dart';

void main() {
  test('generates unique RFC 4122 version 4 identifiers', () {
    final ids = List.generate(1000, (_) => IdGenerator.uuidV4()).toSet();
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-'
      r'[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    expect(ids, hasLength(1000));
    expect(ids.every(uuidV4.hasMatch), isTrue);
  });
}
