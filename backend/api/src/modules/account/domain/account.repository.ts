import type { AccountExport } from './account-export';

export const ACCOUNT_REPOSITORY = Symbol('ACCOUNT_REPOSITORY');

export interface AccountRepository {
  exportForUser(userId: string): Promise<AccountExport | null>;
  deleteAccount(userId: string): Promise<boolean>;
}
