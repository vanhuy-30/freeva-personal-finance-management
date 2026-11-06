import { parseQuantity } from '../../investments/domain/investment';
import { asOfDay, buildNetWorthHistory, debtOutstandingOn, investmentValueOn, type InvestmentHistory, type NetWorthHistorySource } from './net-worth-history';

const q = parseQuantity;
const gold = (over: Partial<InvestmentHistory> = {}): InvestmentHistory => ({
  kind: 'gold', currency: 'VND', unit: 'chi', interestRateBps: null, startDate: null, maturityDate: null,
  trades: [
    { side: 'buy', quantityScaled: q('10'), amountMinor: 70_000_000n, tradedOn: '2026-09-10', createdAt: new Date('2026-09-10T01:00:00Z') },
    { side: 'sell', quantityScaled: q('4'), amountMinor: 32_000_000n, tradedOn: '2026-11-02', createdAt: new Date('2026-11-02T01:00:00Z') },
  ],
  prices: [
    { priceMinor: 7_500_000n, source: 'manual', quotedAt: new Date('2026-09-20T05:00:00Z'), quotedDay: '2026-09-20' },
    { priceMinor: 8_000_000n, source: 'manual', quotedAt: new Date('2026-10-20T05:00:00Z'), quotedDay: '2026-10-20' },
  ],
  ...over,
});

describe('asOfDay', () => {
  it('reads a future bucket as of today', () => {
    expect(asOfDay({ from: '2026-11-01', to: '2026-11-30' }, '2026-11-06')).toBe('2026-11-06');
    expect(asOfDay({ from: '2026-10-01', to: '2026-10-31' }, '2026-11-06')).toBe('2026-10-31');
  });
});

describe('debtOutstandingOn', () => {
  const debt = { currency: 'VND', direction: 'lent' as const, principalMinor: 3_000_000n, occurredOn: '2026-10-05',
    payments: [{ paidOn: '2026-10-20', amountMinor: 1_000_000n }, { paidOn: '2026-11-03', amountMinor: 2_000_000n }] };
  it.each([['2026-10-04', 0n], ['2026-10-05', 3_000_000n], ['2026-10-19', 3_000_000n], ['2026-10-20', 2_000_000n], ['2026-11-03', 0n]])(
    'on %s', (day, expected) => expect(debtOutstandingOn(debt, day)).toBe(expected));
});

describe('investmentValueOn', () => {
  it('is zero before the first buy', () => expect(investmentValueOn(gold(), '2026-09-09')).toBe(0n));
  it('falls back to cost until a price is quoted', () => expect(investmentValueOn(gold(), '2026-09-15')).toBe(70_000_000n));
  it('uses the latest price quoted by that day, not a later one', () => {
    expect(investmentValueOn(gold(), '2026-09-30')).toBe(75_000_000n); // 10 x 7.5m
    expect(investmentValueOn(gold(), '2026-10-31')).toBe(80_000_000n); // 10 x 8m
  });
  it('replays a partial sell', () => expect(investmentValueOn(gold(), '2026-11-05')).toBe(48_000_000n)); // 6 x 8m
  it('is zero once everything is sold', () => {
    const all = gold({ trades: [...gold().trades, { side: 'sell', quantityScaled: q('6'), amountMinor: 49_000_000n, tradedOn: '2026-11-04', createdAt: new Date('2026-11-04T01:00:00Z') }] });
    expect(investmentValueOn(all, '2026-11-05')).toBe(0n);
  });
  it('accrues deposit interest to the day', () => {
    const deposit = gold({ kind: 'savings_deposit', unit: 'deposit', interestRateBps: 1200, startDate: '2026-01-01', maturityDate: null,
      trades: [{ side: 'buy', quantityScaled: q('1'), amountMinor: 100_000_000n, tradedOn: '2026-01-01', createdAt: new Date('2026-01-01T01:00:00Z') }], prices: [] });
    expect(investmentValueOn(deposit, '2027-01-01')).toBe(112_000_000n);
  });
});

describe('buildNetWorthHistory', () => {
  const source: NetWorthHistorySource = {
    buckets: [{ from: '2026-09-01', to: '2026-09-30' }, { from: '2026-10-01', to: '2026-10-31' }, { from: '2026-11-01', to: '2026-11-30' }],
    today: '2026-11-06',
    wallets: [
      { index: 0, currency: 'VND', bucket: 'asset', total: 100_000_000n }, { index: 0, currency: 'VND', bucket: 'liability', total: -5_000_000n },
      { index: 1, currency: 'VND', bucket: 'asset', total: 60_000_000n }, { index: 1, currency: 'VND', bucket: 'liability', total: -5_000_000n },
      { index: 2, currency: 'VND', bucket: 'asset', total: 90_000_000n }, { index: 2, currency: 'VND', bucket: 'liability', total: -5_000_000n },
    ],
    debts: [{ currency: 'VND', direction: 'lent', principalMinor: 3_000_000n, occurredOn: '2026-10-05', payments: [] },
      { currency: 'VND', direction: 'borrowed', principalMinor: 2_000_000n, occurredOn: '2026-10-10', payments: [{ paidOn: '2026-11-02', amountMinor: 2_000_000n }] }],
    investments: [gold()],
  };
  const history = buildNetWorthHistory('3m', source);
  const net = (index: number) => history.points[index]!.items[0]!;

  it('values each bucket at its own end, the current one as of today', () => {
    expect(history.points.map(point => point.asOf)).toEqual(['2026-09-30', '2026-10-31', '2026-11-06']);
  });
  it('Sep: wallets + a position at its latest price', () => {
    // assets 100m + gold 75m, liabilities -5m
    expect(net(0)).toEqual({ currency: 'VND', assetsMinor: '175000000', liabilitiesMinor: '-5000000', netWorthMinor: '170000000' });
  });
  it('Oct: receivable asset, payable liability, repriced gold', () => {
    // assets 60m + 3m lent + gold 80m = 143m; liabilities -5m -2m
    expect(net(1)).toEqual({ currency: 'VND', assetsMinor: '143000000', liabilitiesMinor: '-7000000', netWorthMinor: '136000000' });
  });
  it('Nov: payable repaid, part of the gold sold', () => {
    // assets 90m + 3m + 6 chi x 8m = 141m; liabilities -5m
    expect(net(2)).toEqual({ currency: 'VND', assetsMinor: '141000000', liabilitiesMinor: '-5000000', netWorthMinor: '136000000' });
  });
  it('keeps currencies apart and survives an empty source', () => {
    const empty = buildNetWorthHistory('7d', { buckets: [{ from: '2026-11-06', to: '2026-11-06' }], today: '2026-11-06', wallets: [], debts: [], investments: [] });
    expect(empty.points).toEqual([{ from: '2026-11-06', to: '2026-11-06', asOf: '2026-11-06', items: [] }]);
  });
});
