import type { InsightCategory, InsightTransaction } from './insight';

export const INSIGHT_REPOSITORY = Symbol('INSIGHT_REPOSITORY');

export interface InsightProfile { timezone: string; fiscalMonthStartDay: number; defaultCurrencyCode: string }

export interface InsightRepository {
  profile(userId: string): Promise<InsightProfile | null>;
  /** Live expenses and refunds in `currencyCode` with `from <= occurredOn <= to`, plus every category of the user. */
  ledger(userId: string, currencyCode: string, from: string, to: string): Promise<{ transactions: InsightTransaction[]; categories: InsightCategory[] }>;
}
