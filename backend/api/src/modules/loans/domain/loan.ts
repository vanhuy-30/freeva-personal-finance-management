export const LOAN_KINDS = ['card', 'personal', 'mortgage', 'other'] as const;
export type LoanKind = (typeof LOAN_KINDS)[number];

export const LOAN_FREQUENCIES = ['weekly', 'monthly', 'quarterly', 'yearly'] as const;
export type LoanFrequency = (typeof LOAN_FREQUENCIES)[number];

export const MAX_RATE_BPS = 100_000;
export const MAX_SCHEDULE_PERIODS = 600;

export class LoanError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR' | 'LOAN_NOT_FOUND' | 'LOAN_CONFLICT' | 'LOAN_OVERPAYMENT') {
    super(code);
    this.name = 'LoanError';
  }
}

export type LoanRecord = {
  id: string;
  clientId: string;
  kind: LoanKind;
  name: string;
  currencyCode: string;
  principalMinor: bigint;
  outstandingMinor: bigint;
  /** Annual rate in basis points; 1200 = 12,00%. */
  interestRateBps: number;
  installmentMinor: bigint | null;
  frequency: LoanFrequency;
  /** Calendar days YYYY-MM-DD. */
  startDate: string;
  endDate: string | null;
  nextDueDate: string | null;
  accountId: string | null;
  archivedAt: Date | null;
  version: number;
  createdAt: Date;
  updatedAt: Date;
};

export function validateName(name: string): void {
  const trimmed = name.trim();
  if (trimmed.length < 1 || trimmed.length > 80) throw new LoanError('VALIDATION_ERROR');
}

export function validatePrincipal(principalMinor: bigint): void {
  if (principalMinor <= 0n) throw new LoanError('VALIDATION_ERROR');
}

export function validateOutstanding(outstandingMinor: bigint): void {
  if (outstandingMinor < 0n) throw new LoanError('VALIDATION_ERROR');
}

export function validateRate(rateBps: number): void {
  if (!Number.isInteger(rateBps) || rateBps < 0 || rateBps > MAX_RATE_BPS) throw new LoanError('VALIDATION_ERROR');
}

export function validateInstallment(installmentMinor: bigint | null): void {
  if (installmentMinor !== null && installmentMinor < 0n) throw new LoanError('VALIDATION_ERROR');
}

export function validateDates(startDate: string, endDate: string | null, nextDueDate: string | null): void {
  if (endDate !== null && endDate < startDate) throw new LoanError('VALIDATION_ERROR');
  if (nextDueDate !== null && nextDueDate < startDate) throw new LoanError('VALIDATION_ERROR');
}

export function periodsPerYear(frequency: LoanFrequency): bigint {
  return { weekly: 52n, monthly: 12n, quarterly: 4n, yearly: 1n }[frequency];
}

/** Interest of one period on `outstanding`: `outstanding * rate / (10000 * periodsPerYear)`, rounded half up. */
export function periodInterest(outstandingMinor: bigint, rateBps: number, frequency: LoanFrequency): bigint {
  if (outstandingMinor <= 0n || rateBps <= 0) return 0n;
  const divisor = 10_000n * periodsPerYear(frequency);
  return (outstandingMinor * BigInt(rateBps) + divisor / 2n) / divisor;
}

/** Fixed payment (annuity) that clears `principal` in `periods` equal periods; rounded up. */
export function annuityPayment(principalMinor: bigint, rateBps: number, frequency: LoanFrequency, periods: number): bigint {
  if (principalMinor <= 0n || !Number.isInteger(periods) || periods < 1 || periods > MAX_SCHEDULE_PERIODS) {
    throw new LoanError('VALIDATION_ERROR');
  }
  const count = BigInt(periods);
  if (rateBps <= 0) return (principalMinor + count - 1n) / count;
  // r = a / b per period; payment = P * a * (b + a)^n / (b * ((b + a)^n - b^n))
  const a = BigInt(rateBps);
  const b = 10_000n * periodsPerYear(frequency);
  const grown = (b + a) ** count;
  const numerator = principalMinor * a * grown;
  const denominator = b * (grown - b ** count);
  return (numerator + denominator - 1n) / denominator;
}

export type ScheduleRow = {
  index: number;
  interestMinor: bigint;
  principalMinor: bigint;
  paymentMinor: bigint;
  outstandingAfterMinor: bigint;
};

/**
 * Repayment plan for the declining balance: interest first, rest reduces principal.
 * The last row absorbs rounding so principal sums to `outstanding`. Returns null when the payment
 * never covers the interest (the balance would not shrink) or the plan exceeds MAX_SCHEDULE_PERIODS.
 */
export function schedule(
  outstandingMinor: bigint,
  rateBps: number,
  frequency: LoanFrequency,
  installmentMinor: bigint,
): ScheduleRow[] | null {
  const rows: ScheduleRow[] = [];
  let balance = outstandingMinor;
  while (balance > 0n) {
    if (rows.length >= MAX_SCHEDULE_PERIODS) return null;
    const interest = periodInterest(balance, rateBps, frequency);
    if (installmentMinor <= interest) return null;
    const last = balance + interest <= installmentMinor;
    const payment = last ? balance + interest : installmentMinor;
    const principal = payment - interest;
    balance -= principal;
    rows.push({
      index: rows.length + 1,
      interestMinor: interest,
      principalMinor: principal,
      paymentMinor: payment,
      outstandingAfterMinor: balance,
    });
  }
  return rows;
}

export function totalInterest(rows: ScheduleRow[] | null): bigint | null {
  return rows === null ? null : rows.reduce((sum, row) => sum + row.interestMinor, 0n);
}

/** Splits a payment: interest of the current period first, the rest is principal (never above the balance). */
export function splitPayment(
  outstandingMinor: bigint,
  rateBps: number,
  frequency: LoanFrequency,
  amountMinor: bigint,
): { interestMinor: bigint; principalMinor: bigint } {
  if (amountMinor <= 0n) throw new LoanError('VALIDATION_ERROR');
  const interest = periodInterest(outstandingMinor, rateBps, frequency);
  const interestPart = amountMinor < interest ? amountMinor : interest;
  const principalPart = amountMinor - interestPart;
  if (principalPart > outstandingMinor) throw new LoanError('LOAN_OVERPAYMENT');
  return { interestMinor: interestPart, principalMinor: principalPart };
}

export function paidMinor(principalMinor: bigint, outstandingMinor: bigint): bigint {
  return outstandingMinor >= principalMinor ? 0n : principalMinor - outstandingMinor;
}

/** `paid * 10000 / principal`, floored; 10000 = 100,00%. */
export function percentBps(principalMinor: bigint, outstandingMinor: bigint): number {
  if (principalMinor <= 0n) return 0;
  return Number((paidMinor(principalMinor, outstandingMinor) * 10000n) / principalMinor);
}

export type LoanStatus = 'paid_off' | 'overdue' | 'active';

export function loanStatus(outstandingMinor: bigint, nextDueDate: string | null, today: string): LoanStatus {
  if (outstandingMinor <= 0n) return 'paid_off';
  if (nextDueDate !== null && nextDueDate < today) return 'overdue';
  return 'active';
}

const parts = (day: string): [number, number, number] => {
  const [y, m, d] = day.split('-').map(Number);
  return [y!, m!, d!];
};
const pad = (n: number) => String(n).padStart(2, '0');

/** Next due date one period after `day`; month steps clamp to the last day of the target month. */
export function addPeriod(day: string, frequency: LoanFrequency): string {
  const [y, m, d] = parts(day);
  if (frequency === 'weekly') {
    return new Date(Date.UTC(y, m - 1, d + 7)).toISOString().slice(0, 10);
  }
  const step = { monthly: 1, quarterly: 3, yearly: 12 }[frequency];
  const total = y * 12 + (m - 1) + step;
  const ny = Math.floor(total / 12);
  const nm = (total % 12) + 1;
  const last = new Date(Date.UTC(ny, nm, 0)).getUTCDate();
  return `${ny}-${pad(nm)}-${pad(Math.min(d, last))}`;
}
