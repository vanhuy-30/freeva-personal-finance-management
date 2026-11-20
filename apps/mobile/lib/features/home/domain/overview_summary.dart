import '../../budgets/domain/budget.dart';
import '../../categories/domain/finance_category.dart';
import '../../reports/domain/report.dart';
import '../../wallets/domain/wallet.dart';
import 'overview.dart';

/// Totals of active wallets. The display currency leads. When the server
/// converted at least one currency, [BalanceSummary.main] is the converted
/// total; every currency still keeps its own pill with the original amount.
/// A currency that did not convert exactly is listed in `unconverted` and is
/// never added to the converted total.
BalanceSummary balanceSummary(OverviewData data, String profileCurrency) {
  final counts = <String, int>{};
  for (final wallet in data.wallets) {
    counts.update(wallet.draft.currency, (n) => n + 1, ifAbsent: () => 1);
  }
  final balances = [
    for (final row in data.netWorth.items)
      if ((counts[row.currency] ?? 0) > 0)
        CurrencyBalance(
          currency: row.currency,
          minor: row.netWorthMinor,
          walletCount: counts[row.currency]!,
          assetsMinor: row.assetsMinor,
          liabilitiesMinor: row.liabilitiesMinor,
        ),
  ];
  final converted = data.multiCurrency ? data.netWorth.converted : null;
  final unconverted = data.multiCurrency
      ? _unconverted(data, counts.keys.toSet())
      : const <UnconvertedCurrency>[];
  final left = {for (final item in unconverted) item.currency};
  final included = {
    for (final b in balances)
      if (!left.contains(b.currency)) b.currency,
  };
  if (converted != null && included.isNotEmpty) {
    return BalanceSummary(
      main: CurrencyBalance(
        currency: converted.currency,
        minor: converted.netWorthMinor,
        walletCount: [for (final c in included) counts[c]!]
            .fold(0, (a, b) => a + b),
        assetsMinor: converted.assetsMinor,
        liabilitiesMinor: converted.liabilitiesMinor,
      ),
      others: [
        for (final b in balances)
          if (b.currency != converted.currency) b,
      ],
      isConverted: true,
      unconverted: unconverted,
    );
  }
  final main =
      balances.where((b) => b.currency == profileCurrency).firstOrNull ??
      (balances.isNotEmpty
          ? balances.first
          : CurrencyBalance(
              currency: profileCurrency,
              minor: BigInt.zero,
              walletCount: 0,
            ));
  return BalanceSummary(
    main: main,
    others: [
      for (final b in balances)
        if (b.currency != main.currency) b,
    ],
    unconverted: unconverted,
  );
}

/// Wallet currencies and month currencies the server could not convert.
/// Empty when nothing was asked to convert.
List<UnconvertedCurrency> _unconverted(OverviewData data, Set<String> wallets) {
  final seen = <String>{};
  return [
    for (final item in [
      ...?data.netWorth.converted?.unconverted,
      ...?data.month.converted?.unconverted,
    ])
      if (wallets.contains(item.currency) && seen.add(item.currency)) item,
  ];
}

/// This month's income and expense: the converted totals when [summary] is
/// converted, else the row of the main currency.
MonthFlow monthFlowFor(OverviewData data, BalanceSummary summary) {
  final converted = data.month.converted;
  if (summary.isConverted && converted != null) {
    return MonthFlow(
      income: converted.incomeMinor.abs(),
      expense: converted.expenseMinor.abs(),
    );
  }
  return monthFlow(data.month, summary.main.currency);
}

MonthFlow monthFlow(CashflowReport report, String currency) {
  final row = report.totals.where((t) => t.currency == currency).firstOrNull;
  if (row == null) return MonthFlow(income: BigInt.zero, expense: BigInt.zero);
  return MonthFlow(
    income: row.incomeMinor.abs(),
    expense: row.expenseMinor.abs(),
  );
}

/// Expense in currencies other than [main], for "Ví USD: chi 35,00 USD".

/// Expense per parent category (or the category itself when it is a root).
Map<String?, BigInt> _expenseByParent(CashflowReport report, String currency) {
  final byParent = <String?, BigInt>{};
  for (final row in report.byCategory) {
    if (row.currency != currency || row.expenseMinor == BigInt.zero) continue;
    final key = row.parentId ?? row.categoryId;
    byParent.update(
      key,
      (v) => v + row.expenseMinor.abs(),
      ifAbsent: () => row.expenseMinor.abs(),
    );
  }
  return byParent;
}

/// Lines under the new-month review card: the parent category that grew most
/// from [before] to [previous], and whether [budget] (previous month) went
/// over. Each line is null when its data is missing; nothing is guessed.
MonthInsight monthInsight({
  required CashflowReport previous,
  required String currency,
  required List<FinanceCategory> categories,
  CashflowReport? before,
  BudgetSummary? budget,
}) {
  CategoryIncrease? increase;
  if (before != null) {
    final names = {for (final c in categories) c.id: c.name};
    final now = _expenseByParent(previous, currency);
    final then = _expenseByParent(before, currency);
    BigInt best = BigInt.zero;
    for (final e in now.entries) {
      final name = e.key == null ? null : names[e.key];
      if (name == null) continue;
      final delta = e.value - (then[e.key] ?? BigInt.zero);
      if (delta > best) {
        best = delta;
        increase = CategoryIncrease(name: name, deltaMinor: delta);
      }
    }
  }
  BudgetOverrun? overrun;
  if (budget != null &&
      budget.currencyCode == currency &&
      budget.limitMinor > BigInt.zero &&
      budget.spentMinor > budget.limitMinor) {
    final over =
        ((budget.spentMinor - budget.limitMinor) * BigInt.from(100)) ~/
        budget.limitMinor;
    overrun = BudgetOverrun(
      percent: over.toInt() < 1 ? 1 : over.toInt(),
      spentMinor: budget.spentMinor,
      limitMinor: budget.limitMinor,
    );
  }
  return MonthInsight(topIncrease: increase, overBudget: overrun);
}

/// Credit wallets as cards, in wallet order.
List<CreditCardStatus> creditCards(List<Wallet> wallets, DateTime today) => [
  for (final wallet in wallets)
    if (wallet.draft.type == WalletType.credit)
      CreditCardStatus.of(wallet, today),
];
