import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/home/domain/first_run_checklist.dart';

import 'fixtures.dart';

void main() {
  FirstRunChecklist of({
    bool wallets = true,
    bool rows = true,
    int pending = 0,
    bool hasPin = true,
  }) => FirstRunChecklist.of(
    overview(wallets: wallets ? null : [], rows: rows ? null : []),
    pending: pending,
    hasPin: hasPin,
  );

  test('a set-up account with a PIN shows nothing', () {
    expect(of().visible, isFalse);
  });

  test('nothing yet: both lines open, PIN line counts only without a PIN', () {
    final withPin = of(wallets: false, rows: false);
    expect(withPin.visible, isTrue);
    expect((withPin.done, withPin.total), (0, 2));
    final withoutPin = of(wallets: false, rows: false, hasPin: false);
    expect((withoutPin.done, withoutPin.total), (0, 3));
    expect(withoutPin.showPin, isTrue);
  });

  test('a queued expense counts as the first expense', () {
    final list = of(rows: false, pending: 1);
    expect(list.expenseDone, isTrue);
    expect(list.visible, isFalse);
  });

  test(
    'without a PIN the card still leaves once wallet and expense are done',
    () {
      expect(of(hasPin: false).visible, isFalse);
      expect(of(wallets: false, hasPin: false).visible, isTrue);
    },
  );
}
