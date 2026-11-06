import { Inject, Injectable } from '@nestjs/common';
import { minor } from '../transactions/domain/transaction';
import { formatQuantity, investmentTotals, parseQuantity, valuate, type InvestmentRecord } from './domain/investment';
import { INVESTMENT_REPOSITORY, type InvestmentContext, type InvestmentRepository } from './domain/investment.repository';
import type { AddInvestmentPriceDto, CreateInvestmentDto, TradeInvestmentDto, UpdateInvestmentDto } from './investment.dto';

const text = (value: bigint) => value.toString();

function response(investment: InvestmentRecord, context: InvestmentContext) {
  const valuation = valuate(investment, context.today);
  return {
    id: investment.id,
    clientId: investment.clientId,
    kind: investment.kind,
    name: investment.name,
    currencyCode: investment.currencyCode,
    unit: investment.unit,
    quantity: formatQuantity(investment.quantityScaled),
    costBasisMinor: text(investment.costBasisMinor),
    currentValueMinor: text(valuation.currentValueMinor),
    unrealizedMinor: valuation.unrealizedMinor === null ? null : text(valuation.unrealizedMinor),
    valuationBasis: valuation.basis,
    latestPrice: investment.latestPrice
      ? { priceMinor: text(investment.latestPrice.priceMinor), source: investment.latestPrice.source, quotedAt: investment.latestPrice.quotedAt.toISOString() }
      : null,
    interestRateBps: investment.interestRateBps,
    startDate: investment.startDate,
    maturityDate: investment.maturityDate,
    note: investment.note,
    archivedAt: investment.archivedAt?.toISOString() ?? null,
    version: investment.version,
    createdAt: investment.createdAt.toISOString(),
    updatedAt: investment.updatedAt.toISOString(),
  };
}

@Injectable()
export class InvestmentService {
  constructor(@Inject(INVESTMENT_REPOSITORY) private readonly repository: InvestmentRepository) {}

  async list(userId: string, includeArchived = false) {
    const [items, context] = await Promise.all([this.repository.list(userId, includeArchived), this.repository.context(userId)]);
    return { items: items.map(item => response(item, context)) };
  }

  async find(userId: string, id: string) {
    const [item, context] = await Promise.all([this.repository.find(userId, id), this.repository.context(userId)]);
    return response(item, context);
  }

  /** Cost, current value and unrealized gain per currency. Realized gain is per trade, never mixed into income or expense. */
  async summary(userId: string) {
    const [items, context] = await Promise.all([this.repository.list(userId, false), this.repository.context(userId)]);
    return {
      totals: investmentTotals(items.map(investment => ({ investment, valuation: valuate(investment, context.today) }))).map(row => ({
        currencyCode: row.currencyCode,
        costBasisMinor: text(row.costBasisMinor),
        currentValueMinor: text(row.currentValueMinor),
        unrealizedMinor: text(row.unrealizedMinor),
        unpricedCount: row.unpricedCount,
      })),
    };
  }

  async create(userId: string, dto: CreateInvestmentDto) {
    const result = await this.repository.create(userId, {
      clientId: dto.clientId,
      kind: dto.kind,
      name: dto.name,
      currencyCode: dto.currencyCode,
      unit: dto.unit,
      interestRateBps: dto.interestRateBps ?? null,
      startDate: dto.startDate ?? null,
      maturityDate: dto.maturityDate ?? null,
      note: dto.note ?? null,
    });
    return { investment: response(result.investment, await this.repository.context(userId)), created: result.created };
  }

  async update(userId: string, id: string, dto: UpdateInvestmentDto) {
    const item = await this.repository.update(userId, id, { version: dto.version, name: dto.name, note: dto.note, maturityDate: dto.maturityDate });
    return response(item, await this.repository.context(userId));
  }

  archive(userId: string, id: string, version: number) {
    return this.repository.archive(userId, id, version);
  }

  async trade(userId: string, id: string, dto: TradeInvestmentDto) {
    const result = await this.repository.trade(userId, id, {
      clientId: dto.clientId,
      side: dto.side,
      quantityScaled: parseQuantity(dto.quantity),
      amountMinor: minor(dto.amountMinor),
      accountId: dto.accountId,
      tradedOn: dto.tradedOn,
    });
    return { investment: response(result.investment, await this.repository.context(userId)), created: result.created };
  }

  async trades(userId: string, id: string) {
    const items = await this.repository.trades(userId, id);
    return {
      items: items.map(item => ({
        id: item.id,
        clientId: item.clientId,
        side: item.side,
        quantity: formatQuantity(item.quantityScaled),
        amountMinor: text(item.amountMinor),
        realizedMinor: item.realizedMinor === null ? null : text(item.realizedMinor),
        accountId: item.accountId,
        tradedOn: item.tradedOn,
        createdAt: item.createdAt.toISOString(),
      })),
    };
  }

  async addPrice(userId: string, id: string, dto: AddInvestmentPriceDto) {
    const result = await this.repository.addPrice(userId, id, {
      clientId: dto.clientId,
      priceMinor: minor(dto.priceMinor),
      quotedAt: new Date(dto.quotedAt),
    });
    return { investment: response(result.investment, await this.repository.context(userId)), created: result.created };
  }

  async prices(userId: string, id: string) {
    const items = await this.repository.prices(userId, id);
    return {
      items: items.map(item => ({
        id: item.id, clientId: item.clientId, priceMinor: text(item.priceMinor), source: item.source, quotedAt: item.quotedAt.toISOString(),
      })),
    };
  }
}
