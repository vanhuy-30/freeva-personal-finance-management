import { resolvePeriod, type ResolvedPeriod, type ReportProfile } from '../../reports/domain/report';

export const BUDGET_STATUSES = ['healthy', 'warning', 'critical', 'over'] as const;
export type BudgetStatus = (typeof BUDGET_STATUSES)[number];

export const DEFAULT_ALERT_THRESHOLDS = [70, 80, 90, 100] as const;

export class BudgetError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR' | 'BUDGET_NOT_FOUND' | 'BUDGET_CONFLICT') {
    super(code);
    this.name = 'BudgetError';
  }
}

export type ExpenseRow = {
  type: 'income' | 'expense' | 'transfer';
  amountMinor: bigint;
  currencyCode: string;
  categoryId: string | null;
  deletedAt: Date | null;
};

export type CategoryRef = {
  id: string;
  parentId: string | null;
  kind: 'expense' | 'income' | 'both';
  archivedAt: Date | null;
};

export type BudgetLineInput = { categoryId: string; limitMinor: bigint };

export const BUDGET_APPLY_TO = ['default', 'month'] as const;
export type BudgetApplyTo = (typeof BUDGET_APPLY_TO)[number];

export type BudgetRecord = {
  id: string;
  currencyCode: string;
  limitMinor: bigint;
  alertThresholds: number[];
  version: number;
  createdAt: Date;
  updatedAt: Date;
  categories: BudgetLineInput[];
  /** default = template; month = override for one fiscal month. */
  applyTo: BudgetApplyTo;
  /** True when the effective row is a month override (not inherited default). */
  isOverride: boolean;
};

/** Absolute spend from non-deleted expenses in the budget currency. Income and transfers ignored. */
export function totalSpent(rows: ExpenseRow[], currencyCode: string): bigint {
  let sum = 0n;
  for (const row of rows) {
    if (row.deletedAt !== null || row.type !== 'expense' || row.currencyCode !== currencyCode) continue;
    sum += abs(row.amountMinor);
  }
  return sum;
}

/**
 * Spend for one budget line: the category itself plus every descendant.
 * Uncategorized expenses only count toward the overall total.
 */
export function categorySpent(
  rows: ExpenseRow[],
  currencyCode: string,
  categoryId: string,
  descendants: ReadonlySet<string>,
): bigint {
  let sum = 0n;
  for (const row of rows) {
    if (row.deletedAt !== null || row.type !== 'expense' || row.currencyCode !== currencyCode) continue;
    if (row.categoryId === null) continue;
    if (row.categoryId !== categoryId && !descendants.has(row.categoryId)) continue;
    sum += abs(row.amountMinor);
  }
  return sum;
}

export function descendantIds(categoryId: string, categories: CategoryRef[]): Set<string> {
  const children = new Map<string, string[]>();
  for (const category of categories) {
    if (category.parentId === null) continue;
    const list = children.get(category.parentId) ?? [];
    list.push(category.id);
    children.set(category.parentId, list);
  }
  const out = new Set<string>();
  const stack = [...(children.get(categoryId) ?? [])];
  while (stack.length > 0) {
    const id = stack.pop()!;
    if (out.has(id)) continue;
    out.add(id);
    for (const child of children.get(id) ?? []) stack.push(child);
  }
  return out;
}

export function budgetStatus(spent: bigint, limit: bigint): BudgetStatus {
  if (limit <= 0n) throw new BudgetError('VALIDATION_ERROR');
  if (spent * 100n < limit * 70n) return 'healthy';
  if (spent * 100n <= limit * 90n) return 'warning';
  if (spent <= limit) return 'critical';
  return 'over';
}

/** Basis points of the limit used (7000 = 70.00%). Integer division. */
export function percentBps(spent: bigint, limit: bigint): number {
  if (limit <= 0n) throw new BudgetError('VALIDATION_ERROR');
  const value = (spent * 10000n) / limit;
  if (value > BigInt(Number.MAX_SAFE_INTEGER)) return Number.MAX_SAFE_INTEGER;
  if (value < BigInt(Number.MIN_SAFE_INTEGER)) return Number.MIN_SAFE_INTEGER;
  return Number(value);
}

export function remainingMinor(spent: bigint, limit: bigint): bigint {
  return limit - spent;
}

/** Thresholds the user has already reached or passed (spent/limit >= t/100). */
export function crossedThresholds(spent: bigint, limit: bigint, thresholds: number[]): number[] {
  if (limit <= 0n) throw new BudgetError('VALIDATION_ERROR');
  return thresholds.filter(threshold => spent * 100n >= limit * BigInt(threshold));
}

export function normalizeAlertThresholds(value: number[] | undefined): number[] {
  const thresholds = value === undefined ? [...DEFAULT_ALERT_THRESHOLDS] : value;
  if (thresholds.length < 1 || thresholds.length > 4) throw new BudgetError('VALIDATION_ERROR');
  let previous = 0;
  for (const threshold of thresholds) {
    if (!Number.isInteger(threshold) || threshold < 1 || threshold > 100) throw new BudgetError('VALIDATION_ERROR');
    if (threshold <= previous) throw new BudgetError('VALIDATION_ERROR');
    previous = threshold;
  }
  return thresholds;
}

export function validateLimit(limit: bigint): void {
  if (limit <= 0n || limit > 9223372036854775807n) throw new BudgetError('VALIDATION_ERROR');
}

export function validateCategoryLines(lines: BudgetLineInput[], categories: CategoryRef[]): void {
  const seen = new Set<string>();
  const byId = new Map(categories.map(category => [category.id, category]));
  for (const line of lines) {
    if (seen.has(line.categoryId)) throw new BudgetError('VALIDATION_ERROR');
    seen.add(line.categoryId);
    validateLimit(line.limitMinor);
    const category = byId.get(line.categoryId);
    if (!category || category.archivedAt !== null || category.kind === 'income') {
      throw new BudgetError('VALIDATION_ERROR');
    }
  }
}

export function resolveBudgetPeriod(profile: ReportProfile, on: string | undefined, now = new Date()): ResolvedPeriod {
  return resolvePeriod({ period: 'month', on }, profile, now);
}

export type ProgressLine = {
  limitMinor: bigint;
  spentMinor: bigint;
  remainingMinor: bigint;
  percentBps: number;
  status: BudgetStatus;
};

export function progress(spent: bigint, limit: bigint): ProgressLine {
  validateLimit(limit);
  return {
    limitMinor: limit,
    spentMinor: spent,
    remainingMinor: remainingMinor(spent, limit),
    percentBps: percentBps(spent, limit),
    status: budgetStatus(spent, limit),
  };
}

function abs(value: bigint): bigint {
  return value < 0n ? -value : value;
}
