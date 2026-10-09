import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type { ReportRepository } from '../domain/report.repository';
import type {
  AccountMovement, AccountRef, CategoryAggregate, NetWorthAggregate, ReportMoneyType, ReportProfile, ResolvedPeriod,
} from '../domain/report';

const moneyTypes = new Set<ReportMoneyType>(['income', 'expense', 'transfer']);

@Injectable()
export class PrismaReportRepository implements ReportRepository {
  constructor(private readonly prisma: PrismaService) {}

  cashflow(userId: string, periodOf: (profile: ReportProfile) => ResolvedPeriod) {
    return this.snapshot(async tx => {
      const profile = await this.profile(tx, userId);
      const period = periodOf(profile);
      const [categories, accounts, movements] = [
        await this.categories(tx, userId, period),
        await this.accounts(tx, userId),
        await this.movements(tx, userId, period),
      ];
      return { period, source: { categories, accounts, movements } };
    });
  }

  netWorth(userId: string) {
    return this.snapshot(tx => this.netWorthRows(tx, userId));
  }

  private async snapshot<T>(operation: (tx: Prisma.TransactionClient) => Promise<T>): Promise<T> {
    for (let attempt = 0; ; attempt++) {
      try {
        return await this.prisma.$transaction(operation, { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead });
      } catch (error) {
        if (attempt < 3 && error instanceof Prisma.PrismaClientKnownRequestError &&
          (error.code === 'P2034' || (error.code === 'P2010' && ['40001', '40P01'].includes(String(error.meta?.code))))) continue;
        throw error;
      }
    }
  }

  private async profile(tx: Prisma.TransactionClient, userId: string): Promise<ReportProfile> {
    const user = await tx.user.findUnique({ where: { id: userId }, select: { timezone: true, fiscalMonthStartDay: true } });
    if (!user) throw new Error('Report owner is missing');
    return user;
  }

  private async categories(tx: Prisma.TransactionClient, userId: string, period: ResolvedPeriod): Promise<CategoryAggregate[]> {
    const rows = await tx.$queryRaw<{ currency: string; categoryId: string | null; parentId: string | null; type: string; total: string }[]>(Prisma.sql`
      SELECT t."currencyCode" AS currency, t."categoryId" AS "categoryId", c."parentId" AS "parentId",
        t.type::text AS type, SUM(t."amountMinor")::text AS total
      FROM "Transaction" t
      LEFT JOIN "Category" c ON c.id = t."categoryId" AND c."userId" = t."userId"
      WHERE t."userId" = ${userId}::uuid AND t."deletedAt" IS NULL
        AND t."occurredOn" >= ${period.from}::date AND t."occurredOn" <= ${period.to}::date
        AND t.type::text IN ('income', 'expense')
      GROUP BY t."currencyCode", t."categoryId", c."parentId", t.type
    `);
    return rows.map(row => ({
      currency: row.currency.trim(), categoryId: row.categoryId, parentId: row.parentId, type: flowType(row.type), total: integer(row.total),
    }));
  }

  private async accounts(tx: Prisma.TransactionClient, userId: string): Promise<AccountRef[]> {
    const rows = await tx.$queryRaw<{ accountId: string; currency: string; archived: boolean }[]>(Prisma.sql`
      SELECT id AS "accountId", "currencyCode" AS currency, ("archivedAt" IS NOT NULL) AS archived
      FROM "FinancialAccount" WHERE "userId" = ${userId}::uuid
    `);
    return rows.map(row => ({ ...row, currency: row.currency.trim() }));
  }

  private async movements(tx: Prisma.TransactionClient, userId: string, period: ResolvedPeriod): Promise<AccountMovement[]> {
    const rows = await tx.$queryRaw<{ accountId: string; currency: string; type: string; total: string }[]>(Prisma.sql`
      SELECT t."accountId" AS "accountId", a."currencyCode" AS currency, t.type::text AS type, SUM(t."amountMinor")::text AS total
      FROM "Transaction" t
      JOIN "FinancialAccount" a ON a.id = t."accountId" AND a."userId" = t."userId"
      WHERE t."userId" = ${userId}::uuid AND t."deletedAt" IS NULL
        AND t."occurredOn" >= ${period.from}::date AND t."occurredOn" <= ${period.to}::date
      GROUP BY t."accountId", a."currencyCode", t.type
    `);
    return rows.map(row => {
      if (!moneyTypes.has(row.type as ReportMoneyType)) throw new Error('Invalid report flow');
      return { accountId: row.accountId, currency: row.currency.trim(), type: row.type as ReportMoneyType, total: integer(row.total) };
    });
  }

  private async netWorthRows(tx: Prisma.TransactionClient, userId: string): Promise<NetWorthAggregate[]> {
    const rows = await tx.$queryRaw<{ currency: string; bucket: string; total: string }[]>(Prisma.sql`
      SELECT a."currencyCode" AS currency,
        CASE WHEN a.type::text = 'credit' THEN 'liability' ELSE 'asset' END AS bucket,
        SUM(a."initialBalanceMinor" + COALESCE(mv.total, 0))::text AS total
      FROM "FinancialAccount" a
      LEFT JOIN (
        SELECT "accountId", SUM("amountMinor") AS total FROM "Transaction"
        WHERE "userId" = ${userId}::uuid AND "deletedAt" IS NULL GROUP BY "accountId"
      ) mv ON mv."accountId" = a.id
      WHERE a."userId" = ${userId}::uuid
      GROUP BY a."currencyCode", CASE WHEN a.type::text = 'credit' THEN 'liability' ELSE 'asset' END
    `);
    return rows.map(row => {
      if (row.bucket !== 'asset' && row.bucket !== 'liability') throw new Error('Invalid net worth bucket');
      return { currency: row.currency.trim(), bucket: row.bucket, total: integer(row.total) };
    });
  }
}

function flowType(value: string): 'income' | 'expense' {
  if (value === 'income' || value === 'expense') return value;
  throw new Error('Invalid report flow');
}

function integer(value: string): bigint {
  if (!/^-?[0-9]+$/.test(value)) throw new Error('Invalid money aggregate');
  return BigInt(value);
}
