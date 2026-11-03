import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { CalendarError, profileToday } from '../../calendar/domain/calendar';
import { ForecastError } from '../domain/forecast';
import type { ForecastRepository, ForecastSource } from '../domain/forecast.repository';

function dayString(value: Date): string {
  return value.toISOString().slice(0, 10);
}

@Injectable()
export class PrismaForecastRepository implements ForecastRepository {
  constructor(private readonly prisma: PrismaService) {}

  async load(userId: string, now = new Date()): Promise<ForecastSource> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { timezone: true, defaultCurrencyCode: true },
    });
    if (!user) throw new ForecastError('VALIDATION_ERROR');
    let today: string;
    try {
      today = profileToday(user.timezone, now);
    } catch (error) {
      if (error instanceof CalendarError) throw new ForecastError('VALIDATION_ERROR');
      throw error;
    }

    const [accounts, sums, rules] = await Promise.all([
      this.prisma.financialAccount.findMany({
        where: { userId, archivedAt: null, type: { not: 'credit' } },
        select: { id: true, currencyCode: true, initialBalanceMinor: true },
      }),
      this.prisma.transaction.groupBy({
        by: ['accountId'],
        where: { userId, deletedAt: null, account: { archivedAt: null, type: { not: 'credit' } } },
        _sum: { amountMinor: true },
      }),
      this.prisma.recurringRule.findMany({
        where: { userId, active: true },
        select: {
          id: true, mode: true, type: true, amountMinor: true, currencyCode: true, unit: true, interval: true,
          startDate: true, endDate: true, nextExecutionDate: true,
        },
        orderBy: [{ id: 'asc' }],
      }),
    ]);

    const byAccount = new Map(sums.map(row => [row.accountId, row._sum.amountMinor ?? 0n]));
    const balanceByCurrency = new Map<string, bigint>();
    for (const account of accounts) {
      const code = account.currencyCode.trim();
      balanceByCurrency.set(code, (balanceByCurrency.get(code) ?? 0n) + account.initialBalanceMinor + (byAccount.get(account.id) ?? 0n));
    }

    return {
      timezone: user.timezone,
      today,
      defaultCurrencyCode: user.defaultCurrencyCode.trim(),
      balanceByCurrency,
      rules: rules.map(row => ({
        id: row.id,
        mode: row.mode,
        type: row.type,
        // Rules store signed amounts (expense negative), same as transactions.
        amountMinor: row.amountMinor,
        currencyCode: row.currencyCode.trim(),
        unit: row.unit,
        interval: row.interval,
        startDate: dayString(row.startDate),
        endDate: row.endDate ? dayString(row.endDate) : null,
        nextExecutionDate: dayString(row.nextExecutionDate),
      })),
    };
  }
}
