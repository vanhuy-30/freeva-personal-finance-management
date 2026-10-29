import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/presentation/viewmodels/transaction_composer.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';

import '../home/fixtures.dart' show wallet;
import 'c1_stub.dart';

class _Model extends StubTransactionViewModel {
  _Model() {
    wallets = [wallet('vnd', 'VCB'), wallet('usd', 'Đô', currency: 'USD')];
    currencies = const [WalletCurrency('VND', 0), WalletCurrency('USD', 2)];
    categories = const [
      FinanceCategory(
        id: 'food',
        name: 'Ăn uống',
        parentId: null,
        kind: CategoryKind.expense,
      ),
      FinanceCategory(
        id: 'salary',
        name: 'Lương',
        parentId: null,
        kind: CategoryKind.income,
      ),
      FinanceCategory(id: 'misc', name: 'Khác', parentId: null),
    ];
    recentCategories = categories;
  }
  @override
  String? preferredAccountId() => 'vnd';
  @override
  String? preferredCategoryId() => 'food';
  int ids = 0;
  @override
  String newClientId() => 'id-${ids++}';
}

void main() {
  test('keypad types minor units, 000, backspace and a 13-digit cap', () {
    final c = TransactionComposer(_Model());
    c.typeKeys('000');
    expect(c.amount, BigInt.zero);
    c
      ..typeKeys('6')
      ..typeKeys('5')
      ..typeKeys('000');
    expect(c.amount, BigInt.from(65000));
    c.backspace();
    expect(c.amount, BigInt.from(6500));
    for (var i = 0; i < 20; i++) {
      c.typeKeys('9');
    }
    expect(c.amount.toString().length, TransactionComposer.maxDigits);
  });

  test('switching to income drops an expense-only category', () {
    final c = TransactionComposer(_Model());
    expect(c.categoryId, 'food');
    c.setType(TransactionType.income);
    expect(c.categoryId, isNull);
    expect(c.fitting.map((x) => x.id), ['salary', 'misc']);
  });

  test('cross-currency transfer converts exactly with the rate', () {
    final c = TransactionComposer(
      _Model(),
      initialType: TransactionType.transfer,
    );
    c.pickCounter('usd');
    expect(c.cross, isTrue);
    c.typeKeys('2538000');
    expect(c.received, isNull);
    c.setRate('0.00004');
    expect(c.quotedAt, isNotNull);
    // 2.538.000 ₫ × 0.00004 = 101,52 USD.
    expect(c.received, BigInt.from(10152));
    c.swap();
    expect(c.accountId, 'usd');
    expect(c.counterAccountId, 'vnd');
  });

  test('a copy is new, dated today, with fresh client ids', () {
    final original = TransactionBundle(
      legs: [
        tx(
          'old',
          account: 'vnd',
          amount: -65000,
          day: '2026-09-01',
          time: '09:15',
          category: 'food',
          merchant: 'Phở',
        ),
      ],
    );
    final c = TransactionComposer(_Model(), existing: original, copy: true);
    expect(c.isNew, isTrue);
    expect(c.occurredOn, '2026-10-21');
    expect(c.occurredTime, '12:40');
    expect(c.amount, BigInt.from(65000));
    expect(c.merchant, 'Phở');
    expect(c.clientIds.first, isNot('c-old'));
  });

  test('new composer defaults occurredTime to now; edit keeps stored time', () {
    final fresh = TransactionComposer(_Model());
    expect(fresh.occurredTime, '12:40');
    final edit = TransactionComposer(
      _Model(),
      existing: TransactionBundle(
        legs: [
          tx(
            'old',
            account: 'vnd',
            amount: -1000,
            time: '09:15',
            category: 'food',
          ),
        ],
      ),
    );
    expect(edit.occurredTime, '09:15');
    edit.setWhen(date: '2026-10-20', time: null);
    expect(edit.occurredOn, '2026-10-20');
    expect(edit.occurredTime, isNull);
  });

  test('dirty tracks real changes only', () {
    final c = TransactionComposer(_Model());
    expect(c.dirty, isFalse);
    c.typeKeys('1');
    expect(c.dirty, isTrue);
    c.backspace();
    expect(c.dirty, isFalse);
  });
}
