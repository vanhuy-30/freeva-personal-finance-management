import type { ForecastCategory, ForecastTransaction, GoalEntryRow } from './spend-forecast';

export const SPEND_FORECAST_REPOSITORY = Symbol('SPEND_FORECAST_REPOSITORY');

export interface ForecastProfile { timezone: string; fiscalMonthStartDay: number; defaultCurrencyCode: string }
export interface OutlookRule {
  type: string;
  amountMinor: bigint;
  unit: 'day' | 'week' | 'month' | 'year';
  interval: number;
  startDate: string;
  endDate: string | null;
  nextExecutionDate: string;
}
/** Wallet money and the active recurring rules that move it, in one currency. */
export interface Outlook { walletCount: number; balanceMinor: bigint; rules: OutlookRule[] }
export interface ForecastGoal { targetMinor: bigint; currentMinor: bigint; targetDate: string | null; entries: GoalEntryRow[] }

export interface SpendForecastRepository {
  profile(userId: string): Promise<ForecastProfile | null>;
  /** Live expenses and refunds in `currencyCode` with `from <= occurredOn <= to`, and the user's categories. */
  ledger(userId: string, currencyCode: string, from: string, to: string): Promise<{ transactions: ForecastTransaction[]; categories: ForecastCategory[] }>;
  /** Non-credit, non-archived wallets of `currencyCode` with their balance, and the recurring rules on them. */
  outlook(userId: string, currencyCode: string): Promise<Outlook>;
  /** The user's goal (archived ones too) with its contributions and withdrawals since `since`; null when not theirs. */
  goal(userId: string, goalId: string, since: string): Promise<ForecastGoal | null>;
}
