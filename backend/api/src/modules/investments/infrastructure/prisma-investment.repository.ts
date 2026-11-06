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
  formatQuantity, InvestmentError, isSingleItem, parseQuantity, replayTrades, resolveAmount, tradeLegMinor, validateDepositTerms, validateName,
  validateNote, validateTradeQuantity, validateUnit, type InvestmentKind, type InvestmentRecord,
} from '../domain/investment';
import type {
  InvestmentContext, InvestmentCreateInput, InvestmentPatch, InvestmentPriceInput, InvestmentPriceRecord, InvestmentRepository,
  InvestmentTradeInput, InvestmentTradePatch, InvestmentTradeRecord,
} from '../domain/investment.repository';

type Row = Prisma.InvestmentGetPayload<{ include: { prices: true } }>;
type Position = Prisma.InvestmentGetPayload<object>;

const dayOf = (value: Date) => value.toISOString().slice(0, 10);
const toDate = (value: string) => new Date(`${value}T00:00:00.000Z`);
const optionalDay = (value: Date | null) => (value ? dayOf(value) : null);
const quantityOf = (value: Prisma.Decimal) => parseQuantity(value.toFixed(8));
const withPrice = { prices: { orderBy: [{ quotedAt: 'desc' as const }, { createdAt: 'desc' as const }], take: 1 } };

function map(row: Row): InvestmentRecord {
  const price = row.prices[0];
  return {
    id: row.id,
    clientId: row.clientId,
    kind: row.kind,
    name: row.name,
    currencyCode: row.currencyCode.trim(),
    unit: row.unit,
    quantityScaled: quantityOf(row.quantity),
    costBasisMinor: row.costBasisMinor,
    interestRateBps: row.interestRateBps,
    startDate: optionalDay(row.startDate),
    maturityDate: optionalDay(row.maturityDate),
    note: row.note,
    archivedAt: row.archivedAt,
    version: row.version,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    latestPrice: price ? { priceMinor: price.priceMinor, source: price.source, quotedAt: price.quotedAt } : null,
  };
}

/** Deterministic UUID v4-shaped id so a retry replays the same wallet leg or price. */
function derivedId(purpose: 'trade' | 'price', clientId: string): string {
  const bytes = Buffer.from(createHash('sha256').update(`investment|${purpose}|${clientId}`).digest().subarray(0, 16));
  bytes[6] = (bytes[6]! & 0x0f) | 0x40;
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

const legClientId = (clientId: string) => derivedId('trade', clientId);

const audit = (userId: string, investmentId: string) => ({
  actorType: 'user' as const,
  actorId: userId,
  action: 'investment.create' as const,
  targetType: 'investment',
  targetId: investmentId,
  outcome: 'success' as const,
});

const sameName = (left: string, right: string) => left.trim().toLowerCase() === right.trim().toLowerCase();

@Injectable()
export class PrismaInvestmentRepository implements InvestmentRepository {
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
          throw new InvestmentError('INVESTMENT_CONFLICT');
        }
        throw error;
      }
    }
  }

  async context(userId: string): Promise<InvestmentContext> {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { timezone: true } });
    if (!user) throw new InvestmentError('VALIDATION_ERROR');
    return { today: todayInTimeZone(user.timezone, new Date()) };
  }

  async list(userId: string, includeArchived: boolean, kind?: InvestmentKind): Promise<InvestmentRecord[]> {
    const rows = await this.prisma.investment.findMany({
      where: { userId, ...(includeArchived ? {} : { archivedAt: null }), ...(kind ? { kind } : {}) },
      include: withPrice,
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    });
    return rows.map(map);
  }

  async find(userId: string, id: string): Promise<InvestmentRecord> {
    const row = await this.prisma.investment.findFirst({ where: { id, userId }, include: withPrice });
    if (!row) throw new InvestmentError('INVESTMENT_NOT_FOUND');
    return map(row);
  }

  /**
   * Creates a position, optionally with its first buy (BE-P4-E03). A new clientId whose kind, name, currency and unit match an
   * active divisible position adds the buy to that position instead of opening a second one with the same name.
   */
  create(userId: string, input: InvestmentCreateInput) {
    validateName(input.name);
    validateNote(input.note);
    validateUnit(input.kind, input.unit);
    validateDepositTerms(input.kind, input);
    if (input.initialTrade) validateNote(input.initialTrade.note);
    return this.write(userId, async tx => {
      const existing = await tx.investment.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } }, include: withPrice });
      if (existing) {
        const same = existing.kind === input.kind && existing.name === input.name.trim() && existing.currencyCode.trim() === input.currencyCode &&
          existing.unit === input.unit;
        if (!same) throw new InvestmentError('INVESTMENT_CONFLICT');
        return { investment: map(existing), created: false };
      }
      const currency = await tx.currency.findUnique({ where: { code: input.currencyCode }, select: { code: true } });
      if (!currency) throw new InvestmentError('VALIDATION_ERROR');
      if (input.initialTrade && !isSingleItem(input.kind)) {
        const candidates = await tx.investment.findMany({
          where: { userId, kind: input.kind, currencyCode: input.currencyCode, unit: input.unit, archivedAt: null },
          orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        });
        const target = candidates.find(candidate => sameName(candidate.name, input.name));
        if (target) {
          await this.lock(tx, userId, target.id);
          return this.addTrade(tx, userId, target.id, { ...input.initialTrade, side: 'buy' });
        }
      }
      const row = await tx.investment.create({
        data: {
          userId,
          clientId: input.clientId,
          kind: input.kind,
          name: input.name.trim(),
          currencyCode: input.currencyCode,
          unit: input.unit,
          quantity: '0',
          costBasisMinor: 0n,
          interestRateBps: input.interestRateBps,
          startDate: input.startDate ? toDate(input.startDate) : null,
          maturityDate: input.maturityDate ? toDate(input.maturityDate) : null,
          note: input.note,
        },
        include: withPrice,
      });
      await tx.auditEvent.create({ data: audit(userId, row.id) });
      if (input.initialTrade) return this.addTrade(tx, userId, row.id, { ...input.initialTrade, side: 'buy' });
      return { investment: map(row), created: true };
    });
  }

  update(userId: string, id: string, patch: InvestmentPatch) {
    if (patch.name !== undefined) validateName(patch.name);
    if (patch.note !== undefined) validateNote(patch.note);
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      if (row.version !== patch.version) throw new InvestmentError('INVESTMENT_CONFLICT');
      if (patch.maturityDate !== undefined) {
        if (row.kind !== 'savings_deposit') throw new InvestmentError('VALIDATION_ERROR');
        validateDepositTerms(row.kind, { interestRateBps: row.interestRateBps, startDate: optionalDay(row.startDate), maturityDate: patch.maturityDate });
      }
      const updated = await tx.investment.update({
        where: { id },
        data: {
          ...(patch.name === undefined ? {} : { name: patch.name.trim() }),
          ...(patch.note === undefined ? {} : { note: patch.note }),
          ...(patch.maturityDate === undefined ? {} : { maturityDate: patch.maturityDate ? toDate(patch.maturityDate) : null }),
          version: { increment: 1 },
        },
        include: withPrice,
      });
      return map(updated);
    });
  }

  /** Only an empty position can be archived: archiving a held one would drop it from net worth while the wallet already paid for it. */
  archive(userId: string, id: string, version: number): Promise<void> {
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      if (row.version !== version || !row.quantity.isZero()) throw new InvestmentError('INVESTMENT_CONFLICT');
      await tx.investment.update({ where: { id }, data: { archivedAt: new Date(), version: { increment: 1 } } });
    });
  }

  trade(userId: string, id: string, input: InvestmentTradeInput) {
    validateNote(input.note);
    return this.write(userId, async tx => {
      await this.lock(tx, userId, id);
      return this.addTrade(tx, userId, id, input);
    });
  }

  /** Edits one buy and its wallet leg, then replays the position (BE-P4-E03). Sells are not editable. */
  updateTrade(userId: string, id: string, tradeId: string, patch: InvestmentTradePatch) {
    if (patch.note !== undefined) validateNote(patch.note);
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      if (row.version !== patch.version) throw new InvestmentError('INVESTMENT_CONFLICT');
      const trade = await tx.investmentTrade.findFirst({ where: { id: tradeId, investmentId: id, userId } });
      if (!trade) throw new InvestmentError('INVESTMENT_NOT_FOUND');
      if (trade.side !== 'buy') throw new InvestmentError('INVESTMENT_UNSUPPORTED');
      const quantityScaled = patch.quantityScaled ?? quantityOf(trade.quantity);
      if (isSingleItem(row.kind) && quantityScaled !== quantityOf(trade.quantity)) throw new InvestmentError('VALIDATION_ERROR');
      const amountMinor = patch.amountMinor !== undefined || patch.priceMinor !== undefined
        ? resolveAmount(quantityScaled, patch.amountMinor ?? null, patch.priceMinor ?? null)
        : trade.amountMinor;
      const accountId = patch.accountId === undefined ? trade.accountId : patch.accountId;
      const tradedOn = patch.tradedOn ?? dayOf(trade.tradedOn);
      if (accountId !== null) await this.walletFor(tx, userId, accountId, row.currencyCode);
      const legId = trade.transactionClientId ?? legClientId(trade.clientId);
      await this.moveLeg(tx, userId, legId, trade.accountId, accountId, row.currencyCode.trim(), -amountMinor, tradedOn);
      await tx.investmentTrade.update({
        where: { id: tradeId },
        data: {
          quantity: formatQuantity(quantityScaled),
          amountMinor,
          accountId,
          transactionClientId: accountId === null ? null : legId,
          tradedOn: toDate(tradedOn),
          ...(patch.note === undefined ? {} : { note: patch.note }),
        },
      });
      await this.rebuild(tx, row);
      return this.reload(tx, id);
    });
  }

  /** Removes one buy and gives its money back to the wallet; the last trade takes the position with it. */
  deleteTrade(userId: string, id: string, tradeId: string, version: number) {
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      if (row.version !== version) throw new InvestmentError('INVESTMENT_CONFLICT');
      const trade = await tx.investmentTrade.findFirst({ where: { id: tradeId, investmentId: id, userId } });
      if (!trade) throw new InvestmentError('INVESTMENT_NOT_FOUND');
      if (trade.side !== 'buy') throw new InvestmentError('INVESTMENT_UNSUPPORTED');
      if (trade.transactionClientId) {
        await this.moveLeg(tx, userId, trade.transactionClientId, trade.accountId, null, row.currencyCode.trim(), 0n, dayOf(trade.tradedOn));
      }
      await tx.investmentTrade.delete({ where: { id: tradeId } });
      if (await tx.investmentTrade.count({ where: { investmentId: id } }) === 0) {
        await tx.investment.delete({ where: { id } });
        return null;
      }
      await this.rebuild(tx, row);
      return this.reload(tx, id);
    });
  }

  async trades(userId: string, id: string): Promise<InvestmentTradeRecord[]> {
    await this.find(userId, id);
    const rows = await this.prisma.investmentTrade.findMany({
      where: { investmentId: id, userId },
      orderBy: [{ tradedOn: 'desc' }, { createdAt: 'desc' }, { id: 'desc' }],
    });
    return rows.map(row => ({
      id: row.id,
      clientId: row.clientId,
      side: row.side,
      quantityScaled: quantityOf(row.quantity),
      amountMinor: row.amountMinor,
      realizedMinor: row.realizedMinor,
      accountId: row.accountId,
      tradedOn: dayOf(row.tradedOn),
      note: row.note,
      createdAt: row.createdAt,
    }));
  }

  addPrice(userId: string, id: string, input: InvestmentPriceInput) {
    if (input.priceMinor < 0n) throw new InvestmentError('VALIDATION_ERROR');
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      if (row.kind === 'savings_deposit') throw new InvestmentError('INVESTMENT_UNSUPPORTED');
      const prior = await tx.investmentPrice.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } } });
      if (prior) {
        if (prior.investmentId !== id || prior.priceMinor !== input.priceMinor) throw new InvestmentError('INVESTMENT_CONFLICT');
        return { investment: await this.reload(tx, id), created: false };
      }
      await tx.investmentPrice.create({
        data: { investmentId: id, userId, clientId: input.clientId, priceMinor: input.priceMinor, source: 'manual', quotedAt: input.quotedAt },
      });
      await tx.investment.update({ where: { id }, data: { version: { increment: 1 } } });
      return { investment: await this.reload(tx, id), created: true };
    });
  }

  async prices(userId: string, id: string): Promise<InvestmentPriceRecord[]> {
    await this.find(userId, id);
    const rows = await this.prisma.investmentPrice.findMany({
      where: { investmentId: id, userId },
      orderBy: [{ quotedAt: 'desc' }, { createdAt: 'desc' }, { id: 'asc' }],
    });
    return rows.map(row => ({ id: row.id, clientId: row.clientId, priceMinor: row.priceMinor, source: row.source, quotedAt: row.quotedAt }));
  }

  /**
   * Books one trade on a locked position: wallet leg (unless already owned), the trade row, the trade's unit price as the
   * latest quote when it moved money, then a full replay. Retrying the same clientId returns the position unchanged.
   */
  private async addTrade(tx: Prisma.TransactionClient, userId: string, id: string, input: InvestmentTradeInput) {
    const row = await tx.investment.findUniqueOrThrow({ where: { id } });
    if (input.quantityScaled <= 0n) throw new InvestmentError('VALIDATION_ERROR');
    const amountMinor = resolveAmount(input.quantityScaled, input.amountMinor, input.priceMinor);
    const prior = await tx.investmentTrade.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } } });
    if (prior) {
      const same = prior.investmentId === id && prior.side === input.side && prior.amountMinor === amountMinor &&
        quantityOf(prior.quantity) === input.quantityScaled && prior.accountId === input.accountId;
      if (!same) throw new InvestmentError('INVESTMENT_CONFLICT');
      return { investment: await this.reload(tx, id), created: false };
    }
    if (input.accountId === null && input.side !== 'buy') throw new InvestmentError('VALIDATION_ERROR');
    if (input.accountId !== null) await this.walletFor(tx, userId, input.accountId, row.currencyCode);
    const held = quantityOf(row.quantity);
    validateTradeQuantity(row.kind, input.side, input.quantityScaled, held);
    if (isSingleItem(row.kind) && input.side === 'sell' && input.quantityScaled !== held) throw new InvestmentError('VALIDATION_ERROR');
    const legId = input.accountId === null ? null : legClientId(input.clientId);
    if (legId !== null && input.accountId !== null) {
      await this.book(tx, userId, legId, input.accountId, row.currencyCode.trim(), tradeLegMinor(input.side, amountMinor), input.tradedOn);
    }
    await tx.investmentTrade.create({
      data: {
        investmentId: id,
        userId,
        clientId: input.clientId,
        side: input.side,
        quantity: formatQuantity(input.quantityScaled),
        amountMinor,
        accountId: input.accountId,
        transactionClientId: legId,
        tradedOn: toDate(input.tradedOn),
        note: input.note,
      },
    });
    if (input.priceMinor !== null && input.accountId !== null && row.kind !== 'savings_deposit') {
      await tx.investmentPrice.create({
        data: {
          investmentId: id, userId, clientId: derivedId('price', input.clientId), priceMinor: input.priceMinor, source: 'trade',
          quotedAt: await this.quotedAt(tx, userId, input.tradedOn),
        },
      });
    }
    await this.rebuild(tx, row);
    return { investment: await this.reload(tx, id), created: true };
  }

  /** Replays every trade of the position and stores the result, including the realized gain of each sell. */
  private async rebuild(tx: Prisma.TransactionClient, row: Position) {
    const trades = await tx.investmentTrade.findMany({ where: { investmentId: row.id } });
    const { position, realizedById } = replayTrades(row.kind, trades.map(trade => ({
      id: trade.id, side: trade.side, quantityScaled: quantityOf(trade.quantity), amountMinor: trade.amountMinor,
      tradedOn: dayOf(trade.tradedOn), createdAt: trade.createdAt,
    })));
    for (const trade of trades) {
      const realized = realizedById.get(trade.id) ?? null;
      if (realized !== trade.realizedMinor) await tx.investmentTrade.update({ where: { id: trade.id }, data: { realizedMinor: realized } });
    }
    await tx.investment.update({
      where: { id: row.id },
      data: { quantity: formatQuantity(position.quantityScaled), costBasisMinor: position.costBasisMinor, version: { increment: 1 } },
    });
  }

  /** A trade from today is quoted now; one from an earlier day at noon UTC that day, so it never outranks a later quote. */
  private async quotedAt(tx: Prisma.TransactionClient, userId: string, tradedOn: string): Promise<Date> {
    const user = await tx.user.findUniqueOrThrow({ where: { id: userId }, select: { timezone: true } });
    const now = new Date();
    return tradedOn >= todayInTimeZone(user.timezone, now) ? now : new Date(`${tradedOn}T12:00:00.000Z`);
  }

  private async walletFor(tx: Prisma.TransactionClient, userId: string, accountId: string, currencyCode: string) {
    const account = await tx.financialAccount.findFirst({ where: { id: accountId, userId, archivedAt: null }, select: { currencyCode: true } });
    if (!account || account.currencyCode.trim() !== currencyCode.trim()) throw new InvestmentError('VALIDATION_ERROR');
  }

  /**
   * Points a buy's wallet leg at `toAccount` with `amountMinor` on `day`; null removes it (soft delete). A leg removed earlier
   * is brought back rather than created twice, since its clientId is derived from the trade.
   */
  private async moveLeg(
    tx: Prisma.TransactionClient, userId: string, legId: string, fromAccount: string | null, toAccount: string | null,
    currencyCode: string, amountMinor: bigint, day: string,
  ) {
    const leg = await tx.transaction.findFirst({ where: { userId, clientId: legId } });
    if (toAccount === null) {
      if (leg && !leg.deletedAt) {
        await tx.transaction.update({ where: { id: leg.id }, data: { deletedAt: new Date(), version: { increment: 1 } } });
      }
    } else if (leg) {
      await tx.transaction.update({
        where: { id: leg.id },
        data: { accountId: toAccount, amountMinor, currencyCode, occurredOn: toDate(day), deletedAt: null, version: { increment: 1 } },
      });
    } else {
      await this.book(tx, userId, legId, toAccount, currencyCode, amountMinor, day);
    }
    const touched = [fromAccount, toAccount].filter((value): value is string => value !== null);
    if (touched.length > 0) await tx.financialAccount.updateMany({ where: { userId, id: { in: touched } }, data: { updatedAt: new Date() } });
  }

  private async reload(tx: Prisma.TransactionClient, id: string): Promise<InvestmentRecord> {
    const row = await tx.investment.findUniqueOrThrow({ where: { id }, include: withPrice });
    return map(row);
  }

  private async book(
    tx: Prisma.TransactionClient, userId: string, legId: string, accountId: string, currencyCode: string, amountMinor: bigint, day: string,
  ) {
    const transaction: TransactionInput = {
      type: 'investment',
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
      await createTransactionInTx(tx, userId, transaction);
    } catch (error) {
      if (error instanceof TransactionError) {
        throw new InvestmentError(error.code === 'TRANSACTION_CONFLICT' ? 'INVESTMENT_CONFLICT' : 'VALIDATION_ERROR');
      }
      throw error;
    }
  }

  private async lock(tx: Prisma.TransactionClient, userId: string, id: string) {
    await tx.$queryRaw(Prisma.sql`SELECT id FROM "Investment" WHERE id = ${id}::uuid AND "userId" = ${userId}::uuid FOR UPDATE`);
    const row = await tx.investment.findFirst({ where: { id, userId, archivedAt: null } });
    if (!row) throw new InvestmentError('INVESTMENT_NOT_FOUND');
    return row;
  }
}
