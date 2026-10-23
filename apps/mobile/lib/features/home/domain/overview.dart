import '../../categories/domain/finance_category.dart';
import '../../reports/domain/report.dart';
import '../../transactions/domain/transaction.dart';
import '../../wallets/domain/wallet.dart';

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
  });

  final NetWorthReport netWorth;
  final CashflowReport month;

  /// Only loaded when the current month has no income or expense yet.
  final CashflowReport? previousMonth;

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

enum CreditLevel { normal, high, critical }

class CreditCardStatus {
  const CreditCardStatus({
    required this.wallet,
    required this.used,
    required this.limit,
    required this.nextDue,
  });

  final Wallet wallet;
  final BigInt used;
  final BigInt? limit;
  final DateTime? nextDue;

  /// 0–1 of the limit; 0 when there is no limit.
  double get ratio {
    final cap = limit;
    if (cap == null || cap <= BigInt.zero) return 0;
    final value = used * BigInt.from(10000) ~/ cap;
    return (value.toInt() / 10000).clamp(0, 1).toDouble();
  }

  /// < 70% normal, 70–90% high, > 90% critical.
  CreditLevel get level => ratio > .9
      ? CreditLevel.critical
      : ratio >= .7
      ? CreditLevel.high
      : CreditLevel.normal;

  bool dueWithin(DateTime today, int days) {
    final due = nextDue;
    if (due == null) return false;
    final diff = due.difference(DateTime(today.year, today.month, today.day));
    return diff.inDays >= 0 && diff.inDays <= days;
  }
}
