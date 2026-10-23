import '../../wallets/domain/wallet.dart';

enum ReportPeriodKind { week, month, year, range }

class ReportPeriodQuery {
  const ReportPeriodQuery.week({this.on})
    : kind = ReportPeriodKind.week,
      from = null,
      to = null;
  const ReportPeriodQuery.month({this.on})
    : kind = ReportPeriodKind.month,
      from = null,
      to = null;
  const ReportPeriodQuery.year({this.on})
    : kind = ReportPeriodKind.year,
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
    this.transactionCount = 0,
    this.name,
    this.parentName,
  });

  final String? categoryId;
  final String? parentId;
  final String currency;
  final BigInt incomeMinor;
  final BigInt expenseMinor;

  /// Income and expense transactions behind this row.
  final int transactionCount;
  final String? name;
  final String? parentName;

  CashflowCategoryRow withNames(String? name, String? parentName) =>
      CashflowCategoryRow(
        categoryId: categoryId,
        parentId: parentId,
        currency: currency,
        incomeMinor: incomeMinor,
        expenseMinor: expenseMinor,
        transactionCount: transactionCount,
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
    this.type,
  });

  final String accountId;
  final String currency;
  final BigInt incomeMinor;
  final BigInt expenseMinor;
  final BigInt transferMinor;
  final BigInt netMinor;
  final String? name;
  final WalletType? type;

  CashflowAccountRow withName(String name, WalletType type) =>
      CashflowAccountRow(
        accountId: accountId,
        currency: currency,
        incomeMinor: incomeMinor,
        expenseMinor: expenseMinor,
        transferMinor: transferMinor,
        netMinor: netMinor,
        name: name,
        type: type,
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

class NamedCashflow {
  const NamedCashflow({required this.report, required this.currencies});

  final CashflowReport report;
  final List<WalletCurrency> currencies;

  int digitsOf(String currency) =>
      currencies
          .where((item) => item.code == currency)
          .map((item) => item.minorDigits)
          .firstOrNull ??
      0;
}

class TrendTotal {
  const TrendTotal({
    required this.currency,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final String currency;
  final BigInt incomeMinor;
  final BigInt expenseMinor;
}

/// One bar of the trend chart: an inclusive period and its totals per currency.
class TrendBucket {
  const TrendBucket({
    required this.from,
    required this.to,
    required this.totals,
  });

  final String from;
  final String to;
  final List<TrendTotal> totals;

  /// Expense magnitude in [currency]; zero when the bucket has none.
  BigInt expenseOf(String currency) =>
      totals
          .where((total) => total.currency == currency)
          .map((total) => total.expenseMinor.abs())
          .firstOrNull ??
      BigInt.zero;
}

/// Oldest-first buckets; the last one is the period being viewed.
class TrendReport {
  const TrendReport({required this.kind, required this.buckets});

  final ReportPeriodKind kind;
  final List<TrendBucket> buckets;
}
