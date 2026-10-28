import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { dayString } from '../../bills/domain/bill';
import type { CalendarRepository, CalendarSource } from '../domain/calendar.repository';
import { CalendarError, profileToday, type CalendarMonthBounds } from '../domain/calendar';

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

    const [transactions, recurringRules, bills] = await Promise.all([
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
        where: { userId, active: true },
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
      this.prisma.bill.findMany({
        where: {
          userId,
          dueOn: { gte: from, lte: to },
        },
        select: {
          id: true,
          name: true,
          dueOn: true,
          amountMinor: true,
          amountKind: true,
          currencyCode: true,
          paidTransactionId: true,
        },
        orderBy: [{ dueOn: 'asc' }, { id: 'asc' }],
      }),
    ]);

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
      bills: bills.map(row => ({
        id: row.id,
        name: row.name,
        dueOn: dayString(row.dueOn),
        amountMinor: row.amountMinor,
        amountKind: row.amountKind,
        currencyCode: row.currencyCode,
        paidTransactionId: row.paidTransactionId,
      })),
    };
  }
}
