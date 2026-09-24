export const ACCOUNT_TYPES = ['cash', 'bank', 'ewallet', 'credit'] as const;
export type AccountType = typeof ACCOUNT_TYPES[number];
export interface AccountFields {
  name: string;
  type: AccountType;
  currencyCode: string;
  initialBalanceMinor: bigint;
  sortOrder: number;
  creditLimitMinor: bigint | null;
  statementCloseDay: number | null;
  paymentDueDay: number | null;
}
export interface FinancialAccount extends AccountFields {
  id: string;
  clientId: string;
  version: number;
  archivedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  balanceMinor: bigint;
}
export type CreateAccount = AccountFields & { clientId: string };
export type AccountPatch = Partial<AccountFields> & { version: number; archived?: boolean };
export interface AccountQuery {
  page: number;
  pageSize: number;
  status: 'active' | 'archived' | 'all';
}
export class AccountError extends Error {
  constructor(readonly code: 'VALIDATION_ERROR' | 'ACCOUNT_NOT_FOUND' | 'ACCOUNT_CONFLICT') {
    super(code);
  }
}
export function minor(value: string): bigint {
  if (!/^-?[0-9]+(?![\s\S])/.test(value) || value.length > 20) throw new AccountError('VALIDATION_ERROR');
  const result = BigInt(value);
  if (result < -9223372036854775808n || result > 9223372036854775807n) {
    throw new AccountError('VALIDATION_ERROR');
  }
  return result;
}
export function validateCredit(fields: AccountFields): void {
  const values = [fields.creditLimitMinor, fields.statementCloseDay, fields.paymentDueDay];
  if (fields.type !== 'credit' && values.some(value => value !== null)) {
    throw new AccountError('VALIDATION_ERROR');
  }
  if (fields.creditLimitMinor !== null && fields.creditLimitMinor < 0n) {
    throw new AccountError('VALIDATION_ERROR');
  }
}
export function updatedFields(current: FinancialAccount, patch: AccountPatch, hasTransactions: boolean): AccountFields {
  if (current.version !== patch.version || current.version >= 2147483647) {
    throw new AccountError('ACCOUNT_CONFLICT');
  }
  if (hasTransactions && (
    (patch.type !== undefined && patch.type !== current.type) ||
    (patch.currencyCode !== undefined && patch.currencyCode !== current.currencyCode)
  )) throw new AccountError('ACCOUNT_CONFLICT');
  const fields: AccountFields = {
    name: patch.name ?? current.name,
    type: patch.type ?? current.type,
    currencyCode: patch.currencyCode ?? current.currencyCode,
    initialBalanceMinor: patch.initialBalanceMinor ?? current.initialBalanceMinor,
    sortOrder: patch.sortOrder ?? current.sortOrder,
    creditLimitMinor: patch.creditLimitMinor === undefined ? current.creditLimitMinor : patch.creditLimitMinor,
    statementCloseDay: patch.statementCloseDay === undefined ? current.statementCloseDay : patch.statementCloseDay,
    paymentDueDay: patch.paymentDueDay === undefined ? current.paymentDueDay : patch.paymentDueDay,
  };
  if (current.type === 'credit' && fields.type !== 'credit') {
    // Reject contradictory input, but clear old card configuration automatically.
    if ([patch.creditLimitMinor, patch.statementCloseDay, patch.paymentDueDay]
      .some(value => value !== undefined && value !== null)) throw new AccountError('VALIDATION_ERROR');
    fields.creditLimitMinor = null;
    fields.statementCloseDay = null;
    fields.paymentDueDay = null;
  }
  validateCredit(fields);
  return fields;
}
export function sameCreate(account: FinancialAccount, input: CreateAccount): boolean {
  return (Object.keys(input) as (keyof CreateAccount)[]).every(key => account[key] === input[key]);
}
