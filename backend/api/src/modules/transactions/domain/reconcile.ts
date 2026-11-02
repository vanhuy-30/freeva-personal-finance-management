import { minor, TransactionError } from './transaction';

export type ReconcileAccountType = 'cash' | 'bank' | 'ewallet' | 'credit';

export interface ReconcileInput {
  clientId: string;
  /** Wallet balance the user sees in real life; for a credit card it is the amount owed (debt). */
  actualBalanceMinor: bigint;
  /** Calendar day `YYYY-MM-DD`; null = today in the profile timezone. */
  occurredOn: string | null;
  notes: string | null;
  dryRun: boolean;
}

export interface ReconcileResult {
  accountId: string;
  currencyCode: string;
  currentBalanceMinor: bigint;
  /** Signed ledger balance the wallet must reach (a card's debt is negative). */
  targetBalanceMinor: bigint;
  /** targetBalanceMinor - currentBalanceMinor; 0 means nothing to adjust. */
  deltaMinor: bigint;
  transaction: import('./transaction').TransactionBundle | null;
  created: boolean;
}

/** Credit wallets are reconciled against debt: the ledger balance is the negated debt. */
export function reconcileTarget(type: ReconcileAccountType, actualBalanceMinor: bigint): bigint {
  minor(actualBalanceMinor.toString());
  return type === 'credit' ? -actualBalanceMinor : actualBalanceMinor;
}

export function reconcileDelta(type: ReconcileAccountType, currentBalanceMinor: bigint, actualBalanceMinor: bigint): bigint {
  const delta = reconcileTarget(type, actualBalanceMinor) - currentBalanceMinor;
  minor(delta.toString());
  return delta;
}

export function validateReconcileNotes(notes: string | null): void {
  if (notes !== null && notes.length > 2000) throw new TransactionError('VALIDATION_ERROR');
}
