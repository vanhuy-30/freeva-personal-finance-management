import { randomUUID } from 'node:crypto';
import { Prisma } from '@prisma/client';
import { touchFinancialOwner } from '../../../infrastructure/prisma/financial-owner-lock';
import {
  normalizeRate,
  TransactionError,
  validateInput,
  type TransactionBundle,
  type TransactionInput,
  type TransactionLeg,
} from '../domain/transaction';

const include = { tags: { select: { tagId: true } }, fxQuote: true } satisfies Prisma.TransactionInclude;
type Row = Prisma.TransactionGetPayload<{ include: typeof include }>;

function leg(row: Row): TransactionLeg {
  return {
    id: row.id, clientId: row.clientId, accountId: row.accountId, currencyCode: row.currencyCode,
    amountMinor: row.amountMinor, type: row.type, occurredOn: row.occurredOn, categoryId: row.categoryId,
    notes: row.notes, merchant: row.merchant, tagIds: row.tags.map(tag => tag.tagId).sort(),
    transferGroupId: row.transferGroupId, fxQuoteId: row.fxQuoteId, deletedAt: row.deletedAt,
    version: row.version, createdAt: row.createdAt, updatedAt: row.updatedAt,
  };
}

function bundle(rows: Row[]): TransactionBundle {
  rows.sort((a, b) => (a.amountMinor < b.amountMinor ? -1 : a.amountMinor > b.amountMinor ? 1 : a.id.localeCompare(b.id)));
  const first = rows[0];
  if (!first) throw new TransactionError('TRANSACTION_NOT_FOUND');
  if (
    rows.length !== (first.type === 'transfer' ? 2 : 1) ||
    rows.some(row => row.version !== first.version ||
      row.occurredOn.getTime() !== first.occurredOn.getTime() ||
      row.deletedAt?.getTime() !== first.deletedAt?.getTime() ||
      row.type !== first.type || row.fxQuoteId !== first.fxQuoteId)
  ) {
    throw new TransactionError('TRANSACTION_CONFLICT');
  }
  const quote = first.fxQuote;
  return {
    legs: rows.map(leg),
    fx: quote
      ? { id: quote.id, fromCode: quote.fromCode, toCode: quote.toCode, rate: normalizeRate(quote.rate.toFixed(8)), quotedAt: quote.quotedAt }
      : null,
  };
}

function inputOf(current: TransactionBundle): TransactionInput {
  const first = current.legs[0];
  return {
    type: first.type, occurredOn: first.occurredOn, categoryId: first.categoryId, notes: first.notes,
    merchant: first.merchant, tagIds: first.tagIds,
    legs: current.legs.map(({ clientId, accountId, currencyCode, amountMinor }) => ({ clientId, accountId, currencyCode, amountMinor })),
    fx: current.fx ? { rate: current.fx.rate, quotedAt: current.fx.quotedAt } : null,
  };
}

const fingerprint = (input: TransactionInput) => JSON.stringify(
  {
    type: input.type, occurredOn: input.occurredOn,
    legs: input.legs.map(item => ({
      clientId: item.clientId, accountId: item.accountId, currencyCode: item.currencyCode, amountMinor: item.amountMinor,
    })),
    categoryId: input.categoryId, notes: input.notes, merchant: input.merchant, tagIds: input.tagIds, fx: input.fx,
  },
  (_key, value: unknown) => (typeof value === 'bigint' ? value.toString() : value),
);

async function loadBundle(tx: Prisma.TransactionClient, userId: string, id: string): Promise<TransactionBundle> {
  const row = await tx.transaction.findFirst({ where: { id, userId } });
  if (!row) throw new TransactionError('TRANSACTION_NOT_FOUND');
  const where = row.transferGroupId ? { userId, transferGroupId: row.transferGroupId } : { userId, id };
  return bundle(await tx.transaction.findMany({ where, include }));
}

export type CreateTransactionOptions = {
  recurringRuleId?: string | null;
};

/**
 * Insert or replay a transaction bundle inside an existing Prisma interactive transaction.
 * Shared by HTTP create and recurring occurrence posting so money rules stay in one place.
 */
export async function createTransactionInTx(
  tx: Prisma.TransactionClient,
  userId: string,
  input: TransactionInput,
  options: CreateTransactionOptions = {},
): Promise<{ transaction: TransactionBundle; created: boolean }> {
  await touchFinancialOwner(tx, userId);
  const existing = await tx.transaction.findMany({
    where: { userId, clientId: { in: input.legs.map(item => item.clientId) } },
  });
  if (existing.length) {
    const current = await loadBundle(tx, userId, existing[0].id);
    if (fingerprint(inputOf(current)) !== fingerprint(input)) throw new TransactionError('TRANSACTION_CONFLICT');
    return { transaction: current, created: false };
  }
  const ids = [...new Set(input.legs.map(item => item.accountId))].sort();
  await tx.$queryRaw(Prisma.sql`SELECT id FROM "FinancialAccount" WHERE "userId" = ${userId}::uuid
    AND id IN (${Prisma.join(ids.map(id => Prisma.sql`${id}::uuid`))}) ORDER BY id FOR UPDATE`);
  const accounts = await tx.financialAccount.findMany({
    where: { userId, id: { in: ids } },
    include: { currency: true },
  });
  if (accounts.length !== ids.length) throw new TransactionError('ACCOUNT_NOT_FOUND');
  const digits: Record<string, number> = {};
  for (const item of input.legs) {
    const account = accounts.find(account => account.id === item.accountId)!;
    if (account.currencyCode !== item.currencyCode) throw new TransactionError('VALIDATION_ERROR');
    if (account.archivedAt) throw new TransactionError('TRANSACTION_CONFLICT');
    digits[account.currencyCode] = account.currency.minorDigits;
  }
  validateInput(input, digits);
  await tx.financialAccount.updateMany({ where: { userId, id: { in: ids } }, data: { updatedAt: new Date() } });
  if (input.categoryId && !await tx.category.findFirst({ where: { id: input.categoryId, userId, archivedAt: null } })) {
    throw new TransactionError('VALIDATION_ERROR');
  }
  if (await tx.tag.count({ where: { userId, id: { in: input.tagIds } } }) !== input.tagIds.length) {
    throw new TransactionError('VALIDATION_ERROR');
  }
  let fxQuoteId: string | null = null;
  if (input.fx) {
    fxQuoteId = (await tx.fxQuote.create({
      data: {
        userId, clientId: randomUUID(), fromCode: input.legs[0].currencyCode,
        toCode: input.legs[1].currencyCode, rate: input.fx.rate, quotedAt: input.fx.quotedAt, source: 'manual',
      },
    })).id;
  }
  const transferGroupId = input.type === 'transfer' ? randomUUID() : null;
  const recurringRuleId = options.recurringRuleId ?? null;
  const rows: Row[] = [];
  for (const item of input.legs) {
    rows.push(await tx.transaction.create({
      data: {
        ...item, userId, type: input.type, occurredOn: input.occurredOn, categoryId: input.categoryId,
        notes: input.notes, merchant: input.merchant, transferGroupId, fxQuoteId, recurringRuleId,
        tags: { create: input.tagIds.map(tagId => ({ tagId })) },
      },
      include,
    }));
  }
  return { transaction: bundle(rows), created: true };
}
