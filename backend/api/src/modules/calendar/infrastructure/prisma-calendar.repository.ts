import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { occurrencesInRange } from '../../recurring/domain/calendar';
import type { CalendarRepository, CalendarSource } from '../domain/calendar.repository';
import { CalendarError, profileToday, type CalendarMonthBounds } from '../domain/calendar';

function dayString(value: Date): string {
  return value.toISOString().slice(0, 10);
}

@Injectable()
export class PrismaCalendarRepository implements CalendarRepository {
  constructor(private readonly prisma: PrismaService) {}

  async loadMonth(userId: string, bounds: CalendarMonthBounds, now = new Date()): Promise<CalendarSource> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { timezone: true },
    });
    if (!user) throw new CalendarError('VALIDATION_ERROR');
    const today = profileToday(user.timezone, now);
    const from = new Date(`${bounds.from}T00:00:00.000Z`);
    const to = new Date(`${bounds.to}T00:00:00.000Z`);

    const [transactions, recurringRules, remindRules] = await Promise.all([
      this.prisma.transaction.findMany({
        where: {
          userId,
          deletedAt: null,
          occurredOn: { gte: from, lte: to },
        },
        select: {
          id: true,
          type: true,
          amountMinor: true,
          currencyCode: true,
          transferGroupId: true,
          occurredOn: true,
          category: { select: { name: true } },
        },
        orderBy: [{ occurredOn: 'asc' }, { id: 'asc' }],
      }),
      this.prisma.recurringRule.findMany({
        where: { userId, active: true, mode: 'auto' },
        select: {
          id: true,
          type: true,
          amountMinor: true,
          currencyCode: true,
          unit: true,
          interval: true,
          startDate: true,
          endDate: true,
          nextExecutionDate: true,
          active: true,
          category: { select: { name: true } },
        },
        orderBy: [{ id: 'asc' }],
      }),
      this.prisma.recurringRule.findMany({
        where: { userId, mode: 'remind' },
        select: {
          id: true,
          name: true,
          amountMinor: true,
          amountKind: true,
          currencyCode: true,
          unit: true,
          interval: true,
          startDate: true,
          endDate: true,
          nextExecutionDate: true,
          active: true,
          occurrences: { where: { occurredOn: { gte: from, lte: to } }, select: { occurredOn: true, transactionClientId: true } },
        },
        orderBy: [{ id: 'asc' }],
      }),
    ]);

    const clientIds = remindRules.flatMap(rule => rule.occurrences.map(item => item.transactionClientId));
    const paidTransactions = clientIds.length
      ? await this.prisma.transaction.findMany({ where: { userId, clientId: { in: clientIds } }, select: { id: true, clientId: true } })
      : [];
    const paidIdByClient = new Map(paidTransactions.map(row => [row.clientId, row.id]));
    const bills: CalendarSource['bills'] = [];
    for (const rule of remindRules) {
      const base = {
        id: rule.id,
        name: rule.name ?? '',
        amountMinor: -rule.amountMinor,
        amountKind: rule.amountKind,
        currencyCode: rule.currencyCode.trim(),
      };
      for (const item of rule.occurrences) {
        bills.push({ ...base, dueOn: dayString(item.occurredOn), paidTransactionId: paidIdByClient.get(item.transactionClientId) ?? null });
      }
      for (const dueOn of occurrencesInRange({
        nextExecutionDate: dayString(rule.nextExecutionDate),
        startDate: dayString(rule.startDate),
        endDate: rule.endDate ? dayString(rule.endDate) : null,
        rangeFrom: bounds.from,
        rangeTo: bounds.to,
        unit: rule.unit,
        interval: rule.interval,
        active: rule.active,
      })) {
        bills.push({ ...base, dueOn, paidTransactionId: null });
      }
    }

    return {
      timezone: user.timezone,
      today,
      transactions: transactions.map(row => ({
        id: row.id,
        type: row.type,
        amountMinor: row.amountMinor,
        currencyCode: row.currencyCode,
        categoryName: row.category?.name ?? null,
        transferGroupId: row.transferGroupId,
        occurredOn: dayString(row.occurredOn),
      })),
      recurringRules: recurringRules.map(row => ({
        id: row.id,
        type: row.type,
        amountMinor: row.amountMinor,
        currencyCode: row.currencyCode,
        categoryName: row.category?.name ?? null,
        unit: row.unit,
        interval: row.interval,
        startDate: dayString(row.startDate),
        endDate: row.endDate ? dayString(row.endDate) : null,
        nextExecutionDate: dayString(row.nextExecutionDate),
        active: row.active,
      })),
      bills,
    };
  }
}
