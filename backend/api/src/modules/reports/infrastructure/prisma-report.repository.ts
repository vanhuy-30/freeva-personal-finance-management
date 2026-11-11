import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type { ReportRepository } from '../domain/report.repository';
import type {
  AccountMovement, AccountRef, CategoryAggregate, MerchantAggregate, NetWorthAggregate, ReportMoneyType, ReportProfile, ResolvedPeriod, TrendBucket, TrendRow, TrendSource,
} from '../domain/report';
import { previousPeriod, todayInTimeZone } from '../domain/report';
import { parseQuantity, valuate, type InvestmentKind, type InvestmentRecord } from '../../investments/domain/investment';
import type { DebtHistory, InvestmentHistory, InvestmentValueHistorySource, NetWorthHistorySource, WalletBalanceRow } from '../domain/net-worth-history';

const moneyTypes = new Set<ReportMoneyType>(['income', 'expense', 'transfer', 'adjustment', 'debt', 'refund', 'investment']);

@Injectable()
export class PrismaReportRepository implements ReportRepository {
  constructor(private readonly prisma: PrismaService) {}

  cashflow(userId: string, periodOf: (profile: ReportProfile) => ResolvedPeriod) {
    return this.snapshot(async tx => {
      const profile = await this.profile(tx, userId);
      const period = periodOf(profile);
      const previous = previousPeriod(period);
      const [categories, accounts, movements, previousCategories, merchants] = [
        await this.categories(tx, userId, period.from, period.to),
        await this.accounts(tx, userId),
        await this.movements(tx, userId, period),
        await this.categories(tx, userId, previous.from, previous.to),
        await this.merchants(tx, userId, period.from, period.to),
      ];
      return {
        period,
        source: { categories, accounts, movements },
        previous: { from: previous.from, to: previous.to, categories: previousCategories },
        merchants,
      };
    });
  }

  monthReview(userId: string, periodOf: (profile: ReportProfile) => ResolvedPeriod) {
    return this.snapshot(async tx => {
      const profile = await this.profile(tx, userId);
      const period = periodOf(profile);
      return {
        period,
        categories: await this.categories(tx, userId, period.from, period.to),
      };
    });
  }

  trend(userId: string, bucketsOf: (profile: ReportProfile) => TrendBucket[]): Promise<TrendSource> {
    return this.snapshot(async tx => {
      const buckets = bucketsOf(await this.profile(tx, userId));
      return { buckets, rows: await this.trendRows(tx, userId, buckets), firstOn: await this.firstOn(tx, userId) };
    });
  }

  series(userId: string, bucketsOf: (profile: ReportProfile, firstOn: string | null) => TrendBucket[]): Promise<TrendSource> {
    return this.snapshot(async tx => {
      const profile = await this.profile(tx, userId);
      const firstOn = await this.firstOn(tx, userId);
      const buckets = bucketsOf(profile, firstOn);
      return { buckets, rows: await this.trendRows(tx, userId, buckets), firstOn };
    });
  }

  netWorth(userId: string) {
    return this.snapshot(tx => this.netWorthRows(tx, userId));
  }

  netWorthHistory(userId: string, bucketsOf: (profile: ReportProfile, firstOn: string | null) => TrendBucket[]): Promise<NetWorthHistorySource> {
    return this.snapshot(async tx => {
      const profile = await this.profile(tx, userId);
      const today = todayInTimeZone(profile.timezone, new Date());
      const buckets = bucketsOf(profile, await this.firstActivityOn(tx, userId));
      return {
        buckets,
        today,
        wallets: await this.walletHistory(tx, userId, buckets.map(bucket => (bucket.to < today ? bucket.to : today))),
        debts: await this.debtHistory(tx, userId),
        investments: await this.investmentHistory(tx, userId, profile.timezone),
      };
    });
  }

  investmentValueHistory(
    userId: string, filter: { kind?: InvestmentKind; investmentId?: string },
    bucketsOf: (profile: ReportProfile, firstOn: string | null) => TrendBucket[],
  ): Promise<InvestmentValueHistorySource> {
    return this.snapshot(async tx => {
      const profile = await this.profile(tx, userId);
      const investments = await this.investmentHistory(tx, userId, profile.timezone, filter);
      const first = investments.flatMap(item => item.trades.map(trade => trade.tradedOn)).sort()[0] ?? null;
      return { buckets: bucketsOf(profile, first), today: todayInTimeZone(profile.timezone, new Date()), investments };
    });
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

  private async categories(tx: Prisma.TransactionClient, userId: string, from: string, to: string): Promise<CategoryAggregate[]> {
    const rows = await tx.$queryRaw<{ currency: string; categoryId: string | null; parentId: string | null; type: string; total: string; count: number }[]>(Prisma.sql`
      SELECT t."currencyCode" AS currency, t."categoryId" AS "categoryId", c."parentId" AS "parentId",
        t.type::text AS type, SUM(t."amountMinor")::text AS total, SUM(t.n)::int AS count
      FROM ${flow} t
      LEFT JOIN "Category" c ON c.id = t."categoryId" AND c."userId" = t."userId"
      WHERE t."userId" = ${userId}::uuid AND t."deletedAt" IS NULL
        AND t."occurredOn" >= ${from}::date AND t."occurredOn" <= ${to}::date
      GROUP BY t."currencyCode", t."categoryId", c."parentId", t.type
    `);
    return rows.map(row => ({
      currency: row.currency.trim(), categoryId: row.categoryId, parentId: row.parentId, type: flowType(row.type), total: integer(row.total), count: row.count,
    }));
  }

  private async merchants(tx: Prisma.TransactionClient, userId: string, from: string, to: string): Promise<MerchantAggregate[]> {
    const rows = await tx.$queryRaw<{ currency: string; merchant: string; expense: string; count: number }[]>(Prisma.sql`
      SELECT t."currencyCode" AS currency, t.merchant AS merchant,
        SUM(t."amountMinor")::text AS expense, SUM(t.n)::int AS count
      FROM ${flow} t
      WHERE t."userId" = ${userId}::uuid AND t."deletedAt" IS NULL
        AND t."occurredOn" >= ${from}::date AND t."occurredOn" <= ${to}::date
        AND t.type::text = 'expense' AND t.merchant IS NOT NULL
      GROUP BY t."currencyCode", t.merchant
    `);
    return rows.map(row => ({
      currency: row.currency.trim(), merchant: row.merchant, expense: integer(row.expense), count: row.count,
    }));
  }

  private async trendRows(tx: Prisma.TransactionClient, userId: string, buckets: TrendBucket[]): Promise<TrendRow[]> {
    if (buckets.length === 0) return [];
    const ranges = Prisma.join(buckets.map((bucket, index) => Prisma.sql`(${index}::int, ${bucket.from}::date, ${bucket.to}::date)`));
    const rows = await tx.$queryRaw<{ index: number; currency: string; type: string; total: string }[]>(Prisma.sql`
      SELECT b.idx AS index, t."currencyCode" AS currency, t.type::text AS type, SUM(t."amountMinor")::text AS total
      FROM (VALUES ${ranges}) AS b(idx, first_on, last_on)
      JOIN ${flow} t ON t."occurredOn" >= b.first_on AND t."occurredOn" <= b.last_on
      WHERE t."userId" = ${userId}::uuid AND t."deletedAt" IS NULL
      GROUP BY b.idx, t."currencyCode", t.type
    `);
    return rows.map(row => ({ index: row.index, currency: row.currency.trim(), type: flowType(row.type), total: integer(row.total) }));
  }

  /** Earliest day anything moved: any transaction, a lend/borrow or an investment trade. */
  private async firstActivityOn(tx: Prisma.TransactionClient, userId: string): Promise<string | null> {
    const rows = await tx.$queryRaw<{ first: string | null }[]>(Prisma.sql`
      SELECT LEAST(
        (SELECT MIN("occurredOn") FROM "Transaction" WHERE "userId" = ${userId}::uuid AND "deletedAt" IS NULL),
        (SELECT MIN("occurredOn") FROM "PersonalDebt" WHERE "userId" = ${userId}::uuid),
        (SELECT MIN("tradedOn") FROM "InvestmentTrade" WHERE "userId" = ${userId}::uuid)
      )::text AS first
    `);
    return rows[0]?.first ?? null;
  }

  /** Active wallet balances at the end of each given day, same rule as `netWorthRows` (credit wallets are liabilities). */
  private async walletHistory(tx: Prisma.TransactionClient, userId: string, asOf: string[]): Promise<WalletBalanceRow[]> {
    if (asOf.length === 0) return [];
    const days = Prisma.join(asOf.map((day, index) => Prisma.sql`(${index}::int, ${day}::date)`));
    const rows = await tx.$queryRaw<{ index: number; currency: string; bucket: string; total: string }[]>(Prisma.sql`
      SELECT b.idx AS index, a."currencyCode" AS currency,
        CASE WHEN a.type::text = 'credit' THEN 'liability' ELSE 'asset' END AS bucket,
        SUM(a."initialBalanceMinor" + COALESCE(mv.total, 0))::text AS total
      FROM (VALUES ${days}) AS b(idx, as_of)
      CROSS JOIN "FinancialAccount" a
      LEFT JOIN LATERAL (
        SELECT SUM(t."amountMinor") AS total FROM "Transaction" t
        WHERE t."accountId" = a.id AND t."userId" = a."userId" AND t."deletedAt" IS NULL AND t."occurredOn" <= b.as_of
      ) mv ON true
      WHERE a."userId" = ${userId}::uuid AND a."archivedAt" IS NULL
      GROUP BY b.idx, a."currencyCode", CASE WHEN a.type::text = 'credit' THEN 'liability' ELSE 'asset' END
    `);
    return rows.map(row => {
      if (row.bucket !== 'asset' && row.bucket !== 'liability') throw new Error('Invalid net worth bucket');
      return { index: row.index, currency: row.currency.trim(), bucket: row.bucket, total: integer(row.total) };
    });
  }

  /** Every lend/borrow, archived ones too: a debt settled later was still open on earlier days. */
  private async debtHistory(tx: Prisma.TransactionClient, userId: string): Promise<DebtHistory[]> {
    const rows = await tx.personalDebt.findMany({ where: { userId }, include: { payments: { select: { paidOn: true, amountMinor: true } } } });
    return rows.map(row => ({
      currency: row.currencyCode.trim(),
      direction: row.direction,
      principalMinor: row.principalMinor,
      occurredOn: row.occurredOn.toISOString().slice(0, 10),
      payments: row.payments.map(payment => ({ paidOn: payment.paidOn.toISOString().slice(0, 10), amountMinor: payment.amountMinor })),
    }));
  }

  private async investmentHistory(
    tx: Prisma.TransactionClient, userId: string, timezone: string, filter: { kind?: InvestmentKind; investmentId?: string } = {},
  ): Promise<InvestmentHistory[]> {
    const rows = await tx.investment.findMany({
      where: { userId, ...(filter.kind ? { kind: filter.kind } : {}), ...(filter.investmentId ? { id: filter.investmentId } : {}) },
      include: { trades: true, prices: true },
    });
    return rows.map(row => ({
      kind: row.kind,
      currency: row.currencyCode.trim(),
      unit: row.unit,
      interestRateBps: row.interestRateBps,
      startDate: row.startDate ? row.startDate.toISOString().slice(0, 10) : null,
      maturityDate: row.maturityDate ? row.maturityDate.toISOString().slice(0, 10) : null,
      trades: row.trades.map(trade => ({
        id: trade.id, side: trade.side, quantityScaled: parseQuantity(trade.quantity.toFixed(8)), amountMinor: trade.amountMinor,
        tradedOn: trade.tradedOn.toISOString().slice(0, 10), createdAt: trade.createdAt,
      })),
      prices: row.prices.map(price => ({
        priceMinor: price.priceMinor, source: price.source, quotedAt: price.quotedAt, quotedDay: todayInTimeZone(timezone, price.quotedAt),
      })),
    }));
  }

  private async firstOn(tx: Prisma.TransactionClient, userId: string): Promise<string | null> {
    const rows = await tx.$queryRaw<{ first: string | null }[]>(Prisma.sql`
      SELECT MIN("occurredOn")::text AS first FROM "Transaction"
      WHERE "userId" = ${userId}::uuid AND "deletedAt" IS NULL AND type::text IN ('income', 'expense')
    `);
    return rows[0]?.first ?? null;
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
      WHERE a."userId" = ${userId}::uuid AND a."archivedAt" IS NULL
      GROUP BY a."currencyCode", CASE WHEN a.type::text = 'credit' THEN 'liability' ELSE 'asset' END
    `);
    // Lend / borrow (BE-P3-007): what people owe me is an asset, what I owe them a (negative) liability.
    const debts = await tx.$queryRaw<{ currency: string; direction: string; total: string }[]>(Prisma.sql`
      SELECT "currencyCode" AS currency, direction::text AS direction, SUM("outstandingMinor")::text AS total
      FROM "PersonalDebt"
      WHERE "userId" = ${userId}::uuid AND "archivedAt" IS NULL AND "outstandingMinor" > 0
      GROUP BY "currencyCode", direction
    `);
    // Investments (BE-P4-E01): the wallet already lost the money moved in, so adding the position's value does not double count.
    // Current value is priced here in SQL-free form by the caller; see investmentRows.
    const investments = await this.investmentRows(tx, userId);
    const accountRows: NetWorthAggregate[] = rows.map(row => {
      if (row.bucket !== 'asset' && row.bucket !== 'liability') throw new Error('Invalid net worth bucket');
      return { currency: row.currency.trim(), bucket: row.bucket, total: integer(row.total) };
    });
    const debtRows: NetWorthAggregate[] = debts.map(row => {
      if (row.direction !== 'lent' && row.direction !== 'borrowed') throw new Error('Invalid debt direction');
      const total = integer(row.total);
      return row.direction === 'lent'
        ? { currency: row.currency.trim(), bucket: 'asset' as const, total }
        : { currency: row.currency.trim(), bucket: 'liability' as const, total: -total };
    });
    return [...accountRows, ...debtRows, ...investments];
  }

  /** Held positions as assets: deposits at principal + accrued interest, the rest at quantity x latest price (cost when unpriced). */
  private async investmentRows(tx: Prisma.TransactionClient, userId: string): Promise<NetWorthAggregate[]> {
    const user = await tx.user.findUnique({ where: { id: userId }, select: { timezone: true } });
    const today = todayInTimeZone(user?.timezone ?? 'UTC', new Date());
    const rows = await tx.investment.findMany({
      where: { userId, archivedAt: null, quantity: { gt: 0 } },
      include: { prices: { orderBy: [{ quotedAt: 'desc' }, { createdAt: 'desc' }], take: 1 } },
    });
    const totals = new Map<string, bigint>();
    for (const row of rows) {
      const price = row.prices[0];
      const record: InvestmentRecord = {
        id: row.id, clientId: row.clientId, kind: row.kind, name: row.name, currencyCode: row.currencyCode.trim(), unit: row.unit,
        quantityScaled: parseQuantity(row.quantity.toFixed(8)), costBasisMinor: row.costBasisMinor, interestRateBps: row.interestRateBps,
        startDate: row.startDate ? row.startDate.toISOString().slice(0, 10) : null,
        maturityDate: row.maturityDate ? row.maturityDate.toISOString().slice(0, 10) : null,
        note: row.note, archivedAt: row.archivedAt, version: row.version, createdAt: row.createdAt, updatedAt: row.updatedAt,
        latestPrice: price ? { priceMinor: price.priceMinor, source: price.source, quotedAt: price.quotedAt } : null,
      };
      totals.set(record.currencyCode, (totals.get(record.currencyCode) ?? 0n) + valuate(record, today).currentValueMinor);
    }
    return [...totals.entries()].map(([currency, total]) => ({ currency, bucket: 'asset' as const, total }));
  }
}

/**
 * Income/expense rows for the cashflow queries. A refund (BE-P3-008) is attributed to the expense it returns money for:
 * same date, category and merchant as the original, typed `expense`, so it cancels part of that expense instead of
 * counting as income. `n` is 0 for refunds so transaction counts stay the number of real transactions.
 */
const flow = Prisma.sql`(
  SELECT x.id, x."userId", x."currencyCode", x."categoryId", x.type::text AS type, x."amountMinor", x."occurredOn",
    x.merchant, x."deletedAt", 1 AS n
  FROM "Transaction" x WHERE x.type::text IN ('income', 'expense')
  UNION ALL
  SELECT r.id, r."userId", r."currencyCode", o."categoryId", 'expense' AS type, r."amountMinor", o."occurredOn",
    o.merchant, r."deletedAt", 0 AS n
  FROM "Transaction" r JOIN "Transaction" o ON o.id = r."refundOfId" AND o."userId" = r."userId" AND o."deletedAt" IS NULL
  WHERE r.type::text = 'refund'
)`;

function flowType(value: string): 'income' | 'expense' {
  if (value === 'income' || value === 'expense') return value;
  throw new Error('Invalid report flow');
}

function integer(value: string): bigint {
  if (!/^-?[0-9]+$/.test(value)) throw new Error('Invalid money aggregate');
  return BigInt(value);
}
