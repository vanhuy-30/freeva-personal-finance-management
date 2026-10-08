import type { AccountPatch, AccountQuery, CreateAccount, FinancialAccount } from './financial-account';

export const FINANCIAL_ACCOUNT_REPOSITORY = Symbol('FINANCIAL_ACCOUNT_REPOSITORY');
export interface FinancialAccountRepository {
  create(userId: string, input: CreateAccount): Promise<{ account: FinancialAccount; created: boolean }>;
  find(userId: string, id: string): Promise<FinancialAccount>;
  list(userId: string, query: AccountQuery): Promise<{ items: FinancialAccount[]; total: number }>;
  update(userId: string, id: string, patch: AccountPatch): Promise<FinancialAccount>;
}
