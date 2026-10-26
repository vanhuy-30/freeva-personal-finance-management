import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/money/compact_money.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/reports/data/report_repository_impl.dart';
import 'package:mobile/features/reports/domain/report.dart';
import 'package:mobile/features/reports/domain/report_breakdown.dart';
import 'package:mobile/features/reports/domain/report_period.dart';
import 'package:mobile/features/reports/domain/report_summary.dart';
import 'package:mobile/features/reports/domain/report_trend.dart';

BigInt b(int v) => BigInt.from(v);

ReportPeriod month(String from, String to) => ReportPeriod(
  kind: ReportPeriodKind.month,
  from: from,
  to: to,
  timezone: 'Asia/Ho_Chi_Minh',
  fiscalMonthStartDay: 1,
);

CashflowTotal total(int income, int expense, {String currency = 'VND'}) =>
    CashflowTotal(
      currency: currency,
      incomeMinor: b(income),
      expenseMinor: b(-expense),
      netMinor: b(income - expense),
    );

CashflowReport report(
  List<CashflowTotal> totals, {
  List<CashflowCategoryRow> rows = const [],
  ReportPeriod? period,
}) => CashflowReport(
  period: period ?? month('2026-10-01', '2026-10-31'),
  totals: totals,
  byCategory: rows,
  byAccount: const [],
);

CashflowCategoryRow row(
  String? id,
  String? name,
  int expense, {
  String? parent,
  String? parentName,
  int income = 0,
  int count = 1,
}) => CashflowCategoryRow(
  categoryId: id,
  parentId: parent,
  currency: 'VND',
  incomeMinor: b(income),
  expenseMinor: b(-expense),
  transactionCount: count,
  name: name,
  parentName: parentName,
);

void main() {
  group('summary figures', () {
    test(
      'average per day divides by days passed, then by the whole period',
      () {
        final p = month('2026-10-01', '2026-10-31');
        expect(averagePerDay(b(9320000), p, '2026-10-21'), b(443810));
        expect(averagePerDay(b(3100), p, '2026-11-20'), b(100));
        expect(averagePerDay(b(100), p, '2026-10-01'), b(100));
        expect(averagePerDay(b(100), p, '2026-09-30'), isNull);
      },
    );

    test('change rounds half away from zero and needs a previous expense', () {
      expect(expenseChange(b(9320000), b(9900000)), -6);
      expect(expenseChange(b(150), b(100)), 50);
      expect(expenseChange(b(1), b(8)), -88);
      expect(expenseChange(b(5), b(0)), isNull);
      expect(expenseChange(b(100), b(100)), 0);
    });

    test('summary reads one currency and leaves the others alone', () {
      final current = report([
        total(18500000, 9320000),
        total(50, 5, currency: 'USD'),
      ]);
      final before = report([total(0, 9900000)]);
      final vnd = reportSummary(current, 'VND', '2026-10-31', previous: before);
      expect(vnd.income, b(18500000));
      expect(vnd.remaining, b(9180000));
      expect(vnd.expenseChange, -6);
      final usd = reportSummary(current, 'USD', '2026-10-31', previous: before);
      expect(usd.expenseChange, isNull);
      expect(
        reportSummary(current, 'EUR', '2026-10-31').remaining,
        BigInt.zero,
      );
    });

    test('picks the chosen currency, then the profile one, then the first', () {
      expect(pickCurrency(['USD', 'VND'], 'USD', 'VND'), 'USD');
      expect(pickCurrency(['USD', 'VND'], 'EUR', 'VND'), 'VND');
      expect(pickCurrency(['USD'], null, 'VND'), 'USD');
      expect(pickCurrency(const [], null, 'VND'), isNull);
    });
  });

  group('periods', () {
    test('steps a year and finds the previous range by its own length', () {
      const year = ReportPeriod(
        kind: ReportPeriodKind.year,
        from: '2026-01-01',
        to: '2026-12-31',
        timezone: 'UTC',
        fiscalMonthStartDay: 1,
      );
      expect(adjacentPeriod(year, -1)?.kind, ReportPeriodKind.year);
      expect(adjacentPeriod(year, -1)?.on, '2025-12-31');
      const range = ReportPeriod(
        kind: ReportPeriodKind.range,
        from: '2026-10-06',
        to: '2026-10-19',
        timezone: 'UTC',
        fiscalMonthStartDay: 1,
      );
      final before = previousPeriod(range)!;
      expect(before.from, '2026-09-22');
      expect(before.to, '2026-10-05');
      expect(
        previousPeriod(month('2026-10-01', '2026-10-31'))?.on,
        '2026-09-30',
      );
    });

    test('next is locked once the period holds or passes today', () {
      final p = month('2026-10-01', '2026-10-31');
      expect(reachesToday(p, '2026-10-23'), isTrue);
      expect(reachesToday(p, '2026-10-31'), isTrue);
      expect(reachesToday(p, '2026-11-01'), isFalse);
      expect(calendarDate(DateTime(2026, 3, 4)), '2026-03-04');
    });
  });

  group('breakdown', () {
    final rows = [
      row(
        'coffee',
        'Cà phê',
        1500,
        parent: 'food',
        parentName: 'Ăn uống',
        count: 3,
      ),
      row(
        'lunch',
        'Ăn trưa',
        2500,
        parent: 'food',
        parentName: 'Ăn uống',
        count: 2,
      ),
      row('rent', 'Nhà ở', 2400),
      row('bus', 'Đi lại', 1800),
      row('misc', 'Linh tinh', 900),
      row('gift', 'Quà', 600),
      row(null, null, 0, income: 5000),
    ];

    test('rolls leaves up to parents, keeps three and folds the rest', () {
      final result = reportBreakdown(
        report(const [], rows: rows),
        'VND',
        BreakdownKind.expense,
      );
      expect(result.total, b(9700));
      expect(
        [for (final s in result.slices) s.name],
        ['Ăn uống', 'Nhà ở', 'Đi lại', null],
      );
      expect(result.slices.first.minor, b(4000));
      expect(result.slices.first.transactionCount, 5);
      expect(result.slices.last.categoryCount, 2);
      expect(result.slices.last.minor, b(1500));
      expect(result.slices.fold(0, (a, s) => a + s.percent), 100);
    });

    test('uncategorised income is "Khác"; other currencies are skipped', () {
      final income = reportBreakdown(
        report(const [], rows: rows),
        'VND',
        BreakdownKind.income,
      );
      expect(income.slices.single.isOther, isTrue);
      expect(income.slices.single.percent, 100);
      final none = reportBreakdown(
        report(const [], rows: rows),
        'USD',
        BreakdownKind.expense,
      );
      expect(none.slices, isEmpty);
      expect(none.total, BigInt.zero);
    });
  });

  group('trend', () {
    test('marks the last bar and averages every bar', () {
      TrendBucket bucket(String from, int expense) => TrendBucket(
        from: from,
        to: from,
        totals: [
          TrendTotal(
            currency: 'VND',
            incomeMinor: b(0),
            expenseMinor: b(-expense),
          ),
        ],
      );
      final series = trendSeries(
        TrendReport(
          kind: ReportPeriodKind.month,
          buckets: [
            bucket('2026-08-01', 300),
            bucket('2026-09-01', 0),
            bucket('2026-10-01', 400),
          ],
        ),
        'VND',
      );
      expect(series.bars.map((e) => e.current), [false, false, true]);
      expect(series.peak, b(400));
      expect(series.average, b(233));
      expect(
        trendSeries(
          const TrendReport(kind: ReportPeriodKind.week, buckets: []),
          'VND',
        ).average,
        BigInt.zero,
      );
    });
  });

  group('compact money', () {
    const units = CompactUnits(thousand: 'k', million: 'tr', billion: 'tỷ');
    String short(int minor, [int digits = 0]) =>
        compactMoney(b(minor), digits, 'vi', units);

    test('keeps three significant digits', () {
      expect(short(9320000), '9,32tr');
      expect(short(10600000), '10,6tr');
      expect(short(7800000), '7,8tr');
      expect(short(450000), '450k');
      expect(short(1250000000), '1,25tỷ');
      expect(short(999), '999');
      expect(short(-2000000), '2tr');
    });

    test('rolls 999.9k up and reads minor digits', () {
      expect(short(999950), '1tr');
      expect(short(1250000, 2), '12,5k');
    });
  });

  test('parses the trend response and category counts', () async {
    final api = _Api({
      'reports/trend?period=month&on=2026-10-31': {
        'kind': 'month',
        'buckets': [
          {
            'from': '2026-10-01',
            'to': '2026-10-31',
            'totals': [
              {'currency': 'VND', 'incomeMinor': '5', 'expenseMinor': '-7'},
            ],
          },
        ],
      },
    });
    final result = await ReportRepositoryImpl(api)
        .trend(ReportPeriodKind.month, on: '2026-10-31');
    final trend = result.getOrElse(() => throw StateError('failed'));
    expect(trend.buckets.single.expenseOf('VND'), b(7));
    expect(trend.buckets.single.expenseOf('USD'), BigInt.zero);
    final broken = await ReportRepositoryImpl(_Api({}))
        .trend(ReportPeriodKind.week);
    expect(broken.isLeft(), isTrue);
  });
}

class _Api implements AuthorizedApi {
  _Api(this.responses);

  final Map<String, Map<String, dynamic>> responses;

  @override
  Future<Either<AuthFailure, Map<String, dynamic>>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final json = responses[path];
    return json == null
        ? left(const AuthFailure(AuthError.unavailable))
        : right(json);
  }
}
