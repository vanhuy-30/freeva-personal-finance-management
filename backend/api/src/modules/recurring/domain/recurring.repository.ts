import type { RecurringInput, RecurringPatch, RecurringQuery, RecurringRule } from './recurring';

export const RECURRING_REPOSITORY = Symbol('RECURRING_REPOSITORY');

export interface RecurringRunResult {
  created: number;
  skipped: number;
}

export interface RecurringRepository {
  create(userId: string, input: RecurringInput): Promise<{ rule: RecurringRule; created: boolean }>;
  find(userId: string, id: string): Promise<RecurringRule>;
  list(userId: string, query: RecurringQuery): Promise<{ items: RecurringRule[]; total: number }>;
  update(userId: string, id: string, patch: RecurringPatch): Promise<RecurringRule>;
  delete(userId: string, id: string, version: number): Promise<void>;
  /** Posts due occurrences for one user (or all users when userId is null). */
  runDue(userId: string | null, now?: Date): Promise<RecurringRunResult>;
}
