import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/investments/data/investment_repository_impl.dart';
import 'package:mobile/features/investments/domain/investment.dart';
import 'package:mobile/features/investments/domain/investment_use_cases.dart';
import 'package:mobile/features/investments/presentation/pages/deposit_page.dart';
import 'package:mobile/features/investments/presentation/pages/investment_kind_page.dart';
import 'package:mobile/features/investments/presentation/widgets/investment_labels.dart';

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
      'id': 'dep',
      'clientId': 'dep',
      'kind': 'savings_deposit',
      'name': 'VCB',
      'currencyCode': 'VND',
      'unit': 'deposit',
      'quantity': '1',
      'costBasisMinor': '100',
      'currentValueMinor': '110',
      'valuationBasis': 'deposit',
      'version': 2,
    });
  }
}

void main() {
  test('rate text and days left use integers', () {
    expect(depositRateText(650, 'vi'), '6,5');
    expect(depositRateText(580, 'vi'), '5,8');
    expect(depositRateText(575, 'vi'), '5,75');
    expect(depositRateText(600, 'vi'), '6');
    expect(depositRateText(1, 'en'), '0.01');
    expect(daysUntil('2027-06-01', '2026-10-21'), 223);
    expect(daysUntil('2026-10-21', '2026-10-22'), -1);
  });

  group('repository', () {
    final deposit = Investment(
      id: 'dep',
      clientId: 'dep',
      kind: InvestmentKind.savingsDeposit,
      name: 'VCB',
      currencyCode: 'VND',
      unit: 'deposit',
      quantity: '1',
      costBasisMinor: b(100),
      currentValueMinor: b(110),
      valuation: InvestmentValuation.deposit,
      version: 2,
      startDate: '2026-06-01',
    );

    test('a withdrawal sells 1 for the money back', () async {
      final api = _Api();
      await InvestmentRepositoryImpl(api).sell(
        'dep',
        SellDraft(
          clientId: 'c',
          quantity: BigInt.from(100000000),
          amountMinor: b(102813699),
          accountId: 'vcb',
          tradedOn: '2026-11-06',
        ),
      );
      final body = api.calls.single.$3!;
      expect(body['quantity'], '1');
      expect(body['amountMinor'], '102813699');
      expect(body.containsKey('priceMinor'), isFalse);
    });

    test('edit patches name, note and maturity with the version', () async {
      final api = _Api();
      await InvestmentRepositoryImpl(api).update(
        deposit,
        name: 'VCB 12T',
        note: null,
        maturityDate: '2027-06-01',
      );
      final (method, path, body) = api.calls.single;
      expect((method, path), ('PATCH', 'investments/dep'));
      expect(body, {
        'version': 2,
        'name': 'VCB 12T',
        'note': null,
        'maturityDate': '2027-06-01',
      });
    });

    test('delete sends the position version', () async {
      final api = _Api();
      final r = await InvestmentRepositoryImpl(api).deleteTrade(deposit, 't1');
      expect(r.isRight(), isTrue);
      final (method, path, _) = api.calls.single;
      expect(method, 'DELETE');
      expect(path, 'investments/dep/trades/t1?version=2');
    });

    test('use case refuses a maturity on or before the deposit date', () async {
      final cases = DefaultInvestmentUseCases(
        InvestmentRepositoryImpl(_Api()),
        testServerConfigModel(),
      );
      Future<bool> ok(String maturity) async => (await cases.update(
        deposit,
        name: 'VCB',
        note: null,
        maturityDate: maturity,
      )).isRight();
      expect(await ok('2026-06-01'), isFalse);
      expect(await ok('2027-06-01'), isTrue);
    });
  });

  group('page', () {
    Future<FakeInvestmentUseCases> open(WidgetTester t) async {
      t.view.physicalSize = const Size(390, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final h = await investmentApp(const DepositPage(id: 'dep'));
      await t.pumpWidget(h.app);
      h.router.push('/page');
      await t.pumpAndSettle();
      return h.cases;
    }

    testWidgets('shows value, principal, interest, rate, dates, wallet', (
      t,
    ) async {
      await open(t);
      expect(find.text('Giá trị hôm nay'), findsOneWidget);
      expect(find.text('Gốc'), findsOneWidget);
      expect(find.text('+2.813.699'), findsOneWidget);
      expect(find.text('6,5%/năm'), findsOneWidget);
      expect(find.text('01/06/2026'), findsOneWidget);
      expect(find.text('01/06/2027 · còn 223 ngày'), findsOneWidget);
      expect(find.text('Vietcombank'), findsOneWidget);
      expect(find.text('Rút tiền gửi'), findsOneWidget);
      expect(find.text('Sửa khoản'), findsOneWidget);
      expect(find.text('Xoá khoản'), findsOneWidget);
    });

    testWidgets('withdrawing sends the whole deposit with the money back', (
      t,
    ) async {
      final cases = await open(t);
      await t.tap(find.text('Rút tiền gửi'));
      await t.pumpAndSettle();
      expect(find.text('Tiền nhận về'), findsOneWidget);
      await t.tap(find.textContaining('Rút 102.813.699'));
      await t.pumpAndSettle();
      final d = cases.sold.single;
      expect(d.quantity, BigInt.from(100000000));
      expect(d.amountMinor, b(102813699));
      expect(d.accountId, 'vcb');
    });

    testWidgets('deleting asks first, then removes the only buy', (t) async {
      final cases = await open(t);
      await t.tap(find.text('Xoá khoản'));
      await t.pumpAndSettle();
      expect(find.text('Xoá khoản này?'), findsOneWidget);
      await t.tap(find.text('Xoá khoản').last);
      await t.pumpAndSettle();
      expect(cases.deletedTrades, ['d1']);
    });

    testWidgets('editing saves name, note and maturity', (t) async {
      final cases = await open(t);
      await t.tap(find.text('Sửa khoản'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).first, 'VCB 13 tháng');
      await t.pumpAndSettle();
      await t.tap(find.text('Lưu'));
      await t.pumpAndSettle();
      expect(cases.updated.single.name, 'VCB 13 tháng');
      expect(cases.updated.single.maturity, '2027-06-01');
    });
  });

  testWidgets('the Tiền gửi category lists deposits that open the detail', (
    t,
  ) async {
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final h = await investmentApp(
      const InvestmentKindPage(kind: InvestmentKind.savingsDeposit),
    );
    await t.pumpWidget(h.app);
    h.router.push('/page');
    await t.pumpAndSettle();
    expect(find.text('VCB 12 tháng'), findsOneWidget);
    expect(find.text('Ngày đáo hạn 01/06/2027'), findsOneWidget);
    expect(find.text('Mua thêm'), findsNothing);
  });
}
