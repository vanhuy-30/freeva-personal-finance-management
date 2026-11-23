import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/analytics/analytics_event.dart';
import 'package:mobile/core/analytics/analytics_service.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/reports/domain/report.dart';
import 'package:mobile/features/reports/domain/report_flow.dart';
import 'package:mobile/features/reports/domain/report_holdings.dart';
import 'package:mobile/features/reports/domain/report_use_cases.dart';
import 'package:mobile/features/reports/presentation/viewmodels/report_view_model.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';

import '../auth/fakes.dart';
import '../home/home_fakes.dart' show FakeProfileViewModel;
import '../../support/server_config_fixture.dart';

void main() {
  late _Cases cases;
  late DefaultAuthViewModel auth;
  late DefaultReportViewModel model;
  late _Analytics analytics;

  setUp(() {
    cases = _Cases();
    analytics = _Analytics();
    auth =
        DefaultAuthViewModel(
            DefaultAuthUseCases(
              AuthRepositoryImpl(
                FakeApi(),
                MemoryVault(),
                FakeBiometrics(),
                testServerConfigModel(),
              ),
              testServerConfigModel(),
            ),
          )
          ..stage = AuthStage.unlocked
          ..hasPin = true
          ..ready = true;
    model = DefaultReportViewModel(
      cases,
      auth,
      analytics,
      FakeProfileViewModel(),
      clock: () => DateTime(2026, 10, 23),
    );
  });

  tearDown(() {
    model.dispose();
    auth.dispose();
  });

  test(
    'tracks one report view per visit and steps from server bounds',
    () async {
      model.beginVisit();
      await model.load(const ReportPeriodQuery.month());
      expect(cases.queries.single.kind, ReportPeriodKind.month);
      expect(cases.queries.single.on, isNull);
      await model.step(1);
      expect(cases.queries.last.kind, ReportPeriodKind.week);
      expect(cases.queries.last.on, '2026-10-12');
      expect(analytics.events, hasLength(1));
      expect(analytics.events.single['event'], 'report_viewed');
      expect(analytics.events.single.containsKey('incomeMinor'), isFalse);
      model.beginVisit();
      await model.load(const ReportPeriodQuery.month());
      expect(analytics.events, hasLength(2));
    },
  );

  test('does not step past year 9999', () async {
    cases.report = _named(to: '9999-12-31', from: '9999-12-25');
    model.beginVisit();
    await model.load(const ReportPeriodQuery.week());
    await model.step(1);
    expect(cases.queries, hasLength(1));
  });

  test('drops a late response after lock and does not track it', () async {
    cases.gate = Completer<void>();
    model.beginVisit();
    final pending = model.load(const ReportPeriodQuery.month());
    await Future<void>.delayed(Duration.zero);
    auth.lock();
    cases.gate!.complete();
    await pending;
    expect(model.data, isNull);
    expect(analytics.events, isEmpty);
  });

  test('loads the previous period and trend after the totals', () async {
    model.beginVisit();
    await model.load(const ReportPeriodQuery.week());
    expect(cases.previous.single.from, '2026-10-05');
    expect(cases.trends.single, (ReportPeriodKind.month, '2026-10-11'));
    expect(model.previous, isNotNull);
    expect(model.trend, isNotNull);
    expect(model.summary?.expenseChangeBps, 0);
  });

  test('a failing trend hides only the trend', () async {
    cases.trendFailure = const AuthFailure(AuthError.network);
    model.beginVisit();
    await model.load(const ReportPeriodQuery.week());
    expect(model.data, isNotNull);
    expect(model.failure, isNull);
    expect(model.trend, isNull);
    expect(model.trendFailed, isTrue);
  });

  test('next is locked on the period that holds today', () async {
    model.beginVisit();
    await model.load(const ReportPeriodQuery.week());
    expect(model.atCurrent, isFalse);
    expect(model.canStepNext, isTrue);
    cases.report = _named(from: '2026-10-19', to: '2026-10-25');
    await model.load(const ReportPeriodQuery.week());
    expect(model.atCurrent, isTrue);
    expect(model.canStepNext, isFalse);
    expect(model.canStep, isTrue);
    final before = cases.queries.length;
    await model.step(1);
    expect(cases.queries, hasLength(before));
  });

  test('loads the cash flow and the holdings of the viewed period', () async {
    model.beginVisit();
    await model.load(const ReportPeriodQuery.week());
    expect(cases.flows.single.from, '2026-10-05');
    expect(cases.holdingsAsked.single.to, '2026-10-11');
    expect(model.flow, isNotNull);
    expect(model.holdings, isNotNull);
    // The next period asks again and replaces them.
    cases.report = _named(from: '2026-10-12', to: '2026-10-18');
    await model.load(const ReportPeriodQuery.week(on: '2026-10-12'));
    expect(cases.flows, hasLength(2));
    expect(cases.flows.last.from, '2026-10-12');
    expect(model.flow, isNotNull);
  });

  test('a failing flow or holdings hides only its own card', () async {
    cases.flowFailure = const AuthFailure(AuthError.network);
    model.beginVisit();
    await model.load(const ReportPeriodQuery.week());
    expect(model.data, isNotNull);
    expect(model.failure, isNull);
    expect(model.flow, isNull);
    expect(model.holdings, isNotNull);
    expect(model.trend, isNotNull);
    cases.flowFailure = null;
    cases.holdingsFailure = const AuthFailure(AuthError.network);
    await model.load(const ReportPeriodQuery.week());
    expect(model.flow, isNotNull);
    expect(model.holdings, isNull);
    expect(model.previous, isNotNull);
  });

  test('a custom range is not compared with the period before it', () async {
    cases.report = _named(kind: ReportPeriodKind.range);
    model.beginVisit();
    await model.applyRange('2026-10-05', '2026-10-11');
    expect(cases.previous, isEmpty);
    expect(model.previous, isNull);
    expect(model.summary?.incomeChangeBps, isNull);
    expect(model.summary?.expenseChangeBps, isNull);
    // The cash flow and the holdings still follow the range.
    expect(cases.flows.single.kind, ReportPeriodKind.range);
    expect(cases.holdingsAsked.single.kind, ReportPeriodKind.range);
  });

  test('the trend follows the viewed kind', () async {
    model.beginVisit();
    await model.select(ReportPeriodKind.year);
    expect(model.trendKind, ReportPeriodKind.year);
    expect(cases.trends.last.$1, ReportPeriodKind.year);
  });

  test('keeps a chosen currency only while it has data', () async {
    cases.report = NamedCashflow(
      currencies: const [WalletCurrency('VND', 0), WalletCurrency('USD', 2)],
      report: CashflowReport(
        period: _named().report.period,
        totals: [
          CashflowTotal(
            currency: 'USD',
            incomeMinor: BigInt.one,
            expenseMinor: BigInt.zero,
            netMinor: BigInt.one,
          ),
          ..._named().report.totals,
        ],
        byCategory: const [],
        byAccount: const [],
      ),
    );
    model.beginVisit();
    await model.load(const ReportPeriodQuery.week());
    expect(model.currencies, ['USD', 'VND']);
    expect(model.currency, 'VND');
    model.selectCurrency('USD');
    expect(model.currency, 'USD');
    cases.report = _named();
    await model.load(const ReportPeriodQuery.week());
    expect(model.currency, 'VND');
  });

  test('retry after a failure asks for the same period again', () async {
    cases.failure = const AuthFailure(AuthError.network);
    model.beginVisit();
    await model.load(const ReportPeriodQuery.year());
    expect(model.data, isNull);
    cases.failure = null;
    await model.reload();
    expect(cases.queries.last.kind, ReportPeriodKind.year);
    expect(model.data, isNotNull);
  });

  test('an expired session signs the user out', () async {
    cases.failure = const AuthFailure(AuthError.expired);
    model.beginVisit();
    await model.load(const ReportPeriodQuery.month());
    expect(auth.stage, AuthStage.signedOut);
    expect(model.data, isNull);
    expect(analytics.events, isEmpty);
  });
}

NamedCashflow _named({
  String from = '2026-10-05',
  String to = '2026-10-11',
  ReportPeriodKind kind = ReportPeriodKind.week,
}) => NamedCashflow(
  currencies: const [WalletCurrency('VND', 0)],
  report: CashflowReport(
    period: ReportPeriod(
      kind: kind,
      from: from,
      to: to,
      timezone: 'Asia/Ho_Chi_Minh',
      fiscalMonthStartDay: 1,
    ),
    totals: [
      CashflowTotal(
        currency: 'VND',
        incomeMinor: BigInt.from(1000),
        expenseMinor: BigInt.from(-200),
        netMinor: BigInt.from(800),
      ),
    ],
    byCategory: const [],
    byAccount: const [],
  ),
);

class _Cases implements ReportUseCases {
  final queries = <ReportPeriodQuery>[];
  NamedCashflow report = _named();
  AuthFailure? failure;
  AuthFailure? trendFailure;
  AuthFailure? flowFailure;
  AuthFailure? holdingsFailure;
  Completer<void>? gate;
  final trends = <(ReportPeriodKind, String?)>[];
  final previous = <ReportPeriod>[];
  final flows = <ReportPeriod>[];
  final holdingsAsked = <ReportPeriod>[];

  @override
  Future<Either<AuthFailure, NamedCashflow>> loadCashflow(
    ReportPeriodQuery query,
  ) async {
    queries.add(query);
    final pending = gate;
    if (pending != null) await pending.future;
    final error = failure;
    if (error != null) return left(error);
    return right(report);
  }

  @override
  Future<Either<AuthFailure, CashflowReport>> loadPrevious(
    ReportPeriod period,
  ) async {
    previous.add(period);
    return right(report.report);
  }

  @override
  Future<Either<AuthFailure, FlowReport>> loadFlow(ReportPeriod period) async {
    flows.add(period);
    final error = flowFailure;
    if (error != null) return left(error);
    return right(
      FlowReport(
        kind: period.kind,
        from: period.from,
        to: period.to,
        granularity: FlowGranularity.day,
        buckets: const [],
      ),
    );
  }

  @override
  Future<Either<AuthFailure, HoldingsReport>> loadHoldings(
    ReportPeriod period,
  ) async {
    holdingsAsked.add(period);
    final error = holdingsFailure;
    if (error != null) return left(error);
    return right(
      HoldingsReport(
        kind: period.kind,
        from: period.from,
        to: period.to,
        debt: const [],
        investments: const [],
        nextLoanDue: const [],
      ),
    );
  }

  @override
  Future<Either<AuthFailure, NamedMonthReview>> loadMonthReview({
    String? on,
  }) async => left(const AuthFailure(AuthError.unavailable));

  @override
  Future<Either<AuthFailure, TrendReport>> loadTrend(
    ReportPeriodKind kind, {
    String? on,
  }) async {
    trends.add((kind, on));
    final error = trendFailure;
    if (error != null) return left(error);
    return right(TrendReport(kind: kind, buckets: const []));
  }
}

class _Analytics implements AnalyticsService {
  final events = <Map<String, Object>>[];

  @override
  void track(AnalyticsEvent event) => events.add(event.toPayload());
}
