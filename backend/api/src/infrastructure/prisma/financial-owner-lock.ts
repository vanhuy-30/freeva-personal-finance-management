import type { Prisma } from '@prisma/client';
/**
 * First write in category/transaction mutations. Under Repeatable Read a writer
 * waiting on this row must retry with a fresh snapshot after a concurrent write.
 * SELECT FOR UPDATE alone would not invalidate an older snapshot. Profile
 * version is deliberately unchanged: no profile preference was modified.
 */
export async function touchFinancialOwner(tx: Prisma.TransactionClient, userId: string): Promise<void> {
  await tx.user.update({ where: { id: userId }, data: { updatedAt: new Date() }, select: { id: true } });
}
