export class TransactionError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR' | 'TRANSACTION_NOT_FOUND' | 'TRANSACTION_CONFLICT' | 'ACCOUNT_NOT_FOUND') { super(code); }
}
