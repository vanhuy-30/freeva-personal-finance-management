import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import type { InsightProfile, InsightRepository } from '../domain/insight.repository';

const day = (value: string) => new Date(`${value}T00:00:00.000Z`);

@Injectable()
export class PrismaInsightRepository implements InsightRepository {
  constructor(private readonly prisma: PrismaService) {}

  async profile(userId: string): Promise<InsightProfile | null> {
    return this.prisma.user.findUnique({ where: { id: userId }, select: { timezone: true, fiscalMonthStartDay: true, defaultCurrencyCode: true } });
  }

  async ledger(userId: string, currencyCode: string, from: string, to: string) {
    const [rows, categories] = await Promise.all([
      this.prisma.transaction.findMany({
        where: { userId, deletedAt: null, type: { in: ['expense', 'refund'] }, currencyCode, occurredOn: { gte: day(from), lte: day(to) } },
        select: { id: true, type: true, amountMinor: true, categoryId: true, merchant: true, occurredOn: true },
      }),
      this.prisma.category.findMany({
        where: { userId },
        select: { id: true, name: true, parentId: true, iconToken: true, colorToken: true },
      }),
    ]);
    return {
      transactions: rows.map(row => ({
        id: row.id,
        type: row.type as 'expense' | 'refund',
        amountMinor: row.amountMinor < 0n ? -row.amountMinor : row.amountMinor,
        categoryId: row.categoryId,
        merchant: row.merchant,
        occurredOn: row.occurredOn.toISOString().slice(0, 10),
      })),
      categories,
    };
  }
}
