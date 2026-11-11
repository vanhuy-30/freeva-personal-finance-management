import type { InvestmentKind, InvestmentRecord, InvestmentSide } from './investment';

export const INVESTMENT_REPOSITORY = Symbol('INVESTMENT_REPOSITORY');

export type InvestmentCreateInput = {
  clientId: string;
  kind: InvestmentKind;
  name: string;
  currencyCode: string;
  unit: string;
  interestRateBps: number | null;
  startDate: string | null;
  maturityDate: string | null;
  note: string | null;
  /** First buy booked in the same commit (BE-P4-E03). */
  initialTrade: InvestmentTradeMoney | null;
};

export type InvestmentPatch = { version: number; name?: string; note?: string | null; maturityDate?: string | null };

/** One buy or sell. `amountMinor` wins over `priceMinor` (one unit); `accountId` null = already owned, buys only. */
export type InvestmentTradeMoney = {
  clientId: string;
  quantityScaled: bigint;
  amountMinor: bigint | null;
  priceMinor: bigint | null;
  accountId: string | null;
  tradedOn: string;
  note: string | null;
};

export type InvestmentTradeInput = InvestmentTradeMoney & { side: InvestmentSide };

/** Edit of one buy; `version` is the position's. Omitted fields keep their value. */
export type InvestmentTradePatch = {
  version: number;
  quantityScaled?: bigint;
  amountMinor?: bigint;
  priceMinor?: bigint;
  accountId?: string | null;
  tradedOn?: string;
  note?: string | null;
};

export type InvestmentTradeRecord = {
  id: string;
  clientId: string;
  side: InvestmentSide;
  quantityScaled: bigint;
  amountMinor: bigint;
  realizedMinor: bigint | null;
  accountId: string | null;
  tradedOn: string;
  note: string | null;
  createdAt: Date;
};

export type InvestmentPriceInput = { clientId: string; priceMinor: bigint; quotedAt: Date };

export type InvestmentPriceRecord = { id: string; clientId: string; priceMinor: bigint; source: string; quotedAt: Date };

export type InvestmentContext = { today: string };

export interface InvestmentRepository {
  context(userId: string): Promise<InvestmentContext>;
  list(userId: string, includeArchived: boolean, kind?: InvestmentKind): Promise<InvestmentRecord[]>;
  find(userId: string, id: string): Promise<InvestmentRecord>;
  create(userId: string, input: InvestmentCreateInput): Promise<{ investment: InvestmentRecord; created: boolean }>;
  update(userId: string, id: string, patch: InvestmentPatch): Promise<InvestmentRecord>;
  archive(userId: string, id: string, version: number): Promise<void>;
  trade(userId: string, id: string, input: InvestmentTradeInput): Promise<{ investment: InvestmentRecord; created: boolean }>;
  updateTrade(userId: string, id: string, tradeId: string, patch: InvestmentTradePatch): Promise<InvestmentRecord>;
  /** Returns null when the last trade went and the position was removed with it. */
  deleteTrade(userId: string, id: string, tradeId: string, version: number): Promise<InvestmentRecord | null>;
  trades(userId: string, id: string): Promise<InvestmentTradeRecord[]>;
  addPrice(userId: string, id: string, input: InvestmentPriceInput): Promise<{ investment: InvestmentRecord; created: boolean }>;
  prices(userId: string, id: string): Promise<InvestmentPriceRecord[]>;
}
