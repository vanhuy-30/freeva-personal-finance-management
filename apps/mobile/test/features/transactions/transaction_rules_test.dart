import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/time/calendar_date.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/domain/transaction_money.dart';
import 'package:mobile/features/transactions/domain/transaction_rules.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('calendar date follows the profile zone across UTC midnight', () {
    expect(
      calendarDate(DateTime.utc(2026, 1, 15, 16, 30), 'Asia/Ho_Chi_Minh'),
      '2026-01-15',
    );
    expect(
      calendarDate(DateTime.utc(2026, 1, 15, 17, 30), 'Asia/Ho_Chi_Minh'),
      '2026-01-16',
    );
    expect(
      calendarDate(DateTime.utc(2026, 1, 15, 4, 30), 'America/New_York'),
      '2026-01-14',
    );
    expect(
      calendarDate(DateTime.utc(2026, 1, 15, 5, 30), 'America/New_York'),
      '2026-01-15',
    );
    expect(isCalendarDate('2024-02-29'), isTrue);
    expect(isCalendarDate('2023-02-29'), isFalse);
  });

  test('exact FX accepts integer minor units and rejects a fraction', () {
    expect(
      convertedMinor(BigInt.from(-1000), '25000', 2, 0),
      BigInt.from(250000),
    );
    expect(
      convertedMinor(BigInt.from(-10000), '25000.25', 2, 0),
      BigInt.from(2500025),
    );
    expect(convertedMinor(BigInt.from(-1), '150', 2, 0), isNull);
    expect(normalizeRate('25000'), '25000.00000000');
    expect(inInt64(-BigInt.parse('9223372036854775808')), isTrue);
    expect(inInt64(-BigInt.parse('9223372036854775809')), isFalse);
  });

  test('expense is stored negative and recent wallet wins over sort order', () {
    final categories = [
      const FinanceCategory(id: 'food', name: 'Ăn uống', parentId: null),
    ];
    final result = prepareTransaction(
      TransactionDraft(
        type: TransactionType.expense,
        occurredOn: '2026-01-15',
        accountId: 'card',
        magnitude: BigInt.from(150000),
        clientIds: const ['11111111-1111-4111-8111-111111111111'],
        categoryId: 'food',
        notes: '  lunch  ',
      ),
      [
        _wallet('cash', order: 0),
        _wallet('card', order: 1, type: WalletType.credit),
      ],
      const [WalletCurrency('VND', 0)],
      categories,
    );
    final command = result.getOrElse(() => throw StateError('invalid'));
    expect(command.legs.single.amountMinor, BigInt.from(-150000));
    expect(command.legs.single.currencyCode, 'VND');
    expect(command.notes, 'lunch');
    expect(
      defaultAccountId(
        wallets: [
          _wallet('cash', order: 0),
          _wallet('card', order: 1, type: WalletType.credit),
        ],
        recentLegs: [_leg('card')],
      ),
      'card',
    );
    expect(defaultCategoryId(categories), 'food');
  });

  test(
    'same-currency transfer balances and cross-currency rate is normalized',
    () {
      final same = prepareTransaction(
        _transfer(magnitude: BigInt.from(150000)),
        [_wallet('a'), _wallet('b')],
        const [WalletCurrency('VND', 0)],
        const [],
      ).getOrElse(() => throw StateError('invalid'));
      expect(same.legs.map((leg) => leg.amountMinor), [
        BigInt.from(-150000),
        BigInt.from(150000),
      ]);
      expect(same.categoryId, isNull);
      expect(same.rate, isNull);

      final fx = prepareTransaction(
        _transfer(
          magnitude: BigInt.from(1000),
          counter: 'vnd',
          rate: '25000',
          quotedAt: '2026-01-15T00:00:00.000Z',
        ),
        [_wallet('usd', currency: 'USD'), _wallet('vnd', currency: 'VND')],
        const [WalletCurrency('USD', 2), WalletCurrency('VND', 0)],
        const [],
      ).getOrElse(() => throw StateError('invalid'));
      expect(fx.legs[1].amountMinor, BigInt.from(250000));
      expect(fx.rate, '25000.00000000');

      final fraction = prepareTransaction(
        _transfer(
          magnitude: BigInt.one,
          counter: 'vnd',
          rate: '150',
          quotedAt: '2026-01-15T00:00:00.000Z',
        ),
        [_wallet('usd', currency: 'USD'), _wallet('vnd', currency: 'VND')],
        const [WalletCurrency('USD', 2), WalletCurrency('VND', 0)],
        const [],
      );
      expect(fraction.isLeft(), isTrue);
    },
  );
}

Wallet _wallet(
  String id, {
  int order = 0,
  String currency = 'VND',
  WalletType type = WalletType.cash,
}) => Wallet(
  id: id,
  createdAt: DateTime.utc(2026),
  draft: WalletDraft(
    name: id,
    type: type,
    currency: currency,
    initialBalance: BigInt.zero,
  ),
  balance: BigInt.zero,
  version: 1,
  sortOrder: order,
  archived: false,
);

TxLeg _leg(String accountId) => TxLeg(
  id: accountId,
  clientId: '11111111-1111-4111-8111-111111111111',
  accountId: accountId,
  currencyCode: 'VND',
  amountMinor: BigInt.from(-1),
  type: TransactionType.expense,
  occurredOn: '2026-01-02',
  categoryId: 'food',
  notes: null,
  transferGroupId: null,
  deletedAt: null,
  version: 1,
  createdAt: DateTime.utc(2026, 1, 2),
);

TransactionDraft _transfer({
  required BigInt magnitude,
  String counter = 'b',
  String? rate,
  String? quotedAt,
}) => TransactionDraft(
  type: TransactionType.transfer,
  occurredOn: '2026-01-15',
  accountId: 'usd' == counter ? 'a' : (counter == 'vnd' ? 'usd' : 'a'),
  counterAccountId: counter == 'b' ? 'b' : counter,
  magnitude: magnitude,
  clientIds: const [
    '11111111-1111-4111-8111-111111111111',
    '22222222-2222-4222-8222-222222222222',
  ],
  rate: rate,
  quotedAt: quotedAt,
);
