import { TransactionError } from './transaction-error';

export interface RefundInput {
  /** Also the Idempotency-Key. */
  clientId: string;
  /** Wallet that receives the money. Must use the same currency as the original expense. */
  accountId: string;
  /** Positive minor units. */
  amountMinor: bigint;
  /** Calendar day `YYYY-MM-DD`; null = today in the profile timezone. */
  occurredOn: string | null;
  notes: string | null;
}

/** Expenses are stored negative; the most that can ever be refunded is the absolute amount. */
export function refundCap(originalAmountMinor: bigint): bigint {
  return originalAmountMinor < 0n ? -originalAmountMinor : originalAmountMinor;
}

/** Throws REFUND_EXCEEDS_ORIGINAL when the active refunds (including this one) would pass the original expense. */
export function assertWithinRefundCap(originalAmountMinor: bigint, refundedMinor: bigint): void {
  if (refundedMinor > refundCap(originalAmountMinor)) throw new TransactionError('REFUND_EXCEEDS_ORIGINAL');
}

export function validateRefundAmount(amountMinor: bigint): void {
  if (amountMinor <= 0n) throw new TransactionError('VALIDATION_ERROR');
}
