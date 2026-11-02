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
  addPeriod,
  LoanError,
  splitPayment,
  validateDates,
  validateInstallment,
  validateName,
  validateOutstanding,
  validatePrincipal,
  validateRate,
  type LoanRecord,
} from '../domain/loan';
import type {
  LoanContext,
  LoanCreateInput,
  LoanPatch,
  LoanPaymentInput,
  LoanPaymentRecord,
  LoanRepository,
} from '../domain/loan.repository';

type Row = Prisma.LoanGetPayload<Record<string, never>>;

const dayOf = (value: Date) => value.toISOString().slice(0, 10);
const toDate = (value: string) => new Date(`${value}T00:00:00.000Z`);
const optionalDay = (value: Date | null) => (value ? dayOf(value) : null);

function map(row: Row): LoanRecord {
  return {
    id: row.id,
    clientId: row.clientId,
    kind: row.kind,
    name: row.name,
    currencyCode: row.currencyCode.trim(),
    principalMinor: row.principalMinor,
    outstandingMinor: row.outstandingMinor,
    interestRateBps: row.interestRateBps,
    installmentMinor: row.installmentMinor,
    frequency: row.frequency,
    startDate: dayOf(row.startDate),
    endDate: optionalDay(row.endDate),
    nextDueDate: optionalDay(row.nextDueDate),
    accountId: row.accountId,
    archivedAt: row.archivedAt,
    version: row.version,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

/** Deterministic UUID v4-shaped id so a retried payment replays the same transactions. */
function legClientId(paymentClientId: string, part: 'principal' | 'interest'): string {
  const bytes = Buffer.from(createHash('sha256').update(`loan|${paymentClientId}|${part}`).digest().subarray(0, 16));
  bytes[6] = (bytes[6]! & 0x0f) | 0x40;
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

const audit = (userId: string, loanId: string, action: 'loan.create' | 'loan.adjust') => ({
  actorType: 'user' as const,
  actorId: userId,
  action,
  targetType: 'loan',
  targetId: loanId,
  outcome: 'success' as const,
});

@Injectable()
export class PrismaLoanRepository implements LoanRepository {
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
          throw new LoanError('LOAN_CONFLICT');
        }
        throw error;
      }
    }
  }

  async context(userId: string): Promise<LoanContext> {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { timezone: true } });
    if (!user) throw new LoanError('VALIDATION_ERROR');
    return { today: todayInTimeZone(user.timezone, new Date()) };
  }

  async list(userId: string, includeArchived: boolean): Promise<LoanRecord[]> {
    const rows = await this.prisma.loan.findMany({
      where: { userId, ...(includeArchived ? {} : { archivedAt: null }) },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    });
    return rows.map(map);
  }

  async find(userId: string, id: string): Promise<LoanRecord> {
    const row = await this.prisma.loan.findFirst({ where: { id, userId } });
    if (!row) throw new LoanError('LOAN_NOT_FOUND');
    return map(row);
  }

  create(userId: string, input: LoanCreateInput) {
    validateName(input.name);
    validatePrincipal(input.principalMinor);
    validateOutstanding(input.outstandingMinor);
    validateRate(input.interestRateBps);
    validateInstallment(input.installmentMinor);
    validateDates(input.startDate, input.endDate, input.nextDueDate);
    if (input.outstandingMinor > input.principalMinor) throw new LoanError('VALIDATION_ERROR');
    return this.write(userId, async tx => {
      const existing = await tx.loan.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } } });
      if (existing) {
        const same =
          existing.kind === input.kind && existing.name === input.name &&
          existing.principalMinor === input.principalMinor && existing.interestRateBps === input.interestRateBps &&
          existing.frequency === input.frequency && dayOf(existing.startDate) === input.startDate;
        if (!same) throw new LoanError('LOAN_CONFLICT');
        return { loan: map(existing), created: false };
      }
      if (input.accountId !== null) await this.requireAccount(tx, userId, input.accountId, input.currencyCode);
      else {
        const currency = await tx.currency.findUnique({ where: { code: input.currencyCode } });
        if (!currency) throw new LoanError('VALIDATION_ERROR');
      }
      const row = await tx.loan.create({
        data: {
          userId,
          clientId: input.clientId,
          kind: input.kind,
          name: input.name,
          currencyCode: input.currencyCode,
          principalMinor: input.principalMinor,
          outstandingMinor: input.outstandingMinor,
          interestRateBps: input.interestRateBps,
          installmentMinor: input.installmentMinor,
          frequency: input.frequency,
          startDate: toDate(input.startDate),
          endDate: input.endDate ? toDate(input.endDate) : null,
          nextDueDate: input.nextDueDate ? toDate(input.nextDueDate) : null,
          accountId: input.accountId,
        },
      });
      await tx.auditEvent.create({ data: audit(userId, row.id, 'loan.create') });
      return { loan: map(row), created: true };
    });
  }

  update(userId: string, id: string, patch: LoanPatch) {
    if (patch.name !== undefined) validateName(patch.name);
    if (patch.interestRateBps !== undefined) validateRate(patch.interestRateBps);
    if (patch.installmentMinor !== undefined) validateInstallment(patch.installmentMinor);
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      if (row.version !== patch.version) throw new LoanError('LOAN_CONFLICT');
      const endDate = patch.endDate === undefined ? optionalDay(row.endDate) : patch.endDate;
      const nextDueDate = patch.nextDueDate === undefined ? optionalDay(row.nextDueDate) : patch.nextDueDate;
      validateDates(dayOf(row.startDate), endDate, nextDueDate);
      if (patch.accountId) await this.requireAccount(tx, userId, patch.accountId, row.currencyCode.trim());
      const updated = await tx.loan.update({
        where: { id },
        data: {
          ...(patch.kind === undefined ? {} : { kind: patch.kind }),
          ...(patch.name === undefined ? {} : { name: patch.name }),
          ...(patch.interestRateBps === undefined ? {} : { interestRateBps: patch.interestRateBps }),
          ...(patch.installmentMinor === undefined ? {} : { installmentMinor: patch.installmentMinor }),
          ...(patch.frequency === undefined ? {} : { frequency: patch.frequency }),
          ...(patch.endDate === undefined ? {} : { endDate: patch.endDate ? toDate(patch.endDate) : null }),
          ...(patch.nextDueDate === undefined ? {} : { nextDueDate: patch.nextDueDate ? toDate(patch.nextDueDate) : null }),
          ...(patch.accountId === undefined ? {} : { accountId: patch.accountId }),
          version: { increment: 1 },
        },
      });
      return map(updated);
    });
  }

  archive(userId: string, id: string, version: number): Promise<void> {
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      if (row.version !== version) throw new LoanError('LOAN_CONFLICT');
      await tx.loan.update({ where: { id }, data: { archivedAt: new Date(), version: { increment: 1 } } });
    });
  }

  adjust(userId: string, id: string, outstandingMinor: bigint, version: number): Promise<LoanRecord> {
    validateOutstanding(outstandingMinor);
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      if (row.version !== version) throw new LoanError('LOAN_CONFLICT');
      if (row.outstandingMinor === outstandingMinor) throw new LoanError('VALIDATION_ERROR');
      if (outstandingMinor > row.principalMinor) throw new LoanError('VALIDATION_ERROR');
      const updated = await tx.loan.update({ where: { id }, data: { outstandingMinor, version: { increment: 1 } } });
      await tx.auditEvent.create({ data: audit(userId, id, 'loan.adjust') });
      return map(updated);
    });
  }

  async payments(userId: string, id: string): Promise<LoanPaymentRecord[]> {
    await this.find(userId, id);
    const rows = await this.prisma.loanPayment.findMany({
      where: { loanId: id, userId },
      orderBy: [{ paidOn: 'desc' }, { createdAt: 'desc' }, { id: 'asc' }],
    });
    return rows.map(row => ({
      id: row.id,
      clientId: row.clientId,
      principalMinor: row.principalMinor,
      interestMinor: row.interestMinor,
      paidOn: dayOf(row.paidOn),
      createdAt: row.createdAt,
    }));
  }

  pay(userId: string, id: string, input: LoanPaymentInput) {
    if (input.amountMinor <= 0n) throw new LoanError('VALIDATION_ERROR');
    if ((input.principalMinor === null) !== (input.interestMinor === null)) throw new LoanError('VALIDATION_ERROR');
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      const prior = await tx.loanPayment.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } } });
      if (prior) {
        if (prior.loanId !== id || prior.principalMinor + prior.interestMinor !== input.amountMinor) {
          throw new LoanError('LOAN_CONFLICT');
        }
        return { loan: map(row), created: false };
      }
      if (row.outstandingMinor <= 0n) throw new LoanError('LOAN_OVERPAYMENT');
      const split = input.principalMinor === null || input.interestMinor === null
        ? splitPayment(row.outstandingMinor, row.interestRateBps, row.frequency, input.amountMinor)
        : { principalMinor: input.principalMinor, interestMinor: input.interestMinor };
      if (split.principalMinor < 0n || split.interestMinor < 0n || split.principalMinor + split.interestMinor !== input.amountMinor) {
        throw new LoanError('VALIDATION_ERROR');
      }
      if (split.principalMinor > row.outstandingMinor) throw new LoanError('LOAN_OVERPAYMENT');
      const accountId = input.accountId ?? row.accountId;
      if (accountId === null) throw new LoanError('VALIDATION_ERROR');
      await this.requireAccount(tx, userId, accountId, row.currencyCode.trim());
      const parts = [
        { part: 'principal' as const, amount: split.principalMinor, categoryId: input.principalCategoryId },
        { part: 'interest' as const, amount: split.interestMinor, categoryId: input.interestCategoryId },
      ];
      const ids: Record<'principal' | 'interest', string | null> = { principal: null, interest: null };
      for (const { part, amount, categoryId } of parts) {
        if (amount === 0n) continue;
        if (categoryId === null) throw new LoanError('VALIDATION_ERROR');
        const legId = legClientId(input.clientId, part);
        const expense: TransactionInput = {
          type: 'expense',
          occurredOn: toDate(input.paidOn),
          occurredTime: null,
          legs: [{ clientId: legId, accountId, currencyCode: row.currencyCode.trim(), amountMinor: -amount }],
          categoryId,
          notes: null,
          merchant: null,
          tagIds: [],
          fx: null,
        };
        try {
          await createTransactionInTx(tx, userId, expense);
        } catch (error) {
          if (error instanceof TransactionError) {
            throw new LoanError(error.code === 'TRANSACTION_CONFLICT' ? 'LOAN_CONFLICT' : 'VALIDATION_ERROR');
          }
          throw error;
        }
        ids[part] = legId;
      }
      await tx.loanPayment.create({
        data: {
          loanId: id,
          userId,
          clientId: input.clientId,
          principalMinor: split.principalMinor,
          interestMinor: split.interestMinor,
          principalTransactionClientId: ids.principal,
          interestTransactionClientId: ids.interest,
          paidOn: toDate(input.paidOn),
        },
      });
      const outstanding = row.outstandingMinor - split.principalMinor;
      const updated = await tx.loan.update({
        where: { id },
        data: {
          outstandingMinor: outstanding,
          nextDueDate: outstanding === 0n
            ? null
            : row.nextDueDate
              ? toDate(addPeriod(dayOf(row.nextDueDate), row.frequency))
              : null,
          version: { increment: 1 },
        },
      });
      return { loan: map(updated), created: true };
    });
  }

  private async requireAccount(tx: Prisma.TransactionClient, userId: string, accountId: string, currencyCode: string) {
    const account = await tx.financialAccount.findFirst({
      where: { id: accountId, userId, archivedAt: null },
      select: { currencyCode: true },
    });
    if (!account || account.currencyCode.trim() !== currencyCode.trim()) throw new LoanError('VALIDATION_ERROR');
  }

  private async lock(tx: Prisma.TransactionClient, userId: string, id: string): Promise<Row> {
    await tx.$queryRaw(Prisma.sql`SELECT id FROM "Loan" WHERE id = ${id}::uuid AND "userId" = ${userId}::uuid FOR UPDATE`);
    const row = await tx.loan.findFirst({ where: { id, userId, archivedAt: null } });
    if (!row) throw new LoanError('LOAN_NOT_FOUND');
    return row;
  }
}
