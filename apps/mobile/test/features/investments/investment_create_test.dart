import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/investments/data/investment_repository_impl.dart';
import 'package:mobile/features/investments/domain/investment.dart';
import 'package:mobile/features/investments/domain/investment_use_cases.dart';
import 'package:mobile/features/investments/presentation/pages/investment_editor_page.dart';

import '../home/fixtures.dart' show b;
import 'investment_stub.dart';
import '../../support/server_config_fixture.dart';

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
      'id': 'a',
      'clientId': 'a',
      'kind': 'gold',
      'name': 'Vàng',
      'currencyCode': 'VND',
      'unit': 'chi',
      'quantity': '3',
      'costBasisMinor': '21600000',
      'currentValueMinor': '21600000',
      'valuationBasis': 'cost',
      'version': 1,
    });
  }
}

InvestmentDraft _draft({
  InvestmentKind kind = InvestmentKind.gold,
  BigInt? quantity,
  BigInt? price,
  BigInt? amount,
  String name = 'Vàng SJC',
  String? account = 'vcb',
  int? rate,
  String? start,
  String? maturity,
}) => InvestmentDraft(
  clientId: 'c1',
  tradeClientId: 't1',
  kind: kind,
  name: name,
  currencyCode: 'VND',
  unit: kind.defaultUnit,
  quantity: quantity ?? BigInt.from(300000000),
  tradedOn: '2026-11-06',
  priceMinor: price,
  amountMinor: amount,
  accountId: account,
  interestRateBps: rate,
  startDate: start,
  maturityDate: maturity,
);

void main() {
  group('repository', () {
    test('a gold buy sends the price and a dotted quantity', () async {
      final api = _Api();
      await InvestmentRepositoryImpl(api)
          .create(_draft(price: b(7200000), quantity: BigInt.from(12345678)));
      final (method, path, body) = api.calls.single;
      expect((method, path), ('POST', 'investments'));
      expect(body!['kind'], 'gold');
      final trade = body['initialTrade'] as Map<String, dynamic>;
      expect(trade['quantity'], '0.12345678');
      expect(trade['priceMinor'], '7200000');
      expect(trade.containsKey('amountMinor'), isFalse);
      expect(trade['accountId'], 'vcb');
      expect(body.containsKey('interestRateBps'), isFalse);
    });

    test(
      'a deposit sends the principal, rate and dates; có sẵn is null',
      () async {
        final api = _Api();
        await InvestmentRepositoryImpl(api).create(
          _draft(
            kind: InvestmentKind.savingsDeposit,
            quantity: quantityOneForTest,
            amount: b(30000000),
            account: null,
            rate: 580,
            start: '2026-11-06',
            maturity: '2027-05-06',
          ),
        );
        final body = api.calls.single.$3!;
        expect(body['interestRateBps'], 580);
        expect(body['maturityDate'], '2027-05-06');
        final trade = body['initialTrade'] as Map<String, dynamic>;
        expect(trade['quantity'], '1');
        expect(trade['amountMinor'], '30000000');
        expect(trade.containsKey('priceMinor'), isFalse);
        expect(trade['accountId'], isNull);
      },
    );
  });

  group('use case', () {
    final cases = DefaultInvestmentUseCases(
      InvestmentRepositoryImpl(_Api()),
      testServerConfigModel(),
    );

    test('refuses drafts the API would refuse', () async {
      for (final bad in [
        _draft(price: b(1), name: '  '),
        _draft(price: b(1), quantity: BigInt.zero),
        _draft(),
        _draft(price: b(0)),
        _draft(
          kind: InvestmentKind.savingsDeposit,
          quantity: quantityOneForTest,
          amount: b(100),
          rate: 580,
          start: '2026-11-06',
          maturity: '2026-11-06',
        ),
        _draft(
          kind: InvestmentKind.savingsDeposit,
          quantity: quantityOneForTest,
          amount: b(100),
          start: '2026-11-06',
          maturity: '2027-01-01',
        ),
      ]) {
        expect((await cases.create(bad)).isLeft(), isTrue);
      }
      expect((await cases.create(_draft(price: b(7200000)))).isRight(), isTrue);
    });
  });

  group('editor', () {
    Future<FakeInvestmentUseCases> open(WidgetTester t, {String? kind}) async {
      t.view.physicalSize = const Size(390, 2000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await investmentApp(
        InvestmentEditorPage(
          kind: kind == null
              ? null
              : InvestmentKind.values.firstWhere((k) => k.apiValue == kind),
        ),
      );
      await t.pumpWidget(h.app);
      h.router.push('/page');
      await t.pumpAndSettle();
      return h.cases;
    }

    testWidgets('gold: total follows quantity × price; saves có sẵn', (
      t,
    ) async {
      final cases = await open(t);
      expect(find.text('Khoản đầu tư mới'), findsOneWidget);
      expect(find.text('Tính theo chỉ'), findsOneWidget);
      final fields = find.byType(TextField);
      await t.enterText(fields.at(0), 'Vàng SJC');
      await t.enterText(fields.at(1), '3');
      await t.enterText(fields.at(2), '7200000');
      await t.pumpAndSettle();
      expect(find.textContaining('21.600.000'), findsWidgets);
      await t.tap(find.text('Đã có từ trước'));
      await t.pumpAndSettle();
      await t.tap(find.text('Lưu khoản đầu tư'));
      await t.pumpAndSettle();
      final d = cases.created.single;
      expect(d.kind, InvestmentKind.gold);
      expect(d.unit, 'chi');
      expect(d.quantity, BigInt.from(300000000));
      expect(d.priceMinor, b(7200000));
      expect(d.accountId, isNull);
    });

    testWidgets('save stays off until the form is usable', (t) async {
      await open(t);
      final save = find.text('Lưu khoản đầu tư');
      await t.tap(save, warnIfMissed: false);
      await t.pumpAndSettle();
      expect(find.text('Khoản đầu tư mới'), findsOneWidget);
    });

    testWidgets('deposit: needs a maturity date after the deposit date', (
      t,
    ) async {
      final cases = await open(t, kind: 'savings_deposit');
      expect(find.text('Số tiền gửi'), findsOneWidget);
      expect(find.text('Lãi suất/năm'), findsOneWidget);
      expect(find.text('Ngày đáo hạn'), findsOneWidget);
      final fields = find.byType(TextField);
      await t.enterText(fields.at(0), 'Techcombank 6 tháng');
      await t.enterText(fields.at(1), '30000000');
      await t.enterText(fields.at(2), '5,8');
      await t.pumpAndSettle();
      await t.tap(find.text('Lưu khoản đầu tư'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(cases.created, isEmpty);
    });
  });
}

BigInt get quantityOneForTest => BigInt.from(100000000);
