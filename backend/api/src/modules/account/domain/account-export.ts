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
    emailVerifiedAt: string | null;
    categoriesInitializedAt: string | null;
    categoriesSupplementedAt: string | null;
    createdAt: string;
    updatedAt: string;
  };
  oauthProviders: Array<'google' | 'apple'>;
  financialAccounts: AccountExportAccount[];
  categoryGroups: AccountExportGroup[];
  categories: AccountExportCategory[];
  tags: AccountExportTag[];
  fxQuotes: AccountExportQuote[];
  recurringRules: AccountExportRecurringRule[];
  budget: AccountExportBudget | null;
  budgetMonths: AccountExportBudgetMonth[];
  transactions: AccountExportTransaction[];
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

export interface AccountExportRecurringRule extends Omit<SyncRow, 'createdAt' | 'updatedAt'> {
  type: 'income' | 'expense' | 'transfer';
  unit: 'day' | 'week' | 'month' | 'year';
  interval: number;
  amountMinor: string;
  currencyCode: string;
  accountId: string;
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
  type: 'income' | 'expense' | 'transfer';
  amountMinor: string;
  currencyCode: string;
  occurredOn: string;
  accountId: string;
  categoryId: string | null;
  transferGroupId: string | null;
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
    emailVerifiedAt: Date | null;
    categoriesInitializedAt: Date | null;
    categoriesSupplementedAt: Date | null;
    createdAt: Date;
    updatedAt: Date;
  };
  oauthProviders: Array<'google' | 'apple'>;
  financialAccounts: Array<Omit<AccountExportAccount, 'initialBalanceMinor' | 'creditLimitMinor' | 'archivedAt' | 'createdAt' | 'updatedAt' | 'currencyCode'> & {
    currencyCode: string;
    initialBalanceMinor: bigint;
    creditLimitMinor: bigint | null;
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
  transactions: Array<Omit<AccountExportTransaction, 'amountMinor' | 'occurredOn' | 'deletedAt' | 'createdAt' | 'updatedAt' | 'currencyCode'> & {
    currencyCode: string;
    amountMinor: bigint;
    occurredOn: Date;
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
      emailVerifiedAt: user.emailVerifiedAt ? iso(user.emailVerifiedAt) : null,
      categoriesInitializedAt: user.categoriesInitializedAt ? iso(user.categoriesInitializedAt) : null,
      categoriesSupplementedAt: user.categoriesSupplementedAt ? iso(user.categoriesSupplementedAt) : null,
      ...stamps(user),
    },
    oauthProviders: [...source.oauthProviders].sort(),
    financialAccounts: source.financialAccounts.map(row => ({
      id: row.id, clientId: row.clientId, name: row.name, type: row.type, currencyCode: code(row.currencyCode),
      initialBalanceMinor: row.initialBalanceMinor.toString(), sortOrder: row.sortOrder,
      archivedAt: row.archivedAt ? iso(row.archivedAt) : null,
      creditLimitMinor: row.creditLimitMinor?.toString() ?? null,
      statementCloseDay: row.statementCloseDay, paymentDueDay: row.paymentDueDay, version: row.version, ...stamps(row),
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
    recurringRules: source.recurringRules.map(row => ({
      id: row.id, clientId: row.clientId, type: row.type, unit: row.unit, interval: row.interval,
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
    transactions: source.transactions.map(row => ({
      id: row.id, clientId: row.clientId, type: row.type, amountMinor: row.amountMinor.toString(),
      currencyCode: code(row.currencyCode), occurredOn: day(row.occurredOn), accountId: row.accountId,
      categoryId: row.categoryId, transferGroupId: row.transferGroupId, fxQuoteId: row.fxQuoteId,
      recurringRuleId: row.recurringRuleId, notes: row.notes, merchant: row.merchant,
      deletedAt: row.deletedAt ? iso(row.deletedAt) : null,
      tagIds: [...row.tagIds].sort(), version: row.version, ...stamps(row),
    })),
  };
}
