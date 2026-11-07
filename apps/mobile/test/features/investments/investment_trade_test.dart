import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/money/quantity.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/investments/data/investment_repository_impl.dart';
import 'package:mobile/features/investments/domain/investment.dart';
import 'package:mobile/features/investments/domain/investment_use_cases.dart';
import 'package:mobile/features/investments/presentation/pages/investment_kind_page.dart';

import '../home/fixtures.dart' show b;
import 'investment_stub.dart';

class _Api implements AuthorizedApi {
  final calls = <(String, String, Map<String, dynamic>?)>[];
  Map<String, dynamic> json = {};

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    calls.add((method, path, body));
    return right(json);
  }
}

Map<String, dynamic> _position() => {
  'id': 'g1',
  'clientId': 'g1',
  'kind': 'gold',
  'name': 'Vàng SJC',
  'currencyCode': 'VND',
  'unit': 'chi',
  'quantity': '7',
  'costBasisMinor': '50000000',
  'currentValueMinor': '56000000',
  'valuationBasis': 'price',
  'version': 4,
};

void main() {
  test('sold cost is proportional, half up, and all of it on a full sale', () {
    final cost = b(50000000);
    final held = BigInt.from(700000000);
    // 3 of 7 chỉ: 50.000.000 × 3 / 7 = 21.428.571,43 → 21.428.571.
    expect(soldCostMinor(cost, held, BigInt.from(300000000)), b(21428571));
    expect(soldCostMinor(cost, held, held), cost);
    // 1 of 3 of 100 = 33,33 → 33; 2 of 3 = 66,67 → 67.
    final three = BigInt.from(300000000);
    expect(soldCostMinor(b(100), three, BigInt.from(100000000)), b(33));
    expect(soldCostMinor(b(100), three, BigInt.from(200000000)), b(67));
  });

  group('repository', () {
    test(
      'parses trades: a buy with change, a sell with realized gain',
      () async {
        final api = _Api()
          ..json = {
            'items': [
              {
                'id': 'b1',
                'clientId': 'b1',
                'side': 'buy',
                'quantity': '5',
                'amountMinor': '35000000',
                'unitPriceMinor': '7000000',
                'realizedMinor': null,
                'accountId': null,
                'tradedOn': '2026-09-10',
                'note': null,
                'currentValueMinor': '40000000',
                'unrealizedMinor': '5000000',
                'unrealizedBps': '1429',
                'createdAt': '2026-09-10T01:00:00.000Z',
              },
              {
                'id': 's1',
                'clientId': 's1',
                'side': 'sell',
                'quantity': '0.5',
                'amountMinor': '4000000',
                'unitPriceMinor': '8000000',
                'realizedMinor': '500000',
                'accountId': 'vcb',
                'tradedOn': '2026-10-20',
                'note': null,
                'currentValueMinor': null,
                'unrealizedMinor': null,
                'unrealizedBps': null,
                'createdAt': '2026-10-20T01:00:00.000Z',
              },
            ],
          };
        final list = (await InvestmentRepositoryImpl(api).trades('g1'))
            .toOption()
            .toNullable()!;
        expect(list.first.existing, isTrue);
        expect(list.first.quantity, BigInt.from(500000000));
        expect(list.first.unrealizedBps, 1429);
        expect(list.last.side, TradeSide.sell);
        expect(list.last.quantity, BigInt.from(50000000));
        expect(list.last.realizedMinor, b(500000));
        expect(api.calls.single.$2, 'investments/g1/trades');
      },
    );

    test('a sale posts side, dotted quantity, price and wallet', () async {
      final api = _Api()..json = _position();
      await InvestmentRepositoryImpl(api).sell(
        'g1',
        SellDraft(
          clientId: 'c',
          quantity: BigInt.from(300000000),
          priceMinor: b(8000000),
          accountId: 'vcb',
          tradedOn: '2026-11-06',
        ),
      );
      final (method, path, body) = api.calls.single;
      expect((method, path), ('POST', 'investments/g1/trades'));
      expect(body!['side'], 'sell');
      expect(body['quantity'], '3');
      expect(body['priceMinor'], '8000000');
      expect(body['accountId'], 'vcb');
    });

    test('a price posts the UTC time', () async {
      final api = _Api()..json = _position();
      await InvestmentRepositoryImpl(api).addPrice(
        'g1',
        clientId: 'c',
        priceMinor: b(8000000),
        quotedAt: DateTime.utc(2026, 11, 5, 9),
      );
      expect(api.calls.single.$2, 'investments/g1/prices');
      expect(api.calls.single.$3!['quotedAt'], '2026-11-05T09:00:00.000Z');
      expect(api.calls.single.$3!['priceMinor'], '8000000');
    });
  });

  group('use case', () {
    final cases = DefaultInvestmentUseCases(
      InvestmentRepositoryImpl(_Api()..json = _position()),
    );
    final inv = InvestmentRepositoryImpl.parse(_position());
    SellDraft sale(int q, int price) => SellDraft(
      clientId: 'c',
      quantity: BigInt.from(q) * BigInt.from(100000000),
      priceMinor: b(price),
      accountId: 'vcb',
      tradedOn: '2026-11-06',
    );

    test('refuses selling more than held, zero, or at no price', () async {
      expect((await cases.sell(inv, sale(8, 8000000))).isLeft(), isTrue);
      expect((await cases.sell(inv, sale(0, 8000000))).isLeft(), isTrue);
      expect((await cases.sell(inv, sale(1, 0))).isLeft(), isTrue);
      expect((await cases.sell(inv, sale(7, 8000000))).isRight(), isTrue);
    });

    test('a price is not for deposits and may be zero', () async {
      final deposit = Investment(
        id: 'd',
        clientId: 'd',
        kind: InvestmentKind.savingsDeposit,
        name: 'VCB',
        currencyCode: 'VND',
        unit: 'deposit',
        quantity: '1',
        costBasisMinor: b(1),
        currentValueMinor: b(1),
        valuation: InvestmentValuation.deposit,
        version: 1,
      );
      Future<bool> ok(Investment i, int p) async => (await cases.addPrice(
        i,
        clientId: 'c',
        priceMinor: b(p),
        quotedAt: DateTime.utc(2026, 11, 5),
      )).isRight();
      expect(await ok(deposit, 5), isFalse);
      expect(await ok(inv, 0), isTrue);
    });
  });

  group('view model', () {
    test('groups by kind, buys oldest first, sold sums the sells', () async {
      final h = await investmentApp(const SizedBox());
      await h.model.load();
      await h.model.loadTrades(['g1', 'g2']);
      expect(h.model.ofKind(InvestmentKind.gold).map((i) => i.id), [
        'g2',
        'g1',
      ]);
      expect(h.model.buysOf('g1').map((t) => t.tradedOn), [
        '2026-09-10',
        '2026-09-25',
      ]);
      final sold = h.model.soldOf(InvestmentKind.gold)!;
      expect(sold.quantity, BigInt.from(600000000));
      expect(sold.realized, b(5000000));
      expect(sold.unit, 'chi');
      expect(h.model.soldOf(InvestmentKind.crypto), isNull);
    });

    test('a failed sale keeps the failure; a good one reloads', () async {
      final fake = FakeInvestmentUseCases();
      final h = await investmentApp(const SizedBox(), cases: fake);
      await h.model.load();
      final gold = h.model.byId('g1')!;
      final draft = SellDraft(
        clientId: 'c',
        quantity: BigInt.from(100000000),
        priceMinor: b(8000000),
        accountId: 'vcb',
        tradedOn: '2026-11-06',
      );
      fake.failure = const AuthFailure(AuthError.investmentOversell);
      expect(await h.model.sell(gold, draft), isFalse);
      expect(h.model.failure?.code, AuthError.investmentOversell);
      fake.failure = null;
      expect(await h.model.sell(gold, draft), isTrue);
      expect(h.model.failure, isNull);
      expect(fake.sold, hasLength(2));
    });
  });

  group('page', () {
    Future<(FakeInvestmentUseCases, Widget)> open(WidgetTester t) async {
      t.view.physicalSize = const Size(390, 2400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await investmentApp(
        const InvestmentKindPage(kind: InvestmentKind.gold),
      );
      await t.pumpWidget(h.app);
      h.router.push('/page');
      await t.pumpAndSettle();
      return (h.cases, h.app);
    }

    testWidgets('shows assets, price pill, buys, có sẵn and the sold row', (
      t,
    ) async {
      await open(t);
      expect(find.text('Vàng đang giữ'), findsOneWidget);
      expect(find.text('9 chỉ'), findsOneWidget);
      expect(find.text('Vàng SJC'), findsOneWidget);
      expect(find.text('Vàng nhẫn 9999'), findsOneWidget);
      expect(find.textContaining('8.000.000/chỉ · 05/11'), findsNWidgets(2));
      expect(find.text('CÁC LẦN MUA'), findsNWidgets(2));
      expect(find.text('10/09'), findsOneWidget);
      expect(find.text('có sẵn'), findsOneWidget);
      expect(find.text('Giá vốn 6.000.000/chỉ'), findsOneWidget);
      expect(find.text('Mua thêm'), findsNWidgets(2));
      expect(find.text('Đã bán'), findsOneWidget);
      expect(find.text('6 chỉ · chốt lãi +5.000.000'), findsOneWidget);
    });

    testWidgets('selling shows the proceeds and realized gain, then saves', (
      t,
    ) async {
      final (cases, _) = await open(t);
      await t.tap(find.text('Bán').first);
      await t.pumpAndSettle();
      expect(find.text('Bán Vàng nhẫn 9999'), findsOneWidget);
      expect(find.text('Đang giữ 2 chỉ'), findsOneWidget);
      await t.enterText(find.byType(TextField).first, '1');
      await t.pumpAndSettle();
      // 1 chỉ at the prefilled 8.000.000; cost is half of 12.000.000.
      expect(find.text('Lãi chốt +2.000.000'), findsOneWidget);
      await t.tap(find.textContaining('Bán 1 chỉ'));
      await t.pumpAndSettle();
      final d = cases.sold.single;
      expect(d.quantity, BigInt.from(100000000));
      expect(d.priceMinor, b(8000000));
      expect(d.accountId, 'vcb');
    });

    testWidgets('selling more than held keeps the button off', (t) async {
      final (cases, _) = await open(t);
      await t.tap(find.text('Bán').first);
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, '3');
      await t.pumpAndSettle();
      // The sale button still reads "Bán" and does nothing.
      await t.tap(find.text('Bán').last, warnIfMissed: false);
      await t.pumpAndSettle();
      expect(cases.sold, isEmpty);
    });

    testWidgets('updating the price saves it', (t) async {
      final (cases, _) = await open(t);
      await t.tap(find.text('Cập nhật giá').first);
      await t.pumpAndSettle();
      expect(find.text('Giá Vàng nhẫn 9999'), findsOneWidget);
      expect(find.textContaining('Giá trước 8.000.000'), findsOneWidget);
      await t.enterText(find.byType(TextField).first, '8200000');
      await t.pumpAndSettle();
      await t.tap(find.text('Lưu giá'));
      await t.pumpAndSettle();
      expect(cases.priced.single, b(8200000));
    });
  });
}
