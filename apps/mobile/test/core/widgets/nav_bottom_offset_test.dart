import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/tokens.g.dart';
import 'package:mobile/core/widgets/freeva_bottom_nav.dart';

void main() {
  test(
    'MOB-P6-001: gesture devices keep the board 28 from the screen edge',
    () {
      for (final inset in [0.0, 20, 24, 34]) {
        expect(navBottomOffset(inset.toDouble()), FreevaLayout.navOffsetBottom);
      }
    },
  );

  test('a system button bar stays fully visible under the nav', () {
    expect(navBottomOffset(48), 48 + FreevaSpace.s2);
  });
}
