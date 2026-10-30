import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/core/time/calendar_date.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/tags/domain/tag.dart';
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
    final tags = [
      const Tag(
        id: 'work',
        clientId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        name: 'Work',
        version: 1,
      ),
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
        merchant: '  WinMart  ',
        tagIds: const ['work'],
      ),
      [
        _wallet('cash', order: 0),
        _wallet('card', order: 1, type: WalletType.credit),
      ],
      const [WalletCurrency('VND', 0)],
      categories,
      tags,
    );
    final command = result.getOrElse(() => throw StateError('invalid'));
    expect(command.legs.single.amountMinor, BigInt.from(-150000));
    expect(command.legs.single.currencyCode, 'VND');
    expect(command.notes, 'lunch');
    expect(command.merchant, 'WinMart');
    expect(command.tagIds, ['work']);
    expect(command.occurredTime, isNull);
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

  test('accepts optional occurredTime HH:mm and rejects invalid clocks', () {
    final wallets = [_wallet('card')];
    const currencies = [WalletCurrency('VND', 0)];
    final categories = [
      const FinanceCategory(
        id: 'food',
        name: 'Food',
        parentId: null,
        kind: CategoryKind.expense,
      ),
    ];
    final ok = prepareTransaction(
      TransactionDraft(
        type: TransactionType.expense,
        occurredOn: '2026-01-15',
        occurredTime: '12:40',
        accountId: 'card',
        magnitude: BigInt.from(1000),
        clientIds: const ['11111111-1111-4111-8111-111111111111'],
        categoryId: 'food',
      ),
      wallets,
      currencies,
      categories,
      const [],
    );
    expect(
      ok.getOrElse(() => throw StateError('invalid')).occurredTime,
      '12:40',
    );
    final bad = prepareTransaction(
      TransactionDraft(
        type: TransactionType.expense,
        occurredOn: '2026-01-15',
        occurredTime: '24:00',
        accountId: 'card',
        magnitude: BigInt.from(1000),
        clientIds: const ['11111111-1111-4111-8111-111111111111'],
        categoryId: 'food',
      ),
      wallets,
      currencies,
      categories,
      const [],
    );
    expect(bad.isLeft(), isTrue);
  });

  test(
    'refuses a category whose kind does not fit the type; both fits all',
    () {
      const currencies = [WalletCurrency('VND', 0)];
      final categories = [
        const FinanceCategory(
          id: 'food',
          name: 'Food',
          parentId: null,
          kind: CategoryKind.expense,
        ),
        const FinanceCategory(
          id: 'pay',
          name: 'Pay',
          parentId: null,
          kind: CategoryKind.income,
        ),
        const FinanceCategory(id: 'misc', name: 'Misc', parentId: null),
      ];
      Either<AuthFailure, TransactionCommand> run(
        TransactionType type,
        String id,
      ) => prepareTransaction(
        TransactionDraft(
          type: type,
          occurredOn: '2026-01-15',
          accountId: 'card',
          magnitude: BigInt.from(1000),
          clientIds: const ['11111111-1111-4111-8111-111111111111'],
          categoryId: id,
        ),
        [_wallet('card')],
        currencies,
        categories,
        const [],
      );
      AuthError? code(Either<AuthFailure, TransactionCommand> r) =>
          r.fold((f) => f.code, (_) => null);
      expect(code(run(TransactionType.expense, 'pay')), AuthError.categoryKind);
      expect(code(run(TransactionType.income, 'food')), AuthError.categoryKind);
      expect(run(TransactionType.expense, 'food').isRight(), isTrue);
      expect(run(TransactionType.income, 'pay').isRight(), isTrue);
      expect(run(TransactionType.expense, 'misc').isRight(), isTrue);
      expect(run(TransactionType.income, 'misc').isRight(), isTrue);
    },
  );

  test('blank merchant becomes null and transfer forbids merchant', () {
    final blank = prepareTransaction(
      TransactionDraft(
        type: TransactionType.expense,
        occurredOn: '2026-01-15',
        accountId: 'cash',
        magnitude: BigInt.from(1000),
        clientIds: const ['11111111-1111-4111-8111-111111111111'],
        categoryId: 'food',
        merchant: '   ',
      ),
      [_wallet('cash')],
      const [WalletCurrency('VND', 0)],
      const [FinanceCategory(id: 'food', name: 'Ăn uống', parentId: null)],
      const [],
    ).getOrElse(() => throw StateError('invalid'));
    expect(blank.merchant, isNull);
    expect(blank.tagIds, isEmpty);

    final transfer = prepareTransaction(
      _transfer(magnitude: BigInt.from(1000), merchant: 'Shop'),
      [_wallet('a'), _wallet('b')],
      const [WalletCurrency('VND', 0)],
      const [],
      const [],
    );
    expect(transfer.isLeft(), isTrue);

    final tooMany = prepareTransaction(
      TransactionDraft(
        type: TransactionType.expense,
        occurredOn: '2026-01-15',
        accountId: 'cash',
        magnitude: BigInt.from(1000),
        clientIds: const ['11111111-1111-4111-8111-111111111111'],
        categoryId: 'food',
        tagIds: List.generate(21, (i) => 't$i'),
      ),
      [_wallet('cash')],
      const [WalletCurrency('VND', 0)],
      const [FinanceCategory(id: 'food', name: 'Ăn uống', parentId: null)],
      [
        for (var i = 0; i < 21; i++)
          Tag(
            id: 't$i',
            clientId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
            name: 'T$i',
            version: 1,
          ),
      ],
    );
    expect(tooMany.isLeft(), isTrue);
  });

  test(
    'same-currency transfer balances and cross-currency rate is normalized',
    () {
      final same = prepareTransaction(
        _transfer(magnitude: BigInt.from(150000)),
        [_wallet('a'), _wallet('b')],
        const [WalletCurrency('VND', 0)],
        const [],
        const [],
      ).getOrElse(() => throw StateError('invalid'));
      expect(same.legs.map((leg) => leg.amountMinor), [
        BigInt.from(-150000),
        BigInt.from(150000),
      ]);
      expect(same.categoryId, isNull);
      expect(same.merchant, isNull);
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
  merchant: null,
  tagIds: const [],
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
  String? merchant,
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
  merchant: merchant,
  rate: rate,
  quotedAt: quotedAt,
);
