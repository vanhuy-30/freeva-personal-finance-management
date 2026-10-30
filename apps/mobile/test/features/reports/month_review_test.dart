import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/authorized_api.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/categories/domain/category_repository.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/reports/data/report_repository_impl.dart';
import 'package:mobile/features/reports/domain/month_review_format.dart';
import 'package:mobile/features/reports/domain/report.dart';
import 'package:mobile/features/reports/domain/report_repository.dart';
import 'package:mobile/features/reports/domain/report_use_cases.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/domain/wallet_repository.dart';

void main() {
  test('formats savings rate from integer basis points', () {
    expect(formatSavingsRateBps(3933, 'en'), '39.33%');
    expect(formatSavingsRateBps(3933, 'vi'), '39,33%');
    expect(formatSavingsRateBps(4000, 'en'), '40%');
    expect(formatSavingsRateBps(-250, 'en'), '−2.50%');
  });

  test('parses month review money as strings and rejects JSON numbers', () async {
    final api = _Api()
      ..json = {
        'period': {
          'kind': 'month',
          'from': '2026-09-15',
          'to': '2026-10-14',
          'timezone': 'Asia/Ho_Chi_Minh',
          'fiscalMonthStartDay': 15,
        },
        'currencies': [
          {
            'currency': 'VND',
            'incomeMinor': '3000',
            'expenseMinor': '-1170',
            'savingsMinor': '1830',
            'savingsRateBps': 6100,
            'topCategories': [
              {
                'categoryId': 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
                'parentId': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
                'expenseMinor': '-700',
                'transactionCount': 2,
              },
            ],
          },
        ],
      };
    final ok = await ReportRepositoryImpl(api).monthReview(on: '2026-10-08');
    expect(ok.isRight(), isTrue);
    final review = ok.getOrElse(() => throw StateError('missing'));
    expect(review.period.from, '2026-09-15');
    expect(review.currencies.single.savingsMinor, BigInt.from(1830));
    expect(review.currencies.single.savingsRateBps, 6100);
    expect(
      review.currencies.single.topCategories.single.expenseMinor,
      BigInt.from(-700),
    );
    expect(api.paths.single, contains('reports/month-review'));

    final broken = await ReportRepositoryImpl(
      _Api()
        ..json = {
          'period': {
            'kind': 'month',
            'from': '2026-09-15',
            'to': '2026-10-14',
            'timezone': 'Asia/Ho_Chi_Minh',
            'fiscalMonthStartDay': 15,
          },
          'currencies': [
            {
              'currency': 'VND',
              'incomeMinor': 3000,
              'expenseMinor': '-1170',
              'savingsMinor': '1830',
              'savingsRateBps': 6100,
              'topCategories': <Object>[],
            },
          ],
        },
    ).monthReview();
    expect(broken.fold((e) => e.code, (_) => null), AuthError.unavailable);
  });

  test('names categories and never recomputes savings on the client', () async {
    const housing = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
    const parent = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    final reports = _Reports()
      ..review = MonthReviewReport(
        period: const ReportPeriod(
          kind: ReportPeriodKind.month,
          from: '2026-09-15',
          to: '2026-10-14',
          timezone: 'Asia/Ho_Chi_Minh',
          fiscalMonthStartDay: 15,
        ),
        currencies: [
          MonthReviewCurrency(
            currency: 'VND',
            incomeMinor: BigInt.from(3000),
            expenseMinor: BigInt.from(-700),
            savingsMinor: BigInt.from(2300),
            savingsRateBps: 7666,
            topCategories: [
              MonthReviewCategory(
                categoryId: housing,
                parentId: parent,
                expenseMinor: BigInt.from(-700),
                transactionCount: 1,
              ),
            ],
          ),
        ],
      );
    final wallets = _Wallets()..codes = const [WalletCurrency('VND', 0)];
    final categories = _Categories()
      ..items = const [
        FinanceCategory(id: parent, name: 'Sinh hoạt', parentId: null),
        FinanceCategory(id: housing, name: 'Nhà ở', parentId: parent),
      ];
    final named = await DefaultReportUseCases(
      reports,
      wallets,
      categories,
    ).loadMonthReview(on: '2026-10-08');
    expect(named.isRight(), isTrue);
    final row = named
        .getOrElse(() => throw StateError('missing'))
        .report
        .currencies
        .single;
    expect(row.savingsMinor, BigInt.from(2300));
    expect(row.savingsRateBps, 7666);
    expect(row.topCategories.single.name, 'Nhà ở');
    expect(row.topCategories.single.parentName, 'Sinh hoạt');
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

class _Reports implements ReportRepository {
  MonthReviewReport? review;

  @override
  Future<Either<AuthFailure, CashflowReport>> cashflow(
    ReportPeriodQuery query,
  ) async => left(const AuthFailure(AuthError.unavailable));

  @override
  Future<Either<AuthFailure, MonthReviewReport>> monthReview({
    String? on,
  }) async => right(review!);

  @override
  Future<Either<AuthFailure, TrendReport>> trend(
    ReportPeriodKind kind, {
    String? on,
  }) async => left(const AuthFailure(AuthError.unavailable));

  @override
  Future<Either<AuthFailure, NetWorthReport>> netWorth() async =>
      left(const AuthFailure(AuthError.unavailable));
}

class _Wallets implements WalletRepository {
  List<WalletCurrency> codes = const [];

  @override
  Future<Either<AuthFailure, List<Wallet>>> load() async => right(const []);

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

  @override
  Future<Either<AuthFailure, List<Wallet>>> reorder(List<Wallet> active) =>
      throw UnimplementedError();
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

  @override
  Future<Either<AuthFailure, int>> usage(FinanceCategory category) =>
      throw UnimplementedError();
}
