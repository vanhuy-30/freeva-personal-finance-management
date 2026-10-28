import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { touchFinancialOwner } from '../../../infrastructure/prisma/financial-owner-lock';
import { todayInTimeZone } from '../../reports/domain/report';
import type { BillRepository } from '../domain/bill.repository';
import {
  assertBillVersion,
  dayString,
  normalizeName,
  positiveMinor,
  BillError,
  validateBillInput,
  type Bill,
  type BillInput,
  type BillPatch,
  type BillQuery,
} from '../domain/bill';

const select = {
  id: true,
  clientId: true,
  name: true,
  dueOn: true,
  amountMinor: true,
  amountKind: true,
  currencyCode: true,
  recurringRuleId: true,
  paidTransactionId: true,
  version: true,
  createdAt: true,
  updatedAt: true,
} satisfies Prisma.BillSelect;

type Row = Prisma.BillGetPayload<{ select: typeof select }>;

function mapBill(row: Row): Bill {
  return {
    id: row.id,
    clientId: row.clientId,
    name: row.name,
    dueOn: row.dueOn,
    amountMinor: row.amountMinor,
    amountKind: row.amountKind,
    currencyCode: row.currencyCode.trim(),
    recurringRuleId: row.recurringRuleId,
    paidTransactionId: row.paidTransactionId,
    version: row.version,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

@Injectable()
export class PrismaBillRepository implements BillRepository {
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
          throw new BillError('BILL_CONFLICT');
        }
        throw error;
      }
    }
  }

  private async get(tx: Prisma.TransactionClient | PrismaService, userId: string, id: string): Promise<Bill> {
    const row = await tx.bill.findFirst({ where: { id, userId }, select });
    if (!row) throw new BillError('BILL_NOT_FOUND');
    return mapBill(row);
  }

  private async assertCurrency(tx: Prisma.TransactionClient, currencyCode: string): Promise<void> {
    const currency = await tx.currency.findUnique({ where: { code: currencyCode } });
    if (!currency) throw new BillError('VALIDATION_ERROR');
  }

  private async assertRule(tx: Prisma.TransactionClient, userId: string, ruleId: string | null): Promise<void> {
    if (ruleId === null) return;
    const rule = await tx.recurringRule.findFirst({ where: { id: ruleId, userId }, select: { id: true } });
    if (!rule) throw new BillError('VALIDATION_ERROR');
  }

  async todayForUser(userId: string, now = new Date()): Promise<string> {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { timezone: true } });
    if (!user) throw new BillError('BILL_NOT_FOUND');
    return todayInTimeZone(user.timezone, now);
  }

  create(userId: string, input: BillInput) {
    return this.write(userId, async tx => {
      const existing = await tx.bill.findUnique({
        where: { userId_clientId: { userId, clientId: input.clientId } },
        select,
      });
      if (existing) {
        const current = mapBill(existing);
        if (
          current.name !== input.name ||
          dayString(current.dueOn) !== dayString(input.dueOn) ||
          current.amountMinor !== input.amountMinor ||
          current.amountKind !== input.amountKind ||
          current.currencyCode !== input.currencyCode ||
          current.recurringRuleId !== input.recurringRuleId
        ) {
          throw new BillError('BILL_CONFLICT');
        }
        return { bill: current, created: false };
      }
      validateBillInput(input);
      await this.assertCurrency(tx, input.currencyCode);
      await this.assertRule(tx, userId, input.recurringRuleId);
      const row = await tx.bill.create({
        data: {
          userId,
          clientId: input.clientId,
          name: input.name,
          dueOn: input.dueOn,
          amountMinor: input.amountMinor,
          amountKind: input.amountKind,
          currencyCode: input.currencyCode,
          recurringRuleId: input.recurringRuleId,
        },
        select,
      });
      return { bill: mapBill(row), created: true };
    });
  }

  find(userId: string, id: string) {
    return this.get(this.prisma, userId, id);
  }

  async list(userId: string, query: BillQuery) {
    const today = await this.todayForUser(userId);
    return this.prisma.$transaction(async tx => {
      const where: Prisma.BillWhereInput = { userId };
      if (query.status === 'paid') {
        where.paidTransactionId = { not: null };
      } else if (query.status === 'open' || query.status === 'overdue') {
        where.paidTransactionId = null;
        where.dueOn = query.status === 'overdue'
          ? { lt: new Date(`${today}T00:00:00.000Z`) }
          : { gte: new Date(`${today}T00:00:00.000Z`) };
      }
      const [rows, total] = await Promise.all([
        tx.bill.findMany({
          where,
          select,
          orderBy: [{ dueOn: 'asc' }, { createdAt: 'asc' }, { id: 'asc' }],
          skip: (query.page - 1) * query.pageSize,
          take: query.pageSize,
        }),
        tx.bill.count({ where }),
      ]);
      return { items: rows.map(mapBill), total, today };
    }, { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead });
  }

  update(userId: string, id: string, patch: BillPatch) {
    return this.write(userId, async tx => {
      const current = await this.get(tx, userId, id);
      assertBillVersion(current.version, patch.version);
      const next: BillInput = {
        clientId: current.clientId,
        name: patch.name === undefined ? current.name : normalizeName(patch.name),
        dueOn: patch.dueOn ?? current.dueOn,
        amountMinor: patch.amountMinor === undefined ? current.amountMinor : positiveMinor(patch.amountMinor),
        amountKind: patch.amountKind ?? current.amountKind,
        currencyCode: patch.currencyCode ?? current.currencyCode,
        recurringRuleId: patch.recurringRuleId === undefined ? current.recurringRuleId : patch.recurringRuleId,
      };
      validateBillInput(next);
      await this.assertCurrency(tx, next.currencyCode);
      await this.assertRule(tx, userId, next.recurringRuleId);
      const row = await tx.bill.update({
        where: { id, userId, version: patch.version },
        data: {
          name: next.name,
          dueOn: next.dueOn,
          amountMinor: next.amountMinor,
          amountKind: next.amountKind,
          currencyCode: next.currencyCode,
          recurringRuleId: next.recurringRuleId,
          version: { increment: 1 },
        },
        select,
      });
      return mapBill(row);
    });
  }

  delete(userId: string, id: string, version: number) {
    return this.write(userId, async tx => {
      const current = await this.get(tx, userId, id);
      assertBillVersion(current.version, version);
      await tx.bill.delete({ where: { id, userId, version } });
    });
  }

  pay(userId: string, id: string, transactionId: string, version: number) {
    return this.write(userId, async tx => {
      const current = await this.get(tx, userId, id);
      assertBillVersion(current.version, version);
      if (current.paidTransactionId !== null) {
        if (current.paidTransactionId === transactionId) return current;
        throw new BillError('BILL_CONFLICT');
      }
      const transaction = await tx.transaction.findFirst({
        where: { id: transactionId, userId, deletedAt: null },
        select: { id: true },
      });
      if (!transaction) throw new BillError('VALIDATION_ERROR');
      const taken = await tx.bill.findFirst({
        where: { paidTransactionId: transactionId },
        select: { id: true },
      });
      if (taken && taken.id !== id) throw new BillError('BILL_CONFLICT');
      try {
        const row = await tx.bill.update({
          where: { id, userId, version },
          data: { paidTransactionId: transactionId, version: { increment: 1 } },
          select,
        });
        return mapBill(row);
      } catch (error) {
        if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
          throw new BillError('BILL_CONFLICT');
        }
        throw error;
      }
    });
  }

  unpay(userId: string, id: string, version: number) {
    return this.write(userId, async tx => {
      const current = await this.get(tx, userId, id);
      assertBillVersion(current.version, version);
      if (current.paidTransactionId === null) return current;
      const row = await tx.bill.update({
        where: { id, userId, version },
        data: { paidTransactionId: null, version: { increment: 1 } },
        select,
      });
      return mapBill(row);
    });
  }
}
