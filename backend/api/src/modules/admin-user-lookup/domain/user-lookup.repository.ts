import type { UserAccountSummary } from './user-account-summary';

export const USER_LOOKUP_REPOSITORY = Symbol('USER_LOOKUP_REPOSITORY');

export interface UserLookupRepository {
  findById(userId: string): Promise<UserAccountSummary | null>;
  findByEmail(email: string): Promise<UserAccountSummary | null>;
}
