import 'package:dartz/dartz.dart';

import '../../auth/domain/auth_repository.dart';
import '../../categories/domain/finance_category.dart';
import '../../wallets/domain/wallet.dart';
import 'report.dart';

Either<AuthFailure, OverviewSnapshot> overviewSnapshot(
  NetWorthReport netWorth,
  CashflowReport month,
  List<WalletCurrency> currencies,
) {
  final codes = [
    ...netWorth.items.map((row) => row.currency),
    ...month.totals.map((row) => row.currency),
  ];
  if (codes.any((code) => !_known(code, currencies))) {
    return left(const AuthFailure(AuthError.unavailable));
  }
  return right(
    OverviewSnapshot(netWorth: netWorth, month: month, currencies: currencies),
  );
}

Either<AuthFailure, NamedCashflow> nameCashflow(
  CashflowReport report,
  List<Wallet> wallets,
  List<FinanceCategory> categories,
  List<WalletCurrency> currencies,
) {
  final codes = [
    ...report.totals.map((row) => row.currency),
    ...report.byCategory.map((row) => row.currency),
    ...report.byAccount.map((row) => row.currency),
  ];
  if (codes.any((code) => !_known(code, currencies))) {
    return left(const AuthFailure(AuthError.unavailable));
  }
  final accounts = {
    for (final wallet in wallets)
      if (wallet.draft.name.trim().isNotEmpty) wallet.id: wallet.draft.name,
  };
  final byId = {for (final category in categories) category.id: category};
  final namedCategories = <CashflowCategoryRow>[];
  for (final row in report.byCategory) {
    if (row.categoryId == null) {
      if (row.parentId != null) {
        return left(const AuthFailure(AuthError.unavailable));
      }
      namedCategories.add(row);
      continue;
    }
    final category = byId[row.categoryId];
    if (category == null) return left(const AuthFailure(AuthError.unavailable));
    String? parentName;
    if (row.parentId != null) {
      final parent = byId[row.parentId];
      if (parent == null) return left(const AuthFailure(AuthError.unavailable));
      parentName = parent.name;
    }
    namedCategories.add(row.withNames(category.name, parentName));
  }
  final namedAccounts = <CashflowAccountRow>[];
  for (final row in report.byAccount) {
    final name = accounts[row.accountId];
    if (name == null) return left(const AuthFailure(AuthError.unavailable));
    namedAccounts.add(row.withName(name));
  }
  return right(
    NamedCashflow(
      report: report.withRows(namedCategories, namedAccounts),
      currencies: currencies,
    ),
  );
}

bool _known(String currency, List<WalletCurrency> currencies) =>
    currencies.any((item) => item.code == currency);
