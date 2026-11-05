import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/categories/presentation/viewmodels/category_view_model.dart';
import 'package:mobile/features/profile/domain/profile.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:mobile/features/recurring/domain/recurring_rule.dart';
import 'package:mobile/features/recurring/domain/recurring_use_cases.dart';
import 'package:mobile/features/recurring/presentation/viewmodels/recurring_view_model.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/transactions/domain/transaction_use_cases.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_view_model.dart';

import '../auth/fakes.dart';
import '../categories/e1_stub.dart' show StubCategoryViewModel;
import '../home/fixtures.dart' show b, wallet;
import '../profile/fakes.dart';
import '../wallets/d1_stub.dart' show StubWalletViewModel;

/// "Today" of the L artboards.
final recToday = DateTime(2026, 11, 3);

FinanceCategory _cat(String id, String name, String icon, String color) =>
    FinanceCategory(
      id: id,
      name: name,
      parentId: null,
      iconToken: icon,
      colorToken: color,
      createdAt: DateTime.utc(2026, 10, 1),
    );

List<FinanceCategory> recCategories() => [
  _cat('net', 'Internet', 'internet', 'color.brand.secondary'),
  _cat('power', 'Hóa đơn', 'electricity', 'color.semantic.warning'),
  _cat('school', 'Học phí', 'education', 'color.brand.accent'),
  _cat('home', 'Nhà ở', 'housing', 'color.brand.primary'),
  _cat('fun', 'Giải trí', 'entertainment', 'color.category.gray'),
];

RecurringRule rule(
  String id,
  String name, {
  String type = 'expense',
  String mode = 'auto',
  required int amount,
  required String next,
  String start = '2026-10-01',
  String? end,
  String? categoryId,
  bool active = true,
  bool overdue = false,
  String amountKind = 'fixed',
}) => RecurringRule(
  id: id,
  clientId: 'client-$id',
  type: type,
  unit: 'month',
  interval: 1,
  amountMinor: b(amount),
  currencyCode: 'VND',
  accountId: 'vcb',
  categoryId: categoryId,
  counterAccountId: null,
  counterAmountMinor: null,
  counterCurrencyCode: null,
  fxRate: null,
  startDate: start,
  endDate: end,
  nextExecutionDate: next,
  active: active,
  version: 1,
  mode: mode,
  name: name,
  amountKind: amountKind,
  remindDaysBefore: 3,
  overdue: overdue,
);

/// The six rows of RecList: three bills to pay, three that post on their own.
List<RecurringRule> canvasRules() => [
  rule(
    'net',
    'Internet',
    mode: 'remind',
    amount: -250000,
    next: '2026-10-30',
    categoryId: 'net',
    overdue: true,
  ),
  rule(
    'power',
    'Tiền điện',
    mode: 'remind',
    amount: -850000,
    next: '2026-11-05',
    categoryId: 'power',
    amountKind: 'estimated',
  ),
  rule(
    'school',
    'Học phí',
    mode: 'remind',
    amount: -6230000,
    next: '2026-11-15',
    start: '2026-11-15',
    end: '2026-11-15',
    categoryId: 'school',
  ),
  rule(
    'salary',
    'Lương',
    type: 'income',
    amount: 18500000,
    next: '2026-11-05',
    start: '2026-10-05',
  ),
  rule(
    'rent',
    'Tiền nhà',
    amount: -6000000,
    next: '2026-12-01',
    categoryId: 'home',
  ),
  rule(
    'netflix',
    'Netflix',
    amount: -260000,
    next: '2026-11-20',
    start: '2026-10-20',
    categoryId: 'fun',
    active: false,
  ),
];

class FakeRecurringUseCases implements RecurringUseCases {
  FakeRecurringUseCases({List<RecurringRule>? rules})
    : rules = rules ?? canvasRules();

  List<RecurringRule> rules;
  AuthFailure? failure;
  final created = <RecurringDraft>[];
  final confirms = <RecurringConfirm>[];
  final deleted = <String>[];

  Either<AuthFailure, T> _ok<T>(T value) =>
      failure == null ? right(value) : left(failure!);

  @override
  Future<Either<AuthFailure, List<RecurringRule>>> list({bool? active}) async =>
      _ok(rules);

  @override
  Future<Either<AuthFailure, RecurringRule>> create(RecurringDraft d) async {
    created.add(d);
    return _ok(
      rule(
        'new',
        d.name ?? '',
        type: d.type,
        mode: d.mode,
        amount: d.amountMinor.toInt(),
        next: d.nextExecutionDate,
        start: d.startDate,
        end: d.endDate,
        categoryId: d.categoryId,
        amountKind: d.amountKind,
      ),
    );
  }

  @override
  Future<Either<AuthFailure, RecurringRule>> update(
    RecurringRule r, {
    String? unit,
    int? interval,
    BigInt? amountMinor,
    String? currencyCode,
    String? accountId,
    String? categoryId,
    bool clearCategory = false,
    String? counterAccountId,
    bool clearCounter = false,
    BigInt? counterAmountMinor,
    String? counterCurrencyCode,
    String? fxRate,
    bool clearFx = false,
    String? startDate,
    String? endDate,
    bool clearEnd = false,
    String? nextExecutionDate,
    bool? active,
    String? name,
    String? amountKind,
    int? remindDaysBefore,
  }) async => _ok(
    r.copyWith(
      amountMinor: amountMinor,
      nextExecutionDate: nextExecutionDate,
      active: active,
      name: name,
      amountKind: amountKind,
      remindDaysBefore: remindDaysBefore,
    ),
  );

  @override
  Future<Either<AuthFailure, Unit>> delete(RecurringRule r) async {
    deleted.add(r.id);
    return _ok(unit);
  }

  @override
  Future<Either<AuthFailure, RecurringConfirmResult>> confirm(
    RecurringRule r,
    RecurringConfirm c,
  ) async {
    confirms.add(c);
    return _ok(
      RecurringConfirmResult(
        rule: r.copyWith(
          nextExecutionDate: r.isOneOff ? r.nextExecutionDate : '2026-12-05',
          active: !r.isOneOff,
        ),
        transactionId: 'tx',
        replayed: false,
      ),
    );
  }

  @override
  Future<Either<AuthFailure, RecurringRunResult>> run() async =>
      _ok(const RecurringRunResult(created: 0, skipped: 0));
}

class _Wallets extends StubWalletViewModel {
  _Wallets()
    : super(wallets: [wallet('vcb', 'Vietcombank', balance: 17288000)]);

  @override
  DateTime get today => recToday;
}

class _Expenses implements TransactionUseCases {
  const _Expenses();

  @override
  Future<Either<AuthFailure, TransactionListPage>> list(
    TransactionQuery query,
  ) async => right(
    const TransactionListPage(
      legs: [],
      page: 1,
      total: 0,
      summary: TransactionSummary.empty,
    ),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RecurringHarness {
  RecurringHarness._(this.cases, this.model, this.app, this.router);
  final FakeRecurringUseCases cases;
  final RecurringViewModel model;
  final Widget app;
  final GoRouter router;
}

/// [page] over a real [RecurringViewModel] fed by [FakeRecurringUseCases],
/// one stub wallet and "today" 2026-11-03.
Future<RecurringHarness> recurringApp(
  Widget page, {
  List<RecurringRule>? rules,
  bool dark = false,
  double scale = 1,
}) async {
  await getIt.reset();
  final repo = AuthRepositoryImpl(FakeApi(), MemoryVault(), FakeBiometrics());
  final auth = DefaultAuthViewModel(DefaultAuthUseCases(repo))
    ..stage = AuthStage.unlocked
    ..hasPin = true
    ..ready = true;
  final profiles = MemoryProfiles()
    ..value = const Profile(
      locale: 'vi',
      currency: 'VND',
      timezone: 'Asia/Ho_Chi_Minh',
      fiscalDay: 1,
      version: 1,
      displayName: 'Minh',
    );
  final profile = DefaultProfileViewModel(
    ProfileUseCases(profiles),
    auth,
    exportCase(repo),
  );
  await profile.load();
  final wallets = _Wallets();
  final cases = FakeRecurringUseCases(rules: rules);
  final model = RecurringViewModel(
    cases,
    auth,
    wallets,
    profile,
    const _Expenses(),
  );
  getIt
    ..registerSingleton<AuthViewModel>(auth)
    ..registerSingleton<WalletViewModel>(wallets)
    ..registerSingleton<ProfileViewModel>(profile)
    ..registerSingleton<CategoryViewModel>(
      StubCategoryViewModel(categories: recCategories()),
    )
    ..registerSingleton<RecurringViewModel>(model);
  Widget scaled(Widget child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: scale,
    maxScaleFactor: scale,
    child: child,
  );
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SizedBox()),
      GoRoute(path: '/page', builder: (context, state) => scaled(page)),
      for (final path in const [
        '/me',
        '/me/calendar',
        '/me/recurring',
        '/me/recurring/new',
        '/me/recurring/:id',
      ])
        GoRoute(path: path, builder: (context, state) => const SizedBox()),
    ],
  );
  final app = MaterialApp.router(
    debugShowCheckedModeBanner: false,
    theme: dark ? AppTheme.dark : AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    routerConfig: router,
  );
  return RecurringHarness._(cases, model, app, router);
}
