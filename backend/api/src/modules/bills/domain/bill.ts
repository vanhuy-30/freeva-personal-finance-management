import { calendarDate, minor } from '../../transactions/domain/transaction';
import { TransactionError } from '../../transactions/domain/transaction-error';

export const BILL_AMOUNT_KINDS = ['fixed', 'estimated'] as const;
export type BillAmountKind = (typeof BILL_AMOUNT_KINDS)[number];

export const BILL_STATUSES = ['open', 'overdue', 'paid'] as const;
export type BillStatus = (typeof BILL_STATUSES)[number];

export class BillError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR' | 'BILL_NOT_FOUND' | 'BILL_CONFLICT') {
    super(code);
    this.name = 'BillError';
  }
}

export interface BillInput {
  clientId: string;
  name: string;
  dueOn: Date;
  amountMinor: bigint;
  amountKind: BillAmountKind;
  currencyCode: string;
  recurringRuleId: string | null;
}

export interface Bill extends BillInput {
  id: string;
  paidTransactionId: string | null;
  version: number;
  createdAt: Date;
  updatedAt: Date;
}

export type BillPatch = Partial<Omit<BillInput, 'clientId'>> & { version: number };

export interface BillQuery {
  page: number;
  pageSize: number;
  status?: BillStatus;
}

export function assertBillVersion(actual: number, expected: number): void {
  if (actual !== expected || actual >= 2147483647) throw new BillError('BILL_CONFLICT');
}

export function dayString(value: Date): string {
  return value.toISOString().slice(0, 10);
}

export function parseDay(value: string): Date {
  try {
    return calendarDate(value);
  } catch {
    throw new BillError('VALIDATION_ERROR');
  }
}

export function normalizeName(value: string): string {
  const name = value.trim();
  if (name.length < 1 || name.length > 80) throw new BillError('VALIDATION_ERROR');
  return name;
}

/** Positive integer minor units only (bills are obligations, not signed ledger legs). */
export function positiveMinor(value: string | bigint): bigint {
  try {
    const amount = typeof value === 'bigint' ? value : minor(value);
    if (amount <= 0n) throw new BillError('VALIDATION_ERROR');
    return amount;
  } catch (error) {
    if (error instanceof BillError) throw error;
    if (error instanceof TransactionError) throw new BillError('VALIDATION_ERROR');
    throw error;
  }
}

export function validateBillInput(input: BillInput): void {
  if (!BILL_AMOUNT_KINDS.includes(input.amountKind)) throw new BillError('VALIDATION_ERROR');
  normalizeName(input.name);
  positiveMinor(input.amountMinor);
  try {
    calendarDate(dayString(input.dueOn));
  } catch {
    throw new BillError('VALIDATION_ERROR');
  }
  if (!/^[A-Z]{3}$/.test(input.currencyCode)) throw new BillError('VALIDATION_ERROR');
}

/** Derived on read: paid wins; else overdue when dueOn is before today in the profile timezone. */
export function billFlags(bill: Pick<Bill, 'dueOn' | 'paidTransactionId'>, today: string): {
  paid: boolean;
  overdue: boolean;
  status: BillStatus;
} {
  const paid = bill.paidTransactionId !== null;
  if (paid) return { paid: true, overdue: false, status: 'paid' };
  const overdue = dayString(bill.dueOn) < today;
  return { paid: false, overdue, status: overdue ? 'overdue' : 'open' };
}
