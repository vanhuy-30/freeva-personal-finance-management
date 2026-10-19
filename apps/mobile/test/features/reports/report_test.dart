import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/categories/domain/category_repository.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/reports/data/report_repository_impl.dart';
import 'package:mobile/features/reports/domain/report.dart';
import 'package:mobile/features/reports/domain/report_period.dart';
import 'package:mobile/features/reports/domain/report_repository.dart';
import 'package:mobile/features/reports/domain/report_use_cases.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/domain/wallet_repository.dart';

void main() {
  test('rejects an impossible day and a range past 3660 days', () {
    expect(isCalendarDate('2024-02-29'), isTrue);
    expect(isCalendarDate('2023-02-29'), isFalse);
    expect(shiftCalendarDate('0001-01-01', -1), isNull);
    expect(shiftCalendarDate('9999-12-31', 1), isNull);
    const from = '2026-01-01';
    final edge = shiftCalendarDate(from, maxReportRangeDays)!;
    final past = shiftCalendarDate(from, maxReportRangeDays + 1)!;
    expect(invalidPeriod(ReportPeriodQuery.range(from, edge)), isNull);
    expect(
      invalidPeriod(ReportPeriodQuery.range(from, past))?.code,
      AuthError.invalidInput,
    );
    expect(
      invalidPeriod(ReportPeriodQuery.range(edge, from))?.code,
      AuthError.invalidInput,
    );
    expect(daysApart(from, edge), maxReportRangeDays);
  });

  test('steps a week from the server bounds', () {
    const period = ReportPeriod(
      kind: ReportPeriodKind.week,
      from: '2026-10-05',
      to: '2026-10-11',
      timezone: 'Asia/Ho_Chi_Minh',
      fiscalMonthStartDay: 15,
    );
    expect(adjacentPeriod(period, 1)?.on, '2026-10-12');
    expect(adjacentPeriod(period, -1)?.on, '2026-10-04');
    expect(
      adjacentPeriod(
        const ReportPeriod(
          kind: ReportPeriodKind.week,
          from: '9999-12-25',
          to: '9999-12-31',
          timezone: 'UTC',
          fiscalMonthStartDay: 1,
        ),
        1,
      ),
      isNull,
    );
  });

  test('does not call the API for an invalid range', () async {
    final reports = _Reports();
    final cases = DefaultReportUseCases(reports, _Wallets(), _Categories());
    final result = await cases.loadCashflow(
      const ReportPeriodQuery.range('2026-02-01', '2026-01-01'),
    );
    expect(
      result.fold((error) => error.code, (_) => null),
      AuthError.invalidInput,
    );
    expect(reports.cashflowCalls, 0);
  });

  test(
    'overview asks for the current month and keeps currencies apart',
    () async {
      final reports = _Reports()
        ..cashflowReport = _flow()
        ..worth = _worth();
      final wallets = _Wallets()
        ..codes = const [WalletCurrency('VND', 0), WalletCurrency('USD', 2)];
      final cases = DefaultReportUseCases(reports, wallets, _Categories());
      final result = await cases.loadOverview();
      final snapshot = result.getOrElse(() => throw StateError('overview'));
      expect(reports.queries.single.kind, ReportPeriodKind.month);
      expect(reports.queries.single.on, isNull);
      expect(snapshot.netWorth.items.map((row) => row.currency), [
        'VND',
        'USD',
      ]);
      expect(snapshot.netWorth.items.first.assetsMinor, BigInt.from(1500000));
      expect(snapshot.netWorth.items.last.assetsMinor, BigInt.from(2000));
    },
  );

  test('names leaves without rolling them into the parent', () async {
    final reports = _Reports()..cashflowReport = _flow();
    final wallets = _Wallets()
      ..items = [_wallet('cash', 'Tiền mặt'), _wallet('usd', 'Ngoại tệ')]
      ..codes = const [WalletCurrency('VND', 0), WalletCurrency('USD', 2)];
    final categories = _Categories()
      ..items = [
        const FinanceCategory(id: 'food', name: 'Ăn uống', parentId: null),
        const FinanceCategory(id: 'coffee', name: 'Cà phê', parentId: 'food'),
      ];
    final cases = DefaultReportUseCases(reports, wallets, categories);
    final named = (await cases.loadCashflow(const ReportPeriodQuery.month()))
        .getOrElse(() => throw StateError('cashflow'));
    final coffee = named.report.byCategory.where(
      (row) => row.categoryId == 'coffee',
    );
    expect(coffee.map((row) => row.name), everyElement('Cà phê'));
    expect(coffee.map((row) => row.parentName), everyElement('Ăn uống'));
    expect(coffee.map((row) => row.currency), ['VND', 'USD']);
    final open = named.report.byCategory.singleWhere(
      (row) => row.categoryId == null,
    );
    expect(open.name, isNull);
    expect(named.report.byAccount.map((row) => row.name), [
      'Tiền mặt',
      'Ngoại tệ',
    ]);
  });

  test('missing category name fails closed', () async {
    final reports = _Reports()..cashflowReport = _flow();
    final wallets = _Wallets()
      ..items = [_wallet('cash', 'Tiền mặt'), _wallet('usd', 'Ngoại tệ')]
      ..codes = const [WalletCurrency('VND', 0), WalletCurrency('USD', 2)];
    final result = await DefaultReportUseCases(
      reports,
      wallets,
      _Categories(),
    ).loadCashflow(const ReportPeriodQuery.week());
    expect(
      result.fold((error) => error.code, (_) => null),
      AuthError.unavailable,
    );
  });

  test('parses money beyond int64 and rejects a JSON number', () async {
    final api = _Api()..json = _json(income: '9223372036854775808');
    final repo = ReportRepositoryImpl(api);
    final parsed = await repo.cashflow(const ReportPeriodQuery.month());
    expect(
      parsed
          .getOrElse(() => throw StateError('parse'))
          .totals
          .single
          .incomeMinor,
      BigInt.parse('9223372036854775808'),
    );
    expect(api.paths.single, 'reports/cashflow?period=month');
    api.json = _json(income: 1);
    final rejected = await repo.cashflow(
      const ReportPeriodQuery.range('2026-01-01', '2026-01-31'),
    );
    expect(
      rejected.fold((error) => error.code, (_) => null),
      AuthError.unavailable,
    );
    expect(
      api.paths.last,
      'reports/cashflow?period=range&from=2026-01-01&to=2026-01-31',
    );
  });
}

CashflowReport _flow() => CashflowReport(
  period: const ReportPeriod(
    kind: ReportPeriodKind.month,
    from: '2026-10-01',
    to: '2026-10-31',
    timezone: 'Asia/Ho_Chi_Minh',
    fiscalMonthStartDay: 1,
  ),
  totals: [
    CashflowTotal(
      currency: 'VND',
      incomeMinor: BigInt.from(1000000),
      expenseMinor: BigInt.from(-250000),
      netMinor: BigInt.from(750000),
    ),
    CashflowTotal(
      currency: 'USD',
      incomeMinor: BigInt.from(1050),
      expenseMinor: BigInt.from(-25),
      netMinor: BigInt.from(1025),
    ),
  ],
  byCategory: [
    CashflowCategoryRow(
      categoryId: null,
      parentId: null,
      currency: 'VND',
      incomeMinor: BigInt.from(1000000),
      expenseMinor: BigInt.zero,
    ),
    CashflowCategoryRow(
      categoryId: 'coffee',
      parentId: 'food',
      currency: 'VND',
      incomeMinor: BigInt.zero,
      expenseMinor: BigInt.from(-250000),
    ),
    CashflowCategoryRow(
      categoryId: 'coffee',
      parentId: 'food',
      currency: 'USD',
      incomeMinor: BigInt.from(1050),
      expenseMinor: BigInt.from(-25),
    ),
  ],
  byAccount: [
    CashflowAccountRow(
      accountId: 'cash',
      currency: 'VND',
      incomeMinor: BigInt.from(1000000),
      expenseMinor: BigInt.from(-250000),
      transferMinor: BigInt.zero,
      netMinor: BigInt.from(750000),
    ),
    CashflowAccountRow(
      accountId: 'usd',
      currency: 'USD',
      incomeMinor: BigInt.from(1050),
      expenseMinor: BigInt.from(-25),
      transferMinor: BigInt.from(100),
      netMinor: BigInt.from(1125),
    ),
  ],
);

NetWorthReport _worth() => NetWorthReport(
  items: [
    NetWorthTotal(
      currency: 'VND',
      assetsMinor: BigInt.from(1500000),
      liabilitiesMinor: BigInt.zero,
      netWorthMinor: BigInt.from(1500000),
    ),
    NetWorthTotal(
      currency: 'USD',
      assetsMinor: BigInt.from(2000),
      liabilitiesMinor: BigInt.from(-500),
      netWorthMinor: BigInt.from(1500),
    ),
  ],
);

Wallet _wallet(String id, String name) => Wallet(
  id: id,
  createdAt: DateTime.utc(2026),
  draft: WalletDraft(
    name: name,
    type: WalletType.cash,
    currency: 'VND',
    initialBalance: BigInt.zero,
  ),
  balance: BigInt.zero,
  version: 1,
  sortOrder: 0,
  archived: false,
);

Map<String, dynamic> _json({required Object income}) => {
  'period': {
    'kind': 'month',
    'from': '2026-10-01',
    'to': '2026-10-31',
    'timezone': 'Asia/Ho_Chi_Minh',
    'fiscalMonthStartDay': 1,
  },
  'totals': [
    {
      'currency': 'VND',
      'incomeMinor': income,
      'expenseMinor': '0',
      'netMinor': income is String ? income : '0',
    },
  ],
  'byCategory': <Object>[],
  'byAccount': <Object>[],
};

class _Reports implements ReportRepository {
  CashflowReport? cashflowReport;
  NetWorthReport? worth;
  final queries = <ReportPeriodQuery>[];
  int cashflowCalls = 0;

  @override
  Future<Either<AuthFailure, CashflowReport>> cashflow(
    ReportPeriodQuery query,
  ) async {
    cashflowCalls++;
    queries.add(query);
    return right(cashflowReport!);
  }

  @override
  Future<Either<AuthFailure, NetWorthReport>> netWorth() async => right(worth!);
}

class _Wallets implements WalletRepository {
  List<Wallet> items = const [];
  List<WalletCurrency> codes = const [];

  @override
  Future<Either<AuthFailure, List<Wallet>>> load() async => right(items);

  @override
  Future<Either<AuthFailure, List<WalletCurrency>>> currencies() async =>
      right(codes);

  @override
  Future<Either<AuthFailure, Wallet>> save(
    WalletDraft draft, {
    Wallet? wallet,
    required String clientId,
  }) => throw UnimplementedError();

  @override
  Future<Either<AuthFailure, Wallet>> update(
    Wallet wallet, {
    bool? archived,
    int? sortOrder,
  }) => throw UnimplementedError();
}

class _Categories implements CategoryRepository {
  List<FinanceCategory> items = const [];

  @override
  Future<Either<AuthFailure, CategoryManagement>> manage() async =>
      right(CategoryManagement(items: items, options: const CategoryOptions()));

  @override
  Future<Either<AuthFailure, CategoryCatalog>> load() =>
      throw UnimplementedError();

  @override
  Future<Either<AuthFailure, FinanceCategory>> save(
    CategoryDraft draft, {
    FinanceCategory? category,
    required String clientId,
  }) => throw UnimplementedError();

  @override
  Future<Either<AuthFailure, FinanceCategory>> update(
    FinanceCategory category, {
    required bool archived,
  }) => throw UnimplementedError();

  @override
  Future<Either<AuthFailure, void>> delete(
    FinanceCategory category, {
    String? replacementCategoryId,
  }) => throw UnimplementedError();
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
