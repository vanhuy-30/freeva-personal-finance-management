import '../../budgets/domain/budget.dart';
import '../../categories/domain/finance_category.dart';
import '../../reports/domain/report.dart';
import '../../transactions/domain/transaction.dart';
import '../../wallets/domain/wallet.dart';

export '../../wallets/domain/credit_card_status.dart';

/// Everything the Overview screen needs, loaded together.
class OverviewData {
  const OverviewData({
    required this.netWorth,
    required this.month,
    required this.wallets,
    required this.currencies,
    required this.recent,
    required this.categories,
    required this.loadedAt,
    this.previousMonth,
    this.budget,
  });

  final NetWorthReport netWorth;
  final CashflowReport month;

  /// Only loaded when the current month has no income or expense yet.
  final CashflowReport? previousMonth;

  /// Monthly budget for the current fiscal month; null when unset or failed.
  final BudgetSummary? budget;

  /// Active (not hidden) wallets.
  final List<Wallet> wallets;
  final List<WalletCurrency> currencies;
  final List<TransactionBundle> recent;
  final List<FinanceCategory> categories;
  final DateTime loadedAt;

  int digitsOf(String currency) {
    for (final item in currencies) {
      if (item.code == currency) return item.minorDigits;
    }
    return 0;
  }
}

/// Sum of active wallets in one currency. Never converted between currencies.
class CurrencyBalance {
  const CurrencyBalance({
    required this.currency,
    required this.minor,
    required this.walletCount,
  });

  final String currency;
  final BigInt minor;
  final int walletCount;
}

class BalanceSummary {
  const BalanceSummary({required this.main, required this.others});

  /// The profile currency (or the first currency that has wallets).
  final CurrencyBalance main;
  final List<CurrencyBalance> others;
}

/// Income and expense of the period as positive magnitudes.
class MonthFlow {
  const MonthFlow({required this.income, required this.expense});

  final BigInt income;
  final BigInt expense;

  bool get isEmpty => income == BigInt.zero && expense == BigInt.zero;
}

/// One slice of "Chi tháng": a parent category, or "Khác" when [name] is null.
class SpendingSlice {
  const SpendingSlice({
    required this.name,
    required this.minor,
    required this.percent,
  });

  final String? name;
  final BigInt minor;
  final int percent;
}

class SpendingBreakdown {
  const SpendingBreakdown({required this.total, required this.slices});

  final BigInt total;
  final List<SpendingSlice> slices;
}
