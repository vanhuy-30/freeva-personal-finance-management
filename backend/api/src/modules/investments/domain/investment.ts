export const INVESTMENT_KINDS = ['gold', 'stock', 'fund', 'savings_deposit', 'real_estate', 'crypto'] as const;
export type InvestmentKind = (typeof INVESTMENT_KINDS)[number];
export const INVESTMENT_SIDES = ['buy', 'sell'] as const;
export type InvestmentSide = (typeof INVESTMENT_SIDES)[number];

export type InvestmentErrorCode =
  | 'VALIDATION_ERROR' | 'INVESTMENT_NOT_FOUND' | 'INVESTMENT_CONFLICT' | 'INVESTMENT_OVERSELL' | 'INVESTMENT_UNSUPPORTED';

export class InvestmentError extends Error {
  constructor(readonly code: InvestmentErrorCode) {
    super(code);
    this.name = 'InvestmentError';
  }
}

/** Quantity has up to 8 decimals; it is held as an integer count of 1e-8 units so no float ever touches it. */
export const QUANTITY_SCALE = 100_000_000n;
const QUANTITY_DECIMALS = 8;
const MAX_QUANTITY = 10n ** 20n;

/** Units a kind may use. Gold is tracked in chi or luong (1 luong = 10 chi), never mixed in one position. */
export const INVESTMENT_UNITS: Record<InvestmentKind, readonly string[]> = {
  gold: ['chi', 'luong'],
  stock: ['share'],
  fund: ['unit'],
  savings_deposit: ['deposit'],
  real_estate: ['property'],
  crypto: ['coin'],
};

/** Kinds that always hold exactly one indivisible item. */
const SINGLE_ITEM: ReadonlySet<InvestmentKind> = new Set(['savings_deposit', 'real_estate']);

export const isSingleItem = (kind: InvestmentKind) => SINGLE_ITEM.has(kind);

/** "0.5" -> 50_000_000n. Rejects signs, exponents and more than 8 decimals. */
export function parseQuantity(value: string): bigint {
  const match = /^(\d{1,20})(?:\.(\d{1,8}))?(?![\s\S])/.exec(value);
  if (!match) throw new InvestmentError('VALIDATION_ERROR');
  const whole = BigInt(match[1]!) * QUANTITY_SCALE;
  const fraction = BigInt((match[2] ?? '').padEnd(QUANTITY_DECIMALS, '0'));
  const scaled = whole + fraction;
  if (scaled > MAX_QUANTITY) throw new InvestmentError('VALIDATION_ERROR');
  return scaled;
}

/** 50_000_000n -> "0.5"; whole numbers carry no decimal point. */
export function formatQuantity(scaled: bigint): string {
  const whole = scaled / QUANTITY_SCALE;
  const fraction = (scaled % QUANTITY_SCALE).toString().padStart(QUANTITY_DECIMALS, '0').replace(/0+$/, '');
  return fraction ? `${whole}.${fraction}` : whole.toString();
}

/** Divide non-negative integers rounding half up. */
export function divRoundHalfUp(numerator: bigint, denominator: bigint): bigint {
  if (denominator <= 0n || numerator < 0n) throw new InvestmentError('VALIDATION_ERROR');
  return (numerator * 2n + denominator) / (denominator * 2n);
}

/** Current value = quantity x price per unit, rounded half up to a minor unit. */
export function valueOf(quantityScaled: bigint, priceMinor: bigint): bigint {
  return divRoundHalfUp(quantityScaled * priceMinor, QUANTITY_SCALE);
}

export type Position = { quantityScaled: bigint; costBasisMinor: bigint };

export function applyBuy(position: Position, quantityScaled: bigint, amountMinor: bigint): Position {
  if (quantityScaled <= 0n || amountMinor <= 0n) throw new InvestmentError('VALIDATION_ERROR');
  return { quantityScaled: position.quantityScaled + quantityScaled, costBasisMinor: position.costBasisMinor + amountMinor };
}

export type SellResult = { position: Position; costRemovedMinor: bigint; realizedMinor: bigint };

/**
 * Weighted-average cost. The cost removed is `costBasis x sold / held` rounded half up; selling everything removes all of it,
 * so the position never keeps a leftover cent. Selling more than held is an error, never a silent clamp.
 */
export function applySell(position: Position, quantityScaled: bigint, proceedsMinor: bigint): SellResult {
  if (quantityScaled <= 0n || proceedsMinor <= 0n) throw new InvestmentError('VALIDATION_ERROR');
  if (quantityScaled > position.quantityScaled) throw new InvestmentError('INVESTMENT_OVERSELL');
  const all = quantityScaled === position.quantityScaled;
  const costRemovedMinor = all ? position.costBasisMinor : divRoundHalfUp(position.costBasisMinor * quantityScaled, position.quantityScaled);
  return {
    position: { quantityScaled: position.quantityScaled - quantityScaled, costBasisMinor: position.costBasisMinor - costRemovedMinor },
    costRemovedMinor,
    realizedMinor: proceedsMinor - costRemovedMinor,
  };
}

const MS_PER_DAY = 86_400_000;

/** Whole days from `from` to `to` (YYYY-MM-DD), never negative. */
export function daysBetween(from: string, to: string): number {
  const days = Math.round((Date.parse(`${to}T00:00:00Z`) - Date.parse(`${from}T00:00:00Z`)) / MS_PER_DAY);
  return days > 0 ? days : 0;
}

/** Simple interest: `principal x rateBps x days / (10000 x 365)`, half up. Accrues to maturity at most. */
export function depositInterest(principalMinor: bigint, rateBps: number, startDate: string, maturityDate: string | null, today: string): bigint {
  const end = maturityDate !== null && maturityDate < today ? maturityDate : today;
  const days = daysBetween(startDate, end);
  if (days === 0 || rateBps === 0 || principalMinor === 0n) return 0n;
  return divRoundHalfUp(principalMinor * BigInt(rateBps) * BigInt(days), 10_000n * 365n);
}

export type InvestmentRecord = {
  id: string;
  clientId: string;
  kind: InvestmentKind;
  name: string;
  currencyCode: string;
  unit: string;
  quantityScaled: bigint;
  costBasisMinor: bigint;
  interestRateBps: number | null;
  startDate: string | null;
  maturityDate: string | null;
  note: string | null;
  archivedAt: Date | null;
  version: number;
  createdAt: Date;
  updatedAt: Date;
  latestPrice: { priceMinor: bigint; source: string; quotedAt: Date } | null;
};

export type Valuation = {
  /** `price` = quantity x latest price; `deposit` = principal + accrued interest; `cost` = no price yet, falls back to cost. */
  basis: 'price' | 'deposit' | 'cost';
  currentValueMinor: bigint;
  unrealizedMinor: bigint | null;
};

export function valuate(investment: InvestmentRecord, today: string): Valuation {
  if (investment.kind === 'savings_deposit' && investment.startDate !== null) {
    if (investment.quantityScaled === 0n) return { basis: 'deposit', currentValueMinor: 0n, unrealizedMinor: 0n };
    const interest = depositInterest(investment.costBasisMinor, investment.interestRateBps ?? 0, investment.startDate, investment.maturityDate, today);
    return { basis: 'deposit', currentValueMinor: investment.costBasisMinor + interest, unrealizedMinor: interest };
  }
  if (investment.latestPrice === null) {
    return { basis: 'cost', currentValueMinor: investment.costBasisMinor, unrealizedMinor: null };
  }
  const currentValueMinor = valueOf(investment.quantityScaled, investment.latestPrice.priceMinor);
  return { basis: 'price', currentValueMinor, unrealizedMinor: currentValueMinor - investment.costBasisMinor };
}

export type InvestmentTotals = {
  currencyCode: string;
  costBasisMinor: bigint;
  currentValueMinor: bigint;
  unrealizedMinor: bigint;
  /** Positions with no price yet; their cost stands in for value and they add nothing to `unrealizedMinor`. */
  unpricedCount: number;
  /** Gain over the cost of priced positions only. */
  unrealizedBps: bigint | null;
};

export function investmentTotals(items: { investment: InvestmentRecord; valuation: Valuation }[]): InvestmentTotals[] {
  const totals = new Map<string, InvestmentTotals & { pricedCostMinor: bigint }>();
  for (const { investment, valuation } of items) {
    if (investment.quantityScaled === 0n) continue;
    const entry = totals.get(investment.currencyCode) ?? {
      currencyCode: investment.currencyCode, costBasisMinor: 0n, currentValueMinor: 0n, unrealizedMinor: 0n, unpricedCount: 0,
      unrealizedBps: null, pricedCostMinor: 0n,
    };
    entry.costBasisMinor += investment.costBasisMinor;
    entry.currentValueMinor += valuation.currentValueMinor;
    if (valuation.unrealizedMinor === null) entry.unpricedCount += 1;
    else {
      entry.unrealizedMinor += valuation.unrealizedMinor;
      entry.pricedCostMinor += investment.costBasisMinor;
    }
    totals.set(investment.currencyCode, entry);
  }
  return [...totals.values()]
    .map(({ pricedCostMinor, ...entry }) => ({ ...entry, unrealizedBps: ratioBps(entry.unrealizedMinor, pricedCostMinor) }))
    .sort((a, b) => a.currencyCode.localeCompare(b.currencyCode));
}

export function validateName(name: string): void {
  const length = name.trim().length;
  if (length < 1 || length > 80) throw new InvestmentError('VALIDATION_ERROR');
}

export function validateNote(note: string | null): void {
  if (note !== null && note.length > 500) throw new InvestmentError('VALIDATION_ERROR');
}

export function validateUnit(kind: InvestmentKind, unit: string): void {
  if (!INVESTMENT_UNITS[kind].includes(unit)) throw new InvestmentError('VALIDATION_ERROR');
}

/** Deposit terms are required for a deposit and forbidden on everything else. */
export function validateDepositTerms(
  kind: InvestmentKind, terms: { interestRateBps: number | null; startDate: string | null; maturityDate: string | null },
): void {
  if (kind !== 'savings_deposit') {
    if (terms.interestRateBps !== null || terms.startDate !== null || terms.maturityDate !== null) throw new InvestmentError('VALIDATION_ERROR');
    return;
  }
  if (terms.interestRateBps === null || terms.startDate === null) throw new InvestmentError('VALIDATION_ERROR');
  if (terms.interestRateBps < 0 || terms.interestRateBps > 100_000) throw new InvestmentError('VALIDATION_ERROR');
  if (terms.maturityDate !== null && terms.maturityDate < terms.startDate) throw new InvestmentError('VALIDATION_ERROR');
}

/** Indivisible kinds hold one item: a buy must be exactly 1, and only the first buy is allowed (ADR 014). */
export function validateTradeQuantity(kind: InvestmentKind, side: InvestmentSide, quantityScaled: bigint, heldScaled: bigint): void {
  if (!isSingleItem(kind)) return;
  if (quantityScaled !== QUANTITY_SCALE) throw new InvestmentError('VALIDATION_ERROR');
  if (side === 'buy' && heldScaled !== 0n) throw new InvestmentError('INVESTMENT_UNSUPPORTED');
}

/** The wallet loses money on a buy and gains it on a sell. */
export const tradeLegMinor = (side: InvestmentSide, amountMinor: bigint): bigint => (side === 'buy' ? -amountMinor : amountMinor);

/** `numerator / denominator` in basis points, rounded half away from zero; null when there is nothing to divide by. */
export function ratioBps(numerator: bigint, denominator: bigint): bigint | null {
  if (denominator <= 0n) return null;
  const magnitude = divRoundHalfUp((numerator < 0n ? -numerator : numerator) * 10_000n, denominator);
  return numerator < 0n ? -magnitude : magnitude;
}

/** Money for one unit implied by a trade: `amount / quantity`, half up. */
export const unitPriceOf = (amountMinor: bigint, quantityScaled: bigint): bigint => divRoundHalfUp(amountMinor * QUANTITY_SCALE, quantityScaled);

/** Average cost of one held unit; null when nothing is held. */
export const averageCostOf = (position: Position): bigint | null =>
  position.quantityScaled > 0n ? unitPriceOf(position.costBasisMinor, position.quantityScaled) : null;

export type ReplayTrade = { id: string; side: InvestmentSide; quantityScaled: bigint; amountMinor: bigint; tradedOn: string; createdAt: Date };

/** Order every trade is applied in, here and in the net worth history: trade day, then entry time, then id. */
export function tradeOrder(left: { tradedOn: string; createdAt: Date; id: string }, right: { tradedOn: string; createdAt: Date; id: string }): number {
  return left.tradedOn.localeCompare(right.tradedOn) || left.createdAt.getTime() - right.createdAt.getTime() || left.id.localeCompare(right.id);
}

/**
 * Rebuilds a position from all of its trades in trade order (BE-P4-E03). Run after every add, edit or delete so the position
 * and the realized gain of each sell always match history; a sell that would exceed what was held on its day is an error.
 */
export function replayTrades(kind: InvestmentKind, trades: ReplayTrade[]): { position: Position; realizedById: Map<string, bigint> } {
  let position: Position = { quantityScaled: 0n, costBasisMinor: 0n };
  const realizedById = new Map<string, bigint>();
  for (const trade of [...trades].sort(tradeOrder)) {
    validateTradeQuantity(kind, trade.side, trade.quantityScaled, position.quantityScaled);
    if (trade.side === 'buy') position = applyBuy(position, trade.quantityScaled, trade.amountMinor);
    else {
      if (isSingleItem(kind) && trade.quantityScaled !== position.quantityScaled) throw new InvestmentError('INVESTMENT_OVERSELL');
      const sale = applySell(position, trade.quantityScaled, trade.amountMinor);
      position = sale.position;
      realizedById.set(trade.id, sale.realizedMinor);
    }
  }
  return { position, realizedById };
}

/**
 * What one buy would be worth today at the position's latest price, for reference only: the position itself uses the
 * average cost. Null for deposits and for unpriced positions.
 */
export function lotValuation(investment: InvestmentRecord, quantityScaled: bigint, amountMinor: bigint) {
  if (investment.kind === 'savings_deposit' || investment.latestPrice === null) return null;
  const currentValueMinor = valueOf(quantityScaled, investment.latestPrice.priceMinor);
  const unrealizedMinor = currentValueMinor - amountMinor;
  return { currentValueMinor, unrealizedMinor, unrealizedBps: ratioBps(unrealizedMinor, amountMinor) };
}

export type KindTotals = {
  kind: InvestmentKind;
  currencyCode: string;
  investmentCount: number;
  costBasisMinor: bigint;
  currentValueMinor: bigint;
  unrealizedMinor: bigint;
  /** Gain over the cost of priced positions only. */
  unrealizedBps: bigint | null;
  unpricedCount: number;
  /** Share of the total current value held in this currency. */
  shareBps: bigint | null;
};

/** Held positions grouped by kind and currency, largest value first, with each group's share of its currency total. */
export function kindTotals(items: { investment: InvestmentRecord; valuation: Valuation }[]): KindTotals[] {
  const groups = new Map<string, KindTotals & { pricedCostMinor: bigint }>();
  const currencyValue = new Map<string, bigint>();
  for (const { investment, valuation } of items) {
    if (investment.quantityScaled === 0n) continue;
    const key = `${investment.currencyCode}|${investment.kind}`;
    const entry = groups.get(key) ?? {
      kind: investment.kind, currencyCode: investment.currencyCode, investmentCount: 0, costBasisMinor: 0n, currentValueMinor: 0n,
      unrealizedMinor: 0n, unrealizedBps: null, unpricedCount: 0, shareBps: null, pricedCostMinor: 0n,
    };
    entry.investmentCount += 1;
    entry.costBasisMinor += investment.costBasisMinor;
    entry.currentValueMinor += valuation.currentValueMinor;
    if (valuation.unrealizedMinor === null) entry.unpricedCount += 1;
    else {
      entry.unrealizedMinor += valuation.unrealizedMinor;
      entry.pricedCostMinor += investment.costBasisMinor;
    }
    groups.set(key, entry);
    currencyValue.set(investment.currencyCode, (currencyValue.get(investment.currencyCode) ?? 0n) + valuation.currentValueMinor);
  }
  return [...groups.values()]
    .map(({ pricedCostMinor, ...entry }) => ({
      ...entry,
      unrealizedBps: ratioBps(entry.unrealizedMinor, pricedCostMinor),
      shareBps: ratioBps(entry.currentValueMinor, currencyValue.get(entry.currencyCode) ?? 0n),
    }))
    .sort((a, b) => a.currencyCode.localeCompare(b.currencyCode) || (b.currentValueMinor > a.currentValueMinor ? 1 : b.currentValueMinor < a.currentValueMinor ? -1 : a.kind.localeCompare(b.kind)));
}

/** Money of a trade: the amount when given, else quantity x unit price (half up). One of the two is required. */
export function resolveAmount(quantityScaled: bigint, amountMinor: bigint | null, priceMinor: bigint | null): bigint {
  const amount = amountMinor ?? (priceMinor === null ? null : valueOf(quantityScaled, priceMinor));
  if (amount === null || amount <= 0n) throw new InvestmentError('VALIDATION_ERROR');
  return amount;
}
