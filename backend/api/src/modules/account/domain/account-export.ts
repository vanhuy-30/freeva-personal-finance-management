export interface AccountExport {
  schemaVersion: number;
  exportedAt: string;
  userId: string;
  profile: {
    email: string;
    displayName: string | null;
    locale: string;
    timezone: string;
    defaultCurrencyCode: string;
    fiscalMonthStartDay: number;
    onboardingGoals: string[];
    monthlyIncomeMinor: string | null;
    displayCurrencyCode: string | null;
    emailVerifiedAt: string | null;
    categoriesInitializedAt: string | null;
    categoriesSupplementedAt: string | null;
    autoSuggestEnabled: boolean;
    createdAt: string;
    updatedAt: string;
  };
  oauthProviders: Array<'google' | 'apple'>;
  financialAccounts: AccountExportAccount[];
  categoryGroups: AccountExportGroup[];
  categories: AccountExportCategory[];
  tags: AccountExportTag[];
  fxQuotes: AccountExportQuote[];
  fxRates: AccountExportFxRate[];
  recurringRules: AccountExportRecurringRule[];
  budget: AccountExportBudget | null;
  budgetMonths: AccountExportBudgetMonth[];
  goals: AccountExportGoal[];
  goalEntries: AccountExportGoalEntry[];
  loans: AccountExportLoan[];
  loanPayments: AccountExportLoanPayment[];
  personalDebts: AccountExportPersonalDebt[];
  personalDebtPayments: AccountExportPersonalDebtPayment[];
  investments: AccountExportInvestment[];
  investmentTrades: AccountExportInvestmentTrade[];
  investmentPrices: AccountExportInvestmentPrice[];
  cardInstallmentPlans: AccountExportCardInstallmentPlan[];
  importBatches: AccountExportImportBatch[];
  /** PRD-P5-E01: merchants remembered for category suggestions. */
  categorySuggestionMappings: AccountExportSuggestionMapping[];
  notificationPreferences: AccountExportNotificationPreferences | null;
  notifications: AccountExportNotification[];
  transactions: AccountExportTransaction[];
}

export interface AccountExportNotificationPreferences {
  budgetEnabled: boolean;
  goalEnabled: boolean;
  debtEnabled: boolean;
  cardEnabled: boolean;
  recurringEnabled: boolean;
  monthReviewEnabled: boolean;
  insightEnabled: boolean;
  dailyLogEnabled: boolean;
  dailyLogTime: string;
  quietHoursEnabled: boolean;
  quietStart: string;
  quietEnd: string;
  version: number;
  createdAt: string;
  updatedAt: string;
}

export interface AccountExportNotification {
  id: string;
  kind: string;
  dedupeKey: string;
  titleKey: string;
  bodyKey: string;
  params: Record<string, string | number>;
  createdAt: string;
  readAt: string | null;
}

interface SyncRow {
  id: string;
  clientId: string;
  version: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface AccountExportAccount extends Omit<SyncRow, 'createdAt' | 'updatedAt'> {
  name: string;
  type: 'cash' | 'bank' | 'ewallet' | 'credit';
  currencyCode: string;
  initialBalanceMinor: string;
  sortOrder: number;
  archivedAt: string | null;
  creditLimitMinor: string | null;
  statementCloseDay: number | null;
  paymentDueDay: number | null;
  minimumPaymentMinor: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AccountExportGroup extends Omit<SyncRow, 'createdAt' | 'updatedAt'> {
  name: string;
  isSystem: boolean;
  archivedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AccountExportCategory extends AccountExportGroup {
  kind: 'expense' | 'income' | 'both';
  groupId: string | null;
  parentId: string | null;
  colorToken: string | null;
  iconToken: string | null;
}

export interface AccountExportTag extends Omit<SyncRow, 'createdAt' | 'updatedAt'> {
  name: string;
  createdAt: string;
  updatedAt: string;
}

export interface AccountExportQuote extends Omit<SyncRow, 'createdAt' | 'updatedAt'> {
  fromCode: string;
  toCode: string;
  rate: string;
  quotedAt: string;
  source: 'manual' | 'provider';
  createdAt: string;
  updatedAt: string;
}

/** User-typed rate used only to show converted amounts (BE-P2-013). */
export interface AccountExportFxRate {
  fromCode: string;
  toCode: string;
  rate: string;
  quotedAt: string;
  createdAt: string;
  updatedAt: string;
}

export interface AccountExportRecurringRule extends Omit<SyncRow, 'createdAt' | 'updatedAt'> {
  type: 'income' | 'expense' | 'transfer' | 'adjustment' | 'debt' | 'refund' | 'investment';
  mode: 'auto' | 'remind';
  name: string | null;
  amountKind: 'fixed' | 'estimated';
  remindDaysBefore: number;
  unit: 'day' | 'week' | 'month' | 'year';
  interval: number;
  amountMinor: string;
  currencyCode: string;
  accountId: string | null;
  categoryId: string | null;
  counterAccountId: string | null;
  counterAmountMinor: string | null;
  counterCurrencyCode: string | null;
  fxRate: string | null;
  startDate: string;
  endDate: string | null;
  nextExecutionDate: string;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface AccountExportGoal extends Omit<SyncRow, 'createdAt' | 'updatedAt'> {
  kind: string;
  name: string;
  currencyCode: string;
  targetMinor: string;
  currentMinor: string;
  targetDate: string | null;
  accountId: string;
  monthlyContributionMinor: string | null;
  icon: string;
  colorToken: string | null;
  archivedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AccountExportGoalEntry {
  id: string;
  goalId: string;
  clientId: string;
  kind: string;
  amountMinor: string;
  transactionClientId: string | null;
  occurredOn: string;
  createdAt: string;
}

export interface AccountExportLoan extends Omit<SyncRow, 'createdAt' | 'updatedAt'> {
  kind: string;
  name: string;
  currencyCode: string;
  principalMinor: string;
  outstandingMinor: string;
  interestRateBps: number;
  installmentMinor: string | null;
  frequency: string;
  startDate: string;
  endDate: string | null;
  nextDueDate: string | null;
  accountId: string | null;
  archivedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AccountExportLoanPayment {
  id: string;
  loanId: string;
  clientId: string;
  principalMinor: string;
  interestMinor: string;
  principalTransactionClientId: string | null;
  interestTransactionClientId: string | null;
  paidOn: string;
  createdAt: string;
}

export interface AccountExportPersonalDebt extends Omit<SyncRow, 'createdAt' | 'updatedAt'> {
  direction: string;
  counterparty: string;
  currencyCode: string;
  principalMinor: string;
  outstandingMinor: string;
  accountId: string;
  transactionClientId: string;
  occurredOn: string;
  dueDate: string | null;
  note: string | null;
  archivedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AccountExportPersonalDebtPayment {
  id: string;
  debtId: string;
  clientId: string;
  accountId: string;
  amountMinor: string;
  transactionClientId: string;
  paidOn: string;
  createdAt: string;
}

export interface AccountExportInvestment extends Omit<SyncRow, 'createdAt' | 'updatedAt'> {
  kind: string;
  name: string;
  currencyCode: string;
  unit: string;
  quantity: string;
  costBasisMinor: string;
  interestRateBps: number | null;
  startDate: string | null;
  maturityDate: string | null;
  note: string | null;
  archivedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AccountExportInvestmentTrade {
  id: string;
  investmentId: string;
  clientId: string;
  side: string;
  quantity: string;
  amountMinor: string;
  realizedMinor: string | null;
  /** Null for a buy the user already owned (no wallet leg). */
  accountId: string | null;
  transactionClientId: string | null;
  tradedOn: string;
  note: string | null;
  createdAt: string;
}

export interface AccountExportInvestmentPrice {
  id: string;
  investmentId: string;
  clientId: string;
  priceMinor: string;
  source: string;
  quotedAt: string;
  createdAt: string;
}

export interface AccountExportSuggestionMapping {
  id: string;
  merchant: string;
  categoryId: string;
  createdAt: string;
  updatedAt: string;
}

export interface AccountExportImportBatch {
  id: string;
  clientId: string;
  preset: string;
  rowCount: number;
  createdCount: number;
  duplicateCount: number;
  invalidCount: number;
  undoneAt: string | null;
  createdAt: string;
}

export interface AccountExportCardInstallmentPlan extends Omit<SyncRow, 'createdAt' | 'updatedAt'> {
  transactionId: string;
  accountId: string;
  currencyCode: string;
  totalMinor: string;
  installmentMinor: string;
  installmentCount: number;
  firstDueOn: string;
  status: string;
  closedAt: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface AccountExportBudgetCategory {
  categoryId: string;
  limitMinor: string;
}

export interface AccountExportBudget {
  id: string;
  currencyCode: string;
  limitMinor: string;
  alertThresholds: number[];
  version: number;
  categories: AccountExportBudgetCategory[];
  createdAt: string;
  updatedAt: string;
}

export interface AccountExportBudgetMonth extends AccountExportBudget {
  periodFrom: string;
  periodTo: string;
}

export interface AccountExportTransaction extends Omit<SyncRow, 'createdAt' | 'updatedAt'> {
  type: 'income' | 'expense' | 'transfer' | 'adjustment' | 'debt' | 'refund' | 'investment';
  amountMinor: string;
  currencyCode: string;
  occurredOn: string;
  occurredTime: string | null;
  accountId: string;
  categoryId: string | null;
  transferGroupId: string | null;
  /** Only on `refund`: the expense it returns money for. */
  refundOfId: string | null;
  fxQuoteId: string | null;
  recurringRuleId: string | null;
  notes: string | null;
  merchant: string | null;
  deletedAt: string | null;
  tagIds: string[];
  createdAt: string;
  updatedAt: string;
}

export interface ExportSource {
  schemaVersion: number;
  exportedAt: Date;
  user: {
    id: string;
    email: string;
    displayName: string | null;
    locale: string;
    timezone: string;
    defaultCurrencyCode: string;
    fiscalMonthStartDay: number;
    onboardingGoals: string[];
    monthlyIncomeMinor: bigint | null;
    displayCurrencyCode: string | null;
    emailVerifiedAt: Date | null;
    categoriesInitializedAt: Date | null;
    categoriesSupplementedAt: Date | null;
    autoSuggestEnabled: boolean;
    createdAt: Date;
    updatedAt: Date;
  };
  oauthProviders: Array<'google' | 'apple'>;
  financialAccounts: Array<Omit<AccountExportAccount, 'initialBalanceMinor' | 'creditLimitMinor' | 'minimumPaymentMinor' | 'archivedAt' | 'createdAt' | 'updatedAt' | 'currencyCode'> & {
    currencyCode: string;
    initialBalanceMinor: bigint;
    creditLimitMinor: bigint | null;
    minimumPaymentMinor: bigint | null;
    archivedAt: Date | null;
    createdAt: Date;
    updatedAt: Date;
  }>;
  categoryGroups: Array<Omit<AccountExportGroup, 'archivedAt' | 'createdAt' | 'updatedAt'> & {
    archivedAt: Date | null;
    createdAt: Date;
    updatedAt: Date;
  }>;
  categories: Array<Omit<AccountExportCategory, 'archivedAt' | 'createdAt' | 'updatedAt'> & {
    archivedAt: Date | null;
    createdAt: Date;
    updatedAt: Date;
  }>;
  tags: Array<Omit<AccountExportTag, 'createdAt' | 'updatedAt'> & { createdAt: Date; updatedAt: Date }>;
  fxQuotes: Array<Omit<AccountExportQuote, 'rate' | 'quotedAt' | 'createdAt' | 'updatedAt'> & {
    rate: string;
    quotedAt: Date;
    createdAt: Date;
    updatedAt: Date;
  }>;
  fxRates: Array<Omit<AccountExportFxRate, 'rate' | 'quotedAt' | 'createdAt' | 'updatedAt'> & {
    rate: string;
    quotedAt: Date;
    createdAt: Date;
    updatedAt: Date;
  }>;
  recurringRules: Array<Omit<AccountExportRecurringRule, 'amountMinor' | 'counterAmountMinor' | 'fxRate' | 'startDate' | 'endDate' | 'nextExecutionDate' | 'createdAt' | 'updatedAt' | 'currencyCode' | 'counterCurrencyCode'> & {
    currencyCode: string;
    amountMinor: bigint;
    counterAmountMinor: bigint | null;
    counterCurrencyCode: string | null;
    fxRate: string | null;
    startDate: Date;
    endDate: Date | null;
    nextExecutionDate: Date;
    createdAt: Date;
    updatedAt: Date;
  }>;
  budget: null | {
    id: string;
    currencyCode: string;
    limitMinor: bigint;
    alertThresholds: number[];
    version: number;
    createdAt: Date;
    updatedAt: Date;
    categories: Array<{ categoryId: string; limitMinor: bigint }>;
  };
  goals: Array<{
    id: string;
    clientId: string;
    kind: string;
    name: string;
    currencyCode: string;
    targetMinor: bigint;
    currentMinor: bigint;
    targetDate: Date | null;
    accountId: string;
    monthlyContributionMinor: bigint | null;
    icon: string;
    colorToken: string | null;
    archivedAt: Date | null;
    version: number;
    createdAt: Date;
    updatedAt: Date;
  }>;
  goalEntries: Array<{
    id: string;
    goalId: string;
    clientId: string;
    kind: string;
    amountMinor: bigint;
    transactionClientId: string | null;
    occurredOn: Date;
    createdAt: Date;
  }>;
  loans: Array<{
    id: string;
    clientId: string;
    kind: string;
    name: string;
    currencyCode: string;
    principalMinor: bigint;
    outstandingMinor: bigint;
    interestRateBps: number;
    installmentMinor: bigint | null;
    frequency: string;
    startDate: Date;
    endDate: Date | null;
    nextDueDate: Date | null;
    accountId: string | null;
    archivedAt: Date | null;
    version: number;
    createdAt: Date;
    updatedAt: Date;
  }>;
  loanPayments: Array<{
    id: string;
    loanId: string;
    clientId: string;
    principalMinor: bigint;
    interestMinor: bigint;
    principalTransactionClientId: string | null;
    interestTransactionClientId: string | null;
    paidOn: Date;
    createdAt: Date;
  }>;
  personalDebts: Array<{
    id: string;
    clientId: string;
    direction: string;
    counterparty: string;
    currencyCode: string;
    principalMinor: bigint;
    outstandingMinor: bigint;
    accountId: string;
    transactionClientId: string;
    occurredOn: Date;
    dueDate: Date | null;
    note: string | null;
    archivedAt: Date | null;
    version: number;
    createdAt: Date;
    updatedAt: Date;
  }>;
  personalDebtPayments: Array<{
    id: string;
    debtId: string;
    clientId: string;
    accountId: string;
    amountMinor: bigint;
    transactionClientId: string;
    paidOn: Date;
    createdAt: Date;
  }>;
  investments: Array<{
    id: string;
    clientId: string;
    kind: string;
    name: string;
    currencyCode: string;
    unit: string;
    quantity: { toFixed(digits: number): string };
    costBasisMinor: bigint;
    interestRateBps: number | null;
    startDate: Date | null;
    maturityDate: Date | null;
    note: string | null;
    archivedAt: Date | null;
    version: number;
    createdAt: Date;
    updatedAt: Date;
  }>;
  investmentTrades: Array<{
    id: string;
    investmentId: string;
    clientId: string;
    side: string;
    quantity: { toFixed(digits: number): string };
    amountMinor: bigint;
    realizedMinor: bigint | null;
    accountId: string | null;
    transactionClientId: string | null;
    tradedOn: Date;
    note: string | null;
    createdAt: Date;
  }>;
  investmentPrices: Array<{
    id: string;
    investmentId: string;
    clientId: string;
    priceMinor: bigint;
    source: string;
    quotedAt: Date;
    createdAt: Date;
  }>;
  categorySuggestionMappings: Array<{ id: string; merchant: string; categoryId: string; createdAt: Date; updatedAt: Date }>;
  importBatches: Array<{
    id: string;
    clientId: string;
    preset: string;
    rowCount: number;
    createdCount: number;
    duplicateCount: number;
    invalidCount: number;
    undoneAt: Date | null;
    createdAt: Date;
  }>;
  cardInstallmentPlans: Array<{
    id: string;
    clientId: string;
    transactionId: string;
    accountId: string;
    currencyCode: string;
    totalMinor: bigint;
    installmentMinor: bigint;
    installmentCount: number;
    firstDueOn: Date;
    status: string;
    closedAt: Date | null;
    version: number;
    createdAt: Date;
    updatedAt: Date;
  }>;
  budgetMonths: Array<{
    id: string;
    currencyCode: string;
    limitMinor: bigint;
    alertThresholds: number[];
    version: number;
    periodFrom: Date;
    periodTo: Date;
    createdAt: Date;
    updatedAt: Date;
    categories: Array<{ categoryId: string; limitMinor: bigint }>;
  }>;
  notificationPreferences: null | {
    budgetEnabled: boolean;
    goalEnabled: boolean;
    debtEnabled: boolean;
    cardEnabled: boolean;
    recurringEnabled: boolean;
    monthReviewEnabled: boolean;
    insightEnabled: boolean;
    dailyLogEnabled: boolean;
    dailyLogTime: string;
    quietHoursEnabled: boolean;
    quietStart: string;
    quietEnd: string;
    version: number;
    createdAt: Date;
    updatedAt: Date;
  };
  notifications: Array<{
    id: string;
    kind: string;
    dedupeKey: string;
    titleKey: string;
    bodyKey: string;
    params: Record<string, string | number>;
    createdAt: Date;
    readAt: Date | null;
  }>;
  transactions: Array<Omit<AccountExportTransaction, 'amountMinor' | 'occurredOn' | 'deletedAt' | 'createdAt' | 'updatedAt' | 'currencyCode'> & {
    currencyCode: string;
    amountMinor: bigint;
    occurredOn: Date;
    occurredTime: string | null;
    deletedAt: Date | null;
    createdAt: Date;
    updatedAt: Date;
  }>;
}

const iso = (value: Date) => value.toISOString();
const day = (value: Date) => value.toISOString().slice(0, 10);
const code = (value: string) => value.trim();
const stamps = (row: { createdAt: Date; updatedAt: Date }) => ({ createdAt: iso(row.createdAt), updatedAt: iso(row.updatedAt) });

export function toAccountExport(source: ExportSource): AccountExport {
  const user = source.user;
  return {
    schemaVersion: source.schemaVersion,
    exportedAt: iso(source.exportedAt),
    userId: user.id,
    profile: {
      email: user.email,
      displayName: user.displayName,
      locale: user.locale,
      timezone: user.timezone,
      defaultCurrencyCode: code(user.defaultCurrencyCode),
      fiscalMonthStartDay: user.fiscalMonthStartDay,
      onboardingGoals: [...user.onboardingGoals],
      monthlyIncomeMinor: user.monthlyIncomeMinor?.toString() ?? null,
      displayCurrencyCode: user.displayCurrencyCode ? code(user.displayCurrencyCode) : null,
      emailVerifiedAt: user.emailVerifiedAt ? iso(user.emailVerifiedAt) : null,
      categoriesInitializedAt: user.categoriesInitializedAt ? iso(user.categoriesInitializedAt) : null,
      categoriesSupplementedAt: user.categoriesSupplementedAt ? iso(user.categoriesSupplementedAt) : null,
      autoSuggestEnabled: user.autoSuggestEnabled,
      ...stamps(user),
    },
    oauthProviders: [...source.oauthProviders].sort(),
    financialAccounts: source.financialAccounts.map(row => ({
      id: row.id, clientId: row.clientId, name: row.name, type: row.type, currencyCode: code(row.currencyCode),
      initialBalanceMinor: row.initialBalanceMinor.toString(), sortOrder: row.sortOrder,
      archivedAt: row.archivedAt ? iso(row.archivedAt) : null,
      creditLimitMinor: row.creditLimitMinor?.toString() ?? null,
      statementCloseDay: row.statementCloseDay, paymentDueDay: row.paymentDueDay,
      minimumPaymentMinor: row.minimumPaymentMinor?.toString() ?? null,
      version: row.version, ...stamps(row),
    })),
    categoryGroups: source.categoryGroups.map(row => ({
      id: row.id, clientId: row.clientId, name: row.name, isSystem: row.isSystem,
      archivedAt: row.archivedAt ? iso(row.archivedAt) : null, version: row.version, ...stamps(row),
    })),
    categories: source.categories.map(row => ({
      id: row.id, clientId: row.clientId, name: row.name, isSystem: row.isSystem, kind: row.kind,
      groupId: row.groupId, parentId: row.parentId, colorToken: row.colorToken, iconToken: row.iconToken,
      archivedAt: row.archivedAt ? iso(row.archivedAt) : null, version: row.version, ...stamps(row),
    })),
    tags: source.tags.map(row => ({ id: row.id, clientId: row.clientId, name: row.name, version: row.version, ...stamps(row) })),
    fxQuotes: source.fxQuotes.map(row => ({
      id: row.id, clientId: row.clientId, fromCode: code(row.fromCode), toCode: code(row.toCode),
      rate: row.rate, quotedAt: iso(row.quotedAt), source: row.source, version: row.version, ...stamps(row),
    })),
    fxRates: source.fxRates.map(row => ({
      fromCode: code(row.fromCode), toCode: code(row.toCode), rate: row.rate, quotedAt: iso(row.quotedAt), ...stamps(row),
    })),
    recurringRules: source.recurringRules.map(row => ({
      id: row.id, clientId: row.clientId, type: row.type, mode: row.mode, name: row.name,
      amountKind: row.amountKind, remindDaysBefore: row.remindDaysBefore, unit: row.unit, interval: row.interval,
      amountMinor: row.amountMinor.toString(), currencyCode: code(row.currencyCode), accountId: row.accountId,
      categoryId: row.categoryId, counterAccountId: row.counterAccountId,
      counterAmountMinor: row.counterAmountMinor?.toString() ?? null,
      counterCurrencyCode: row.counterCurrencyCode ? code(row.counterCurrencyCode) : null,
      fxRate: row.fxRate, startDate: day(row.startDate), endDate: row.endDate ? day(row.endDate) : null,
      nextExecutionDate: day(row.nextExecutionDate), active: row.active, version: row.version, ...stamps(row),
    })),
    budget: source.budget === null ? null : {
      id: source.budget.id,
      currencyCode: code(source.budget.currencyCode),
      limitMinor: source.budget.limitMinor.toString(),
      alertThresholds: [...source.budget.alertThresholds],
      version: source.budget.version,
      categories: source.budget.categories.map(line => ({
        categoryId: line.categoryId,
        limitMinor: line.limitMinor.toString(),
      })),
      ...stamps(source.budget),
    },
    budgetMonths: source.budgetMonths.map(row => ({
      id: row.id,
      currencyCode: code(row.currencyCode),
      limitMinor: row.limitMinor.toString(),
      alertThresholds: [...row.alertThresholds],
      version: row.version,
      periodFrom: day(row.periodFrom),
      periodTo: day(row.periodTo),
      categories: row.categories.map(line => ({
        categoryId: line.categoryId,
        limitMinor: line.limitMinor.toString(),
      })),
      ...stamps(row),
    })),
    goals: source.goals.map(row => ({
      id: row.id, clientId: row.clientId, kind: row.kind, name: row.name, currencyCode: code(row.currencyCode),
      targetMinor: row.targetMinor.toString(), currentMinor: row.currentMinor.toString(),
      targetDate: row.targetDate ? day(row.targetDate) : null, accountId: row.accountId,
      monthlyContributionMinor: row.monthlyContributionMinor === null ? null : row.monthlyContributionMinor.toString(),
      icon: row.icon, colorToken: row.colorToken, archivedAt: row.archivedAt ? iso(row.archivedAt) : null,
      version: row.version, ...stamps(row),
    })),
    goalEntries: source.goalEntries.map(row => ({
      id: row.id, goalId: row.goalId, clientId: row.clientId, kind: row.kind,
      amountMinor: row.amountMinor.toString(), transactionClientId: row.transactionClientId,
      occurredOn: day(row.occurredOn), createdAt: iso(row.createdAt),
    })),
    loans: source.loans.map(row => ({
      id: row.id, clientId: row.clientId, kind: row.kind, name: row.name, currencyCode: code(row.currencyCode),
      principalMinor: row.principalMinor.toString(), outstandingMinor: row.outstandingMinor.toString(),
      interestRateBps: row.interestRateBps,
      installmentMinor: row.installmentMinor === null ? null : row.installmentMinor.toString(),
      frequency: row.frequency, startDate: day(row.startDate),
      endDate: row.endDate ? day(row.endDate) : null, nextDueDate: row.nextDueDate ? day(row.nextDueDate) : null,
      accountId: row.accountId, archivedAt: row.archivedAt ? iso(row.archivedAt) : null,
      version: row.version, ...stamps(row),
    })),
    loanPayments: source.loanPayments.map(row => ({
      id: row.id, loanId: row.loanId, clientId: row.clientId,
      principalMinor: row.principalMinor.toString(), interestMinor: row.interestMinor.toString(),
      principalTransactionClientId: row.principalTransactionClientId,
      interestTransactionClientId: row.interestTransactionClientId,
      paidOn: day(row.paidOn), createdAt: iso(row.createdAt),
    })),
    personalDebts: source.personalDebts.map(row => ({
      id: row.id, clientId: row.clientId, direction: row.direction, counterparty: row.counterparty,
      currencyCode: code(row.currencyCode),
      principalMinor: row.principalMinor.toString(), outstandingMinor: row.outstandingMinor.toString(),
      accountId: row.accountId, transactionClientId: row.transactionClientId, occurredOn: day(row.occurredOn),
      dueDate: row.dueDate ? day(row.dueDate) : null, note: row.note,
      archivedAt: row.archivedAt ? iso(row.archivedAt) : null,
      version: row.version, ...stamps(row),
    })),
    personalDebtPayments: source.personalDebtPayments.map(row => ({
      id: row.id, debtId: row.debtId, clientId: row.clientId, accountId: row.accountId,
      amountMinor: row.amountMinor.toString(), transactionClientId: row.transactionClientId,
      paidOn: day(row.paidOn), createdAt: iso(row.createdAt),
    })),
    investments: source.investments.map(row => ({
      id: row.id, clientId: row.clientId, kind: row.kind, name: row.name, currencyCode: code(row.currencyCode), unit: row.unit,
      quantity: row.quantity.toFixed(8), costBasisMinor: row.costBasisMinor.toString(),
      interestRateBps: row.interestRateBps, startDate: row.startDate ? day(row.startDate) : null,
      maturityDate: row.maturityDate ? day(row.maturityDate) : null, note: row.note,
      archivedAt: row.archivedAt ? iso(row.archivedAt) : null,
      version: row.version, ...stamps(row),
    })),
    investmentTrades: source.investmentTrades.map(row => ({
      id: row.id, investmentId: row.investmentId, clientId: row.clientId, side: row.side, quantity: row.quantity.toFixed(8),
      amountMinor: row.amountMinor.toString(), realizedMinor: row.realizedMinor === null ? null : row.realizedMinor.toString(),
      accountId: row.accountId, transactionClientId: row.transactionClientId, tradedOn: day(row.tradedOn), note: row.note,
      createdAt: iso(row.createdAt),
    })),
    investmentPrices: source.investmentPrices.map(row => ({
      id: row.id, investmentId: row.investmentId, clientId: row.clientId, priceMinor: row.priceMinor.toString(),
      source: row.source, quotedAt: iso(row.quotedAt), createdAt: iso(row.createdAt),
    })),
    cardInstallmentPlans: source.cardInstallmentPlans.map(row => ({
      id: row.id, clientId: row.clientId, transactionId: row.transactionId, accountId: row.accountId,
      currencyCode: code(row.currencyCode), totalMinor: row.totalMinor.toString(),
      installmentMinor: row.installmentMinor.toString(), installmentCount: row.installmentCount,
      firstDueOn: day(row.firstDueOn), status: row.status, closedAt: row.closedAt ? iso(row.closedAt) : null,
      version: row.version, ...stamps(row),
    })),
    importBatches: source.importBatches.map(row => ({
      id: row.id, clientId: row.clientId, preset: row.preset, rowCount: row.rowCount, createdCount: row.createdCount,
      duplicateCount: row.duplicateCount, invalidCount: row.invalidCount,
      undoneAt: row.undoneAt ? iso(row.undoneAt) : null, createdAt: iso(row.createdAt),
    })),
    categorySuggestionMappings: source.categorySuggestionMappings.map(row => ({
      id: row.id, merchant: row.merchant, categoryId: row.categoryId, ...stamps(row),
    })),
    notificationPreferences: source.notificationPreferences === null ? null : {
      budgetEnabled: source.notificationPreferences.budgetEnabled,
      goalEnabled: source.notificationPreferences.goalEnabled,
      debtEnabled: source.notificationPreferences.debtEnabled,
      cardEnabled: source.notificationPreferences.cardEnabled,
      recurringEnabled: source.notificationPreferences.recurringEnabled,
      monthReviewEnabled: source.notificationPreferences.monthReviewEnabled,
      insightEnabled: source.notificationPreferences.insightEnabled,
      dailyLogEnabled: source.notificationPreferences.dailyLogEnabled,
      dailyLogTime: source.notificationPreferences.dailyLogTime,
      quietHoursEnabled: source.notificationPreferences.quietHoursEnabled,
      quietStart: source.notificationPreferences.quietStart,
      quietEnd: source.notificationPreferences.quietEnd,
      version: source.notificationPreferences.version,
      ...stamps(source.notificationPreferences),
    },
    notifications: source.notifications.map(row => ({
      id: row.id,
      kind: row.kind,
      dedupeKey: row.dedupeKey,
      titleKey: row.titleKey,
      bodyKey: row.bodyKey,
      params: { ...row.params },
      createdAt: iso(row.createdAt),
      readAt: row.readAt ? iso(row.readAt) : null,
    })),
    transactions: source.transactions.map(row => ({
      id: row.id, clientId: row.clientId, type: row.type, amountMinor: row.amountMinor.toString(),
      currencyCode: code(row.currencyCode), occurredOn: day(row.occurredOn), occurredTime: row.occurredTime,
      accountId: row.accountId, categoryId: row.categoryId, transferGroupId: row.transferGroupId, refundOfId: row.refundOfId,
      fxQuoteId: row.fxQuoteId, recurringRuleId: row.recurringRuleId, notes: row.notes, merchant: row.merchant,
      deletedAt: row.deletedAt ? iso(row.deletedAt) : null,
      tagIds: [...row.tagIds].sort(), version: row.version, ...stamps(row),
    })),
  };
}
