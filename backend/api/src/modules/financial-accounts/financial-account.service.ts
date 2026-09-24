import { Inject, Injectable } from '@nestjs/common';
import { FINANCIAL_ACCOUNT_REPOSITORY, type FinancialAccountRepository } from './domain/financial-account.repository';
import { minor, validateCredit, type AccountPatch, type FinancialAccount } from './domain/financial-account';
import type { AccountQueryDto, CreateAccountDto, UpdateAccountDto } from './financial-account.dto';

function response(account: FinancialAccount) {
  return {
    id: account.id, clientId: account.clientId, name: account.name, type: account.type,
    currencyCode: account.currencyCode, initialBalanceMinor: account.initialBalanceMinor.toString(),
    balanceMinor: account.balanceMinor.toString(), sortOrder: account.sortOrder,
    creditLimitMinor: account.creditLimitMinor?.toString() ?? null,
    statementCloseDay: account.statementCloseDay, paymentDueDay: account.paymentDueDay,
    archivedAt: account.archivedAt?.toISOString() ?? null, version: account.version,
    createdAt: account.createdAt.toISOString(), updatedAt: account.updatedAt.toISOString(),
  };
}
@Injectable()
export class FinancialAccountService {
  constructor(@Inject(FINANCIAL_ACCOUNT_REPOSITORY) private readonly repository: FinancialAccountRepository) {}

  async create(userId: string, dto: CreateAccountDto) {
    const input = {
      ...dto, clientId: dto.clientId.toLowerCase(), initialBalanceMinor: minor(dto.initialBalanceMinor),
      sortOrder: dto.sortOrder ?? 0,
      creditLimitMinor: dto.creditLimitMinor == null ? null : minor(dto.creditLimitMinor),
      statementCloseDay: dto.statementCloseDay ?? null, paymentDueDay: dto.paymentDueDay ?? null,
    };
    validateCredit(input);
    const result = await this.repository.create(userId, input);
    return { account: response(result.account), created: result.created };
  }
  async find(userId: string, id: string) { return response(await this.repository.find(userId, id)); }
  async list(userId: string, query: AccountQueryDto) {
    const result = await this.repository.list(userId, query);
    return { items: result.items.map(response), page: query.page, pageSize: query.pageSize, total: result.total };
  }
  async update(userId: string, id: string, dto: UpdateAccountDto) {
    const { initialBalanceMinor, creditLimitMinor, ...rest } = dto;
    const patch: AccountPatch = { ...rest };
    if (initialBalanceMinor !== undefined) patch.initialBalanceMinor = minor(initialBalanceMinor);
    if (creditLimitMinor !== undefined) patch.creditLimitMinor = creditLimitMinor === null ? null : minor(creditLimitMinor);
    return response(await this.repository.update(userId, id, patch));
  }
  async archive(userId: string, id: string, version: number): Promise<void> {
    await this.repository.update(userId, id, { version, archived: true });
  }
}
