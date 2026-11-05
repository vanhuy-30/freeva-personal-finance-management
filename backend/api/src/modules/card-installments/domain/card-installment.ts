import { addInterval, parseCalendarParts } from '../../recurring/domain/calendar';

export const MIN_INSTALLMENTS = 2;
export const MAX_INSTALLMENTS = 60;

export class CardInstallmentError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR' | 'PLAN_NOT_FOUND' | 'PLAN_CONFLICT') {
    super(code);
    this.name = 'CardInstallmentError';
  }
}

export type CardInstallmentStatus = 'active' | 'closed';

export type CardInstallmentRecord = {
  id: string;
  clientId: string;
  transactionId: string;
  accountId: string;
  currencyCode: string;
  totalMinor: bigint;
  installmentMinor: bigint;
  installmentCount: number;
  /** Calendar days YYYY-MM-DD. */
  firstDueOn: string;
  status: CardInstallmentStatus;
  closedAt: Date | null;
  version: number;
  createdAt: Date;
  updatedAt: Date;
  /** The purchase, for naming the plan on the app (MOB-P3-009). Absent only in pure domain tests. */
  purchase?: InstallmentPurchase;
};

export type InstallmentPurchase = { occurredOn: string; merchant: string | null; notes: string | null; categoryId: string | null };

export type InstallmentPeriod = { index: number; dueOn: string; amountMinor: bigint };

/** Even split rounded up; the last period takes the (smaller or equal) remainder. */
export function defaultInstallmentMinor(totalMinor: bigint, count: number): bigint {
  const n = BigInt(count);
  return (totalMinor + n - 1n) / n;
}

/**
 * The periods must add up to the purchase: every period but the last pays `installmentMinor`, and what is left
 * for the last one has to be positive and no more than a regular period.
 */
export function validatePlan(totalMinor: bigint, count: number, installmentMinor: bigint, purchaseOn: string, firstDueOn: string): void {
  if (!Number.isInteger(count) || count < MIN_INSTALLMENTS || count > MAX_INSTALLMENTS) throw new CardInstallmentError('VALIDATION_ERROR');
  if (totalMinor <= 0n || installmentMinor <= 0n) throw new CardInstallmentError('VALIDATION_ERROR');
  const lastMinor = totalMinor - installmentMinor * BigInt(count - 1);
  if (lastMinor <= 0n || lastMinor > installmentMinor) throw new CardInstallmentError('VALIDATION_ERROR');
  try {
    parseCalendarParts(purchaseOn);
    parseCalendarParts(firstDueOn);
  } catch {
    throw new CardInstallmentError('VALIDATION_ERROR');
  }
  if (firstDueOn < purchaseOn) throw new CardInstallmentError('VALIDATION_ERROR');
}

/** Monthly periods from `firstDueOn`, keeping its day of month (clamped to short months). Sums to totalMinor. */
export function buildSchedule(plan: Pick<CardInstallmentRecord, 'totalMinor' | 'installmentMinor' | 'installmentCount' | 'firstDueOn'>): InstallmentPeriod[] {
  const anchor = parseCalendarParts(plan.firstDueOn).day;
  const periods: InstallmentPeriod[] = [];
  let paid = 0n;
  for (let index = 0; index < plan.installmentCount; index++) {
    const last = index === plan.installmentCount - 1;
    const amountMinor = last ? plan.totalMinor - paid : plan.installmentMinor;
    paid += amountMinor;
    periods.push({ index: index + 1, dueOn: index === 0 ? plan.firstDueOn : addInterval(plan.firstDueOn, 'month', index, anchor), amountMinor });
  }
  return periods;
}

/** Periods that are still ahead (due today or later). A closed plan has none. */
export function remainingPeriods(plan: CardInstallmentRecord, today: string): InstallmentPeriod[] {
  if (plan.status !== 'active') return [];
  return buildSchedule(plan).filter(period => period.dueOn >= today);
}

export type InstallmentDue = { accountId: string; currencyCode: string; dueMinor: bigint; planCount: number };

/** Instalment amount falling due in [from, to] (inclusive) per card; the client adds it to the card's amount due. */
export function dueForRange(plans: CardInstallmentRecord[], from: string, to: string): InstallmentDue[] {
  const byAccount = new Map<string, InstallmentDue>();
  for (const plan of plans) {
    if (plan.status !== 'active') continue;
    const inRange = buildSchedule(plan).filter(period => period.dueOn >= from && period.dueOn <= to);
    if (!inRange.length) continue;
    const entry = byAccount.get(plan.accountId) ?? { accountId: plan.accountId, currencyCode: plan.currencyCode, dueMinor: 0n, planCount: 0 };
    entry.dueMinor += inRange.reduce((sum, period) => sum + period.amountMinor, 0n);
    entry.planCount += 1;
    byAccount.set(plan.accountId, entry);
  }
  return [...byAccount.values()].sort((a, b) => a.accountId.localeCompare(b.accountId));
}
