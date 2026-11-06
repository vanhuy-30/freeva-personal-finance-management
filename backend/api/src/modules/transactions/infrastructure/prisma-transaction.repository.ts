import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../../infrastructure/prisma/prisma.service';
import { touchFinancialOwner } from '../../../infrastructure/prisma/financial-owner-lock';
import type { RecentMatchQuery, TransactionRepository } from '../domain/transaction.repository';
import { categoryKindFits, normalizeRate, TransactionError, validateInput, type TransactionBundle, type TransactionInput, type TransactionLeg, type TransactionPatch, type TransactionQuery } from '../domain/transaction';
import { VIETNAMESE_FOLD_FROM, VIETNAMESE_FOLD_TO, parseTransactionSearch, type AmountSearch, type ParsedTransactionSearch } from '../domain/search';
import { createTransactionInTx } from './create-transaction-in-tx';
import { reconcileDelta, reconcileTarget, validateReconcileNotes, type ReconcileInput, type ReconcileResult } from '../domain/reconcile';
import { calendarDate } from '../domain/transaction';
import { assertWithinRefundCap, validateRefundAmount, type RefundInput } from '../domain/refund';
import type { CsvTransactionRow } from '../domain/csv-export';
import { todayInTimeZone } from '../../reports/domain/report';

const include = { tags: { select: { tagId: true } }, fxQuote: true } satisfies Prisma.TransactionInclude;
type Row = Prisma.TransactionGetPayload<{ include: typeof include }>;
function leg(row: Row): TransactionLeg {
  return { id: row.id, clientId: row.clientId, accountId: row.accountId, currencyCode: row.currencyCode, amountMinor: row.amountMinor,
    type: row.type, occurredOn: row.occurredOn, occurredTime: row.occurredTime, categoryId: row.categoryId, notes: row.notes, merchant: row.merchant,
    tagIds: row.tags.map(tag => tag.tagId).sort(),
    transferGroupId: row.transferGroupId, refundOfId: row.refundOfId, fxQuoteId: row.fxQuoteId, deletedAt: row.deletedAt, version: row.version, createdAt: row.createdAt, updatedAt: row.updatedAt };
}
function bundle(rows: Row[]): TransactionBundle {
  rows.sort((a, b) => a.amountMinor < b.amountMinor ? -1 : a.amountMinor > b.amountMinor ? 1 : a.id.localeCompare(b.id));
  const first = rows[0];
  if (!first) throw new TransactionError('TRANSACTION_NOT_FOUND');
  if (rows.length !== (first.type === 'transfer' ? 2 : 1) || rows.some(row => row.version !== first.version ||
    row.occurredOn.getTime() !== first.occurredOn.getTime() || row.occurredTime !== first.occurredTime ||
    row.deletedAt?.getTime() !== first.deletedAt?.getTime() ||
    row.type !== first.type || row.fxQuoteId !== first.fxQuoteId)) throw new TransactionError('TRANSACTION_CONFLICT');
  const quote = first.fxQuote;
  return { legs: rows.map(leg), fx: quote ? { id: quote.id, fromCode: quote.fromCode, toCode: quote.toCode,
    rate: normalizeRate(quote.rate.toFixed(8)), quotedAt: quote.quotedAt } : null };
}
function inputOf(current: TransactionBundle): TransactionInput {
  const first = current.legs[0];
  return { type: first.type, occurredOn: first.occurredOn, occurredTime: first.occurredTime,
    categoryId: first.categoryId, notes: first.notes, merchant: first.merchant, tagIds: first.tagIds,
    legs: current.legs.map(({ clientId, accountId, currencyCode, amountMinor }) => ({ clientId, accountId, currencyCode, amountMinor })),
    fx: current.fx ? { rate: current.fx.rate, quotedAt: current.fx.quotedAt } : null };
}
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
    if (input.categoryId) {
      const category = await tx.category.findFirst({ where: { id: input.categoryId, userId, archivedAt: null }, select: { kind: true } });
      if (!category) throw new TransactionError('VALIDATION_ERROR');
      if (!categoryKindFits(input.type, category.kind)) throw new TransactionError('CATEGORY_KIND_MISMATCH');
    }
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
    return this.snapshot(tx => createTransactionInTx(tx, userId, input), true);
  }
  find(userId: string, id: string) { return this.snapshot(tx => this.load(tx, userId, id)); }
  findByClientId(userId: string, clientId: string) {
    return this.snapshot(async tx => {
      const row = await tx.transaction.findFirst({ where: { userId, clientId } });
      return row ? this.load(tx, userId, row.id) : null;
    });
  }
  findRecentMatches(userId: string, query: RecentMatchQuery) {
    return this.snapshot(async tx => {
      if (!query.legs.length) return [];
      return tx.transaction.findMany({
        where: {
          userId, deletedAt: null, occurredOn: query.occurredOn, type: { notIn: ['adjustment', 'debt', 'refund', 'investment'] },
          createdAt: { gte: query.createdAfter, lte: query.createdBefore },
          clientId: { notIn: query.excludeClientIds },
          OR: query.legs.map(leg => ({ accountId: leg.accountId, amountMinor: leg.amountMinor })),
        },
        select: { id: true, clientId: true, accountId: true, amountMinor: true, occurredOn: true, createdAt: true, deletedAt: true },
        orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        take: 50,
      });
    });
  }
  list(userId: string, query: TransactionQuery) {
    return this.snapshot(async tx => {
      const where = listFilters(userId, query, parseTransactionSearch(query.search));
      const listed = Prisma.sql`
        FROM "Transaction" t
        LEFT JOIN "Category" c ON c.id = t."categoryId" AND c."userId" = t."userId"
        LEFT JOIN "FinancialAccount" a ON a.id = t."accountId" AND a."userId" = t."userId"
        JOIN "Currency" ccy ON ccy.code = t."currencyCode"
        WHERE ${where}`;
      const ids = await tx.$queryRaw<{ id: string }[]>(Prisma.sql`
        SELECT t.id ${listed}
        ORDER BY ${query.sort === 'amountDesc' ? Prisma.sql`ABS(t."amountMinor") DESC, ` : Prisma.empty}t."occurredOn" DESC, t."createdAt" DESC, t.id ASC
        LIMIT ${query.pageSize} OFFSET ${(query.page - 1) * query.pageSize}`);
      const [count] = await tx.$queryRaw<{ total: string; bundles: string }[]>(Prisma.sql`
        SELECT COUNT(*)::text AS total, COUNT(DISTINCT COALESCE(t."transferGroupId", t.id))::text AS bundles ${listed}`);
      const totals = await tx.$queryRaw<{ currency: string; income: string; expense: string; transferIn: string; transferOut: string; adjustment: string; debt: string; refund: string }[]>(Prisma.sql`
        SELECT t."currencyCode" AS currency,
          COALESCE(SUM(CASE WHEN t.type::text = 'income' THEN t."amountMinor" ELSE 0 END), 0)::text AS income,
          COALESCE(SUM(CASE WHEN t.type::text = 'expense' THEN t."amountMinor" ELSE 0 END), 0)::text AS expense,
          COALESCE(SUM(CASE WHEN t.type::text = 'transfer' AND t."amountMinor" > 0 THEN t."amountMinor" ELSE 0 END), 0)::text AS "transferIn",
          COALESCE(SUM(CASE WHEN t.type::text = 'transfer' AND t."amountMinor" < 0 THEN t."amountMinor" ELSE 0 END), 0)::text AS "transferOut",
          COALESCE(SUM(CASE WHEN t.type::text = 'adjustment' THEN t."amountMinor" ELSE 0 END), 0)::text AS adjustment,
          COALESCE(SUM(CASE WHEN t.type::text = 'debt' THEN t."amountMinor" ELSE 0 END), 0)::text AS debt,
          COALESCE(SUM(CASE WHEN t.type::text = 'refund' THEN t."amountMinor" ELSE 0 END), 0)::text AS refund
        ${listed}
        GROUP BY t."currencyCode" ORDER BY t."currencyCode"`);
      const summary = {
        count: Number(count.bundles),
        totals: totals
          .map(row => ({ currency: row.currency.trim(), incomeMinor: BigInt(row.income), expenseMinor: BigInt(row.expense),
            transferInMinor: BigInt(row.transferIn), transferOutMinor: BigInt(row.transferOut), adjustmentMinor: BigInt(row.adjustment), debtMinor: BigInt(row.debt), refundMinor: BigInt(row.refund) }))
          .filter(row => [row.incomeMinor, row.expenseMinor, row.transferInMinor, row.transferOutMinor, row.adjustmentMinor, row.debtMinor, row.refundMinor].some(value => value !== 0n)),
      };
      if (!ids.length) return { items: [], total: Number(count.total), summary };
      const rows = await tx.transaction.findMany({ where: { userId, id: { in: ids.map(row => row.id) } }, include });
      const rank = new Map(ids.map((row, index) => [row.id, index]));
      rows.sort((left, right) => rank.get(left.id)! - rank.get(right.id)!);
      return { items: rows.map(leg), total: Number(count.total), summary };
    });
  }
  /** Same filters as `list`, oldest first so the file reads like a statement; audit is written in the same transaction (fail closed). */
  listForCsv(userId: string, query: TransactionQuery, maxRows: number): Promise<CsvTransactionRow[]> {
    return this.snapshot(async tx => {
      const where = listFilters(userId, { ...query, status: 'active' }, parseTransactionSearch(query.search));
      const rows = await tx.$queryRaw<{ id: string; occurredOn: string; occurredTime: string | null; type: string; amountMinor: bigint; currencyCode: string;
        minorDigits: number; walletName: string | null; categoryName: string | null; merchant: string | null; notes: string | null; tagNames: string[] }[]>(Prisma.sql`
        SELECT t.id::text AS id, to_char(t."occurredOn", 'YYYY-MM-DD') AS "occurredOn", t."occurredTime" AS "occurredTime", t.type::text AS type,
          t."amountMinor" AS "amountMinor", t."currencyCode"::text AS "currencyCode", ccy."minorDigits" AS "minorDigits",
          a.name AS "walletName", c.name AS "categoryName", t.merchant, t.notes,
          COALESCE((SELECT array_agg(tag.name ORDER BY tag.name) FROM "TransactionTag" tt JOIN "Tag" tag ON tag.id = tt."tagId" AND tag."userId" = t."userId"
            WHERE tt."transactionId" = t.id), ARRAY[]::text[]) AS "tagNames"
        FROM "Transaction" t
        LEFT JOIN "Category" c ON c.id = t."categoryId" AND c."userId" = t."userId"
        LEFT JOIN "FinancialAccount" a ON a.id = t."accountId" AND a."userId" = t."userId"
        JOIN "Currency" ccy ON ccy.code = t."currencyCode"
        WHERE ${where}
        ORDER BY t."occurredOn" ASC, t."createdAt" ASC, t.id ASC
        LIMIT ${maxRows + 1}`);
      if (rows.length > maxRows) throw new TransactionError('VALIDATION_ERROR');
      await tx.auditEvent.create({ data: { actorType: 'user', actorId: userId, action: 'user.transactions_export', targetType: 'user', targetId: userId, outcome: 'success' } });
      return rows.map(row => ({ ...row, amountMinor: BigInt(row.amountMinor), minorDigits: Number(row.minorDigits) }));
    });
  }
  /**
   * Wallet reconciliation (BE-P3-005): compare the real balance with the ledger and write one one-leg adjustment.
   * A retry with the same clientId replays the stored adjustment instead of recomputing against the new balance.
   */
  reconcile(userId: string, accountId: string, input: ReconcileInput): Promise<ReconcileResult> {
    validateReconcileNotes(input.notes);
    return this.snapshot(async tx => {
      await touchFinancialOwner(tx, userId);
      await tx.$queryRaw(Prisma.sql`SELECT id FROM "FinancialAccount" WHERE id = ${accountId}::uuid AND "userId" = ${userId}::uuid FOR UPDATE`);
      const account = await tx.financialAccount.findFirst({ where: { id: accountId, userId }, include: { currency: true } });
      if (!account) throw new TransactionError('ACCOUNT_NOT_FOUND');
      const [sum] = await tx.$queryRaw<{ total: string }[]>(Prisma.sql`
        SELECT COALESCE(SUM("amountMinor"), 0)::text AS total FROM "Transaction"
        WHERE "userId" = ${userId}::uuid AND "accountId" = ${accountId}::uuid AND "deletedAt" IS NULL`);
      const target = reconcileTarget(account.type, input.actualBalanceMinor);
      const replay = await tx.transaction.findFirst({ where: { userId, clientId: input.clientId } });
      if (replay) {
        if (replay.type !== 'adjustment' || replay.accountId !== accountId) throw new TransactionError('TRANSACTION_CONFLICT');
        const current = await this.load(tx, userId, replay.id);
        return { accountId, currencyCode: account.currencyCode, currentBalanceMinor: account.initialBalanceMinor + BigInt(sum.total),
          targetBalanceMinor: target, deltaMinor: replay.amountMinor, transaction: current, created: false };
      }
      const currentBalance = account.initialBalanceMinor + BigInt(sum.total);
      const delta = reconcileDelta(account.type, currentBalance, input.actualBalanceMinor);
      const base = { accountId, currencyCode: account.currencyCode, currentBalanceMinor: currentBalance, targetBalanceMinor: target, deltaMinor: delta };
      if (delta === 0n || input.dryRun) return { ...base, transaction: null, created: false };
      const user = await tx.user.findUnique({ where: { id: userId }, select: { timezone: true } });
      const day = input.occurredOn ?? todayInTimeZone(user?.timezone ?? 'UTC', new Date());
      const created = await createTransactionInTx(tx, userId, {
        type: 'adjustment', occurredOn: calendarDate(day), occurredTime: null, categoryId: null, notes: input.notes,
        merchant: null, tagIds: [], fx: null,
        legs: [{ clientId: input.clientId, accountId, currencyCode: account.currencyCode, amountMinor: delta }],
      });
      return { ...base, transaction: created.transaction, created: created.created };
    }, true);
  }
  async refundedTotals(userId: string, expenseIds: string[]): Promise<Map<string, bigint>> {
    if (!expenseIds.length) return new Map();
    const rows = await this.prisma.transaction.groupBy({ by: ['refundOfId'], _sum: { amountMinor: true },
      where: { userId, type: 'refund', deletedAt: null, refundOfId: { in: expenseIds } } });
    return new Map(rows.filter(row => row.refundOfId && row._sum.amountMinor).map(row => [row.refundOfId!, row._sum.amountMinor!]));
  }
  async installmentPlanIds(userId: string, expenseIds: string[]): Promise<Map<string, string>> {
    if (!expenseIds.length) return new Map();
    const rows = await this.prisma.cardInstallmentPlan.findMany({ where: { userId, transactionId: { in: expenseIds }, status: 'active' }, select: { id: true, transactionId: true } });
    return new Map(rows.map(row => [row.transactionId, row.id]));
  }
  /** Sum of active refunds of one expense, optionally leaving one refund out (its own edit). */
  private async refunded(tx: Prisma.TransactionClient, userId: string, originalId: string, exceptId?: string): Promise<bigint> {
    const [sum] = await tx.$queryRaw<{ total: string }[]>(Prisma.sql`
      SELECT COALESCE(SUM("amountMinor"), 0)::text AS total FROM "Transaction"
      WHERE "userId" = ${userId}::uuid AND "refundOfId" = ${originalId}::uuid AND type::text = 'refund' AND "deletedAt" IS NULL
        ${exceptId ? Prisma.sql`AND id <> ${exceptId}::uuid` : Prisma.empty}`);
    return BigInt(sum.total);
  }
  /**
   * Refund (BE-P3-008): one positive leg in `accountId`, pointing at the expense. The expense row is locked so two
   * refunds cannot pass the original amount together. A retry with the same clientId replays the stored refund.
   */
  refund(userId: string, originalId: string, input: RefundInput) {
    validateRefundAmount(input.amountMinor);
    return this.snapshot(async tx => {
      await touchFinancialOwner(tx, userId);
      await tx.$queryRaw(Prisma.sql`SELECT id FROM "Transaction" WHERE id = ${originalId}::uuid AND "userId" = ${userId}::uuid FOR UPDATE`);
      const original = await tx.transaction.findFirst({ where: { id: originalId, userId } });
      if (!original) throw new TransactionError('TRANSACTION_NOT_FOUND');
      const replay = await tx.transaction.findFirst({ where: { userId, clientId: input.clientId } });
      if (replay) {
        if (replay.type !== 'refund' || replay.refundOfId !== originalId || replay.accountId !== input.accountId ||
          replay.amountMinor !== input.amountMinor) throw new TransactionError('TRANSACTION_CONFLICT');
        return { transaction: await this.load(tx, userId, replay.id), created: false };
      }
      if (original.type !== 'expense' || original.deletedAt) throw new TransactionError('TRANSACTION_CONFLICT');
      assertWithinRefundCap(original.amountMinor, await this.refunded(tx, userId, originalId) + input.amountMinor);
      const user = await tx.user.findUnique({ where: { id: userId }, select: { timezone: true } });
      const day = input.occurredOn ?? todayInTimeZone(user?.timezone ?? 'UTC', new Date());
      return createTransactionInTx(tx, userId, {
        type: 'refund', occurredOn: calendarDate(day), occurredTime: null, categoryId: original.categoryId, notes: input.notes,
        merchant: null, tagIds: [], fx: null,
        legs: [{ clientId: input.clientId, accountId: input.accountId, currencyCode: original.currencyCode, amountMinor: input.amountMinor }],
      }, { refundOfId: originalId });
    }, true);
  }
  /** Deleting an expense that still has refunds needs an explicit choice; otherwise the refunds would dangle. */
  private async settleRefunds(tx: Prisma.TransactionClient, userId: string, originalId: string, disposition: TransactionPatch['refunds']) {
    const active = await tx.transaction.findMany({ where: { userId, refundOfId: originalId, deletedAt: null }, select: { id: true, accountId: true } });
    if (!active.length) return;
    if (!disposition) throw new TransactionError('REFUND_EXISTS');
    const ids = [...new Set(active.map(row => row.accountId))].sort();
    await tx.$queryRaw(Prisma.sql`SELECT id FROM "FinancialAccount" WHERE "userId" = ${userId}::uuid
      AND id IN (${Prisma.join(ids.map(id => Prisma.sql`${id}::uuid`))}) ORDER BY id FOR UPDATE`);
    await tx.financialAccount.updateMany({ where: { userId, id: { in: ids } }, data: { updatedAt: new Date() } });
    const where = { userId, refundOfId: originalId, deletedAt: null };
    // cascade removes the money from the wallet; keep leaves the wallet balance alone and turns the refund into plain income.
    if (disposition === 'cascade') await tx.transaction.updateMany({ where, data: { deletedAt: new Date(), version: { increment: 1 } } });
    else await tx.transaction.updateMany({ where, data: { type: 'income', refundOfId: null, categoryId: null, version: { increment: 1 } } });
  }
  update(userId: string, id: string, patch: TransactionPatch) {
    return this.snapshot(async tx => {
      await touchFinancialOwner(tx, userId);
      const current = await this.load(tx, userId, id, true);
      const first = current.legs[0];
      // Debt legs are owned by /personal-debts (BE-P3-007) and investment legs by /investments (BE-P4-E01): editing or deleting one would desync the position.
      if (first.type === 'debt' || first.type === 'investment') throw new TransactionError('VALIDATION_ERROR');
      if (first.version !== patch.version || first.version >= 2147483647) throw new TransactionError('TRANSACTION_CONFLICT');
      const { version: _version, deleted, refunds: refundDisposition, ...fields } = patch;
      const input = { ...inputOf(current), ...fields };
      if (input.legs.length !== current.legs.length || input.legs.some((item, index) => item.clientId !== current.legs[index].clientId)) throw new TransactionError('TRANSACTION_CONFLICT');
      const deletionOnly = Object.keys(fields).length === 0 && deleted === true;
      if (first.deletedAt && !deletionOnly && deleted !== false) throw new TransactionError('TRANSACTION_CONFLICT');
      if (first.type === 'refund' && (fields.categoryId !== undefined || fields.merchant !== undefined || fields.fx !== undefined || fields.tagIds !== undefined)) throw new TransactionError('VALIDATION_ERROR');
      if (first.type === 'refund' && !deletionOnly && first.refundOfId) {
        const original = await tx.transaction.findFirst({ where: { id: first.refundOfId, userId } });
        if (!original || original.deletedAt) throw new TransactionError('TRANSACTION_CONFLICT');
        assertWithinRefundCap(original.amountMinor, await this.refunded(tx, userId, original.id, first.id) + input.legs[0].amountMinor);
      }
      if (first.type === 'expense' && deleted === true && !first.deletedAt) {
        await this.settleRefunds(tx, userId, id, refundDisposition);
        // A schedule over a deleted purchase would list money nobody owes any more (BE-P3-009).
        await tx.cardInstallmentPlan.updateMany({ where: { userId, transactionId: id, status: 'active' }, data: { status: 'closed', closedAt: new Date(), version: { increment: 1 } } });
      }
      if (first.type === 'expense' && !deletionOnly) {
        const refundedNow = await this.refunded(tx, userId, id);
        if (refundedNow > 0n) {
          // The refunds were measured against this amount, currency and category: keep them consistent.
          if (input.legs[0].currencyCode !== first.currencyCode) throw new TransactionError('VALIDATION_ERROR');
          assertWithinRefundCap(input.legs[0].amountMinor, refundedNow);
          if (input.categoryId !== first.categoryId) {
            await tx.transaction.updateMany({ where: { userId, refundOfId: id, deletedAt: null }, data: { categoryId: input.categoryId, version: { increment: 1 } } });
          }
        }
      }
      await this.accounts(tx, userId, input, current.legs, !deletionOnly);
      if (!deletionOnly && first.type !== 'refund') await this.references(tx, userId, input);
      const fxQuoteId = await this.quote(tx, userId, input, current);
      const deletedAt = deleted === undefined ? first.deletedAt : deleted ? first.deletedAt ?? new Date() : null;
      const rows: Row[] = [];
      for (let index = 0; index < input.legs.length; index++) {
        rows.push(await tx.transaction.update({ where: { id: current.legs[index].id, userId, version: patch.version }, data: {
          ...input.legs[index], occurredOn: input.occurredOn, occurredTime: input.occurredTime,
          categoryId: input.categoryId, notes: input.notes, merchant: input.merchant,
          fxQuoteId, deletedAt, version: { increment: 1 }, tags: { deleteMany: {}, create: input.tagIds.map(tagId => ({ tagId })) },
        }, include }));
      }
      return bundle(rows);
    });
  }
}

function listFilters(userId: string, query: TransactionQuery, search: ParsedTransactionSearch | null) {
  const parts: Prisma.Sql[] = [Prisma.sql`t."userId" = ${userId}::uuid`];
  if (query.status === 'active') parts.push(Prisma.sql`t."deletedAt" IS NULL`);
  else if (query.status === 'deleted') parts.push(Prisma.sql`t."deletedAt" IS NOT NULL`);
  if (query.accountIds?.length) parts.push(Prisma.sql`t."accountId" IN (${uuids(query.accountIds)})`);
  if (query.categoryIds?.length) parts.push(Prisma.sql`t."categoryId" IN (${uuids(query.categoryIds)})`);
  if (query.tagIds?.length) {
    parts.push(Prisma.sql`EXISTS (
      SELECT 1 FROM "TransactionTag" ft WHERE ft."transactionId" = t.id AND ft."tagId" IN (${uuids(query.tagIds)})
    )`);
  }
  if (query.type) parts.push(Prisma.sql`t.type::text = ${query.type}`);
  if (query.currency) parts.push(Prisma.sql`t."currencyCode" = ${query.currency}`);
  if (query.from) parts.push(Prisma.sql`t."occurredOn" >= ${query.from}::date`);
  if (query.to) parts.push(Prisma.sql`t."occurredOn" <= ${query.to}::date`);
  if (search) parts.push(searchMatch(search));
  return Prisma.join(parts, ' AND ');
}

function uuids(values: string[]) {
  return Prisma.join(values.map(value => Prisma.sql`${value}::uuid`));
}

function searchMatch(search: ParsedTransactionSearch) {
  const text = Prisma.sql`(
    ${likeFold(Prisma.sql`t.notes`, search.like)}
    OR ${likeFold(Prisma.sql`t.merchant`, search.like)}
    OR ${likeFold(Prisma.sql`c.name`, search.like)}
    OR ${likeFold(Prisma.sql`a.name`, search.like)}
    OR EXISTS (
      SELECT 1 FROM "TransactionTag" tt
      JOIN "Tag" tag ON tag.id = tt."tagId" AND tag."userId" = t."userId"
      WHERE tt."transactionId" = t.id AND ${likeFold(Prisma.sql`tag.name`, search.like)}
    )
  )`;
  const amount = amountMatch(search.amount);
  return amount ? Prisma.sql`(${text} OR ${amount})` : text;
}

function likeFold(column: Prisma.Sql, like: string) {
  return Prisma.sql`translate(normalize(coalesce(${column}, '')), ${VIETNAMESE_FOLD_FROM}, ${VIETNAMESE_FOLD_TO}) LIKE ${like} ESCAPE '\\'`;
}

/** Mirrors resolvedMinor: major units scale by Currency.minorDigits, no rounding. */
function amountMatch(amount: AmountSearch | null) {
  if (!amount) return null;
  if (amount.kind === 'minor') return Prisma.sql`abs(t."amountMinor") = ${amount.minor.toString()}::bigint`;
  return Prisma.sql`(
    ccy."minorDigits" >= ${amount.fractionDigits}
    AND abs(t."amountMinor")::numeric =
      ${amount.whole.toString()}::numeric * (10::numeric ^ ccy."minorDigits")
      + ${amount.fraction.toString()}::numeric * (10::numeric ^ (ccy."minorDigits" - ${amount.fractionDigits}))
  )`;
}
