import 'package:dartz/dartz.dart';
import 'package:mobile/features/auth/domain/auth_repository.dart';
import 'package:mobile/features/installments/domain/card_installment.dart';
import 'package:mobile/features/installments/domain/card_installment_use_cases.dart';

/// Use cases over fixed data; records the last preview and create.
class FakeInstallmentUseCases implements CardInstallmentUseCases {
  FakeInstallmentUseCases({
    this.plans = const [],
    this.thisPeriod,
    this.later,
    this.previewResult,
    Map<String, CardInstallment>? details,
  }) : details = details ?? {};

  List<CardInstallment> plans;
  BigInt? thisPeriod;
  BigInt? later;
  Either<AuthFailure, InstallmentPreview>? previewResult;
  final Map<String, CardInstallment> details;
  final List<InstallmentDraft> previews = [];
  final List<({String from, String to})> dueCalls = [];
  InstallmentDraft? created;
  String? createdClientId;
  CardInstallment? closed;

  @override
  Future<Either<AuthFailure, List<CardInstallment>>> list({
    String? accountId,
    bool? active,
  }) async => right([
    for (final p in plans)
      if (accountId == null || p.accountId == accountId) p,
  ]);

  @override
  Future<Either<AuthFailure, CardInstallment>> find(String id) async {
    final plan = details[id];
    return plan == null
        ? left(const AuthFailure(AuthError.unavailable))
        : right(plan);
  }

  /// Purchase price the default preview splits.
  BigInt total = BigInt.from(24000000);

  @override
  Future<Either<AuthFailure, InstallmentPreview>> preview(
    InstallmentDraft draft,
  ) async {
    previews.add(draft);
    return previewResult ?? right(_monthly(draft));
  }

  /// Test stand-in for the server: monthly from the first day, last
  /// period takes the rest (the real numbers come from the API).
  InstallmentPreview _monthly(InstallmentDraft draft) {
    final n = draft.installmentCount;
    final each =
        draft.installmentMinor ??
        (total + BigInt.from(n - 1)) ~/ BigInt.from(n);
    final first = DateTime.parse(draft.firstDueOn);
    final periods = [
      for (var i = 0; i < n; i++)
        period(
          i + 1,
          isoDay(DateTime(first.year, first.month + i, first.day)),
          (i == n - 1 ? total - each * BigInt.from(n - 1) : each).toInt(),
        ),
    ];
    return InstallmentPreview(
      totalMinor: total,
      installmentMinor: each,
      installmentCount: n,
      firstDueOn: draft.firstDueOn,
      lastDueOn: periods.last.dueOn,
      periods: periods,
    );
  }

  @override
  Future<Either<AuthFailure, CardInstallment>> create(
    InstallmentDraft draft, {
    required String clientId,
  }) async {
    created = draft;
    createdClientId = clientId;
    final plan = details.values.firstOrNull;
    return plan == null
        ? left(const AuthFailure(AuthError.conflict))
        : right(plan);
  }

  @override
  Future<Either<AuthFailure, CardInstallment>> close(
    CardInstallment plan,
  ) async {
    closed = plan;
    return right(plan);
  }

  @override
  Future<Either<AuthFailure, List<InstallmentDue>>> due({
    required String from,
    required String to,
    String? accountId,
  }) async {
    dueCalls.add((from: from, to: to));
    final value = to == '2099-12-31' ? later : thisPeriod;
    return right([
      if (value != null)
        InstallmentDue(
          accountId: accountId ?? '',
          currencyCode: 'VND',
          dueMinor: value,
          planCount: 1,
        ),
    ]);
  }
}

InstallmentPeriod period(
  int index,
  String dueOn,
  int amount, [
  InstallmentPeriodState state = InstallmentPeriodState.upcoming,
]) => InstallmentPeriod(
  index: index,
  dueOn: dueOn,
  amountMinor: BigInt.from(amount),
  state: state,
);

/// "Điện thoại 24.000.000" over 6 periods from 25/11/2026 on `credit`.
CardInstallment phonePlan({
  int remaining = 5,
  bool active = true,
  bool withPeriods = true,
}) {
  const dues = [
    '2026-11-25',
    '2026-12-25',
    '2027-01-25',
    '2027-02-25',
    '2027-03-25',
    '2027-04-25',
  ];
  final past = 6 - remaining;
  return CardInstallment(
    id: 'plan-1',
    clientId: 'c-plan-1',
    transactionId: 'tx-phone',
    accountId: 'card',
    currencyCode: 'VND',
    totalMinor: BigInt.from(24000000),
    installmentMinor: BigInt.from(4000000),
    installmentCount: 6,
    firstDueOn: dues.first,
    active: active,
    remainingCount: active ? remaining : 0,
    nextDueOn: active && remaining > 0 ? dues[past] : null,
    nextAmountMinor: active && remaining > 0 ? BigInt.from(4000000) : null,
    version: 1,
    purchaseOn: '2026-10-12',
    purchaseMerchant: 'Điện thoại',
    purchaseCategoryId: 'shopping',
    periods: withPeriods
        ? [
            for (var i = 0; i < 6; i++)
              period(
                i + 1,
                dues[i],
                4000000,
                !active
                    ? InstallmentPeriodState.closed
                    : i < past
                    ? InstallmentPeriodState.past
                    : InstallmentPeriodState.upcoming,
              ),
          ]
        : null,
  );
}
