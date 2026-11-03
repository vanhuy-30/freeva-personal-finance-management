import type { Prisma, PrismaClient } from '@prisma/client';
import type { ExpenseRow } from '../domain/budget';

/**
 * Rows that make up a budget period's spend: expenses dated inside it, plus refunds of those expenses
 * (even when the refund itself is dated later), carrying the original's category.
 */
export async function periodSpendRows(
  db: PrismaClient | Prisma.TransactionClient,
  userId: string,
  from: Date,
  to: Date,
): Promise<ExpenseRow[]> {
  const expenses = await db.transaction.findMany({
    where: { userId, type: 'expense', deletedAt: null, occurredOn: { gte: from, lte: to } },
    select: { type: true, amountMinor: true, currencyCode: true, categoryId: true, deletedAt: true },
  });
  const refunds = await db.transaction.findMany({
    where: { userId, type: 'refund', deletedAt: null, refundOf: { type: 'expense', deletedAt: null, occurredOn: { gte: from, lte: to } } },
    select: { type: true, amountMinor: true, currencyCode: true, deletedAt: true, refundOf: { select: { categoryId: true } } },
  });
  return [
    ...expenses,
    ...refunds.map(({ refundOf, ...row }) => ({ ...row, categoryId: refundOf?.categoryId ?? null })),
  ];
}
