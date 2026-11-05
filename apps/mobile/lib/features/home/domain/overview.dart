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
    this.monthBefore,
    this.previousBudget,
    this.budget,
    this.multiCurrency = true,
  });

  final NetWorthReport netWorth;
  final CashflowReport month;

  /// Only loaded when the current month has no income or expense yet.
  final CashflowReport? previousMonth;

  /// The month before [previousMonth]; loaded with it, for the "biggest
  /// increase" line of the review card. Null when it failed.
  final CashflowReport? monthBefore;

  /// Budget of [previousMonth]; null when unset or failed.
  final BudgetSummary? previousBudget;

  /// Monthly budget for the current fiscal month; null when unset or failed.
  final BudgetSummary? budget;

  /// Whether wallets or transactions use two or more currencies. When false
  /// the converted totals, rate lines and display-currency choice are hidden
  /// (MOB-P3-004); stored rates are kept.
  final bool multiCurrency;

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

/// Sum of active wallets in one currency. A row is never converted by itself;
/// [BalanceSummary.main] may carry a display-only converted total.
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
  const BalanceSummary({
    required this.main,
    required this.others,
    this.isConverted = false,
    this.unconverted = const [],
  });

  /// The display currency (or the first currency that has wallets). With
  /// [isConverted] it is the converted total of every currency that
  /// converted exactly (BE-P2-013).
  final CurrencyBalance main;
  final List<CurrencyBalance> others;

  /// True when [main] is a display-only converted total.
  final bool isConverted;

  /// Currencies with wallets or spending that are left out of the converted
  /// numbers and still shown as their own lines.
  final List<UnconvertedCurrency> unconverted;
}

/// Income and expense of the period as positive magnitudes.
class MonthFlow {
  const MonthFlow({required this.income, required this.expense});

  final BigInt income;
  final BigInt expense;

  bool get isEmpty => income == BigInt.zero && expense == BigInt.zero;
}

/// Parent category whose spending grew most against the month before.
class CategoryIncrease {
  const CategoryIncrease({required this.name, required this.deltaMinor});

  final String name;
  final BigInt deltaMinor;
}

/// Previous month's budget when spending went past its limit.
class BudgetOverrun {
  const BudgetOverrun({
    required this.percent,
    required this.spentMinor,
    required this.limitMinor,
  });

  /// Whole percent over the limit, at least 1.
  final int percent;
  final BigInt spentMinor;
  final BigInt limitMinor;
}

/// The two optional lines under the new-month review card (MOB-P3-002).
class MonthInsight {
  const MonthInsight({this.topIncrease, this.overBudget});

  final CategoryIncrease? topIncrease;
  final BudgetOverrun? overBudget;

  bool get isEmpty => topIncrease == null && overBudget == null;
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
