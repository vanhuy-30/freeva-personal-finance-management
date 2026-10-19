import { Inject, Injectable } from '@nestjs/common';
import { AccountPrivacyError } from './domain/account-privacy';
import { ACCOUNT_REPOSITORY, type AccountRepository } from './domain/account.repository';

@Injectable()
export class AccountService {
  constructor(@Inject(ACCOUNT_REPOSITORY) private readonly accounts: AccountRepository) {}

  async export(userId: string) {
    const snapshot = await this.accounts.exportForUser(userId);
    if (!snapshot) throw new AccountPrivacyError('SESSION_INVALID');
    return snapshot;
  }

  async remove(userId: string): Promise<void> {
    const deleted = await this.accounts.deleteAccount(userId);
    if (!deleted) throw new AccountPrivacyError('SESSION_INVALID');
  }
}
