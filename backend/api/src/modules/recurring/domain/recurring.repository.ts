import type { RecurringInput, RecurringPatch, RecurringQuery, RecurringRule } from './recurring';

export const RECURRING_REPOSITORY = Symbol('RECURRING_REPOSITORY');

export interface RecurringRunResult {
  created: number;
  skipped: number;
}

export interface ConfirmInput {
  version: number;
  /** Due day being confirmed; must be the rule's next due day, or one already confirmed (replay). */
  occurredOn: Date;
  /** Point at an existing expense instead of posting a new one. */
  transactionId: string | null;
  accountId: string | null;
  categoryId: string | null;
  /** Positive magnitude overriding the rule amount (estimated bills). */
  amountMinor: bigint | null;
  /** Day the expense is dated; defaults to today in the profile timezone. */
  paidOn: Date | null;
}

export interface ConfirmResult {
  rule: RecurringRule;
  transactionId: string;
  replayed: boolean;
}

export interface RecurringRepository {
  todayForUser(userId: string, now?: Date): Promise<string>;
  /** Confirms a remind rule's due day: posts or links one expense, once per due day. */
  confirm(userId: string, id: string, input: ConfirmInput): Promise<ConfirmResult>;
  create(userId: string, input: RecurringInput): Promise<{ rule: RecurringRule; created: boolean }>;
  find(userId: string, id: string): Promise<RecurringRule>;
  list(userId: string, query: RecurringQuery): Promise<{ items: RecurringRule[]; total: number }>;
  update(userId: string, id: string, patch: RecurringPatch): Promise<RecurringRule>;
  delete(userId: string, id: string, version: number): Promise<void>;
  /** Posts due occurrences for one user (or all users when userId is null). */
  runDue(userId: string | null, now?: Date): Promise<RecurringRunResult>;
}
