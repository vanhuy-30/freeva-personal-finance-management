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
import 'package:mobile/features/reports/domain/report_use_cases.dart';
import 'package:mobile/features/reports/presentation/viewmodels/report_view_model.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';

import '../auth/fakes.dart';

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
              AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics()),
            ),
          )
          ..stage = AuthStage.unlocked
          ..ready = true;
    model = DefaultReportViewModel(cases, auth, analytics);
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

  test('an expired session signs the user out', () async {
    cases.failure = const AuthFailure(AuthError.expired);
    model.beginVisit();
    await model.load(const ReportPeriodQuery.month());
    expect(auth.stage, AuthStage.signedOut);
    expect(model.data, isNull);
    expect(analytics.events, isEmpty);
  });
}

NamedCashflow _named({String from = '2026-10-05', String to = '2026-10-11'}) =>
    NamedCashflow(
      currencies: const [WalletCurrency('VND', 0)],
      report: CashflowReport(
        period: ReportPeriod(
          kind: ReportPeriodKind.week,
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
  Completer<void>? gate;

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
  Future<Either<AuthFailure, OverviewSnapshot>> loadOverview() =>
      throw UnimplementedError();
}

class _Analytics implements AnalyticsService {
  final events = <Map<String, Object>>[];

  @override
  void track(AnalyticsEvent event) => events.add(event.toPayload());
}
