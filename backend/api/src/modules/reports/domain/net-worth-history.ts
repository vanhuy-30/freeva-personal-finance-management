import {
  applyBuy, applySell, valuate, type InvestmentKind, type InvestmentRecord, type InvestmentSide,
} from '../../investments/domain/investment';
import { buildNetWorth, type NetWorthAggregate, type SeriesWindow, type TrendBucket } from './report';

/** Wallet balances at the end of one bucket, per currency and side (credit wallets are liabilities). */
export type WalletBalanceRow = { index: number; currency: string; bucket: 'asset' | 'liability'; total: bigint };

export type DebtHistory = {
  currency: string;
  direction: 'lent' | 'borrowed';
  principalMinor: bigint;
  /** Calendar days YYYY-MM-DD. */
  occurredOn: string;
  payments: { paidOn: string; amountMinor: bigint }[];
};

export type InvestmentHistory = {
  kind: InvestmentKind;
  currency: string;
  unit: string;
  interestRateBps: number | null;
  startDate: string | null;
  maturityDate: string | null;
  trades: { side: InvestmentSide; quantityScaled: bigint; amountMinor: bigint; tradedOn: string; createdAt: Date }[];
  /** `quotedDay` is the quote's calendar day in the profile timezone. */
  prices: { priceMinor: bigint; source: string; quotedAt: Date; quotedDay: string }[];
};

export type NetWorthHistorySource = {
  buckets: TrendBucket[];
  /** Today in the profile timezone: a bucket that ends later is read as of today. */
  today: string;
  wallets: WalletBalanceRow[];
  debts: DebtHistory[];
  investments: InvestmentHistory[];
};

/** The day a bucket is valued at: its last day, but never later than today. */
export const asOfDay = (bucket: TrendBucket, today: string): string => (bucket.to < today ? bucket.to : today);

/** Open amount of a lend/borrow on `day`: nothing before it was made, then principal minus what was paid by then. */
export function debtOutstandingOn(debt: DebtHistory, day: string): bigint {
  if (debt.occurredOn > day) return 0n;
  const paid = debt.payments.filter(payment => payment.paidOn <= day).reduce((sum, payment) => sum + payment.amountMinor, 0n);
  return debt.principalMinor - paid;
}

/**
 * Replays the trades up to `day` in the order they were made (same weighted-average rules as the live ledger),
 * then values what is still held with the latest price quoted by that day. Unpriced positions count at cost.
 */
export function investmentValueOn(history: InvestmentHistory, day: string): bigint {
  let position = { quantityScaled: 0n, costBasisMinor: 0n };
  const trades = history.trades
    .filter(trade => trade.tradedOn <= day)
    .sort((left, right) => left.tradedOn.localeCompare(right.tradedOn) || left.createdAt.getTime() - right.createdAt.getTime());
  for (const trade of trades) {
    position = trade.side === 'buy'
      ? applyBuy(position, trade.quantityScaled, trade.amountMinor)
      : applySell(position, trade.quantityScaled, trade.amountMinor).position;
  }
  if (position.quantityScaled === 0n) return 0n;
  const price = history.prices
    .filter(item => item.quotedDay <= day)
    .sort((left, right) => right.quotedAt.getTime() - left.quotedAt.getTime())[0];
  const record: InvestmentRecord = {
    id: '', clientId: '', kind: history.kind, name: '', currencyCode: history.currency, unit: history.unit,
    quantityScaled: position.quantityScaled, costBasisMinor: position.costBasisMinor, interestRateBps: history.interestRateBps,
    startDate: history.startDate, maturityDate: history.maturityDate, note: null, archivedAt: null, version: 1,
    createdAt: new Date(0), updatedAt: new Date(0),
    latestPrice: price ? { priceMinor: price.priceMinor, source: price.source, quotedAt: price.quotedAt } : null,
  };
  return valuate(record, day).currentValueMinor;
}

/**
 * Net worth at the end of every bucket, oldest first. Same parts as the live `/net-worth`: active wallets, open lend/borrow
 * (receivable is an asset, payable a negative liability) and held investments. Money moved into an investment already left
 * the wallet, so adding the position's value counts it once.
 */
export function buildNetWorthHistory(window: SeriesWindow, source: NetWorthHistorySource) {
  return {
    window,
    points: source.buckets.map((bucket, index) => {
      const asOf = asOfDay(bucket, source.today);
      const rows: NetWorthAggregate[] = source.wallets.filter(row => row.index === index)
        .map(row => ({ currency: row.currency, bucket: row.bucket, total: row.total }));
      for (const debt of source.debts) {
        const open = debtOutstandingOn(debt, asOf);
        if (open <= 0n) continue;
        rows.push(debt.direction === 'lent'
          ? { currency: debt.currency, bucket: 'asset', total: open }
          : { currency: debt.currency, bucket: 'liability', total: -open });
      }
      for (const investment of source.investments) {
        const value = investmentValueOn(investment, asOf);
        if (value > 0n) rows.push({ currency: investment.currency, bucket: 'asset', total: value });
      }
      return { from: bucket.from, to: bucket.to, asOf, items: buildNetWorth(rows).items };
    }),
  };
}
