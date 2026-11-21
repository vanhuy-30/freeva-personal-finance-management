import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/reports/data/report_repository_impl.dart';
import 'package:mobile/features/reports/domain/report.dart';
import 'package:mobile/features/reports/domain/report_flow.dart';
import 'package:mobile/features/reports/domain/report_period.dart';

BigInt b(int v) => BigInt.from(v);

TrendBucket day(
  String d, {
  int income = 0,
  int expense = 0,
  String cur = 'VND',
}) => TrendBucket(
  from: d,
  to: d,
  totals: income == 0 && expense == 0
      ? const []
      : [
          TrendTotal(
            currency: cur,
            incomeMinor: b(income),
            expenseMinor: b(-expense),
          ),
        ],
);

FlowReport flowOf(
  List<TrendBucket> buckets, {
  FlowGranularity g = FlowGranularity.day,
}) => FlowReport(
  kind: ReportPeriodKind.month,
  from: '2026-11-01',
  to: '2026-11-30',
  granularity: g,
  buckets: buckets,
);

void main() {
  group('flowSeries', () {
    test('adds up what moved and keeps empty days as flat points', () {
      final s = flowSeries(
        flowOf([
          day('2026-11-01', expense: 300),
          day('2026-11-02'),
          day('2026-11-03', income: 1000, expense: 100),
          day('2026-11-04', expense: 200),
        ]),
        'VND',
      );
      expect(s.points.map((p) => p.cumulative), [
        b(-300),
        b(-300),
        b(600),
        b(400),
      ]);
      expect(s.points[2].net, b(900));
      expect(s.high, b(600));
      expect(s.low, b(-300));
      expect(s.last, b(400));
      expect(s.isEmpty, isFalse);
      expect(s.biggestIncome?.from, '2026-11-03');
      expect(s.biggestExpense?.from, '2026-11-01');
    });

    test(
      'keeps zero inside the axis when everything is negative or positive',
      () {
        final spent = flowSeries(
          flowOf([
            day('2026-11-01', expense: 100),
            day('2026-11-02', expense: 50),
          ]),
          'VND',
        );
        expect(spent.high, BigInt.zero);
        expect(spent.low, b(-150));
        expect(spent.biggestIncome, isNull);
        expect(spent.isEmpty, isFalse);
        final earned = flowSeries(
          flowOf([
            day('2026-11-01', income: 100),
            day('2026-11-02', income: 50),
          ]),
          'VND',
        );
        expect(earned.low, BigInt.zero);
        expect(earned.high, b(150));
        expect(earned.biggestExpense, isNull);
      },
    );

    test(
      'is empty with no buckets, no activity or no activity in that currency',
      () {
        expect(flowSeries(flowOf(const []), 'VND').isEmpty, isTrue);
        expect(flowSeries(flowOf(const []), 'VND').last, BigInt.zero);
        expect(
          flowSeries(
            flowOf([day('2026-11-01'), day('2026-11-02')]),
            'VND',
          ).isEmpty,
          isTrue,
        );
        final usd = flowSeries(
          flowOf([day('2026-11-01', income: 5, cur: 'USD')]),
          'VND',
        );
        expect(usd.isEmpty, isTrue);
        expect(usd.points, hasLength(1));
        expect(usd.high, BigInt.zero);
        expect(usd.low, BigInt.zero);
      },
    );

    test('a single point and money past int64 stay exact', () {
      final one = flowSeries(flowOf([day('2026-11-01', income: 7)]), 'VND');
      expect(one.points, hasLength(1));
      expect(one.high, b(7));
      final huge = BigInt.parse('9223372036854775808');
      final big = flowSeries(
        flowOf([
          TrendBucket(
            from: '2026-11-01',
            to: '2026-11-01',
            totals: [
              TrendTotal(
                currency: 'VND',
                incomeMinor: huge,
                expenseMinor: BigInt.zero,
              ),
            ],
          ),
          day('2026-11-02', expense: 1),
        ]),
        'VND',
      );
      expect(big.last, huge - BigInt.one);
    });

    test('breaks ties toward the earlier bucket', () {
      final s = flowSeries(
        flowOf([
          day('2026-11-01', expense: 100),
          day('2026-11-02', expense: 100),
        ]),
        'VND',
      );
      expect(s.biggestExpense?.from, '2026-11-01');
    });

    test('keeps the granularity for the labels', () {
      expect(
        flowSeries(
          flowOf(const [], g: FlowGranularity.month),
          'VND',
        ).granularity,
        FlowGranularity.month,
      );
    });
  });

  group('parsing flow and holdings', () {
    test('parses a flow report and asks for the same period', () async {
      final api = _Api()
        ..json = {
          'period': {'kind': 'month', 'from': '2026-11-01', 'to': '2026-11-30'},
          'granularity': 'day',
          'buckets': [
            {
              'from': '2026-11-01',
              'to': '2026-11-01',
              'totals': [
                {
                  'currency': 'VND',
                  'incomeMinor': '26000000',
                  'expenseMinor': '-500000',
                },
              ],
            },
            {'from': '2026-11-02', 'to': '2026-11-02', 'totals': <Object>[]},
          ],
        };
      final repo = ReportRepositoryImpl(api);
      final flow = (await repo.flow(
        const ReportPeriodQuery.month(on: '2026-11-01'),
      )).getOrElse(() => throw StateError('parse'));
      expect(api.paths.single, 'reports/flow?period=month&on=2026-11-01');
      expect(flow.granularity, FlowGranularity.day);
      expect(flow.buckets, hasLength(2));
      expect(flow.buckets.first.totals.single.expenseMinor, b(-500000));
      expect(flow.buckets.last.totals, isEmpty);
      await repo.flow(
        const ReportPeriodQuery.range('2026-10-01', '2026-10-31'),
      );
      expect(
        api.paths.last,
        'reports/flow?period=range&from=2026-10-01&to=2026-10-31',
      );
    });

    test(
      'rejects a bad flow: unknown granularity, a JSON number, a bad date',
      () async {
        for (final bad in [
          {'granularity': 'hour', 'buckets': <Object>[]},
          {
            'granularity': 'day',
            'buckets': [
              {
                'from': '2026-11-01',
                'to': '2026-11-01',
                'totals': [
                  {'currency': 'VND', 'incomeMinor': 5, 'expenseMinor': '0'},
                ],
              },
            ],
          },
          {
            'granularity': 'day',
            'buckets': [
              {'from': '2026-13-01', 'to': '2026-11-01', 'totals': <Object>[]},
            ],
          },
        ]) {
          final api = _Api()
            ..json = {
              'period': {
                'kind': 'month',
                'from': '2026-11-01',
                'to': '2026-11-30',
              },
              ...bad,
            };
          final result = await ReportRepositoryImpl(api)
              .flow(const ReportPeriodQuery.month());
          expect(
            result.fold((e) => e.code, (_) => null),
            AuthError.unavailable,
          );
        }
      },
    );

    test('parses holdings, null rate and null installment included', () async {
      final api = _Api()
        ..json = {
          'period': {'kind': 'month', 'from': '2026-11-01', 'to': '2026-11-30'},
          'debt': [
            {
              'currency': 'VND',
              'startMinor': '108000000',
              'endMinor': '103000000',
              'changeMinor': '-5000000',
              'paidMinor': '13000000',
              'borrowedMinor': '8000000',
            },
          ],
          'investments': [
            {
              'currency': 'VND',
              'startValueMinor': '80000000',
              'endValueMinor': '48000000',
              'investedMinor': '0',
              'withdrawnMinor': '32000000',
              'pnlMinor': '-1350000',
              'pnlBps': null,
            },
          ],
          'nextLoanDue': [
            {'currency': 'VND', 'dueOn': '2026-12-05', 'amountMinor': null},
          ],
        };
      final h = (await ReportRepositoryImpl(api).holdings(
        const ReportPeriodQuery.week(),
      )).getOrElse(() => throw StateError('parse'));
      expect(api.paths.single, 'reports/holdings?period=week');
      expect(h.debtOf('VND')?.change, b(-5000000));
      expect(h.debtOf('VND')?.borrowed, b(8000000));
      expect(h.debtOf('USD'), isNull);
      expect(h.investOf('VND')?.pnl, b(-1350000));
      expect(h.investOf('VND')?.pnlBps, isNull);
      expect(h.dueOf('VND')?.amount, isNull);
      expect(h.dueOf('VND')?.dueOn, '2026-12-05');
    });

    test(
      'reads wallet balances from the cashflow and tolerates their absence',
      () async {
        final base = {
          'period': {
            'kind': 'month',
            'from': '2026-11-01',
            'to': '2026-11-30',
            'timezone': 'Asia/Ho_Chi_Minh',
            'fiscalMonthStartDay': 1,
          },
          'totals': <Object>[],
          'byCategory': <Object>[],
          'byAccount': <Object>[],
        };
        final api = _Api()
          ..json = {
            ...base,
            'walletBalances': [
              {
                'currency': 'VND',
                'endMinor': '48250000',
                'previousEndMinor': '41639000',
              },
            ],
          };
        final repo = ReportRepositoryImpl(api);
        final with_ = (await repo.cashflow(const ReportPeriodQuery.month()))
            .getOrElse(() => throw StateError('parse'));
        expect(with_.walletBalances.single.endMinor, b(48250000));
        expect(with_.walletBalances.single.previousEndMinor, b(41639000));
        api.json = base;
        final without = (await repo.cashflow(const ReportPeriodQuery.month()))
            .getOrElse(() => throw StateError('parse'));
        expect(without.walletBalances, isEmpty);
      },
    );
  });

  group('periodLength and queryOf', () {
    test('count inclusive days and rebuild the query of a period', () {
      const month = ReportPeriod(
        kind: ReportPeriodKind.month,
        from: '2026-11-01',
        to: '2026-11-30',
        timezone: 'UTC',
        fiscalMonthStartDay: 1,
      );
      expect(periodLength(month), 30);
      expect(queryOf(month).kind, ReportPeriodKind.month);
      expect(queryOf(month).on, '2026-11-01');
      const range = ReportPeriod(
        kind: ReportPeriodKind.range,
        from: '2026-10-06',
        to: '2026-10-19',
        timezone: 'UTC',
        fiscalMonthStartDay: 1,
      );
      expect(periodLength(range), 14);
      expect(queryOf(range).from, '2026-10-06');
      expect(queryOf(range).to, '2026-10-19');
      expect(queryOf(range).on, isNull);
    });
  });
}

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
