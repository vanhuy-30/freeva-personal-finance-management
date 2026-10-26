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
  FinanceCategory(id: 'home', name: 'Nhà ở', parentId: null),
  FinanceCategory(id: 'bus', name: 'Đi lại', parentId: null),
  FinanceCategory(id: 'fun', name: 'Giải trí', parentId: null),
  FinanceCategory(id: 'gift', name: 'Quà tặng', parentId: null),
  FinanceCategory(id: 'salary', name: 'Thu nhập', parentId: null),
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

List<TransactionBundle> recent() => [
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
        merchant: 'Lương tháng 10',
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
  List<TransactionBundle>? rows,
}) => OverviewData(
  netWorth: NetWorthReport(items: net ?? [worth('VND', 48250000)]),
  month: flow ?? month(),
  previousMonth: previous,
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
  loadedAt: DateTime(2026, 10, 21, 9, 30),
);

CashflowTotal usdSpend() => CashflowTotal(
  currency: 'USD',
  incomeMinor: BigInt.zero,
  expenseMinor: b(-3500),
  netMinor: b(-3500),
);
