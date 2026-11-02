export const PERSONAL_DEBT_DIRECTIONS = ['lent', 'borrowed'] as const;
export type PersonalDebtDirection = (typeof PERSONAL_DEBT_DIRECTIONS)[number];

export class PersonalDebtError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR' | 'DEBT_NOT_FOUND' | 'DEBT_CONFLICT' | 'DEBT_OVERPAYMENT') {
    super(code);
    this.name = 'PersonalDebtError';
  }
}

export type PersonalDebtRecord = {
  id: string;
  clientId: string;
  direction: PersonalDebtDirection;
  counterparty: string;
  currencyCode: string;
  principalMinor: bigint;
  outstandingMinor: bigint;
  accountId: string;
  /** Calendar days YYYY-MM-DD. */
  occurredOn: string;
  dueDate: string | null;
  note: string | null;
  archivedAt: Date | null;
  version: number;
  createdAt: Date;
  updatedAt: Date;
};

export type PersonalDebtStatus = 'settled' | 'overdue' | 'open';

/** Lending moves money out of the wallet, borrowing moves it in. */
export function openingLegMinor(direction: PersonalDebtDirection, amountMinor: bigint): bigint {
  return direction === 'lent' ? -amountMinor : amountMinor;
}

/** Collecting a loan you made brings money in, repaying what you borrowed sends it out. */
export function paymentLegMinor(direction: PersonalDebtDirection, amountMinor: bigint): bigint {
  return direction === 'lent' ? amountMinor : -amountMinor;
}

export function validateCounterparty(name: string): void {
  const trimmed = name.trim();
  if (trimmed.length < 1 || trimmed.length > 80) throw new PersonalDebtError('VALIDATION_ERROR');
}

export function validateNote(note: string | null): void {
  if (note !== null && note.length > 500) throw new PersonalDebtError('VALIDATION_ERROR');
}

export function validatePrincipal(principalMinor: bigint): void {
  if (principalMinor <= 0n) throw new PersonalDebtError('VALIDATION_ERROR');
}

export function validateDueDate(occurredOn: string, dueDate: string | null): void {
  if (dueDate !== null && dueDate < occurredOn) throw new PersonalDebtError('VALIDATION_ERROR');
}

/** Outstanding after a partial or full payment; paying more than is left is an error, never a silent clamp. */
export function outstandingAfter(outstandingMinor: bigint, amountMinor: bigint): bigint {
  if (amountMinor <= 0n) throw new PersonalDebtError('VALIDATION_ERROR');
  if (amountMinor > outstandingMinor) throw new PersonalDebtError('DEBT_OVERPAYMENT');
  return outstandingMinor - amountMinor;
}

export function debtStatus(outstandingMinor: bigint, dueDate: string | null, today: string): PersonalDebtStatus {
  if (outstandingMinor <= 0n) return 'settled';
  return dueDate !== null && dueDate < today ? 'overdue' : 'open';
}

export type DebtTotals = { currencyCode: string; receivableMinor: bigint; payableMinor: bigint; receivableCount: number; payableCount: number };

/** Receivable (people owe me) and payable (I owe people) per currency over the given debts. */
export function debtTotals(debts: Pick<PersonalDebtRecord, 'direction' | 'currencyCode' | 'outstandingMinor'>[]): DebtTotals[] {
  const totals = new Map<string, DebtTotals>();
  for (const debt of debts) {
    if (debt.outstandingMinor <= 0n) continue;
    const entry = totals.get(debt.currencyCode) ??
      { currencyCode: debt.currencyCode, receivableMinor: 0n, payableMinor: 0n, receivableCount: 0, payableCount: 0 };
    if (debt.direction === 'lent') {
      entry.receivableMinor += debt.outstandingMinor;
      entry.receivableCount += 1;
    } else {
      entry.payableMinor += debt.outstandingMinor;
      entry.payableCount += 1;
    }
    totals.set(debt.currencyCode, entry);
  }
  return [...totals.values()].sort((a, b) => a.currencyCode.localeCompare(b.currencyCode));
}
