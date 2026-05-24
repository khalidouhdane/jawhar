import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/utils/tablet_layout_math.dart';

void main() {
  group('TabletLayoutMath tests', () {
    test('pageToSpread maps correctly', () {
      expect(TabletLayoutMath.pageToSpread(1), 1);
      expect(TabletLayoutMath.pageToSpread(2), 1);
      expect(TabletLayoutMath.pageToSpread(3), 2);
      expect(TabletLayoutMath.pageToSpread(4), 2);
      expect(TabletLayoutMath.pageToSpread(603), 302);
      expect(TabletLayoutMath.pageToSpread(604), 302);
    });

    test('pageToSpread handles out of bound inputs gracefully', () {
      expect(TabletLayoutMath.pageToSpread(0), 1);
      expect(TabletLayoutMath.pageToSpread(-5), 1);
      expect(TabletLayoutMath.pageToSpread(605), 302);
      expect(TabletLayoutMath.pageToSpread(1000), 302);
    });

    test('spreadToRightPage maps correctly', () {
      expect(TabletLayoutMath.spreadToRightPage(1), 1);
      expect(TabletLayoutMath.spreadToRightPage(2), 3);
      expect(TabletLayoutMath.spreadToRightPage(302), 603);
    });

    test('spreadToLeftPage maps correctly', () {
      expect(TabletLayoutMath.spreadToLeftPage(1), 2);
      expect(TabletLayoutMath.spreadToLeftPage(2), 4);
      expect(TabletLayoutMath.spreadToLeftPage(302), 604);
    });
  });
}
