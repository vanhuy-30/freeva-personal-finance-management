export class TransactionError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR' | 'TRANSACTION_NOT_FOUND' | 'TRANSACTION_CONFLICT' | 'ACCOUNT_NOT_FOUND' | 'CATEGORY_KIND_MISMATCH' | 'REFUND_EXCEEDS_ORIGINAL' | 'REFUND_EXISTS') { super(code); }
}
