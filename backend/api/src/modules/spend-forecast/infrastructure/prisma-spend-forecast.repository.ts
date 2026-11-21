import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type { ForecastProfile, Outlook, SpendForecastRepository } from '../domain/spend-forecast.repository';

const day = (value: string) => new Date(`${value}T00:00:00.000Z`);
const text = (value: Date) => value.toISOString().slice(0, 10);

@Injectable()
export class PrismaSpendForecastRepository implements SpendForecastRepository {
  constructor(private readonly prisma: PrismaService) {}

  async profile(userId: string): Promise<ForecastProfile | null> {
    return this.prisma.user.findUnique({ where: { id: userId }, select: { timezone: true, fiscalMonthStartDay: true, defaultCurrencyCode: true } });
  }

  async ledger(userId: string, currencyCode: string, from: string, to: string) {
    const [rows, categories] = await Promise.all([
      this.prisma.transaction.findMany({
        where: { userId, deletedAt: null, type: { in: ['expense', 'refund'] }, currencyCode, occurredOn: { gte: day(from), lte: day(to) } },
        select: { type: true, amountMinor: true, categoryId: true, occurredOn: true, recurringRuleId: true },
      }),
      this.prisma.category.findMany({ where: { userId }, select: { id: true, name: true, parentId: true, iconToken: true, colorToken: true } }),
    ]);
    return {
      transactions: rows.map(row => ({
        type: row.type as 'expense' | 'refund',
        amountMinor: row.amountMinor < 0n ? -row.amountMinor : row.amountMinor,
        categoryId: row.categoryId,
        occurredOn: text(row.occurredOn),
        recurring: row.recurringRuleId !== null,
      })),
      categories,
    };
  }

  async outlook(userId: string, currencyCode: string): Promise<Outlook> {
    const walletWhere = { userId, archivedAt: null, type: { not: 'credit' as const }, currencyCode };
    const [accounts, sums, rules] = await Promise.all([
      this.prisma.financialAccount.findMany({ where: walletWhere, select: { id: true, initialBalanceMinor: true } }),
      this.prisma.transaction.groupBy({
        by: ['accountId'],
        where: { userId, deletedAt: null, account: walletWhere },
        _sum: { amountMinor: true },
      }),
      this.prisma.recurringRule.findMany({
        where: { userId, active: true, currencyCode, type: { in: ['income', 'expense'] }, OR: [{ account: null }, { account: { type: { not: 'credit' } } }] },
        select: { type: true, amountMinor: true, unit: true, interval: true, startDate: true, endDate: true, nextExecutionDate: true },
      }),
    ]);
    const byAccount = new Map(sums.map(row => [row.accountId, row._sum.amountMinor ?? 0n]));
    return {
      walletCount: accounts.length,
      balanceMinor: accounts.reduce((sum, a) => sum + a.initialBalanceMinor + (byAccount.get(a.id) ?? 0n), 0n),
      rules: rules.map(rule => ({
        type: rule.type, amountMinor: rule.amountMinor, unit: rule.unit, interval: rule.interval,
        startDate: text(rule.startDate), endDate: rule.endDate ? text(rule.endDate) : null, nextExecutionDate: text(rule.nextExecutionDate),
      })),
    };
  }

  async goal(userId: string, goalId: string, since: string) {
    const goal = await this.prisma.goal.findFirst({
      where: { id: goalId, userId },
      select: {
        targetMinor: true, currentMinor: true, targetDate: true,
        entries: { where: { occurredOn: { gte: day(since) } }, select: { kind: true, amountMinor: true, occurredOn: true } },
      },
    });
    if (!goal) return null;
    return {
      targetMinor: goal.targetMinor,
      currentMinor: goal.currentMinor,
      targetDate: goal.targetDate ? text(goal.targetDate) : null,
      entries: goal.entries.map(entry => ({ kind: entry.kind, amountMinor: entry.amountMinor < 0n ? -entry.amountMinor : entry.amountMinor, occurredOn: text(entry.occurredOn) })),
    };
  }
}
