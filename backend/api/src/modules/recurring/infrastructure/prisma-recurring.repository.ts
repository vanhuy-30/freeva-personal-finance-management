import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { touchFinancialOwner } from '../../../infrastructure/prisma/financial-owner-lock';
import { todayInTimeZone } from '../../reports/domain/report';
import { TransactionError } from '../../transactions/domain/transaction-error';
import { normalizeRate, type TransactionInput } from '../../transactions/domain/transaction';
import { createTransactionInTx } from '../../transactions/infrastructure/create-transaction-in-tx';
import { addInterval, anchorDay, dueDates } from '../domain/calendar';
import { occurrenceClientId } from '../domain/occurrence-id';
import type { RecurringRepository, RecurringRunResult } from '../domain/recurring.repository';
import {
  assertRecurringVersion,
  dayString,
  RecurringError,
  validateRecurringInput,
  type RecurringInput,
  type RecurringPatch,
  type RecurringQuery,
  type RecurringRule,
} from '../domain/recurring';

const select = {
  id: true, clientId: true, type: true, unit: true, interval: true, amountMinor: true, currencyCode: true,
  accountId: true, categoryId: true, counterAccountId: true, counterAmountMinor: true, counterCurrencyCode: true,
  fxRate: true, startDate: true, endDate: true, nextExecutionDate: true, active: true, version: true,
  createdAt: true, updatedAt: true,
} satisfies Prisma.RecurringRuleSelect;

type Row = Prisma.RecurringRuleGetPayload<{ select: typeof select }>;

function mapRule(row: Row): RecurringRule {
  return {
    id: row.id,
    clientId: row.clientId,
    type: row.type,
    unit: row.unit,
    interval: row.interval,
    amountMinor: row.amountMinor,
    currencyCode: row.currencyCode.trim(),
    accountId: row.accountId,
    categoryId: row.categoryId,
    counterAccountId: row.counterAccountId,
    counterAmountMinor: row.counterAmountMinor,
    counterCurrencyCode: row.counterCurrencyCode?.trim() ?? null,
    fxRate: row.fxRate ? normalizeRate(row.fxRate.toFixed(8)) : null,
    startDate: row.startDate,
    endDate: row.endDate,
    nextExecutionDate: row.nextExecutionDate,
    active: row.active,
    version: row.version,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
}

function toDate(value: string): Date {
  return new Date(`${value}T00:00:00.000Z`);
}

@Injectable()
export class PrismaRecurringRepository implements RecurringRepository {
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
        throw error;
      }
    }
  }

  private async get(tx: Prisma.TransactionClient | PrismaService, userId: string, id: string): Promise<RecurringRule> {
    const row = await tx.recurringRule.findFirst({ where: { id, userId }, select });
    if (!row) throw new RecurringError('RECURRING_NOT_FOUND');
    return mapRule(row);
  }

  private async validateAccounts(tx: Prisma.TransactionClient, userId: string, input: RecurringInput): Promise<void> {
    const ids = [input.accountId, ...(input.counterAccountId ? [input.counterAccountId] : [])].sort();
    await tx.$queryRaw(Prisma.sql`SELECT id FROM "FinancialAccount" WHERE "userId" = ${userId}::uuid
      AND id IN (${Prisma.join(ids.map(id => Prisma.sql`${id}::uuid`))}) ORDER BY id FOR UPDATE`);
    const accounts = await tx.financialAccount.findMany({
      where: { userId, id: { in: ids } },
      include: { currency: true },
    });
    if (accounts.length !== ids.length) throw new RecurringError('VALIDATION_ERROR');
    const digits: Record<string, number> = {};
    for (const account of accounts) {
      if (account.archivedAt) throw new RecurringError('RECURRING_CONFLICT');
      digits[account.currencyCode.trim()] = account.currency.minorDigits;
    }
    const source = accounts.find(item => item.id === input.accountId)!;
    if (source.currencyCode.trim() !== input.currencyCode) throw new RecurringError('VALIDATION_ERROR');
    if (input.counterAccountId) {
      const counter = accounts.find(item => item.id === input.counterAccountId)!;
      if (counter.currencyCode.trim() !== input.counterCurrencyCode) throw new RecurringError('VALIDATION_ERROR');
    }
    if (input.categoryId && !await tx.category.findFirst({ where: { id: input.categoryId, userId, archivedAt: null } })) {
      throw new RecurringError('VALIDATION_ERROR');
    }
    validateRecurringInput(input, digits);
  }

  create(userId: string, input: RecurringInput) {
    return this.write(userId, async tx => {
      const existing = await tx.recurringRule.findUnique({
        where: { userId_clientId: { userId, clientId: input.clientId } },
        select,
      });
      if (existing) {
        const current = mapRule(existing);
        if (
          current.type !== input.type ||
          current.unit !== input.unit ||
          current.interval !== input.interval ||
          current.amountMinor !== input.amountMinor ||
          current.currencyCode !== input.currencyCode ||
          current.accountId !== input.accountId ||
          current.categoryId !== input.categoryId ||
          current.counterAccountId !== input.counterAccountId ||
          current.counterAmountMinor !== input.counterAmountMinor ||
          current.counterCurrencyCode !== input.counterCurrencyCode ||
          current.fxRate !== input.fxRate ||
          dayString(current.startDate) !== dayString(input.startDate) ||
          (current.endDate ? dayString(current.endDate) : null) !== (input.endDate ? dayString(input.endDate) : null) ||
          dayString(current.nextExecutionDate) !== dayString(input.nextExecutionDate) ||
          current.active !== input.active
        ) {
          throw new RecurringError('RECURRING_CONFLICT');
        }
        return { rule: current, created: false };
      }
      await this.validateAccounts(tx, userId, input);
      const row = await tx.recurringRule.create({
        data: {
          userId,
          clientId: input.clientId,
          type: input.type,
          unit: input.unit,
          interval: input.interval,
          amountMinor: input.amountMinor,
          currencyCode: input.currencyCode,
          accountId: input.accountId,
          categoryId: input.categoryId,
          counterAccountId: input.counterAccountId,
          counterAmountMinor: input.counterAmountMinor,
          counterCurrencyCode: input.counterCurrencyCode,
          fxRate: input.fxRate,
          startDate: input.startDate,
          endDate: input.endDate,
          nextExecutionDate: input.nextExecutionDate,
          active: input.active,
        },
        select,
      });
      return { rule: mapRule(row), created: true };
    });
  }

  find(userId: string, id: string) {
    return this.get(this.prisma, userId, id);
  }

  list(userId: string, query: RecurringQuery) {
    return this.prisma.$transaction(async tx => {
      const where: Prisma.RecurringRuleWhereInput = {
        userId,
        ...(query.active === undefined ? {} : { active: query.active }),
      };
      const [rows, total] = await Promise.all([
        tx.recurringRule.findMany({
          where,
          select,
          orderBy: [{ nextExecutionDate: 'asc' }, { createdAt: 'asc' }, { id: 'asc' }],
          skip: (query.page - 1) * query.pageSize,
          take: query.pageSize,
        }),
        tx.recurringRule.count({ where }),
      ]);
      return { items: rows.map(mapRule), total };
    }, { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead });
  }

  update(userId: string, id: string, patch: RecurringPatch) {
    return this.write(userId, async tx => {
      const current = await this.get(tx, userId, id);
      assertRecurringVersion(current.version, patch.version);
      const { version: _version, ...fields } = patch;
      const next: RecurringInput = {
        clientId: current.clientId,
        type: current.type,
        unit: fields.unit ?? current.unit,
        interval: fields.interval ?? current.interval,
        amountMinor: fields.amountMinor ?? current.amountMinor,
        currencyCode: fields.currencyCode ?? current.currencyCode,
        accountId: fields.accountId ?? current.accountId,
        categoryId: fields.categoryId === undefined ? current.categoryId : fields.categoryId,
        counterAccountId: fields.counterAccountId === undefined ? current.counterAccountId : fields.counterAccountId,
        counterAmountMinor: fields.counterAmountMinor === undefined ? current.counterAmountMinor : fields.counterAmountMinor,
        counterCurrencyCode: fields.counterCurrencyCode === undefined ? current.counterCurrencyCode : fields.counterCurrencyCode,
        fxRate: fields.fxRate === undefined ? current.fxRate : fields.fxRate,
        startDate: fields.startDate ?? current.startDate,
        endDate: fields.endDate === undefined ? current.endDate : fields.endDate,
        nextExecutionDate: fields.nextExecutionDate ?? current.nextExecutionDate,
        active: fields.active ?? current.active,
      };
      await this.validateAccounts(tx, userId, next);
      const row = await tx.recurringRule.update({
        where: { id, userId, version: patch.version },
        data: {
          unit: next.unit,
          interval: next.interval,
          amountMinor: next.amountMinor,
          currencyCode: next.currencyCode,
          accountId: next.accountId,
          categoryId: next.categoryId,
          counterAccountId: next.counterAccountId,
          counterAmountMinor: next.counterAmountMinor,
          counterCurrencyCode: next.counterCurrencyCode,
          fxRate: next.fxRate,
          startDate: next.startDate,
          endDate: next.endDate,
          nextExecutionDate: next.nextExecutionDate,
          active: next.active,
          version: { increment: 1 },
        },
        select,
      });
      return mapRule(row);
    });
  }

  delete(userId: string, id: string, version: number) {
    return this.write(userId, async tx => {
      const current = await this.get(tx, userId, id);
      assertRecurringVersion(current.version, version);
      await tx.recurringRule.delete({ where: { id, userId, version } });
    });
  }

  async runDue(userId: string | null, now = new Date()): Promise<RecurringRunResult> {
    const due = await this.prisma.recurringRule.findMany({
      where: {
        active: true,
        ...(userId ? { userId } : {}),
      },
      select: { id: true, userId: true },
      orderBy: [{ nextExecutionDate: 'asc' }, { id: 'asc' }],
      take: 200,
    });
    let created = 0;
    let skipped = 0;
    for (const item of due) {
      const result = await this.runOne(item.userId, item.id, now);
      created += result.created;
      skipped += result.skipped;
    }
    return { created, skipped };
  }

  private async runOne(userId: string, ruleId: string, now: Date): Promise<RecurringRunResult> {
    for (let attempt = 0; ; attempt++) {
      try {
        return await this.prisma.$transaction(async tx => {
          await touchFinancialOwner(tx, userId);
          await tx.$queryRaw`SELECT id FROM "RecurringRule" WHERE id = ${ruleId}::uuid AND "userId" = ${userId}::uuid FOR UPDATE`;
          const row = await tx.recurringRule.findFirst({ where: { id: ruleId, userId }, select });
          if (!row || !row.active) return { created: 0, skipped: 0 };
          const user = await tx.user.findUnique({ where: { id: userId }, select: { timezone: true } });
          if (!user) return { created: 0, skipped: 0 };
          const today = todayInTimeZone(user.timezone, now);
          const rule = mapRule(row);
          const dates = dueDates({
            nextExecutionDate: dayString(rule.nextExecutionDate),
            startDate: dayString(rule.startDate),
            endDate: rule.endDate ? dayString(rule.endDate) : null,
            today,
            unit: rule.unit,
            interval: rule.interval,
            active: rule.active,
            limit: 36,
          });
          if (!dates.length) return { created: 0, skipped: 0 };
          let created = 0;
          let skipped = 0;
          let cursor = dayString(rule.nextExecutionDate);
          const preferred = anchorDay(dayString(rule.startDate));
          for (const occurredOn of dates) {
            const posted = await this.postOccurrence(tx, userId, rule, occurredOn, now);
            if (posted === 'blocked') {
              skipped += 1;
              break;
            }
            if (posted === 'created') created += 1;
            cursor = addInterval(occurredOn, rule.unit, rule.interval, preferred);
          }
          await tx.recurringRule.update({
            where: { id: ruleId, userId },
            data: { nextExecutionDate: toDate(cursor) },
          });
          return { created, skipped };
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
        throw error;
      }
    }
  }

  private buildInput(rule: RecurringRule, occurredOn: string, quotedAt: Date): TransactionInput {
    const sourceClientId = occurrenceClientId(rule.id, occurredOn, 0);
    const legs = [{
      clientId: sourceClientId,
      accountId: rule.accountId,
      currencyCode: rule.currencyCode,
      amountMinor: rule.amountMinor,
    }];
    if (rule.type === 'transfer') {
      legs.push({
        clientId: occurrenceClientId(rule.id, occurredOn, 1),
        accountId: rule.counterAccountId!,
        currencyCode: rule.counterCurrencyCode!,
        amountMinor: rule.counterAmountMinor!,
      });
    }
    return {
      type: rule.type,
      occurredOn: toDate(occurredOn),
      occurredTime: null,
      categoryId: rule.categoryId,
      notes: null,
      merchant: null,
      tagIds: [],
      legs,
      fx: rule.fxRate ? { rate: rule.fxRate, quotedAt } : null,
    };
  }

  private async postOccurrence(
    tx: Prisma.TransactionClient,
    userId: string,
    rule: RecurringRule,
    occurredOn: string,
    now: Date,
  ): Promise<'created' | 'replayed' | 'blocked'> {
    const existing = await tx.recurringOccurrence.findUnique({
      where: { ruleId_occurredOn: { ruleId: rule.id, occurredOn: toDate(occurredOn) } },
    });
    if (existing) return 'replayed';
    const input = this.buildInput(rule, occurredOn, now);
    try {
      const result = await createTransactionInTx(tx, userId, input, { recurringRuleId: rule.id });
      await tx.recurringOccurrence.create({
        data: {
          ruleId: rule.id,
          occurredOn: toDate(occurredOn),
          transactionClientId: input.legs[0].clientId,
          counterClientId: input.legs[1]?.clientId ?? null,
        },
      });
      return result.created ? 'created' : 'replayed';
    } catch (error) {
      if (error instanceof TransactionError) {
        if (error.code === 'TRANSACTION_CONFLICT' || error.code === 'VALIDATION_ERROR' || error.code === 'ACCOUNT_NOT_FOUND') {
          return 'blocked';
        }
      }
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        return 'replayed';
      }
      throw error;
    }
  }
}
