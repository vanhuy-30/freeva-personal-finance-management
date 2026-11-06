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
};

export type InvestmentPatch = { version: number; name?: string; note?: string | null; maturityDate?: string | null };

export type InvestmentTradeInput = {
  clientId: string;
  side: InvestmentSide;
  quantityScaled: bigint;
  amountMinor: bigint;
  accountId: string;
  tradedOn: string;
};

export type InvestmentTradeRecord = {
  id: string;
  clientId: string;
  side: InvestmentSide;
  quantityScaled: bigint;
  amountMinor: bigint;
  realizedMinor: bigint | null;
  accountId: string;
  tradedOn: string;
  createdAt: Date;
};

export type InvestmentPriceInput = { clientId: string; priceMinor: bigint; quotedAt: Date };

export type InvestmentPriceRecord = { id: string; clientId: string; priceMinor: bigint; source: string; quotedAt: Date };

export type InvestmentContext = { today: string };

export interface InvestmentRepository {
  context(userId: string): Promise<InvestmentContext>;
  list(userId: string, includeArchived: boolean): Promise<InvestmentRecord[]>;
  find(userId: string, id: string): Promise<InvestmentRecord>;
  create(userId: string, input: InvestmentCreateInput): Promise<{ investment: InvestmentRecord; created: boolean }>;
  update(userId: string, id: string, patch: InvestmentPatch): Promise<InvestmentRecord>;
  archive(userId: string, id: string, version: number): Promise<void>;
  trade(userId: string, id: string, input: InvestmentTradeInput): Promise<{ investment: InvestmentRecord; created: boolean }>;
  trades(userId: string, id: string): Promise<InvestmentTradeRecord[]>;
  addPrice(userId: string, id: string, input: InvestmentPriceInput): Promise<{ investment: InvestmentRecord; created: boolean }>;
  prices(userId: string, id: string): Promise<InvestmentPriceRecord[]>;
}
