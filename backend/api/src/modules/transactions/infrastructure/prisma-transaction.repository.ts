import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { touchFinancialOwner } from '../../../infrastructure/prisma/financial-owner-lock';
import type { TransactionRepository } from '../domain/transaction.repository';
import { normalizeRate, TransactionError, validateInput, type TransactionBundle, type TransactionInput, type TransactionLeg, type TransactionPatch, type TransactionQuery } from '../domain/transaction';

const include = { tags: { select: { tagId: true } }, fxQuote: true } satisfies Prisma.TransactionInclude;
type Row = Prisma.TransactionGetPayload<{ include: typeof include }>;
function leg(row: Row): TransactionLeg {
  return { id: row.id, clientId: row.clientId, accountId: row.accountId, currencyCode: row.currencyCode, amountMinor: row.amountMinor,
    type: row.type, occurredOn: row.occurredOn, categoryId: row.categoryId, notes: row.notes, tagIds: row.tags.map(tag => tag.tagId).sort(),
    transferGroupId: row.transferGroupId, fxQuoteId: row.fxQuoteId, deletedAt: row.deletedAt, version: row.version, createdAt: row.createdAt, updatedAt: row.updatedAt };
}
function bundle(rows: Row[]): TransactionBundle {
  rows.sort((a, b) => a.amountMinor < b.amountMinor ? -1 : a.amountMinor > b.amountMinor ? 1 : a.id.localeCompare(b.id));
  const first = rows[0];
  if (!first) throw new TransactionError('TRANSACTION_NOT_FOUND');
  if (rows.length !== (first.type === 'transfer' ? 2 : 1) || rows.some(row => row.version !== first.version ||
    row.occurredOn.getTime() !== first.occurredOn.getTime() || row.deletedAt?.getTime() !== first.deletedAt?.getTime() ||
    row.type !== first.type || row.fxQuoteId !== first.fxQuoteId)) throw new TransactionError('TRANSACTION_CONFLICT');
  const quote = first.fxQuote;
  return { legs: rows.map(leg), fx: quote ? { id: quote.id, fromCode: quote.fromCode, toCode: quote.toCode,
    rate: normalizeRate(quote.rate.toFixed(8)), quotedAt: quote.quotedAt } : null };
}
function inputOf(current: TransactionBundle): TransactionInput {
  const first = current.legs[0];
  return { type: first.type, occurredOn: first.occurredOn, categoryId: first.categoryId, notes: first.notes, tagIds: first.tagIds,
    legs: current.legs.map(({ clientId, accountId, currencyCode, amountMinor }) => ({ clientId, accountId, currencyCode, amountMinor })),
    fx: current.fx ? { rate: current.fx.rate, quotedAt: current.fx.quotedAt } : null };
}
const fingerprint = (input: TransactionInput) => JSON.stringify({ type: input.type, occurredOn: input.occurredOn,
  legs: input.legs.map(item => ({ clientId: item.clientId, accountId: item.accountId, currencyCode: item.currencyCode, amountMinor: item.amountMinor })),
  categoryId: input.categoryId, notes: input.notes, tagIds: input.tagIds, fx: input.fx }, (_key, value: unknown) => typeof value === 'bigint' ? value.toString() : value);
@Injectable()
export class PrismaTransactionRepository implements TransactionRepository {
  constructor(private readonly prisma: PrismaService) {}
  private async snapshot<T>(operation: (tx: Prisma.TransactionClient) => Promise<T>, creating = false): Promise<T> {
    for (let attempt = 0; ; attempt++) {
      try { return await this.prisma.$transaction(operation, { isolationLevel: Prisma.TransactionIsolationLevel.RepeatableRead }); }
      catch (error) {
        if (attempt < 3 && error instanceof Prisma.PrismaClientKnownRequestError && (error.code === 'P2034' ||
          (error.code === 'P2010' && ['40001', '40P01'].includes(String(error.meta?.code))) || (creating && error.code === 'P2002'))) continue;
        throw error;
      }
    }
  }
  private async load(tx: Prisma.TransactionClient, userId: string, id: string, lock = false): Promise<TransactionBundle> {
    const row = await tx.transaction.findFirst({ where: { id, userId } });
    if (!row) throw new TransactionError('TRANSACTION_NOT_FOUND');
    const where = row.transferGroupId ? { userId, transferGroupId: row.transferGroupId } : { userId, id };
    if (lock) {
      await tx.$queryRaw(Prisma.sql`SELECT id FROM "Transaction" WHERE "userId" = ${userId}::uuid AND
        ${row.transferGroupId ? Prisma.sql`"transferGroupId" = ${row.transferGroupId}::uuid` : Prisma.sql`id = ${id}::uuid`}
        ORDER BY id FOR UPDATE`);
    }
    return bundle(await tx.transaction.findMany({ where, include }));
  }
  private async accounts(tx: Prisma.TransactionClient, userId: string, input: TransactionInput, old: TransactionLeg[] = [], requireActive = true) {
    const ids = [...new Set([...input.legs, ...old].map(item => item.accountId))].sort();
    await tx.$queryRaw(Prisma.sql`SELECT id FROM "FinancialAccount" WHERE "userId" = ${userId}::uuid
      AND id IN (${Prisma.join(ids.map(id => Prisma.sql`${id}::uuid`))}) ORDER BY id FOR UPDATE`);
    const accounts = await tx.financialAccount.findMany({ where: { userId, id: { in: ids } }, include: { currency: true } });
    if (accounts.length !== ids.length) throw new TransactionError('ACCOUNT_NOT_FOUND');
    const digits: Record<string, number> = {};
    for (const item of input.legs) {
      const account = accounts.find(account => account.id === item.accountId)!;
      if (account.currencyCode !== item.currencyCode) throw new TransactionError('VALIDATION_ERROR');
      if (requireActive && account.archivedAt) throw new TransactionError('TRANSACTION_CONFLICT');
      digits[account.currencyCode] = account.currency.minorDigits;
    }
    validateInput(input, digits);
    // A row lock alone does not invalidate an account writer's Repeatable Read snapshot.
    // Touch rows so concurrent type/currency/archive writes retry and see committed history.
    await tx.financialAccount.updateMany({ where: { userId, id: { in: ids } }, data: { updatedAt: new Date() } });
  }
  private async references(tx: Prisma.TransactionClient, userId: string, input: TransactionInput) {
    if (input.categoryId && !await tx.category.findFirst({ where: { id: input.categoryId, userId, archivedAt: null } })) throw new TransactionError('VALIDATION_ERROR');
    if (await tx.tag.count({ where: { userId, id: { in: input.tagIds } } }) !== input.tagIds.length) throw new TransactionError('VALIDATION_ERROR');
  }
  private async quote(tx: Prisma.TransactionClient, userId: string, input: TransactionInput, current?: TransactionBundle) {
    if (!input.fx) return null;
    if (current?.fx && current.fx.rate === input.fx.rate && current.fx.quotedAt.getTime() === input.fx.quotedAt.getTime() &&
      current.fx.fromCode === input.legs[0].currencyCode && current.fx.toCode === input.legs[1].currencyCode) return current.fx.id;
    return (await tx.fxQuote.create({ data: { userId, clientId: randomUUID(), fromCode: input.legs[0].currencyCode,
      toCode: input.legs[1].currencyCode, rate: input.fx.rate, quotedAt: input.fx.quotedAt, source: 'manual' } })).id;
  }
  create(userId: string, input: TransactionInput) {
    return this.snapshot(async tx => {
      await touchFinancialOwner(tx, userId);
      const existing = await tx.transaction.findMany({ where: { userId, clientId: { in: input.legs.map(item => item.clientId) } } });
      if (existing.length) {
        const current = await this.load(tx, userId, existing[0].id);
        if (fingerprint(inputOf(current)) !== fingerprint(input)) throw new TransactionError('TRANSACTION_CONFLICT');
        return { transaction: current, created: false };
      }
      await this.accounts(tx, userId, input);
      await this.references(tx, userId, input);
      const fxQuoteId = await this.quote(tx, userId, input);
      const transferGroupId = input.type === 'transfer' ? randomUUID() : null;
      const rows: Row[] = [];
      for (const item of input.legs) {
        rows.push(await tx.transaction.create({ data: { ...item, userId, type: input.type, occurredOn: input.occurredOn,
          categoryId: input.categoryId, notes: input.notes, transferGroupId, fxQuoteId,
          tags: { create: input.tagIds.map(tagId => ({ tagId })) } }, include }));
      }
      return { transaction: bundle(rows), created: true };
    }, true);
  }
  find(userId: string, id: string) { return this.snapshot(tx => this.load(tx, userId, id)); }
  list(userId: string, query: TransactionQuery) {
    return this.snapshot(async tx => {
      const where: Prisma.TransactionWhereInput = { userId,
        ...(query.status === 'all' ? {} : { deletedAt: query.status === 'active' ? null : { not: null } }),
        accountId: query.accountId, categoryId: query.categoryId, type: query.type,
        occurredOn: { ...(query.from ? { gte: new Date(query.from) } : {}), ...(query.to ? { lte: new Date(query.to) } : {}) },
        ...(query.search ? { notes: { contains: query.search, mode: 'insensitive' } } : {}),
      };
      const rows = await tx.transaction.findMany({ where, include, orderBy: [{ occurredOn: 'desc' }, { createdAt: 'desc' }, { id: 'asc' }],
        skip: (query.page - 1) * query.pageSize, take: query.pageSize });
      return { items: rows.map(leg), total: await tx.transaction.count({ where }) };
    });
  }
  update(userId: string, id: string, patch: TransactionPatch) {
    return this.snapshot(async tx => {
      await touchFinancialOwner(tx, userId);
      const current = await this.load(tx, userId, id, true);
      const first = current.legs[0];
      if (first.version !== patch.version || first.version >= 2147483647) throw new TransactionError('TRANSACTION_CONFLICT');
      const { version: _version, deleted, ...fields } = patch;
      const input = { ...inputOf(current), ...fields };
      if (input.legs.length !== current.legs.length || input.legs.some((item, index) => item.clientId !== current.legs[index].clientId)) throw new TransactionError('TRANSACTION_CONFLICT');
      const deletionOnly = Object.keys(fields).length === 0 && deleted === true;
      if (first.deletedAt && !deletionOnly && deleted !== false) throw new TransactionError('TRANSACTION_CONFLICT');
      await this.accounts(tx, userId, input, current.legs, !deletionOnly);
      if (!deletionOnly) await this.references(tx, userId, input);
      const fxQuoteId = await this.quote(tx, userId, input, current);
      const deletedAt = deleted === undefined ? first.deletedAt : deleted ? first.deletedAt ?? new Date() : null;
      const rows: Row[] = [];
      for (let index = 0; index < input.legs.length; index++) {
        rows.push(await tx.transaction.update({ where: { id: current.legs[index].id, userId, version: patch.version }, data: {
          ...input.legs[index], occurredOn: input.occurredOn, categoryId: input.categoryId, notes: input.notes,
          fxQuoteId, deletedAt, version: { increment: 1 }, tags: { deleteMany: {}, create: input.tagIds.map(tagId => ({ tagId })) },
        }, include }));
      }
      return bundle(rows);
    });
  }
}
