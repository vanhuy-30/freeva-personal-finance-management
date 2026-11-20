import 'package:mobile/features/budgets/domain/budget.dart';
import 'package:mobile/features/calendar/domain/calendar_month.dart';
import 'package:mobile/features/investments/domain/investment.dart';
import 'package:mobile/features/loans/domain/loan.dart';
import 'package:mobile/features/net_worth/domain/net_worth_history.dart';
import 'package:mobile/features/categories/domain/finance_category.dart';
import 'package:mobile/features/home/domain/overview.dart';
import 'package:mobile/features/reports/domain/report.dart';
import 'package:mobile/features/transactions/domain/transaction.dart';
import 'package:mobile/features/wallets/domain/wallet.dart';

BigInt b(int v) => BigInt.from(v);

Wallet wallet(
  String id,
  String name, {
  WalletType type = WalletType.bank,
  String currency = 'VND',
  int balance = 0,
  int? limit,
  int? dueDay,
  bool archived = false,
}) => Wallet(
  id: id,
  createdAt: DateTime.utc(2026),
  draft: WalletDraft(
    name: name,
    type: type,
    currency: currency,
    initialBalance: BigInt.zero,
    creditLimit: limit == null ? null : b(limit),
    dueDay: dueDay,
  ),
  balance: b(balance),
  version: 1,
  sortOrder: 0,
  archived: archived,
);

ReportPeriod period(String from, String to) => ReportPeriod(
  kind: ReportPeriodKind.month,
  from: from,
  to: to,
  timezone: 'Asia/Ho_Chi_Minh',
  fiscalMonthStartDay: 1,
);

CashflowCategoryRow spend(
  String id,
  int minor, {
  String? parent,
  String currency = 'VND',
}) => CashflowCategoryRow(
  categoryId: id,
  parentId: parent,
  currency: currency,
  incomeMinor: BigInt.zero,
  expenseMinor: b(-minor),
);

CashflowReport month({
  int income = 18500000,
  int expense = 9320000,
  List<CashflowCategoryRow>? rows,
  List<CashflowTotal> extra = const [],
  String from = '2026-10-01',
  String to = '2026-10-31',
}) => CashflowReport(
  period: period(from, to),
  totals: [
    CashflowTotal(
      currency: 'VND',
      incomeMinor: b(income),
      expenseMinor: b(-expense),
      netMinor: b(income - expense),
    ),
    ...extra,
  ],
  byCategory:
      rows ??
      [
        spend('food', 3541600),
        spend('home', 2236800),
        spend('bus', 1677600),
        spend('fun', 1000000),
        spend('gift', 864000),
      ],
  byAccount: const [],
);

const categories = [
  FinanceCategory(
    id: 'food',
    name: 'Ăn uống',
    parentId: null,
    iconToken: 'food',
  ),
  FinanceCategory(id: 'pho', name: 'Phở', parentId: 'food'),
  FinanceCategory(
    id: 'home',
    name: 'Nhà ở',
    parentId: null,
    iconToken: 'housing',
  ),
  FinanceCategory(
    id: 'bus',
    name: 'Đi lại',
    parentId: null,
    iconToken: 'transport',
  ),
  FinanceCategory(
    id: 'coffee',
    name: 'Cà phê',
    parentId: null,
    iconToken: 'coffee',
  ),
  FinanceCategory(id: 'fun', name: 'Giải trí', parentId: null),
  FinanceCategory(id: 'gift', name: 'Quà tặng', parentId: null),
  FinanceCategory(
    id: 'salary',
    name: 'Thu nhập',
    parentId: null,
    iconToken: 'salary',
  ),
];

TxLeg leg(
  String id, {
  required String account,
  required int amount,
  TransactionType type = TransactionType.expense,
  String? category,
  String? merchant,
  String? group,
}) => TxLeg(
  id: id,
  clientId: 'c-$id',
  accountId: account,
  currencyCode: 'VND',
  amountMinor: b(amount),
  type: type,
  occurredOn: '2026-10-21',
  categoryId: category,
  notes: null,
  merchant: merchant,
  tagIds: const [],
  transferGroupId: group,
  deletedAt: null,
  version: 1,
  createdAt: DateTime.utc(2026, 10, 21),
);

List<TransactionBundle> recent({String salary = 'Lương tháng 10'}) => [
  TransactionBundle(
    legs: [
      leg(
        't1',
        account: 'cash',
        amount: -65000,
        category: 'food',
        merchant: 'Phở Thìn',
      ),
    ],
  ),
  TransactionBundle(
    legs: [
      leg(
        't2',
        account: 'momo',
        amount: -48000,
        category: 'bus',
        merchant: 'Grab',
      ),
    ],
  ),
  TransactionBundle(
    legs: [
      leg(
        't3',
        account: 'vcb',
        amount: 18500000,
        type: TransactionType.income,
        category: 'salary',
        merchant: salary,
      ),
    ],
  ),
];

NetWorthTotal worth(String currency, int minor) => NetWorthTotal(
  currency: currency,
  assetsMinor: b(minor),
  liabilitiesMinor: BigInt.zero,
  netWorthMinor: b(minor),
);

OverviewData overview({
  List<Wallet>? wallets,
  List<NetWorthTotal>? net,
  CashflowReport? flow,
  CashflowReport? previous,
  CashflowReport? before,
  BudgetSummary? previousBudget,
  BudgetSummary? budget,
  List<TransactionBundle>? rows,
  NetWorthSeries? trend,
  InvestmentSummary? investments,
  List<Loan>? loans,
  List<CalendarMonth>? calendar,
  DateTime? loadedAt,
}) => OverviewData(
  netWorth: NetWorthReport(items: net ?? [worth('VND', 48250000)]),
  month: flow ?? month(),
  previousMonth: previous,
  monthBefore: before,
  previousBudget: previousBudget,
  budget: budget,
  netWorthTrend: trend,
  investments: investments,
  loans: loans,
  calendar: calendar,
  wallets:
      wallets ??
      [
        wallet('vcb', 'Vietcombank', balance: 32400000),
        wallet('cash', 'Tiền mặt', type: WalletType.cash, balance: 3700000),
        wallet('momo', 'MoMo', type: WalletType.ewallet, balance: 2150000),
        wallet('tcb', 'Techcombank', balance: 10000000),
      ],
  currencies: const [WalletCurrency('VND', 0), WalletCurrency('USD', 2)],
  recent: rows ?? recent(),
  categories: categories,
  loadedAt: loadedAt ?? DateTime(2026, 10, 21, 9, 30),
);

CashflowTotal usdSpend() => CashflowTotal(
  currency: 'USD',
  incomeMinor: BigInt.zero,
  expenseMinor: b(-3500),
  netMinor: b(-3500),
);

/// Budget of [spent] against [limit], VND, for the month of [from].
BudgetSummary budgetOf(
  int limit,
  int spent, {
  String currency = 'VND',
  String from = '2026-10-01',
  String to = '2026-10-31',
}) => BudgetSummary(
  id: 'b1',
  currencyCode: currency,
  limitMinor: b(limit),
  spentMinor: b(spent),
  remainingMinor: b(limit - spent),
  percentBps: limit == 0 ? 0 : spent * 10000 ~/ limit,
  status: spent > limit ? BudgetStatus.over : BudgetStatus.healthy,
  alertThresholds: const [80, 100],
  crossedThresholds: const [],
  categories: const [],
  period: BudgetPeriod(
    from: from,
    to: to,
    timezone: 'Asia/Ho_Chi_Minh',
    fiscalMonthStartDay: 1,
  ),
  applyTo: BudgetApplyTo.defaultTemplate,
  isOverride: false,
  version: 1,
);

/// PA 3 (board BHome), 10/11: net worth 703.609.734 (assets 966.009.734,
/// debts 262.400.000), budget 5,4/15 tr, tuition due 15/11, the main card
/// due 25/11, a mortgage installment on 25/11 and investments up 8%.
OverviewData pa3Overview() {
  const day = 86400000;
  final end = DateTime(2026, 11, 10);
  return overview(
    net: [
      NetWorthTotal(
        currency: 'VND',
        assetsMinor: b(966009734),
        liabilitiesMinor: b(-262400000),
        netWorthMinor: b(703609734),
      ),
    ],
    wallets: [
      wallet('vcb', 'Vietcombank', balance: 52530000),
      wallet('cash', 'Tiền mặt', type: WalletType.cash, balance: 3700000),
      wallet('momo', 'MoMo', type: WalletType.ewallet, balance: 4300000),
      wallet('tcb', 'Techcombank', balance: 10000000),
      wallet(
        'main',
        'Thẻ chính',
        type: WalletType.credit,
        balance: -15600000,
        limit: 20000000,
        dueDay: 25,
      ),
      wallet(
        'travel',
        'Thẻ du lịch',
        type: WalletType.credit,
        balance: -1800000,
        limit: 10000000,
        dueDay: 5,
      ),
    ],
    flow: month(
      income: 18500000,
      expense: 5400000,
      rows: [
        spend('food', 2160000),
        spend('home', 1782000),
        spend('bus', 1458000),
      ],
      from: '2026-11-01',
      to: '2026-11-30',
    ),
    budget: budgetOf(15000000, 5400000, from: '2026-11-01', to: '2026-11-30'),
    trend: NetWorthSeries(
      window: NetWorthWindow.month,
      currency: 'VND',
      points: [
        for (var i = 29; i >= 0; i--)
          NetWorthPoint(
            asOf: DateTime.fromMillisecondsSinceEpoch(
              end.millisecondsSinceEpoch - i * day,
            ).toIso8601String().substring(0, 10),
            assetsMinor: b(966009734),
            liabilitiesMinor: b(-262400000),
            // 691.168.697 on 31/10, so +1,8% by today.
            netWorthMinor: b(
              i == 0 ? 703609734 : 691168697 - (i - 10) * 300000,
            ),
            investmentMinor: b(
              830250000 + (29 - i) * 2180000 + (i % 3) * 1500000,
            ),
          ),
      ],
    ),
    investments: InvestmentSummary(
      totals: [
        InvestmentTotal(
          currencyCode: 'VND',
          costBasisMinor: b(830250000),
          currentValueMinor: b(893479734),
          unrealizedMinor: b(63229734),
          unrealizedBps: 800,
          unpricedCount: 0,
        ),
      ],
    ),
    loans: [
      Loan(
        id: 'home',
        clientId: 'c-home',
        kind: LoanKind.mortgage,
        name: 'Vay mua nhà',
        currencyCode: 'VND',
        principalMinor: b(300000000),
        outstandingMinor: b(245000000),
        paidMinor: b(55000000),
        percentBps: 1833,
        interestRateBps: 900,
        frequency: LoanFrequency.monthly,
        startDate: '2024-01-25',
        periodInterestMinor: b(1837500),
        status: LoanStatus.active,
        version: 1,
        installmentMinor: b(9200000),
        nextDueDate: '2026-11-25',
      ),
    ],
    calendar: [
      CalendarMonth(
        month: '2026-11',
        timezone: 'Asia/Ho_Chi_Minh',
        today: '2026-11-10',
        days: [
          CalendarDay(
            date: '2026-11-15',
            transactions: const [],
            recurring: const [],
            bills: [
              CalendarBillItem(
                id: 'tuition',
                name: 'Học phí',
                dueOn: '2026-11-15',
                amountMinor: b(6230000),
                amountKind: 'fixed',
                currencyCode: 'VND',
                paid: false,
                overdue: false,
              ),
            ],
          ),
        ],
      ),
    ],
    rows: recent(salary: 'Lương tháng 11'),
    loadedAt: DateTime(2026, 11, 10, 9, 30),
  );
}
