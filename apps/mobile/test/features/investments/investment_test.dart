import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/investments/data/investment_repository_impl.dart';
import 'package:mobile/features/investments/domain/investment.dart';
import 'package:mobile/features/investments/domain/investment_use_cases.dart';
import 'package:mobile/features/investments/presentation/pages/investments_page.dart';
import 'package:mobile/features/investments/presentation/widgets/investment_labels.dart';
import 'package:mobile/features/net_worth/domain/net_worth_history.dart';

import '../home/fixtures.dart' show b;
import 'investment_stub.dart';
import '../../support/server_config_fixture.dart';

class _Api implements AuthorizedApi {
  Map<String, dynamic> json = {};
  final paths = <String>[];

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    paths.add(path);
    return right(json);
  }
}

Map<String, dynamic> _item({Object? cost = '100', String basis = 'price'}) => {
  'id': 'a',
  'clientId': 'a',
  'kind': 'savings_deposit',
  'name': 'VCB',
  'currencyCode': 'VND',
  'unit': 'deposit',
  'quantity': '1',
  'costBasisMinor': cost,
  'currentValueMinor': '110',
  'valuationBasis': basis,
  'averageCostMinor': null,
  'unrealizedMinor': basis == 'cost' ? null : '10',
  'unrealizedBps': basis == 'cost' ? null : '1000',
  'latestPrice': null,
  'interestRateBps': 580,
  'startDate': '2026-01-01',
  'maturityDate': '2027-01-01',
  'note': null,
  'archivedAt': null,
  'version': 3,
};

void main() {
  group('percent', () {
    test('one decimal, half away from zero, no float', () {
      expect(investmentPercent(829, 'vi'), '8,3%');
      expect(investmentPercent(-1429, 'vi'), '14,3%');
      expect(investmentPercent(0, 'vi'), '0,0%');
      expect(investmentPercent(1005, 'en'), '10.1%');
      expect(investmentPill(829, 'vi'), '▲ 8,3%');
      expect(investmentPill(-320, 'vi'), '▼ 3,2%');
      expect(investmentPill(0, 'vi'), '0,0%');
    });
  });

  group('repository', () {
    test('parses a position, an unpriced one has no profit', () {
      final priced = InvestmentRepositoryImpl.parse(_item());
      expect(priced.kind, InvestmentKind.savingsDeposit);
      expect(priced.unrealizedBps, 1000);
      expect(priced.unpriced, isFalse);
      expect(priced.interestRateBps, 580);
      final unpriced = InvestmentRepositoryImpl.parse(_item(basis: 'cost'));
      expect(unpriced.unpriced, isTrue);
      expect(unpriced.unrealizedMinor, isNull);
      expect(unpriced.unrealizedBps, isNull);
    });

    test('rejects a JSON number for money', () async {
      final api = _Api()
        ..json = {
          'items': [_item(cost: 100)],
        };
      expect((await InvestmentRepositoryImpl(api).list()).isLeft(), isTrue);
    });

    test('parses summary and the history window', () async {
      final api = _Api()
        ..json = {
          'totals': [
            {
              'currencyCode': 'VND',
              'costBasisMinor': '100',
              'currentValueMinor': '110',
              'unrealizedMinor': '10',
              'unrealizedBps': '1000',
              'unpricedCount': 0,
            },
          ],
          'byKind': [
            {
              'kind': 'gold',
              'currencyCode': 'VND',
              'investmentCount': 2,
              'costBasisMinor': '100',
              'currentValueMinor': '110',
              'unrealizedMinor': '10',
              'unrealizedBps': null,
              'unpricedCount': 1,
              'shareBps': '10000',
            },
          ],
        };
      final repo = InvestmentRepositoryImpl(api);
      final s = (await repo.summary()).toOption().toNullable()!;
      expect(s.totalOf('VND')!.unrealizedBps, 1000);
      expect(s.kindsOf('VND').single.kind, InvestmentKind.gold);
      expect(s.kindsOf('VND').single.shareBps, 10000);
      expect(s.kindsOf('VND').single.unrealizedBps, isNull);
      api.json = {
        'points': [
          {
            'from': '2026-10-31',
            'to': '2026-10-31',
            'asOf': '2026-10-31',
            'items': [
              {'currency': 'VND', 'valueMinor': '40'},
            ],
          },
        ],
      };
      final h = (await repo.history(NetWorthWindow.half))
          .toOption()
          .toNullable()!;
      expect(h.single.valueByCurrency['VND'], b(40));
      expect(api.paths.last, 'reports/investments/history?window=6m');
    });
  });

  group('use case', () {
    test('rejects a malformed currency', () async {
      final r = await DefaultInvestmentUseCases(
        InvestmentRepositoryImpl(_Api()),
        testServerConfigModel(),
      ).valueLine(NetWorthWindow.half, currency: 'vnd');
      expect(r.isLeft(), isTrue);
    });
  });

  group('view model', () {
    tearDown(() async => investmentApp(const SizedBox()));

    test('loads list, totals and the value line', () async {
      final h = await investmentApp(const SizedBox());
      await h.model.load();
      expect(h.model.loaded, isTrue);
      expect(h.model.total!.currentValueMinor, b(800813699));
      expect(h.model.kinds.first.kind, InvestmentKind.realEstate);
      expect(h.model.names(InvestmentKind.gold), [
        'Vàng nhẫn 9999',
        'Vàng SJC',
      ]);
      expect(h.model.hasLine, isTrue);
      expect(h.model.digits, 0);
    });

    test('a failing history only hides the line', () async {
      final fake = FakeInvestmentUseCases()..historyFails = true;
      final h = await investmentApp(const SizedBox(), cases: fake);
      await h.model.load();
      expect(h.model.loaded, isTrue);
      expect(h.model.hasLine, isFalse);
    });

    test('a failing list keeps it unloaded with the failure', () async {
      final fake = FakeInvestmentUseCases()
        ..failure = const AuthFailure(AuthError.network);
      final h = await investmentApp(const SizedBox(), cases: fake);
      await h.model.load();
      expect(h.model.loaded, isFalse);
      expect(h.model.failure?.code, AuthError.network);
    });
  });

  group('page', () {
    testWidgets('shows totals, share, categories and the unpriced tag', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final h = await investmentApp(const InvestmentsPage());
      await tester.pumpWidget(h.app);
      h.router.push('/page');
      await tester.pumpAndSettle();
      expect(find.text('Tổng giá trị đầu tư'), findsOneWidget);
      expect(find.text('▲ 8,3%'), findsWidgets);
      expect(find.text('Tỷ trọng theo danh mục'), findsOneWidget);
      expect(find.text('DANH MỤC'), findsOneWidget);
      expect(find.text('Chưa có giá'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Đất nền Long An'), findsOneWidget);
    });

    testWidgets('empty list shows the empty state', (tester) async {
      final fake = FakeInvestmentUseCases()
        ..items = []
        ..summaryValue = const InvestmentSummary();
      final h = await investmentApp(const InvestmentsPage(), cases: fake);
      await tester.pumpWidget(h.app);
      h.router.push('/page');
      await tester.pumpAndSettle();
      expect(find.text('Chưa có khoản đầu tư'), findsOneWidget);
    });
  });
}
