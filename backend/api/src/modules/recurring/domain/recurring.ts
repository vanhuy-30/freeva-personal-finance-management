import { calendarDate, minor, normalizeRate, TRANSACTION_TYPES, type TransactionType } from '../../transactions/domain/transaction';
import { TransactionError } from '../../transactions/domain/transaction-error';
import { convertedMinor } from '../../transactions/domain/transaction-money';
import { RECURRING_UNITS, type RecurringUnit, RecurringCalendarError, parseCalendarParts } from './calendar';

export { RECURRING_UNITS, type RecurringUnit };
export type { TransactionType };

export class RecurringError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR' | 'RECURRING_NOT_FOUND' | 'RECURRING_CONFLICT') {
    super(code);
  }
}

function asValidation(error: unknown): never {
  if (error instanceof RecurringCalendarError || error instanceof TransactionError) {
    throw new RecurringError('VALIDATION_ERROR');
  }
  throw error;
}

export const RECURRING_MODES = ['auto', 'remind'] as const;
export type RecurringMode = (typeof RECURRING_MODES)[number];
export const AMOUNT_KINDS = ['fixed', 'estimated'] as const;
export type AmountKind = (typeof AMOUNT_KINDS)[number];

export interface RecurringInput {
  clientId: string;
  type: TransactionType;
  mode: RecurringMode;
  name: string | null;
  amountKind: AmountKind;
  remindDaysBefore: number;
  unit: RecurringUnit;
  interval: number;
  amountMinor: bigint;
  currencyCode: string;
  accountId: string | null;
  categoryId: string | null;
  counterAccountId: string | null;
  counterAmountMinor: bigint | null;
  counterCurrencyCode: string | null;
  fxRate: string | null;
  startDate: Date;
  endDate: Date | null;
  nextExecutionDate: Date;
  active: boolean;
}

export interface RecurringRule extends RecurringInput {
  id: string;
  version: number;
  createdAt: Date;
  updatedAt: Date;
}

export type RecurringPatch = Partial<Omit<RecurringInput, 'clientId' | 'type' | 'mode'>> & { version: number };

export interface RecurringQuery {
  page: number;
  pageSize: number;
  active?: boolean;
  mode?: RecurringMode;
}

export function assertRecurringVersion(actual: number, expected: number): void {
  if (actual !== expected || actual >= 2147483647) throw new RecurringError('RECURRING_CONFLICT');
}

export function dayString(value: Date): string {
  return value.toISOString().slice(0, 10);
}

/** A remind rule is a bill: one expense with a name, no counter leg. */
function validateRemind(input: RecurringInput): void {
  const name = input.name?.trim() ?? '';
  if (name.length < 1 || name.length > 80) throw new RecurringError('VALIDATION_ERROR');
  if (input.type !== 'expense' || input.amountMinor >= 0n) throw new RecurringError('VALIDATION_ERROR');
  if (input.counterAccountId !== null || input.counterAmountMinor !== null || input.counterCurrencyCode !== null || input.fxRate !== null) {
    throw new RecurringError('VALIDATION_ERROR');
  }
}

export function validateRecurringInput(input: RecurringInput, digits: Record<string, number>): void {
  if (!TRANSACTION_TYPES.includes(input.type)) throw new RecurringError('VALIDATION_ERROR');
  if (!RECURRING_MODES.includes(input.mode) || !AMOUNT_KINDS.includes(input.amountKind)) {
    throw new RecurringError('VALIDATION_ERROR');
  }
  if (!Number.isInteger(input.remindDaysBefore) || input.remindDaysBefore < 0 || input.remindDaysBefore > 30) {
    throw new RecurringError('VALIDATION_ERROR');
  }
  if (input.mode === 'auto' && input.accountId === null) throw new RecurringError('VALIDATION_ERROR');
  if (input.mode === 'remind') validateRemind(input);
  if (!RECURRING_UNITS.includes(input.unit)) throw new RecurringError('VALIDATION_ERROR');
  if (!Number.isInteger(input.interval) || input.interval < 1 || input.interval > 366) {
    throw new RecurringError('VALIDATION_ERROR');
  }
  try {
    minor(input.amountMinor.toString());
    parseCalendarParts(dayString(input.startDate));
    parseCalendarParts(dayString(input.nextExecutionDate));
    if (input.endDate) parseCalendarParts(dayString(input.endDate));
  } catch (error) {
    asValidation(error);
  }
  if (dayString(input.nextExecutionDate) < dayString(input.startDate)) {
    throw new RecurringError('VALIDATION_ERROR');
  }
  if (input.endDate && dayString(input.endDate) < dayString(input.startDate)) {
    throw new RecurringError('VALIDATION_ERROR');
  }
  if (input.mode === 'remind') return;
  if (input.type === 'expense') {
    if (input.categoryId === null || input.amountMinor >= 0n) throw new RecurringError('VALIDATION_ERROR');
    if (input.counterAccountId !== null || input.counterAmountMinor !== null || input.counterCurrencyCode !== null || input.fxRate !== null) {
      throw new RecurringError('VALIDATION_ERROR');
    }
    return;
  }
  if (input.type === 'income') {
    if (input.amountMinor <= 0n) throw new RecurringError('VALIDATION_ERROR');
    if (input.counterAccountId !== null || input.counterAmountMinor !== null || input.counterCurrencyCode !== null || input.fxRate !== null) {
      throw new RecurringError('VALIDATION_ERROR');
    }
    return;
  }
  if (input.categoryId !== null) throw new RecurringError('VALIDATION_ERROR');
  if (!input.counterAccountId || input.counterAmountMinor === null || !input.counterCurrencyCode) {
    throw new RecurringError('VALIDATION_ERROR');
  }
  if (input.accountId === input.counterAccountId) throw new RecurringError('VALIDATION_ERROR');
  if (input.amountMinor >= 0n || input.counterAmountMinor <= 0n) throw new RecurringError('VALIDATION_ERROR');
  try {
    minor(input.counterAmountMinor.toString());
  } catch (error) {
    asValidation(error);
  }
  if (input.currencyCode === input.counterCurrencyCode) {
    if (input.fxRate !== null || input.amountMinor + input.counterAmountMinor !== 0n) {
      throw new RecurringError('VALIDATION_ERROR');
    }
    return;
  }
  if (input.fxRate === null) throw new RecurringError('VALIDATION_ERROR');
  try {
    const rate = normalizeRate(input.fxRate);
    const expected = convertedMinor(
      input.amountMinor,
      rate,
      digits[input.currencyCode] ?? 0,
      digits[input.counterCurrencyCode] ?? 0,
    );
    if (expected !== input.counterAmountMinor) throw new RecurringError('VALIDATION_ERROR');
  } catch (error) {
    asValidation(error);
  }
}

export function parseDay(value: string): Date {
  try {
    return calendarDate(value);
  } catch {
    throw new RecurringError('VALIDATION_ERROR');
  }
}

/** Remind rules wait for a user confirm: pending when active, overdue once the due day has passed. */
export function remindFlags(
  rule: Pick<RecurringRule, 'mode' | 'active' | 'nextExecutionDate'>,
  today: string,
): { pending: boolean; overdue: boolean } {
  const pending = rule.mode === 'remind' && rule.active;
  return { pending, overdue: pending && dayString(rule.nextExecutionDate) < today };
}
