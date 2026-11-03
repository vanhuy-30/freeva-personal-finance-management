import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { touchFinancialOwner } from '../../../infrastructure/prisma/financial-owner-lock';
import { todayInTimeZone } from '../../reports/domain/report';
import { refundCap } from '../../transactions/domain/refund';
import {
  CardInstallmentError, defaultInstallmentMinor, validatePlan, type CardInstallmentRecord,
} from '../domain/card-installment';
import type {
  CardInstallmentCreateInput, CardInstallmentFilter, CardInstallmentRepository,
} from '../domain/card-installment.repository';

type Row = Prisma.CardInstallmentPlanGetPayload<Record<string, never>>;

const dayOf = (value: Date) => value.toISOString().slice(0, 10);
const toDate = (value: string) => new Date(`${value}T00:00:00.000Z`);

function map(row: Row): CardInstallmentRecord {
  return {
    id: row.id,
    clientId: row.clientId,
    transactionId: row.transactionId,
    accountId: row.accountId,
    currencyCode: row.currencyCode.trim(),
    totalMinor: row.totalMinor,
    installmentMinor: row.installmentMinor,
    installmentCount: row.installmentCount,
    firstDueOn: dayOf(row.firstDueOn),
    status: row.status,
    closedAt: row.closedAt,
    version: row.version,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

@Injectable()
export class PrismaCardInstallmentRepository implements CardInstallmentRepository {
  constructor(private readonly prisma: PrismaService) {}

  private async write<T>(userId: string, operation: (tx: Prisma.TransactionClient) => Promise<T>): Promise<T> {
    for (let attempt = 0; ; attempt++) {
      try {
        return await this.prisma.$transaction(async tx => {
          await touchFinancialOwner(tx, userId);
          return operation(tx);
        }, { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead });
      } catch (error) {
        if (
          attempt < 3 &&
          error instanceof Prisma.PrismaClientKnownRequestError &&
          (error.code === 'P2034' || error.code === 'P2002' ||
            (error.code === 'P2010' && ['40001', '40P01'].includes(String(error.meta?.code))))
        ) {
          continue;
        }
        if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
          throw new CardInstallmentError('PLAN_CONFLICT');
        }
        throw error;
      }
    }
  }

  async today(userId: string): Promise<string> {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { timezone: true } });
    if (!user) throw new CardInstallmentError('VALIDATION_ERROR');
    return todayInTimeZone(user.timezone, new Date());
  }

  async list(userId: string, filter: CardInstallmentFilter): Promise<CardInstallmentRecord[]> {
    const rows = await this.prisma.cardInstallmentPlan.findMany({
      where: { userId, ...(filter.accountId ? { accountId: filter.accountId } : {}), ...(filter.status ? { status: filter.status } : {}) },
      orderBy: [{ firstDueOn: 'asc' }, { createdAt: 'asc' }, { id: 'asc' }],
    });
    return rows.map(map);
  }

  async find(userId: string, id: string): Promise<CardInstallmentRecord> {
    const row = await this.prisma.cardInstallmentPlan.findFirst({ where: { id, userId } });
    if (!row) throw new CardInstallmentError('PLAN_NOT_FOUND');
    return map(row);
  }

  create(userId: string, input: CardInstallmentCreateInput) {
    return this.write(userId, async tx => {
      const existing = await tx.cardInstallmentPlan.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } } });
      if (existing) {
        const same = existing.transactionId === input.transactionId && existing.installmentCount === input.installmentCount &&
          dayOf(existing.firstDueOn) === input.firstDueOn &&
          (input.installmentMinor === null || existing.installmentMinor === input.installmentMinor);
        if (!same) throw new CardInstallmentError('PLAN_CONFLICT');
        return { plan: map(existing), created: false };
      }
      // The purchase row is locked so two plans cannot be made over it together.
      await tx.$queryRaw(Prisma.sql`SELECT id FROM "Transaction" WHERE id = ${input.transactionId}::uuid AND "userId" = ${userId}::uuid FOR UPDATE`);
      const purchase = await tx.transaction.findFirst({ where: { id: input.transactionId, userId }, include: { account: true } });
      if (!purchase) throw new CardInstallmentError('VALIDATION_ERROR');
      if (purchase.type !== 'expense' || purchase.deletedAt || purchase.account.type !== 'credit' || purchase.account.archivedAt) {
        throw new CardInstallmentError('PLAN_CONFLICT');
      }
      if (await tx.cardInstallmentPlan.findUnique({ where: { transactionId: purchase.id } })) throw new CardInstallmentError('PLAN_CONFLICT');
      const totalMinor = refundCap(purchase.amountMinor);
      const installmentMinor = input.installmentMinor ?? defaultInstallmentMinor(totalMinor, input.installmentCount);
      validatePlan(totalMinor, input.installmentCount, installmentMinor, dayOf(purchase.occurredOn), input.firstDueOn);
      const row = await tx.cardInstallmentPlan.create({
        data: {
          userId,
          clientId: input.clientId,
          transactionId: purchase.id,
          accountId: purchase.accountId,
          currencyCode: purchase.currencyCode.trim(),
          totalMinor,
          installmentMinor,
          installmentCount: input.installmentCount,
          firstDueOn: toDate(input.firstDueOn),
        },
      });
      return { plan: map(row), created: true };
    });
  }

  close(userId: string, id: string, version: number) {
    return this.write(userId, async tx => {
      await tx.$queryRaw(Prisma.sql`SELECT id FROM "CardInstallmentPlan" WHERE id = ${id}::uuid AND "userId" = ${userId}::uuid FOR UPDATE`);
      const row = await tx.cardInstallmentPlan.findFirst({ where: { id, userId } });
      if (!row) throw new CardInstallmentError('PLAN_NOT_FOUND');
      if (row.version !== version || row.status === 'closed') throw new CardInstallmentError('PLAN_CONFLICT');
      return map(await tx.cardInstallmentPlan.update({
        where: { id },
        data: { status: 'closed', closedAt: new Date(), version: { increment: 1 } },
      }));
    });
  }
}
