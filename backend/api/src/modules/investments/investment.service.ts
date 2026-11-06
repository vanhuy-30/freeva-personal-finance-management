import { Inject, Injectable } from '@nestjs/common';
import { minor } from '../transactions/domain/transaction';
import {
  averageCostOf, formatQuantity, investmentTotals, kindTotals, lotValuation, parseQuantity, ratioBps, unitPriceOf, valuate, type InvestmentRecord,
} from './domain/investment';
import { INVESTMENT_REPOSITORY, type InvestmentContext, type InvestmentRepository, type InvestmentTradeMoney } from './domain/investment.repository';
import type {
  AddInvestmentPriceDto, CreateInvestmentDto, InitialTradeDto, TradeInvestmentDto, UpdateInvestmentDto, UpdateInvestmentTradeDto,
} from './investment.dto';

const text = (value: bigint) => value.toString();
const optionalText = (value: bigint | null) => (value === null ? null : value.toString());

function response(investment: InvestmentRecord, context: InvestmentContext) {
  const valuation = valuate(investment, context.today);
  const average = averageCostOf(investment);
  return {
    id: investment.id,
    clientId: investment.clientId,
    kind: investment.kind,
    name: investment.name,
    currencyCode: investment.currencyCode,
    unit: investment.unit,
    quantity: formatQuantity(investment.quantityScaled),
    costBasisMinor: text(investment.costBasisMinor),
    averageCostMinor: optionalText(average),
    currentValueMinor: text(valuation.currentValueMinor),
    unrealizedMinor: optionalText(valuation.unrealizedMinor),
    unrealizedBps: valuation.unrealizedMinor === null ? null : optionalText(ratioBps(valuation.unrealizedMinor, investment.costBasisMinor)),
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

function money(dto: InitialTradeDto | TradeInvestmentDto): InvestmentTradeMoney {
  return {
    clientId: dto.clientId,
    quantityScaled: parseQuantity(dto.quantity),
    amountMinor: dto.amountMinor === undefined ? null : minor(dto.amountMinor),
    priceMinor: dto.priceMinor === undefined ? null : minor(dto.priceMinor),
    accountId: dto.accountId,
    tradedOn: dto.tradedOn,
    note: dto.note ?? null,
  };
}

@Injectable()
export class InvestmentService {
  constructor(@Inject(INVESTMENT_REPOSITORY) private readonly repository: InvestmentRepository) {}

  async list(userId: string, includeArchived = false, kind?: InvestmentRecord['kind']) {
    const [items, context] = await Promise.all([this.repository.list(userId, includeArchived, kind), this.repository.context(userId)]);
    return { items: items.map(item => response(item, context)) };
  }

  async find(userId: string, id: string) {
    const [item, context] = await Promise.all([this.repository.find(userId, id), this.repository.context(userId)]);
    return response(item, context);
  }

  /**
   * Cost, current value and unrealized gain per currency, and the same per kind with its share of the currency total.
   * Realized gain is per trade, never mixed into income or expense.
   */
  async summary(userId: string) {
    const [items, context] = await Promise.all([this.repository.list(userId, false), this.repository.context(userId)]);
    const valued = items.map(investment => ({ investment, valuation: valuate(investment, context.today) }));
    return {
      totals: investmentTotals(valued).map(row => ({
        currencyCode: row.currencyCode,
        costBasisMinor: text(row.costBasisMinor),
        currentValueMinor: text(row.currentValueMinor),
        unrealizedMinor: text(row.unrealizedMinor),
        unrealizedBps: optionalText(row.unrealizedBps),
        unpricedCount: row.unpricedCount,
      })),
      byKind: kindTotals(valued).map(row => ({
        kind: row.kind,
        currencyCode: row.currencyCode,
        investmentCount: row.investmentCount,
        costBasisMinor: text(row.costBasisMinor),
        currentValueMinor: text(row.currentValueMinor),
        unrealizedMinor: text(row.unrealizedMinor),
        unrealizedBps: optionalText(row.unrealizedBps),
        unpricedCount: row.unpricedCount,
        shareBps: optionalText(row.shareBps),
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
      initialTrade: dto.initialTrade ? money(dto.initialTrade) : null,
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
    const result = await this.repository.trade(userId, id, { ...money(dto), side: dto.side });
    return { investment: response(result.investment, await this.repository.context(userId)), created: result.created };
  }

  async updateTrade(userId: string, id: string, tradeId: string, dto: UpdateInvestmentTradeDto) {
    const item = await this.repository.updateTrade(userId, id, tradeId, {
      version: dto.version,
      ...(dto.quantity === undefined ? {} : { quantityScaled: parseQuantity(dto.quantity) }),
      ...(dto.amountMinor === undefined ? {} : { amountMinor: minor(dto.amountMinor) }),
      ...(dto.priceMinor === undefined ? {} : { priceMinor: minor(dto.priceMinor) }),
      ...(dto.accountId === undefined ? {} : { accountId: dto.accountId }),
      ...(dto.tradedOn === undefined ? {} : { tradedOn: dto.tradedOn }),
      ...(dto.note === undefined ? {} : { note: dto.note }),
    });
    return response(item, await this.repository.context(userId));
  }

  /** Null when the deleted buy was the last trade and the position went with it. */
  async deleteTrade(userId: string, id: string, tradeId: string, version: number) {
    const item = await this.repository.deleteTrade(userId, id, tradeId, version);
    return item === null ? null : response(item, await this.repository.context(userId));
  }

  async trades(userId: string, id: string) {
    const [investment, items] = await Promise.all([this.repository.find(userId, id), this.repository.trades(userId, id)]);
    return {
      items: items.map(item => {
        const lot = item.side === 'buy' ? lotValuation(investment, item.quantityScaled, item.amountMinor) : null;
        return {
          id: item.id,
          clientId: item.clientId,
          side: item.side,
          quantity: formatQuantity(item.quantityScaled),
          amountMinor: text(item.amountMinor),
          unitPriceMinor: text(unitPriceOf(item.amountMinor, item.quantityScaled)),
          realizedMinor: optionalText(item.realizedMinor),
          accountId: item.accountId,
          tradedOn: item.tradedOn,
          note: item.note,
          currentValueMinor: lot ? text(lot.currentValueMinor) : null,
          unrealizedMinor: lot ? text(lot.unrealizedMinor) : null,
          unrealizedBps: lot ? optionalText(lot.unrealizedBps) : null,
          createdAt: item.createdAt.toISOString(),
        };
      }),
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
