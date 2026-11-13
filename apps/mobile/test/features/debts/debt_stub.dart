import 'package:dartz/dartz.dart';

import '../../support/server_config_fixture.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/injection.dart';
import 'package:mobile/core/l10n/generated/app_localizations.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/data/auth_repository_impl.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/auth/domain/auth_use_cases.dart';
import 'package:mobile/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:mobile/features/debts/domain/debt_use_cases.dart';
import 'package:mobile/features/debts/domain/personal_debt.dart';
import 'package:mobile/features/debts/presentation/viewmodels/debt_view_model.dart';
import 'package:mobile/features/loans/domain/loan.dart';
import 'package:mobile/features/loans/domain/loan_use_cases.dart';
import 'package:mobile/features/loans/presentation/viewmodels/loan_view_model.dart';
import 'package:mobile/features/profile/domain/profile.dart';
import 'package:mobile/features/profile/domain/profile_use_cases.dart';
import 'package:mobile/features/profile/presentation/viewmodels/profile_view_model.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';
import 'package:mobile/features/wallets/presentation/viewmodels/wallet_view_model.dart';

import '../auth/fakes.dart';
import '../home/fixtures.dart' show b, wallet;
import '../profile/fakes.dart';
import '../wallets/d1_stub.dart' show StubWalletViewModel;

// Stub "today" is 2026-10-21 (StubWalletViewModel).

PersonalDebt debt({
  String id = 'tuan',
  DebtDirection direction = DebtDirection.lent,
  String name = 'Tuấn',
  int principal = 3000000,
  int outstanding = 2000000,
  String occurredOn = '2026-10-12',
  String? dueDate = '2026-10-30',
  String? note = 'Mượn sửa xe',
  DebtStatus? status,
  String accountId = 'cash',
}) => PersonalDebt(
  id: id,
  clientId: 'client-$id',
  direction: direction,
  counterparty: name,
  currencyCode: 'VND',
  principalMinor: b(principal),
  outstandingMinor: b(outstanding),
  paidMinor: b(principal - outstanding),
  accountId: accountId,
  occurredOn: occurredOn,
  dueDate: dueDate,
  note: note,
  status:
      status ??
      (outstanding == 0
          ? DebtStatus.settled
          : dueDate != null && dueDate.compareTo('2026-10-21') < 0
          ? DebtStatus.overdue
          : DebtStatus.open),
  version: 1,
);

/// DebtList: Tuấn and Hà owe you, you owe Chị Lan, four settled.
List<PersonalDebt> canvasDebts() => [
  debt(),
  debt(
    id: 'ha',
    name: 'Hà',
    principal: 500000,
    outstanding: 500000,
    occurredOn: '2026-09-01',
    dueDate: '2026-10-01',
    note: null,
  ),
  debt(
    id: 'lan',
    direction: DebtDirection.borrowed,
    name: 'Chị Lan',
    principal: 2000000,
    outstanding: 2000000,
    occurredOn: '2026-10-05',
    dueDate: null,
    note: null,
  ),
  for (final (i, n) in const ['Nam', 'Minh', 'Hoa', 'Bình'].indexed)
    debt(
      id: 'done$i',
      name: n,
      principal: 300000,
      outstanding: 0,
      occurredOn: '2026-08-0${i + 1}',
      dueDate: null,
      note: null,
    ),
];

List<DebtTotal> canvasDebtTotals() => [
  DebtTotal(
    currencyCode: 'VND',
    receivableMinor: b(2500000),
    payableMinor: b(2000000),
    receivableCount: 2,
    payableCount: 1,
  ),
];

/// Wallets of the K boards.
List<Wallet> debtWallets() => [
  wallet('cash', 'Tiền mặt', type: WalletType.cash, balance: 12300000),
  wallet('vcb', 'Vietcombank', balance: 17288000),
];

class FakeDebtUseCases implements DebtUseCases {
  FakeDebtUseCases({List<PersonalDebt>? debts, List<DebtTotal>? totals_})
    : debts = debts ?? canvasDebts(),
      totalsList = totals_ ?? canvasDebtTotals();

  List<PersonalDebt> debts;
  List<DebtTotal> totalsList;
  AuthFailure? failure;
  final created = <DebtDraft>[];
  final repaid = <DebtRepay>[];

  Either<AuthFailure, T> _ok<T>(T value) =>
      failure == null ? right(value) : left(failure!);

  @override
  Future<Either<AuthFailure, List<PersonalDebt>>> list() async => _ok(debts);

  @override
  Future<Either<AuthFailure, List<DebtTotal>>> totals() async =>
      _ok(totalsList);

  @override
  Future<Either<AuthFailure, PersonalDebt>> create(DebtDraft draft) async {
    created.add(draft);
    return _ok(
      debt(
        id: 'new',
        direction: draft.direction,
        name: draft.counterparty,
        principal: draft.amountMinor.toInt(),
        outstanding: draft.amountMinor.toInt(),
        occurredOn: draft.occurredOn,
        dueDate: draft.dueDate,
        note: draft.note,
        accountId: draft.accountId,
      ),
    );
  }

  @override
  Future<Either<AuthFailure, PersonalDebt>> update(
    PersonalDebt d, {
    required String counterparty,
    required String? dueDate,
    required String? note,
  }) async => _ok(
    debt(
      id: d.id,
      direction: d.direction,
      name: counterparty,
      principal: d.principalMinor.toInt(),
      outstanding: d.outstandingMinor.toInt(),
      occurredOn: d.occurredOn,
      dueDate: dueDate,
      note: note,
    ),
  );

  @override
  Future<Either<AuthFailure, List<DebtPayment>>> payments(String id) async =>
      _ok(
        id == 'tuan'
            ? [
                DebtPayment(
                  id: 'p1',
                  accountId: 'cash',
                  amountMinor: b(1000000),
                  paidOn: '2026-10-20',
                ),
              ]
            : const [],
      );

  @override
  Future<Either<AuthFailure, PersonalDebt>> repay(
    PersonalDebt d,
    DebtRepay r,
  ) async {
    repaid.add(r);
    return _ok(
      debt(
        id: d.id,
        direction: d.direction,
        name: d.counterparty,
        principal: d.principalMinor.toInt(),
        outstanding: (d.outstandingMinor - r.amountMinor).toInt(),
        occurredOn: d.occurredOn,
        dueDate: d.dueDate,
        note: d.note,
      ),
    );
  }
}

Loan loan({
  String id = 'home',
  LoanKind kind = LoanKind.mortgage,
  String name = 'Vay mua nhà',
  int principal = 300000000,
  int outstanding = 210000000,
  int rateBps = 1200,
  int? installment = 6500000,
  String? next = '2026-10-25',
  String? end = '2035-10-25',
  String? accountId = 'vcb',
}) => Loan(
  id: id,
  clientId: 'client-$id',
  kind: kind,
  name: name,
  currencyCode: 'VND',
  principalMinor: b(principal),
  outstandingMinor: b(outstanding),
  paidMinor: b(principal - outstanding),
  percentBps: (principal - outstanding) * 10000 ~/ principal,
  interestRateBps: rateBps,
  installmentMinor: installment == null ? null : b(installment),
  frequency: LoanFrequency.monthly,
  startDate: '2020-10-25',
  endDate: end,
  nextDueDate: next,
  periodInterestMinor: b(outstanding * rateBps ~/ 120000),
  status: outstanding == 0 ? LoanStatus.paidOff : LoanStatus.active,
  accountId: accountId,
  version: 1,
);

/// LoanList: a home loan and a car loan.
List<Loan> canvasLoans() => [
  loan(),
  loan(
    id: 'car',
    kind: LoanKind.personal,
    name: 'Vay mua xe',
    principal: 80000000,
    outstanding: 35000000,
    rateBps: 950,
    installment: 2700000,
    next: '2026-11-05',
  ),
];

List<LoanScheduleRow> canvasSchedule() => [
  for (final (i, (due, p, interest)) in const [
    ('2026-10-25', 4400000, 2100000),
    ('2026-11-25', 4444000, 2056000),
    ('2026-12-25', 4488000, 2012000),
    ('2035-10-25', 6400000, 64000),
  ].indexed)
    LoanScheduleRow(
      index: i + 1,
      dueDate: due,
      principalMinor: b(p),
      interestMinor: b(interest),
      paymentMinor: b(p + interest),
      outstandingAfterMinor: BigInt.zero,
    ),
];

class FakeLoanUseCases implements LoanUseCases {
  FakeLoanUseCases({List<Loan>? loans}) : loans = loans ?? canvasLoans();

  List<Loan> loans;
  AuthFailure? failure;
  final created = <LoanDraft>[];
  final paid = <LoanPayment>[];

  Either<AuthFailure, T> _ok<T>(T value) =>
      failure == null ? right(value) : left(failure!);

  @override
  Future<Either<AuthFailure, List<Loan>>> list() async => _ok(loans);

  @override
  Future<Either<AuthFailure, List<LoanTotal>>> totals() async => _ok(
    loans.isEmpty
        ? const []
        : [
            LoanTotal(
              currencyCode: 'VND',
              loanCount: loans.length,
              principalMinor: b(380000000),
              paidMinor: b(135000000),
              outstandingMinor: b(245000000),
              dueThisMonthMinor: b(9200000),
            ),
          ],
  );

  @override
  Future<Either<AuthFailure, List<LoanScheduleRow>>> schedule(
    String id,
  ) async => _ok(canvasSchedule());

  @override
  Future<Either<AuthFailure, Loan>> create(LoanDraft draft) async {
    created.add(draft);
    return _ok(loan(id: 'new', name: draft.name));
  }

  @override
  Future<Either<AuthFailure, Loan>> update(
    Loan l, {
    required LoanKind kind,
    required String name,
    required int interestRateBps,
    required BigInt? installmentMinor,
    required LoanFrequency frequency,
    required String? endDate,
    required String? nextDueDate,
    required String? accountId,
  }) async => _ok(loan(id: l.id, kind: kind, name: name));

  @override
  Future<Either<AuthFailure, Loan>> adjust(Loan l, BigInt outstanding) async =>
      _ok(loan(id: l.id, outstanding: outstanding.toInt()));

  @override
  Future<Either<AuthFailure, Loan>> pay(Loan l, LoanPayment payment) async {
    paid.add(payment);
    return _ok(
      loan(
        id: l.id,
        outstanding: (l.outstandingMinor - payment.principalMinor).toInt(),
      ),
    );
  }
}

class DebtHarness {
  DebtHarness._(
    this.debts,
    this.loans,
    this.debtModel,
    this.loanModel,
    this.app,
  );
  final FakeDebtUseCases debts;
  final FakeLoanUseCases loans;
  final DebtViewModel debtModel;
  final LoanViewModel loanModel;
  final Widget app;
}

/// [page] over real view models fed by the fakes above and stub wallets.
Future<DebtHarness> debtsApp(
  Widget page, {
  List<PersonalDebt>? debts,
  List<Loan>? loans,
  bool dark = false,
  double scale = 1,
}) async {
  await getIt.reset();
  registerTestServerConfig();
  final auth =
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
    ProfileUseCases(profiles, testServerConfigModel()),
    auth,
    exportCase(
      AuthRepositoryImpl(
        FakeApi(),
        MemoryVault(),
        FakeBiometrics(),
        testServerConfigModel(),
      ),
    ),
  );
  await profile.load();
  final wallets = StubWalletViewModel(wallets: debtWallets());
  final debtCases = FakeDebtUseCases(
    debts: debts,
    totals_: debts != null && debts.isEmpty ? const [] : null,
  );
  final loanCases = FakeLoanUseCases(loans: loans);
  final debtModel = DebtViewModel(debtCases, wallets, profile, auth);
  final loanModel = LoanViewModel(loanCases, wallets, profile, auth);
  getIt
    ..registerSingleton<AuthViewModel>(auth)
    ..registerSingleton<WalletViewModel>(wallets)
    ..registerSingleton<ProfileViewModel>(profile)
    ..registerSingleton<DebtViewModel>(debtModel)
    ..registerSingleton<LoanViewModel>(loanModel);
  Widget scaled(Widget child) => MediaQuery.withClampedTextScaling(
    minScaleFactor: scale,
    maxScaleFactor: scale,
    child: child,
  );
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => scaled(page)),
      for (final path in const [
        '/me',
        '/me/debts',
        '/me/debts/new',
        '/me/debts/:id',
        '/me/debts/:id/edit',
        '/me/debts/loans/new',
        '/me/debts/loans/:id',
        '/me/debts/loans/:id/edit',
        '/me/debts/loans/:id/schedule',
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
  return DebtHarness._(debtCases, loanCases, debtModel, loanModel, app);
}
