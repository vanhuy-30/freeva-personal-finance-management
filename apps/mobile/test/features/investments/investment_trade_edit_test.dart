import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/investments/data/investment_repository_impl.dart';
import 'package:mobile/features/investments/domain/investment.dart';
import 'package:mobile/features/investments/domain/investment_use_cases.dart';
import 'package:mobile/features/investments/presentation/pages/trade_edit_page.dart';
import 'package:mobile/features/investments/presentation/pages/trade_page.dart';

import '../home/fixtures.dart' show b;
import 'investment_stub.dart';

class _Api implements AuthorizedApi {
  final calls = <(String, String, Map<String, dynamic>?)>[];

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    calls.add((method, path, body));
    return right({
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
      'version': 5,
    });
  }
}

void main() {
  final inv = InvestmentRepositoryImpl.parse({
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
  });

  group('repository', () {
    test('edit patches the buy with the version, price and wallet', () async {
      final api = _Api();
      await InvestmentRepositoryImpl(api).updateTrade(
        inv,
        'b1',
        TradeEdit(
          quantity: BigInt.from(550000000),
          priceMinor: b(7100000),
          accountId: null,
          tradedOn: '2026-09-11',
          note: ' ',
        ),
      );
      final (method, path, body) = api.calls.single;
      expect((method, path), ('PATCH', 'investments/g1/trades/b1'));
      expect(body, {
        'version': 4,
        'quantity': '5.5',
        'priceMinor': '7100000',
        'accountId': null,
        'tradedOn': '2026-09-11',
        'note': null,
      });
    });

    test('a one-lot buy sends the total instead of a price', () async {
      final api = _Api();
      final lot = InvestmentRepositoryImpl.parse({
        'id': 'p',
        'clientId': 'p',
        'kind': 'real_estate',
        'name': 'Đất',
        'currencyCode': 'VND',
        'unit': 'property',
        'quantity': '1',
        'costBasisMinor': '600000000',
        'currentValueMinor': '600000000',
        'valuationBasis': 'cost',
        'version': 1,
      });
      await InvestmentRepositoryImpl(api).updateTrade(
        lot,
        't',
        TradeEdit(
          quantity: BigInt.from(100000000),
          amountMinor: b(650000000),
          accountId: 'vcb',
          tradedOn: '2026-09-11',
        ),
      );
      final body = api.calls.single.$3!;
      expect(body['amountMinor'], '650000000');
      expect(body.containsKey('priceMinor'), isFalse);
    });

    test('use case refuses zero, no price or a bad date', () async {
      final cases = DefaultInvestmentUseCases(InvestmentRepositoryImpl(_Api()));
      Future<bool> ok(BigInt q, BigInt? p, String day) async =>
          (await cases.updateTrade(
            inv,
            'b1',
            TradeEdit(
              quantity: q,
              priceMinor: p,
              accountId: 'vcb',
              tradedOn: day,
            ),
          )).isRight();
      final one = BigInt.from(100000000);
      expect(await ok(BigInt.zero, b(1), '2026-09-11'), isFalse);
      expect(await ok(one, null, '2026-09-11'), isFalse);
      expect(await ok(one, b(1), '11/09/2026'), isFalse);
      expect(await ok(one, b(1), '2026-09-11'), isTrue);
    });
  });

  group('view model', () {
    test('deleting a buy keeps the asset; the last buy removes it', () async {
      final h = await investmentApp(const SizedBox());
      await h.model.load();
      await h.model.loadTrades(['g1', 'g2']);
      expect(await h.model.deleteBuy(h.model.byId('g1')!, 'b1'), isTrue);
      expect(h.cases.deletedTrades, ['b1']);
      expect(h.model.byId('g1'), isNotNull);
      expect(await h.model.deleteBuy(h.model.byId('g2')!, 'b3'), isTrue);
      expect(h.model.byId('g2'), isNull);
    });

    test('an oversell refusal is kept as the failure', () async {
      final h = await investmentApp(const SizedBox());
      await h.model.load();
      await h.model.loadTrades(['g1']);
      h.cases.failure = const AuthFailure(AuthError.investmentOversell);
      expect(await h.model.deleteBuy(h.model.byId('g1')!, 'b1'), isFalse);
      expect(h.model.failure?.code, AuthError.investmentOversell);
    });
  });

  group('pages', () {
    Future<FakeInvestmentUseCases> open(WidgetTester t, Widget page) async {
      t.view.physicalSize = const Size(390, 1500);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await investmentApp(page);
      await t.pumpWidget(h.app);
      h.router.push('/page');
      await t.pumpAndSettle();
      return h.cases;
    }

    testWidgets('the buy shows value, rows and the current price', (t) async {
      await open(t, const TradePage(id: 'g1', tradeId: 'b1'));
      expect(find.text('Lần mua 10/09'), findsOneWidget);
      expect(find.text('Vàng SJC · giá trị hiện tại'), findsOneWidget);
      expect(
        find.textContaining('40.000.000', findRichText: true),
        findsWidgets,
      );
      expect(find.text('5 chỉ × 8.000.000'), findsOneWidget);
      expect(find.text('10/09/2026'), findsOneWidget);
      expect(find.text('7.000.000/chỉ'), findsOneWidget);
      expect(find.text('Vietcombank'), findsOneWidget);
      expect(find.text('8.000.000 · 05/11'), findsOneWidget);
      expect(find.text('Sửa'), findsOneWidget);
      expect(find.text('Xoá'), findsOneWidget);
    });

    testWidgets('a có sẵn buy shows "Đã có từ trước" and no refund', (t) async {
      final cases = await open(t, const TradePage(id: 'g2', tradeId: 'b3'));
      expect(find.text('Đã có từ trước'), findsOneWidget);
      await t.tap(find.text('Xoá'));
      await t.pumpAndSettle();
      expect(find.text('Xoá lần mua 01/08?'), findsOneWidget);
      expect(find.textContaining('Trả lại'), findsNothing);
      await t.tap(find.text('Giữ lại'));
      await t.pumpAndSettle();
      expect(cases.deletedTrades, isEmpty);
    });

    testWidgets('delete asks first and says what comes back', (t) async {
      final cases = await open(t, const TradePage(id: 'g1', tradeId: 'b1'));
      await t.tap(find.text('Xoá'));
      await t.pumpAndSettle();
      expect(find.text('Xoá lần mua 10/09?'), findsOneWidget);
      expect(find.text('5 chỉ Vàng SJC'), findsOneWidget);
      expect(find.text('Trả lại Vietcombank'), findsOneWidget);
      expect(find.text('+35.000.000'), findsOneWidget);
      await t.tap(find.text('Xoá lần mua'));
      await t.pumpAndSettle();
      expect(cases.deletedTrades, ['b1']);
    });

    testWidgets('editing sends the new quantity and price', (t) async {
      final cases = await open(t, const TradeEditPage(id: 'g1', tradeId: 'b1'));
      expect(find.text('Sửa lần mua'), findsOneWidget);
      expect(find.text('Xoá lần mua này'), findsOneWidget);
      await t.enterText(find.byType(TextField).at(0), '6');
      await t.pumpAndSettle();
      expect(find.textContaining('42.000.000'), findsWidgets);
      await t.tap(find.text('Lưu'));
      await t.pumpAndSettle();
      final e = cases.edited.single;
      expect(e.quantity, BigInt.from(600000000));
      expect(e.priceMinor, b(7000000));
      expect(e.accountId, 'vcb');
      expect(e.tradedOn, '2026-09-10');
    });
  });
}
