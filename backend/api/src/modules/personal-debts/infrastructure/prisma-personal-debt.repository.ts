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
  openingLegMinor,
  outstandingAfter,
  paymentLegMinor,
  PersonalDebtError,
  validateCounterparty,
  validateDueDate,
  validateNote,
  validatePrincipal,
  type PersonalDebtRecord,
} from '../domain/personal-debt';
import type {
  PersonalDebtContext,
  PersonalDebtCreateInput,
  PersonalDebtPatch,
  PersonalDebtPaymentInput,
  PersonalDebtPaymentRecord,
  PersonalDebtRepository,
} from '../domain/personal-debt.repository';

type Row = Prisma.PersonalDebtGetPayload<Record<string, never>>;

const dayOf = (value: Date) => value.toISOString().slice(0, 10);
const toDate = (value: string) => new Date(`${value}T00:00:00.000Z`);
const optionalDay = (value: Date | null) => (value ? dayOf(value) : null);

function map(row: Row): PersonalDebtRecord {
  return {
    id: row.id,
    clientId: row.clientId,
    direction: row.direction,
    counterparty: row.counterparty,
    currencyCode: row.currencyCode.trim(),
    principalMinor: row.principalMinor,
    outstandingMinor: row.outstandingMinor,
    accountId: row.accountId,
    occurredOn: dayOf(row.occurredOn),
    dueDate: optionalDay(row.dueDate),
    note: row.note,
    archivedAt: row.archivedAt,
    version: row.version,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

/** Deterministic UUID v4-shaped id so a retry replays the same transaction leg. */
function legClientId(clientId: string, part: 'open' | 'payment'): string {
  const bytes = Buffer.from(createHash('sha256').update(`personal-debt|${part}|${clientId}`).digest().subarray(0, 16));
  bytes[6] = (bytes[6]! & 0x0f) | 0x40;
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

const audit = (userId: string, debtId: string) => ({
  actorType: 'user' as const,
  actorId: userId,
  action: 'personal_debt.create' as const,
  targetType: 'personal_debt',
  targetId: debtId,
  outcome: 'success' as const,
});

@Injectable()
export class PrismaPersonalDebtRepository implements PersonalDebtRepository {
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
          throw new PersonalDebtError('DEBT_CONFLICT');
        }
        throw error;
      }
    }
  }

  async context(userId: string): Promise<PersonalDebtContext> {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { timezone: true } });
    if (!user) throw new PersonalDebtError('VALIDATION_ERROR');
    return { today: todayInTimeZone(user.timezone, new Date()) };
  }

  async list(userId: string, includeArchived: boolean): Promise<PersonalDebtRecord[]> {
    const rows = await this.prisma.personalDebt.findMany({
      where: { userId, ...(includeArchived ? {} : { archivedAt: null }) },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    });
    return rows.map(map);
  }

  async find(userId: string, id: string): Promise<PersonalDebtRecord> {
    const row = await this.prisma.personalDebt.findFirst({ where: { id, userId } });
    if (!row) throw new PersonalDebtError('DEBT_NOT_FOUND');
    return map(row);
  }

  create(userId: string, input: PersonalDebtCreateInput) {
    validateCounterparty(input.counterparty);
    validatePrincipal(input.amountMinor);
    validateNote(input.note);
    validateDueDate(input.occurredOn, input.dueDate);
    return this.write(userId, async tx => {
      const existing = await tx.personalDebt.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } } });
      if (existing) {
        const same =
          existing.direction === input.direction && existing.counterparty === input.counterparty &&
          existing.principalMinor === input.amountMinor && existing.accountId === input.accountId &&
          dayOf(existing.occurredOn) === input.occurredOn;
        if (!same) throw new PersonalDebtError('DEBT_CONFLICT');
        return { debt: map(existing), created: false };
      }
      const account = await tx.financialAccount.findFirst({
        where: { id: input.accountId, userId, archivedAt: null },
        select: { currencyCode: true },
      });
      if (!account) throw new PersonalDebtError('VALIDATION_ERROR');
      const currencyCode = account.currencyCode.trim();
      const legId = legClientId(input.clientId, 'open');
      await this.book(tx, userId, legId, input.accountId, currencyCode, openingLegMinor(input.direction, input.amountMinor), input.occurredOn);
      const row = await tx.personalDebt.create({
        data: {
          userId,
          clientId: input.clientId,
          direction: input.direction,
          counterparty: input.counterparty.trim(),
          currencyCode,
          principalMinor: input.amountMinor,
          outstandingMinor: input.amountMinor,
          accountId: input.accountId,
          transactionClientId: legId,
          occurredOn: toDate(input.occurredOn),
          dueDate: input.dueDate ? toDate(input.dueDate) : null,
          note: input.note,
        },
      });
      await tx.auditEvent.create({ data: audit(userId, row.id) });
      return { debt: map(row), created: true };
    });
  }

  update(userId: string, id: string, patch: PersonalDebtPatch) {
    if (patch.counterparty !== undefined) validateCounterparty(patch.counterparty);
    if (patch.note !== undefined) validateNote(patch.note);
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      if (row.version !== patch.version) throw new PersonalDebtError('DEBT_CONFLICT');
      if (patch.dueDate !== undefined) validateDueDate(dayOf(row.occurredOn), patch.dueDate);
      const updated = await tx.personalDebt.update({
        where: { id },
        data: {
          ...(patch.counterparty === undefined ? {} : { counterparty: patch.counterparty.trim() }),
          ...(patch.dueDate === undefined ? {} : { dueDate: patch.dueDate ? toDate(patch.dueDate) : null }),
          ...(patch.note === undefined ? {} : { note: patch.note }),
          version: { increment: 1 },
        },
      });
      return map(updated);
    });
  }

  /** Only a settled debt can be archived: archiving an open one would drop it from net worth while the wallet already moved. */
  archive(userId: string, id: string, version: number): Promise<void> {
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      if (row.version !== version || row.outstandingMinor > 0n) throw new PersonalDebtError('DEBT_CONFLICT');
      await tx.personalDebt.update({ where: { id }, data: { archivedAt: new Date(), version: { increment: 1 } } });
    });
  }

  async payments(userId: string, id: string): Promise<PersonalDebtPaymentRecord[]> {
    await this.find(userId, id);
    const rows = await this.prisma.personalDebtPayment.findMany({
      where: { debtId: id, userId },
      orderBy: [{ paidOn: 'desc' }, { createdAt: 'desc' }, { id: 'asc' }],
    });
    return rows.map(row => ({
      id: row.id,
      clientId: row.clientId,
      accountId: row.accountId,
      amountMinor: row.amountMinor,
      paidOn: dayOf(row.paidOn),
      createdAt: row.createdAt,
    }));
  }

  pay(userId: string, id: string, input: PersonalDebtPaymentInput) {
    if (input.amountMinor <= 0n) throw new PersonalDebtError('VALIDATION_ERROR');
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      const prior = await tx.personalDebtPayment.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } } });
      if (prior) {
        if (prior.debtId !== id || prior.amountMinor !== input.amountMinor) throw new PersonalDebtError('DEBT_CONFLICT');
        return { debt: map(row), created: false };
      }
      const outstanding = outstandingAfter(row.outstandingMinor, input.amountMinor);
      const accountId = input.accountId ?? row.accountId;
      const account = await tx.financialAccount.findFirst({
        where: { id: accountId, userId, archivedAt: null },
        select: { currencyCode: true },
      });
      if (!account || account.currencyCode.trim() !== row.currencyCode.trim()) throw new PersonalDebtError('VALIDATION_ERROR');
      const legId = legClientId(input.clientId, 'payment');
      await this.book(tx, userId, legId, accountId, row.currencyCode.trim(), paymentLegMinor(row.direction, input.amountMinor), input.paidOn);
      await tx.personalDebtPayment.create({
        data: {
          debtId: id,
          userId,
          clientId: input.clientId,
          accountId,
          amountMinor: input.amountMinor,
          transactionClientId: legId,
          paidOn: toDate(input.paidOn),
        },
      });
      const updated = await tx.personalDebt.update({
        where: { id },
        data: { outstandingMinor: outstanding, version: { increment: 1 } },
      });
      return { debt: map(updated), created: true };
    });
  }

  private async book(
    tx: Prisma.TransactionClient, userId: string, legId: string, accountId: string, currencyCode: string,
    amountMinor: bigint, day: string,
  ) {
    const debtTransaction: TransactionInput = {
      type: 'debt',
      occurredOn: toDate(day),
      occurredTime: null,
      legs: [{ clientId: legId, accountId, currencyCode, amountMinor }],
      categoryId: null,
      notes: null,
      merchant: null,
      tagIds: [],
      fx: null,
    };
    try {
      await createTransactionInTx(tx, userId, debtTransaction);
    } catch (error) {
      if (error instanceof TransactionError) {
        throw new PersonalDebtError(error.code === 'TRANSACTION_CONFLICT' ? 'DEBT_CONFLICT' : 'VALIDATION_ERROR');
      }
      throw error;
    }
  }

  private async lock(tx: Prisma.TransactionClient, userId: string, id: string): Promise<Row> {
    await tx.$queryRaw(Prisma.sql`SELECT id FROM "PersonalDebt" WHERE id = ${id}::uuid AND "userId" = ${userId}::uuid FOR UPDATE`);
    const row = await tx.personalDebt.findFirst({ where: { id, userId, archivedAt: null } });
    if (!row) throw new PersonalDebtError('DEBT_NOT_FOUND');
    return row;
  }
}
