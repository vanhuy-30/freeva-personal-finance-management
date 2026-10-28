import type { ResolvedPeriod } from '../../reports/domain/report';
import type { BudgetApplyTo, BudgetLineInput, BudgetRecord, CategoryRef, ExpenseRow } from './budget';

export const BUDGET_REPOSITORY = Symbol('BUDGET_REPOSITORY');

export type BudgetPutInput = {
  limitMinor: bigint;
  alertThresholds: number[];
  categories: BudgetLineInput[];
  version?: number;
  /** default = template for all months; month = override for the period of `on`. */
  applyTo: BudgetApplyTo;
  /** Anchor day for the fiscal month when applyTo is month. */
  on?: string;
};

export type BudgetDeleteInput = {
  applyTo: BudgetApplyTo;
  version?: number;
  on?: string;
};

export type BudgetSummarySource = {
  budget: BudgetRecord | null;
  expenses: ExpenseRow[];
  categories: CategoryRef[];
  period: ResolvedPeriod;
};

export type BudgetCurrentQuery = {
  on?: string;
  /** When `default`, return the template only (ignore month overrides). */
  applyTo?: BudgetApplyTo;
};

export interface BudgetRepository {
  current(userId: string, query?: BudgetCurrentQuery): Promise<BudgetSummarySource>;
  put(userId: string, input: BudgetPutInput): Promise<BudgetRecord>;
  delete(userId: string, input: BudgetDeleteInput): Promise<void>;
}
