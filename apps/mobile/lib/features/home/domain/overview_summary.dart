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
        ),
  ];
  final converted = data.netWorth.converted;
  final unconverted = _unconverted(data, counts.keys.toSet());
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
        walletCount: [for (final c in included) counts[c]!].fold(0, (a, b) => a + b),
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
List<CashflowTotal> otherCurrencySpending(CashflowReport report, String main) =>
    [
      for (final row in report.totals)
        if (row.currency != main && row.expenseMinor != BigInt.zero) row,
    ];

/// Expense rolled up to parent categories: top [top] by amount, the rest as
/// one "Khác" slice. Percentages are whole numbers that add up to 100.
SpendingBreakdown spendingBreakdown(
  CashflowReport report,
  String currency,
  List<FinanceCategory> categories, {
  int top = 3,
}) {
  final namesById = {for (final c in categories) c.id: c.name};
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
  // Unknown or uncategorised spending falls into "Khác".
  String? nameOf(String? id) => id == null ? null : namesById[id];
  final total = byParent.values.fold(BigInt.zero, (a, b) => a + b);
  if (total == BigInt.zero) {
    return SpendingBreakdown(total: total, slices: const []);
  }
  final sorted = byParent.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final named = [
    for (final e in sorted)
      if (nameOf(e.key) != null) e,
  ];
  final head = named.take(top).toList();
  final rest = sorted
      .where((e) => !head.contains(e))
      .fold(BigInt.zero, (a, e) => a + e.value);
  final amounts = [
    for (final e in head) (nameOf(e.key), e.value),
    if (rest > BigInt.zero) (null, rest),
  ];
  final percents = _wholePercents([for (final a in amounts) a.$2], total);
  return SpendingBreakdown(
    total: total,
    slices: [
      for (var i = 0; i < amounts.length; i++)
        SpendingSlice(
          name: amounts[i].$1,
          minor: amounts[i].$2,
          percent: percents[i],
        ),
    ],
  );
}

/// Largest-remainder rounding so the shown percentages sum to exactly 100.
List<int> _wholePercents(List<BigInt> parts, BigInt total) {
  final scaled = [for (final p in parts) p * BigInt.from(100)];
  final floors = [for (final s in scaled) (s ~/ total).toInt()];
  final remainders = [
    for (var i = 0; i < parts.length; i++) (i, scaled[i] % total),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  var missing = 100 - floors.fold(0, (a, b) => a + b);
  for (final (index, _) in remainders) {
    if (missing <= 0) break;
    floors[index]++;
    missing--;
  }
  return floors;
}

/// Credit wallets as cards, in wallet order.
List<CreditCardStatus> creditCards(List<Wallet> wallets, DateTime today) => [
  for (final wallet in wallets)
    if (wallet.draft.type == WalletType.credit)
      CreditCardStatus.of(wallet, today),
];
