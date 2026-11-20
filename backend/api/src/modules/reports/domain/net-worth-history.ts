import {
  applyBuy, applySell, tradeOrder, valuate, type InvestmentKind, type InvestmentRecord, type InvestmentSide,
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

/** A loan that is not archived (MOB-P6-005). Outstanding today plus the principal paid after a day gives that day's debt. */
export type LoanHistory = {
  currency: string;
  /** Calendar days YYYY-MM-DD. */
  startDate: string;
  outstandingMinor: bigint;
  payments: { paidOn: string; principalMinor: bigint }[];
};

export type InvestmentHistory = {
  kind: InvestmentKind;
  currency: string;
  unit: string;
  interestRateBps: number | null;
  startDate: string | null;
  maturityDate: string | null;
  trades: { id: string; side: InvestmentSide; quantityScaled: bigint; amountMinor: bigint; tradedOn: string; createdAt: Date }[];
  /** `quotedDay` is the quote's calendar day in the profile timezone. */
  prices: { priceMinor: bigint; source: string; quotedAt: Date; quotedDay: string }[];
};

export type NetWorthHistorySource = {
  buckets: TrendBucket[];
  /** Today in the profile timezone: a bucket that ends later is read as of today. */
  today: string;
  wallets: WalletBalanceRow[];
  debts: DebtHistory[];
  loans: LoanHistory[];
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
 * Loan debt on `day`: nothing before it started, then today's outstanding plus the principal paid after `day`.
 * Hand corrections of the outstanding (audit events) are not replayed, so days before a correction use the corrected number.
 */
export function loanOutstandingOn(loan: LoanHistory, day: string): bigint {
  if (loan.startDate > day) return 0n;
  const paidLater = loan.payments.filter(payment => payment.paidOn > day).reduce((sum, payment) => sum + payment.principalMinor, 0n);
  return loan.outstandingMinor + paidLater;
}

/**
 * Replays the trades up to `day` in the order they were made (same weighted-average rules as the live ledger),
 * then values what is still held with the latest price quoted by that day. Unpriced positions count at cost.
 */
export function investmentValueOn(history: InvestmentHistory, day: string): bigint {
  let position = { quantityScaled: 0n, costBasisMinor: 0n };
  const trades = history.trades
    .filter(trade => trade.tradedOn <= day)
    .sort(tradeOrder);
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
 * (receivable is an asset, payable a negative liability), loans that are not archived (negative liability) and held investments. Money moved into an investment already left
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
      for (const loan of source.loans) {
        const open = loanOutstandingOn(loan, asOf);
        if (open > 0n) rows.push({ currency: loan.currency, bucket: 'liability', total: -open });
      }
      for (const investment of source.investments) {
        const value = investmentValueOn(investment, asOf);
        if (value > 0n) rows.push({ currency: investment.currency, bucket: 'asset', total: value });
      }
      return { from: bucket.from, to: bucket.to, asOf, items: buildNetWorth(rows).items };
    }),
  };
}

export type InvestmentValueHistorySource = { buckets: TrendBucket[]; today: string; investments: InvestmentHistory[] };

/**
 * Value of the chosen positions at the end of every bucket, oldest first, per currency (BE-P4-E03). Same replay and pricing
 * as the investment part of the net worth history, so the two lines agree.
 */
export function buildInvestmentValueHistory(window: SeriesWindow, source: InvestmentValueHistorySource) {
  return {
    window,
    points: source.buckets.map(bucket => {
      const asOf = asOfDay(bucket, source.today);
      const totals = new Map<string, bigint>();
      for (const investment of source.investments) {
        const value = investmentValueOn(investment, asOf);
        if (value > 0n) totals.set(investment.currency, (totals.get(investment.currency) ?? 0n) + value);
      }
      const items = [...totals.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([currency, valueMinor]) => ({ currency, valueMinor: valueMinor.toString() }));
      return { from: bucket.from, to: bucket.to, asOf, items };
    }),
  };
}
