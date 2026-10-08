import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type { FinancialAccountRepository } from '../domain/financial-account.repository';
import {
  AccountError, sameCreate, updatedFields,
  type AccountPatch, type AccountQuery, type CreateAccount, type FinancialAccount,
} from '../domain/financial-account';

const select = {
  id: true, clientId: true, name: true, type: true, currencyCode: true,
  initialBalanceMinor: true, sortOrder: true, creditLimitMinor: true,
  statementCloseDay: true, paymentDueDay: true, archivedAt: true,
  version: true, createdAt: true, updatedAt: true,
} satisfies Prisma.FinancialAccountSelect;
type Row = Prisma.FinancialAccountGetPayload<{ select: typeof select }>;

@Injectable()
export class PrismaFinancialAccountRepository implements FinancialAccountRepository {
  constructor(private readonly prisma: PrismaService) {}

  private async snapshot<T>(operation: (tx: Prisma.TransactionClient) => Promise<T>, creating = false): Promise<T> {
    for (let attempt = 0; ; attempt++) {
      try {
        return await this.prisma.$transaction(operation, { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead });
      } catch (error) {
        // Retry a fresh snapshot after concurrent update/create; never swallow business errors.
        if (attempt < 3 && error instanceof Prisma.PrismaClientKnownRequestError &&
          (error.code === 'P2034' ||
            (error.code === 'P2010' && ['40001', '40P01'].includes(String(error.meta?.code))) ||
            (creating && error.code === 'P2002'))) continue;
        throw error;
      }
    }
  }

  private async balances(tx: Prisma.TransactionClient, userId: string, rows: Row[]): Promise<FinancialAccount[]> {
    if (!rows.length) return [];
    // PostgreSQL SUM(bigint) is numeric. Cast to text to preserve sums beyond int64 too.
    const totals = await tx.$queryRaw<{ accountId: string; total: string }[]>(Prisma.sql`
      SELECT "accountId", SUM("amountMinor")::text AS total FROM "Transaction"
      WHERE "userId" = ${userId}::uuid AND "deletedAt" IS NULL
        AND "accountId" IN (${Prisma.join(rows.map(row => Prisma.sql`${row.id}::uuid`))})
      GROUP BY "accountId"
    `);
    const byId = new Map(totals.map(total => [total.accountId, BigInt(total.total)]));
    return rows.map(row => ({ ...row, balanceMinor: row.initialBalanceMinor + (byId.get(row.id) ?? 0n) }));
  }

  private async currency(tx: Prisma.TransactionClient, code: string): Promise<void> {
    if (!await tx.currency.findUnique({ where: { code }, select: { code: true } })) {
      throw new AccountError('VALIDATION_ERROR');
    }
  }

  create(userId: string, input: CreateAccount) {
    return this.snapshot(async tx => {
      const existing = await tx.financialAccount.findUnique({
        where: { userId_clientId: { userId, clientId: input.clientId } }, select,
      });
      if (existing) {
        const [account] = await this.balances(tx, userId, [existing]);
        if (!sameCreate(account, input)) throw new AccountError('ACCOUNT_CONFLICT');
        return { account, created: false };
      }
      await this.currency(tx, input.currencyCode);
      const row = await tx.financialAccount.create({ data: { ...input, userId }, select });
      return { account: { ...row, balanceMinor: row.initialBalanceMinor }, created: true };
    }, true);
  }

  find(userId: string, id: string) {
    return this.snapshot(async tx => {
      const row = await tx.financialAccount.findFirst({ where: { id, userId }, select });
      if (!row) throw new AccountError('ACCOUNT_NOT_FOUND');
      return (await this.balances(tx, userId, [row]))[0];
    });
  }

  list(userId: string, query: AccountQuery) {
    return this.snapshot(async tx => {
      const where: Prisma.FinancialAccountWhereInput = {
        userId, ...(query.status === 'all' ? {} : { archivedAt: query.status === 'active' ? null : { not: null } }),
      };
      const rows = await tx.financialAccount.findMany({
        where, select, orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }, { id: 'asc' }],
        skip: (query.page - 1) * query.pageSize, take: query.pageSize,
      });
      return { items: await this.balances(tx, userId, rows), total: await tx.financialAccount.count({ where }) };
    });
  }

  update(userId: string, id: string, patch: AccountPatch) {
    return this.snapshot(async tx => {
      // Lock before checking history and version; concurrent account writes retry a new snapshot.
      const locked = await tx.$queryRaw<{ id: string }[]>`
        SELECT id FROM "FinancialAccount" WHERE id = ${id}::uuid AND "userId" = ${userId}::uuid FOR UPDATE
      `;
      if (!locked.length) throw new AccountError('ACCOUNT_NOT_FOUND');
      const row = await tx.financialAccount.findFirstOrThrow({ where: { id, userId }, select });
      // Include deleted transactions: changing their denomination/type would corrupt restored history.
      const hasTransactions = await tx.transaction.count({ where: { accountId: id } }) > 0;
      const fields = updatedFields({ ...row, balanceMinor: row.initialBalanceMinor }, patch, hasTransactions);
      await this.currency(tx, fields.currencyCode);
      const saved = await tx.financialAccount.update({
        where: { id, userId, version: patch.version },
        data: { ...fields, version: { increment: 1 },
          ...(patch.archived === undefined ? {} : { archivedAt: patch.archived ? row.archivedAt ?? new Date() : null }),
        }, select,
      });
      return (await this.balances(tx, userId, [saved]))[0];
    });
  }
}
