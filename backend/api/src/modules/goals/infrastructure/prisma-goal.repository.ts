import { createHash } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { touchFinancialOwner } from '../../../infrastructure/prisma/financial-owner-lock';
import { todayInTimeZone } from '../../reports/domain/report';
import { TransactionError } from '../../transactions/domain/transaction-error';
import type { TransactionInput } from '../../transactions/domain/transaction';
import { createTransactionInTx } from '../../transactions/infrastructure/create-transaction-in-tx';
import {
  GoalError,
  validateCurrent,
  validateLook,
  validateMonthly,
  validateName,
  validateTarget,
  type GoalKind,
  type GoalRecord,
} from '../domain/goal';
import type {
  GoalContext,
  GoalCreateInput,
  GoalMoveInput,
  GoalPatch,
  GoalRepository,
} from '../domain/goal.repository';

const DAY_MS = 86_400_000;

type Row = Prisma.GoalGetPayload<Record<string, never>>;

const dayOf = (value: Date) => value.toISOString().slice(0, 10);
const toDate = (value: string) => new Date(`${value}T00:00:00.000Z`);

function map(row: Row): GoalRecord {
  return {
    id: row.id,
    clientId: row.clientId,
    kind: row.kind,
    name: row.name,
    currencyCode: row.currencyCode.trim(),
    targetMinor: row.targetMinor,
    currentMinor: row.currentMinor,
    targetDate: row.targetDate ? dayOf(row.targetDate) : null,
    accountId: row.accountId,
    monthlyContributionMinor: row.monthlyContributionMinor,
    icon: row.icon,
    colorToken: row.colorToken,
    archivedAt: row.archivedAt,
    version: row.version,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

/** Deterministic UUID v4-shaped leg id so a retried move replays the same transfer. */
function legClientId(entryClientId: string, index: number): string {
  const bytes = Buffer.from(createHash('sha256').update(`goal|${entryClientId}|${index}`).digest().subarray(0, 16));
  bytes[6] = (bytes[6]! & 0x0f) | 0x40;
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

const audit = (userId: string, goalId: string, action: 'goal.create' | 'goal.adjust') => ({
  actorType: 'user' as const,
  actorId: userId,
  action,
  targetType: 'goal',
  targetId: goalId,
  outcome: 'success' as const,
});

@Injectable()
export class PrismaGoalRepository implements GoalRepository {
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
          throw new GoalError('GOAL_CONFLICT');
        }
        throw error;
      }
    }
  }

  async context(userId: string): Promise<GoalContext> {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { timezone: true } });
    if (!user) throw new GoalError('VALIDATION_ERROR');
    const today = todayInTimeZone(user.timezone, new Date());
    const from = new Date(toDate(today).getTime() - 90 * DAY_MS);
    const sums = await this.prisma.transaction.groupBy({
      by: ['currencyCode'],
      where: { userId, type: 'income', deletedAt: null, occurredOn: { gt: from, lte: toDate(today) } },
      _sum: { amountMinor: true },
    });
    const monthlyIncomeMinor: Record<string, bigint> = {};
    for (const row of sums) monthlyIncomeMinor[row.currencyCode.trim()] = (row._sum.amountMinor ?? 0n) / 3n;
    return { today, monthlyIncomeMinor };
  }

  async list(userId: string, includeArchived: boolean): Promise<GoalRecord[]> {
    const rows = await this.prisma.goal.findMany({
      where: { userId, ...(includeArchived ? {} : { archivedAt: null }) },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    });
    return rows.map(map);
  }

  async find(userId: string, id: string): Promise<GoalRecord> {
    const row = await this.prisma.goal.findFirst({ where: { id, userId } });
    if (!row) throw new GoalError('GOAL_NOT_FOUND');
    return map(row);
  }

  create(userId: string, input: GoalCreateInput) {
    validateName(input.name);
    validateTarget(input.targetMinor);
    validateCurrent(input.currentMinor);
    validateMonthly(input.monthlyContributionMinor);
    validateLook(input.icon, input.colorToken);
    return this.write(userId, async tx => {
      const existing = await tx.goal.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } } });
      if (existing) {
        const same =
          existing.kind === input.kind && existing.name === input.name &&
          existing.targetMinor === input.targetMinor && existing.accountId === input.accountId &&
          (existing.targetDate ? dayOf(existing.targetDate) : null) === input.targetDate;
        if (!same) throw new GoalError('GOAL_CONFLICT');
        return { goal: map(existing), created: false };
      }
      const account = await tx.financialAccount.findFirst({
        where: { id: input.accountId, userId, archivedAt: null },
        select: { currencyCode: true },
      });
      if (!account) throw new GoalError('VALIDATION_ERROR');
      const row = await tx.goal.create({
        data: {
          userId,
          clientId: input.clientId,
          kind: input.kind,
          name: input.name,
          currencyCode: account.currencyCode,
          targetMinor: input.targetMinor,
          currentMinor: input.currentMinor,
          targetDate: input.targetDate ? toDate(input.targetDate) : null,
          accountId: input.accountId,
          monthlyContributionMinor: input.monthlyContributionMinor,
          icon: input.icon,
          colorToken: input.colorToken,
        },
      });
      if (input.currentMinor > 0n) await tx.auditEvent.create({ data: audit(userId, row.id, 'goal.create') });
      return { goal: map(row), created: true };
    });
  }

  update(userId: string, id: string, patch: GoalPatch) {
    if (patch.name !== undefined) validateName(patch.name);
    if (patch.targetMinor !== undefined) validateTarget(patch.targetMinor);
    if (patch.monthlyContributionMinor !== undefined) validateMonthly(patch.monthlyContributionMinor);
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      if (row.version !== patch.version) throw new GoalError('GOAL_CONFLICT');
      const icon = patch.icon ?? row.icon;
      const colorToken = patch.colorToken === undefined ? row.colorToken : patch.colorToken;
      validateLook(icon, colorToken);
      const updated = await tx.goal.update({
        where: { id },
        data: {
          ...(patch.kind === undefined ? {} : { kind: patch.kind as GoalKind }),
          ...(patch.name === undefined ? {} : { name: patch.name }),
          ...(patch.targetMinor === undefined ? {} : { targetMinor: patch.targetMinor }),
          ...(patch.targetDate === undefined ? {} : { targetDate: patch.targetDate ? toDate(patch.targetDate) : null }),
          ...(patch.monthlyContributionMinor === undefined
            ? {}
            : { monthlyContributionMinor: patch.monthlyContributionMinor }),
          icon,
          colorToken,
          version: { increment: 1 },
        },
      });
      return map(updated);
    });
  }

  archive(userId: string, id: string, version: number): Promise<void> {
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      if (row.version !== version) throw new GoalError('GOAL_CONFLICT');
      await tx.goal.update({ where: { id }, data: { archivedAt: new Date(), version: { increment: 1 } } });
    });
  }

  contribute(userId: string, id: string, input: GoalMoveInput) {
    return this.move(userId, id, input, 'contribute');
  }

  withdraw(userId: string, id: string, input: GoalMoveInput) {
    return this.move(userId, id, input, 'withdraw');
  }

  adjust(userId: string, id: string, currentMinor: bigint, version: number): Promise<GoalRecord> {
    validateCurrent(currentMinor);
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      if (row.version !== version) throw new GoalError('GOAL_CONFLICT');
      if (row.currentMinor === currentMinor) throw new GoalError('VALIDATION_ERROR');
      const updated = await tx.goal.update({
        where: { id },
        data: { currentMinor, version: { increment: 1 } },
      });
      await tx.auditEvent.create({ data: audit(userId, id, 'goal.adjust') });
      return map(updated);
    });
  }

  private async lock(tx: Prisma.TransactionClient, userId: string, id: string): Promise<Row> {
    await tx.$queryRaw(Prisma.sql`SELECT id FROM "Goal" WHERE id = ${id}::uuid AND "userId" = ${userId}::uuid FOR UPDATE`);
    const row = await tx.goal.findFirst({ where: { id, userId, archivedAt: null } });
    if (!row) throw new GoalError('GOAL_NOT_FOUND');
    return row;
  }

  private move(userId: string, id: string, input: GoalMoveInput, kind: 'contribute' | 'withdraw') {
    if (input.amountMinor <= 0n) throw new GoalError('VALIDATION_ERROR');
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      const prior = await tx.goalEntry.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } } });
      if (prior) {
        if (prior.goalId !== id || prior.kind !== kind || prior.amountMinor !== input.amountMinor) {
          throw new GoalError('GOAL_CONFLICT');
        }
        return { goal: map(row), created: false };
      }
      if (kind === 'withdraw' && input.amountMinor > row.currentMinor) {
        throw new GoalError('INSUFFICIENT_GOAL_BALANCE');
      }
      let transactionClientId: string | null = null;
      if (input.otherAccountId !== null) {
        if (input.otherAccountId === row.accountId) throw new GoalError('VALIDATION_ERROR');
        const other = await tx.financialAccount.findFirst({
          where: { id: input.otherAccountId, userId, archivedAt: null },
          select: { currencyCode: true },
        });
        if (!other || other.currencyCode.trim() !== row.currencyCode.trim()) throw new GoalError('VALIDATION_ERROR');
        const out = kind === 'contribute' ? input.otherAccountId : row.accountId;
        const into = kind === 'contribute' ? row.accountId : input.otherAccountId;
        const transfer: TransactionInput = {
          type: 'transfer',
          occurredOn: toDate(input.occurredOn),
          occurredTime: null,
          legs: [
            { clientId: legClientId(input.clientId, 0), accountId: out, currencyCode: row.currencyCode.trim(), amountMinor: -input.amountMinor },
            { clientId: legClientId(input.clientId, 1), accountId: into, currencyCode: row.currencyCode.trim(), amountMinor: input.amountMinor },
          ],
          categoryId: null,
          notes: null,
          merchant: null,
          tagIds: [],
          fx: null,
        };
        try {
          await createTransactionInTx(tx, userId, transfer);
        } catch (error) {
          if (error instanceof TransactionError) {
            throw new GoalError(error.code === 'TRANSACTION_CONFLICT' ? 'GOAL_CONFLICT' : 'VALIDATION_ERROR');
          }
          throw error;
        }
        transactionClientId = transfer.legs[0]!.clientId;
      }
      const delta = kind === 'contribute' ? input.amountMinor : -input.amountMinor;
      await tx.goalEntry.create({
        data: {
          goalId: id,
          userId,
          clientId: input.clientId,
          kind,
          amountMinor: input.amountMinor,
          transactionClientId,
          occurredOn: toDate(input.occurredOn),
        },
      });
      const updated = await tx.goal.update({
        where: { id },
        data: { currentMinor: row.currentMinor + delta, version: { increment: 1 } },
      });
      return { goal: map(updated), created: true };
    });
  }
}
