/// One calendar month of the forecast: `opening + income + expense = closing`.
/// [expenseMinor] is negative. Amounts are minor units.
class ForecastMonth {
  const ForecastMonth({
    required this.month,
    required this.openingMinor,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.closingMinor,
  });

  /// `yyyy-MM`.
  final String month;
  final BigInt openingMinor;
  final BigInt incomeMinor;
  final BigInt expenseMinor;
  final BigInt closingMinor;
}

/// What the forecast assumed; the screen shows it and lets the user edit it.
class ForecastAssumptions {
  const ForecastAssumptions({
    required this.fromWallets,
    required this.includedRuleIds,
    required this.excludedRuleIds,
    required this.otherCurrencyRuleIds,
  });

  /// True when the start balance came from wallets, false when the user set it.
  final bool fromWallets;
  final List<String> includedRuleIds;
  final List<String> excludedRuleIds;

  /// Rules in another currency: left out (no FX conversion).
  final List<String> otherCurrencyRuleIds;
}

class BalanceForecast {
  const BalanceForecast({
    required this.currencyCode,
    required this.from,
    required this.to,
    required this.startingBalanceMinor,
    required this.months,
    required this.assumptions,
  });

  final String currencyCode;

  /// `yyyy-MM-dd`, today in the profile timezone.
  final String from;
  final String to;
  final BigInt startingBalanceMinor;
  final List<ForecastMonth> months;
  final ForecastAssumptions assumptions;

  /// Balance at the end of the last month; the start balance when empty.
  BigInt get endingMinor =>
      months.isEmpty ? startingBalanceMinor : months.last.closingMinor;

  BigInt get changeMinor => endingMinor - startingBalanceMinor;
}
