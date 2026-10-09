import '../../wallets/domain/wallet.dart';

enum ReportPeriodKind { week, month, range }

class ReportPeriodQuery {
  const ReportPeriodQuery.week({this.on})
    : kind = ReportPeriodKind.week,
      from = null,
      to = null;
  const ReportPeriodQuery.month({this.on})
    : kind = ReportPeriodKind.month,
      from = null,
      to = null;
  const ReportPeriodQuery.range(this.from, this.to)
    : kind = ReportPeriodKind.range,
      on = null;

  final ReportPeriodKind kind;
  final String? on;
  final String? from;
  final String? to;
}

class ReportPeriod {
  const ReportPeriod({
    required this.kind,
    required this.from,
    required this.to,
    required this.timezone,
    required this.fiscalMonthStartDay,
  });

  final ReportPeriodKind kind;
  final String from;
  final String to;
  final String timezone;
  final int fiscalMonthStartDay;
}

class CashflowTotal {
  const CashflowTotal({
    required this.currency,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.netMinor,
  });

  final String currency;
  final BigInt incomeMinor;
  final BigInt expenseMinor;
  final BigInt netMinor;
}

class CashflowCategoryRow {
  const CashflowCategoryRow({
    required this.categoryId,
    required this.parentId,
    required this.currency,
    required this.incomeMinor,
    required this.expenseMinor,
    this.name,
    this.parentName,
  });

  final String? categoryId;
  final String? parentId;
  final String currency;
  final BigInt incomeMinor;
  final BigInt expenseMinor;
  final String? name;
  final String? parentName;

  CashflowCategoryRow withNames(String? name, String? parentName) =>
      CashflowCategoryRow(
        categoryId: categoryId,
        parentId: parentId,
        currency: currency,
        incomeMinor: incomeMinor,
        expenseMinor: expenseMinor,
        name: name,
        parentName: parentName,
      );
}

class CashflowAccountRow {
  const CashflowAccountRow({
    required this.accountId,
    required this.currency,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.transferMinor,
    required this.netMinor,
    this.name,
  });

  final String accountId;
  final String currency;
  final BigInt incomeMinor;
  final BigInt expenseMinor;
  final BigInt transferMinor;
  final BigInt netMinor;
  final String? name;

  CashflowAccountRow withName(String name) => CashflowAccountRow(
    accountId: accountId,
    currency: currency,
    incomeMinor: incomeMinor,
    expenseMinor: expenseMinor,
    transferMinor: transferMinor,
    netMinor: netMinor,
    name: name,
  );
}

class CashflowReport {
  const CashflowReport({
    required this.period,
    required this.totals,
    required this.byCategory,
    required this.byAccount,
  });

  final ReportPeriod period;
  final List<CashflowTotal> totals;
  final List<CashflowCategoryRow> byCategory;
  final List<CashflowAccountRow> byAccount;

  CashflowReport withRows(
    List<CashflowCategoryRow> categories,
    List<CashflowAccountRow> accounts,
  ) => CashflowReport(
    period: period,
    totals: totals,
    byCategory: categories,
    byAccount: accounts,
  );
}

class NetWorthTotal {
  const NetWorthTotal({
    required this.currency,
    required this.assetsMinor,
    required this.liabilitiesMinor,
    required this.netWorthMinor,
  });

  final String currency;
  final BigInt assetsMinor;
  final BigInt liabilitiesMinor;
  final BigInt netWorthMinor;
}

class NetWorthReport {
  const NetWorthReport({required this.items});

  final List<NetWorthTotal> items;
}

class OverviewSnapshot {
  const OverviewSnapshot({
    required this.netWorth,
    required this.month,
    required this.currencies,
  });

  final NetWorthReport netWorth;
  final CashflowReport month;
  final List<WalletCurrency> currencies;
}

class NamedCashflow {
  const NamedCashflow({required this.report, required this.currencies});

  final CashflowReport report;
  final List<WalletCurrency> currencies;
}
