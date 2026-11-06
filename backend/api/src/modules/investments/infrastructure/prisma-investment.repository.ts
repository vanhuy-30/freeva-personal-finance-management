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
  applyBuy, applySell, formatQuantity, InvestmentError, isSingleItem, parseQuantity, tradeLegMinor, validateDepositTerms, validateName, validateNote,
  validateTradeQuantity, validateUnit, type InvestmentRecord,
} from '../domain/investment';
import type {
  InvestmentContext, InvestmentCreateInput, InvestmentPatch, InvestmentPriceInput, InvestmentPriceRecord, InvestmentRepository,
  InvestmentTradeInput, InvestmentTradeRecord,
} from '../domain/investment.repository';

type Row = Prisma.InvestmentGetPayload<{ include: { prices: true } }>;

const dayOf = (value: Date) => value.toISOString().slice(0, 10);
const toDate = (value: string) => new Date(`${value}T00:00:00.000Z`);
const optionalDay = (value: Date | null) => (value ? dayOf(value) : null);
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
    quantityScaled: parseQuantity(row.quantity.toFixed(8)),
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

/** Deterministic UUID v4-shaped id so a retry replays the same wallet leg. */
function legClientId(clientId: string): string {
  const bytes = Buffer.from(createHash('sha256').update(`investment|trade|${clientId}`).digest().subarray(0, 16));
  bytes[6] = (bytes[6]! & 0x0f) | 0x40;
  bytes[8] = (bytes[8]! & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

const audit = (userId: string, investmentId: string) => ({
  actorType: 'user' as const,
  actorId: userId,
  action: 'investment.create' as const,
  targetType: 'investment',
  targetId: investmentId,
  outcome: 'success' as const,
});

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

  async list(userId: string, includeArchived: boolean): Promise<InvestmentRecord[]> {
    const rows = await this.prisma.investment.findMany({
      where: { userId, ...(includeArchived ? {} : { archivedAt: null }) },
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

  create(userId: string, input: InvestmentCreateInput) {
    validateName(input.name);
    validateNote(input.note);
    validateUnit(input.kind, input.unit);
    validateDepositTerms(input.kind, input);
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
    if (input.amountMinor <= 0n || input.quantityScaled <= 0n) throw new InvestmentError('VALIDATION_ERROR');
    return this.write(userId, async tx => {
      const row = await this.lock(tx, userId, id);
      const prior = await tx.investmentTrade.findUnique({ where: { userId_clientId: { userId, clientId: input.clientId } } });
      if (prior) {
        const same = prior.investmentId === id && prior.side === input.side && prior.amountMinor === input.amountMinor &&
          parseQuantity(prior.quantity.toFixed(8)) === input.quantityScaled && prior.accountId === input.accountId;
        if (!same) throw new InvestmentError('INVESTMENT_CONFLICT');
        return { investment: await this.reload(tx, id), created: false };
      }
      const account = await tx.financialAccount.findFirst({
        where: { id: input.accountId, userId, archivedAt: null },
        select: { currencyCode: true, type: true },
      });
      if (!account || account.currencyCode.trim() !== row.currencyCode.trim()) throw new InvestmentError('VALIDATION_ERROR');
      const held = parseQuantity(row.quantity.toFixed(8));
      validateTradeQuantity(row.kind, input.side, input.quantityScaled, held);
      if (isSingleItem(row.kind) && input.side === 'sell' && input.quantityScaled !== held) throw new InvestmentError('VALIDATION_ERROR');
      const position = { quantityScaled: held, costBasisMinor: row.costBasisMinor };
      let next = position;
      let realizedMinor: bigint | null = null;
      if (input.side === 'buy') next = applyBuy(position, input.quantityScaled, input.amountMinor);
      else {
        const sale = applySell(position, input.quantityScaled, input.amountMinor);
        next = sale.position;
        realizedMinor = sale.realizedMinor;
      }
      const legId = legClientId(input.clientId);
      await this.book(tx, userId, legId, input.accountId, row.currencyCode.trim(), tradeLegMinor(input.side, input.amountMinor), input.tradedOn);
      await tx.investmentTrade.create({
        data: {
          investmentId: id,
          userId,
          clientId: input.clientId,
          side: input.side,
          quantity: formatQuantity(input.quantityScaled),
          amountMinor: input.amountMinor,
          realizedMinor,
          accountId: input.accountId,
          transactionClientId: legId,
          tradedOn: toDate(input.tradedOn),
        },
      });
      await tx.investment.update({
        where: { id },
        data: { quantity: formatQuantity(next.quantityScaled), costBasisMinor: next.costBasisMinor, version: { increment: 1 } },
      });
      return { investment: await this.reload(tx, id), created: true };
    });
  }

  async trades(userId: string, id: string): Promise<InvestmentTradeRecord[]> {
    await this.find(userId, id);
    const rows = await this.prisma.investmentTrade.findMany({
      where: { investmentId: id, userId },
      orderBy: [{ tradedOn: 'desc' }, { createdAt: 'desc' }, { id: 'asc' }],
    });
    return rows.map(row => ({
      id: row.id,
      clientId: row.clientId,
      side: row.side,
      quantityScaled: parseQuantity(row.quantity.toFixed(8)),
      amountMinor: row.amountMinor,
      realizedMinor: row.realizedMinor,
      accountId: row.accountId,
      tradedOn: dayOf(row.tradedOn),
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
