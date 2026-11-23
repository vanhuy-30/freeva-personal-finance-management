import { parseQuantity } from '../../investments/domain/investment';
import { asOfDay, buildHoldings, buildInvestmentValueHistory, buildNetWorthHistory, debtOutstandingOn, investmentValueOn, loanOutstandingOn, type HoldingsSource, type InvestmentHistory, type LoanHistory, type NetWorthHistorySource } from './net-worth-history';

const q = parseQuantity;
const gold = (over: Partial<InvestmentHistory> = {}): InvestmentHistory => ({
  kind: 'gold', currency: 'VND', unit: 'chi', interestRateBps: null, startDate: null, maturityDate: null,
  trades: [
    { id: 't1', side: 'buy', quantityScaled: q('10'), amountMinor: 70_000_000n, tradedOn: '2026-09-10', createdAt: new Date('2026-09-10T01:00:00Z') },
    { id: 't2', side: 'sell', quantityScaled: q('4'), amountMinor: 32_000_000n, tradedOn: '2026-11-02', createdAt: new Date('2026-11-02T01:00:00Z') },
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
    const all = gold({ trades: [...gold().trades, { id: 't3', side: 'sell', quantityScaled: q('6'), amountMinor: 49_000_000n, tradedOn: '2026-11-04', createdAt: new Date('2026-11-04T01:00:00Z') }] });
    expect(investmentValueOn(all, '2026-11-05')).toBe(0n);
  });
  it('counts a deposit at principal only, whatever the day', () => {
    const deposit = gold({ kind: 'savings_deposit', unit: 'deposit', interestRateBps: 1200, startDate: '2026-01-01', maturityDate: null,
      trades: [{ id: 't4', side: 'buy', quantityScaled: q('1'), amountMinor: 100_000_000n, tradedOn: '2026-01-01', createdAt: new Date('2026-01-01T01:00:00Z') }], prices: [] });
    expect(investmentValueOn(deposit, '2027-01-01')).toBe(100_000_000n);
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
    loans: [],
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
    const empty = buildNetWorthHistory('7d', { buckets: [{ from: '2026-11-06', to: '2026-11-06' }], today: '2026-11-06', wallets: [], debts: [], loans: [], investments: [] });
    expect(empty.points).toEqual([{ from: '2026-11-06', to: '2026-11-06', asOf: '2026-11-06', items: [] }]);
  });
});

describe('loanOutstandingOn', () => {
  const loan: LoanHistory = { currency: 'VND', startDate: '2026-09-15', outstandingMinor: 180_000_000n,
    payments: [{ paidOn: '2026-10-25', principalMinor: 10_000_000n }, { paidOn: '2026-11-05', principalMinor: 10_000_000n }] };
  it.each([['2026-09-14', 0n], ['2026-09-30', 200_000_000n], ['2026-10-31', 190_000_000n], ['2026-11-06', 180_000_000n]])(
    'on %s', (day, expected) => expect(loanOutstandingOn(loan, day)).toBe(expected));
});

describe('buildNetWorthHistory with a loan', () => {
  it('adds the loan as a liability from its start day', () => {
    const result = buildNetWorthHistory('3m', {
      buckets: [{ from: '2026-09-01', to: '2026-09-10' }, { from: '2026-10-01', to: '2026-10-31' }],
      today: '2026-11-06',
      wallets: [{ index: 0, currency: 'VND', bucket: 'asset', total: 50_000_000n }, { index: 1, currency: 'VND', bucket: 'asset', total: 50_000_000n }],
      debts: [],
      loans: [{ currency: 'VND', startDate: '2026-09-15', outstandingMinor: 180_000_000n, payments: [{ paidOn: '2026-11-05', principalMinor: 10_000_000n }] }],
      investments: [],
    });
    expect(result.points.map(point => point.items[0]!.liabilitiesMinor)).toEqual(['0', '-190000000']);
    expect(result.points[1]!.items[0]!.netWorthMinor).toBe('-140000000');
  });
});

describe('buildInvestmentValueHistory', () => {
  it('values the chosen positions at the end of each bucket', () => {
    const result = buildInvestmentValueHistory('3m', {
      buckets: [{ from: '2026-09-01', to: '2026-09-30' }, { from: '2026-10-01', to: '2026-10-31' }, { from: '2026-11-01', to: '2026-11-30' }],
      today: '2026-11-06',
      investments: [gold()],
    });
    expect(result.points.map(point => [point.asOf, point.items])).toEqual([
      ['2026-09-30', [{ currency: 'VND', valueMinor: '75000000' }]],
      ['2026-10-31', [{ currency: 'VND', valueMinor: '80000000' }]],
      ['2026-11-06', [{ currency: 'VND', valueMinor: '48000000' }]],
    ]);
  });
  it('leaves a bucket empty before the first trade', () => {
    const result = buildInvestmentValueHistory('7d', { buckets: [{ from: '2026-09-01', to: '2026-09-01' }], today: '2026-11-06', investments: [gold()] });
    expect(result.points[0]!.items).toEqual([]);
  });
});

describe('buildHoldings', () => {
  const period = { kind: 'month' as const, from: '2026-11-01', to: '2026-11-30', timezone: 'Asia/Ho_Chi_Minh', fiscalMonthStartDay: 1 };
  const source = (over: Partial<HoldingsSource> = {}): HoldingsSource => ({
    period, startDay: '2026-10-31', endDay: '2026-11-21', wallets: [], debts: [], loans: [], cardPayments: [], loanDues: [], investments: [], ...over,
  });

  it('is empty for someone with no debt and no investment', () => {
    expect(buildHoldings(source())).toEqual({
      period: { kind: 'month', from: '2026-11-01', to: '2026-11-30' }, debt: [], investments: [], nextLoanDue: [],
    });
  });

  it('adds loans, borrowed money and card debt, and tells paid from newly borrowed', () => {
    const loan: LoanHistory = { currency: 'VND', startDate: '2026-01-01', outstandingMinor: 90_000_000n, payments: [{ paidOn: '2026-11-05', principalMinor: 10_000_000n }] };
    const borrowed = { currency: 'VND', direction: 'borrowed' as const, principalMinor: 5_000_000n, occurredOn: '2026-11-10', payments: [{ paidOn: '2026-11-15', amountMinor: 1_000_000n }] };
    const lent = { currency: 'VND', direction: 'lent' as const, principalMinor: 7_000_000n, occurredOn: '2026-10-01', payments: [] };
    const result = buildHoldings(source({
      loans: [loan],
      debts: [borrowed, lent],
      wallets: [
        { index: 0, currency: 'VND', bucket: 'liability', total: -8_000_000n },
        { index: 1, currency: 'VND', bucket: 'liability', total: -9_000_000n },
        { index: 0, currency: 'VND', bucket: 'asset', total: 50_000_000n },
      ],
      cardPayments: [{ currency: 'VND', total: 2_000_000n }],
    }));
    // start 100m loan + 0 + 8m card; end 90m + 4m + 9m; paid 10m + 1m + 2m card; new = -5m + 13m.
    expect(result.debt).toEqual([{
      currency: 'VND', startMinor: '108000000', endMinor: '103000000', changeMinor: '-5000000', paidMinor: '13000000', borrowedMinor: '8000000',
    }]);
  });

  it('does not count a card surplus or a settled loan as debt, and drops currencies with nothing', () => {
    const settled: LoanHistory = { currency: 'USD', startDate: '2026-01-01', outstandingMinor: 0n, payments: [{ paidOn: '2025-12-01', principalMinor: 0n }] };
    const result = buildHoldings(source({
      loans: [settled],
      wallets: [{ index: 1, currency: 'VND', bucket: 'liability', total: 500_000n }],
    }));
    expect(result.debt).toEqual([]);
  });

  it('reads the loan debt before and after a payment made on the start or end day', () => {
    const loan: LoanHistory = { currency: 'VND', startDate: '2026-01-01', outstandingMinor: 90_000_000n,
      payments: [{ paidOn: '2026-10-31', principalMinor: 3_000_000n }, { paidOn: '2026-11-21', principalMinor: 4_000_000n }] };
    const [debt] = buildHoldings(source({ loans: [loan] })).debt;
    // The payment on the start day is before the period; the one on the end day is inside it.
    expect(debt).toMatchObject({ startMinor: '94000000', endMinor: '90000000', paidMinor: '4000000', borrowedMinor: '0' });
  });

  it('gives the gain or loss of the period: value change minus money put in plus money taken out', () => {
    const [flat] = buildHoldings(source({ investments: [gold()] })).investments;
    // 10 x 8m = 80m at the start; 4 chi sold for 32m on 02/11 leaves 6 x 8m = 48m: nothing gained or lost.
    expect(flat).toEqual({
      currency: 'VND', startValueMinor: '80000000', endValueMinor: '48000000', investedMinor: '0', withdrawnMinor: '32000000',
      pnlMinor: '0', pnlBps: 0,
    });
    const more = gold({
      trades: [
        ...gold().trades,
        { id: 't3', side: 'buy', quantityScaled: q('2'), amountMinor: 16_400_000n, tradedOn: '2026-11-10', createdAt: new Date('2026-11-10T01:00:00Z') },
      ],
    });
    const [lost] = buildHoldings(source({ investments: [more] })).investments;
    // 8 x 8m = 64m at the end; 64 - 80 - 16.4 + 32 = -0.4m, on 96.4m at stake.
    expect(lost).toMatchObject({ endValueMinor: '64000000', investedMinor: '16400000', pnlMinor: '-400000', pnlBps: -41 });
  });

  it('has no rate before anything was invested, and counts money put in during the period as invested', () => {
    const fresh = gold({ trades: [{ id: 'n1', side: 'buy', quantityScaled: q('1'), amountMinor: 7_000_000n, tradedOn: '2026-11-03', createdAt: new Date('2026-11-03T01:00:00Z') }] });
    const [first] = buildHoldings(source({ investments: [fresh] })).investments;
    expect(first).toMatchObject({ startValueMinor: '0', investedMinor: '7000000', endValueMinor: '8000000', pnlMinor: '1000000', pnlBps: 1428 });
    const none = gold({ trades: [] });
    expect(buildHoldings(source({ investments: [none] })).investments).toEqual([]);
  });

  it('lists the soonest loan installment per currency', () => {
    const result = buildHoldings(source({
      loanDues: [{ currency: 'VND', dueOn: '2026-12-05', amountMinor: 5_200_000n }, { currency: 'USD', dueOn: '2026-12-01', amountMinor: null }],
    }));
    expect(result.nextLoanDue).toEqual([
      { currency: 'USD', dueOn: '2026-12-01', amountMinor: null },
      { currency: 'VND', dueOn: '2026-12-05', amountMinor: '5200000' },
    ]);
  });
});
