import {
  applyBuy, applySell, averageCostOf, depositInterest, divRoundHalfUp, formatQuantity, InvestmentError, investmentTotals, kindTotals, lotValuation,
  parseQuantity, QUANTITY_SCALE, ratioBps, replayTrades, resolveAmount, tradeLegMinor, unitPriceOf, valuate, valueOf, validateDepositTerms,
  validateTradeQuantity, type InvestmentRecord, type ReplayTrade,
} from './investment';

const q = parseQuantity;
const record = (over: Partial<InvestmentRecord>): InvestmentRecord => ({
  id: 'i', clientId: 'c', kind: 'gold', name: 'SJC', currencyCode: 'VND', unit: 'chi', quantityScaled: q('10'), costBasisMinor: 70_000_000n,
  interestRateBps: null, startDate: null, maturityDate: null, note: null, archivedAt: null, version: 1, createdAt: new Date(0), updatedAt: new Date(0),
  latestPrice: null, ...over,
});

describe('quantity', () => {
  it('parses and formats exact decimals', () => {
    expect(q('0.00000001')).toBe(1n);
    expect(q('1.5')).toBe(150_000_000n);
    expect(formatQuantity(q('0.12345678'))).toBe('0.12345678');
    expect(formatQuantity(q('10'))).toBe('10');
    expect(formatQuantity(q('2.50'))).toBe('2.5');
  });
  it.each(['', '-1', '1e3', '1.123456789', '.5', '1,5', ' 1'])('rejects %p', value => {
    expect(() => q(value)).toThrow(InvestmentError);
  });
});

describe('rounding', () => {
  it('rounds half up', () => {
    expect(divRoundHalfUp(5n, 2n)).toBe(3n);
    expect(divRoundHalfUp(4n, 3n)).toBe(1n);
    expect(divRoundHalfUp(7n, 3n)).toBe(2n);
  });
});

describe('gold in chi and luong', () => {
  it('values 2 luong (20 chi) at the price per chi', () => {
    expect(valueOf(q('20'), 7_500_000n)).toBe(150_000_000n);
  });
  it('keeps 1 luong = 10 chi equivalence when the price is per luong', () => {
    // 1.5 luong at 75.000.000 per luong = 112.500.000
    expect(valueOf(q('1.5'), 75_000_000n)).toBe(112_500_000n);
  });
});

describe('crypto fractional quantity', () => {
  it('values 0.12345678 BTC at 2.500.000.000 per coin with half-up rounding', () => {
    // 0.12345678 x 2_500_000_000 = 308_641_950
    expect(valueOf(q('0.12345678'), 2_500_000_000n)).toBe(308_641_950n);
  });
  it('rounds a sub-minor remainder half up', () => {
    // 0.00000003 x 50_000_000 = 1.5 -> 2; 0.00000001 x 49_000_000 = 0.49 -> 0
    expect(valueOf(q('0.00000003'), 50_000_000n)).toBe(2n);
    expect(valueOf(q('0.00000001'), 49_000_000n)).toBe(0n);
  });
});

describe('buy -> add -> partial sell round trip', () => {
  it('tracks weighted-average cost and realized profit', () => {
    let position = { quantityScaled: 0n, costBasisMinor: 0n };
    position = applyBuy(position, q('10'), 70_000_000n); // 10 chi @ 7.000.000
    position = applyBuy(position, q('5'), 37_500_000n); // 5 chi @ 7.500.000
    expect(position).toEqual({ quantityScaled: q('15'), costBasisMinor: 107_500_000n });
    // sell 6 of 15 for 48.000.000: removed = 107.5m x 6/15 = 43.000.000
    const sale = applySell(position, q('6'), 48_000_000n);
    expect(sale.costRemovedMinor).toBe(43_000_000n);
    expect(sale.realizedMinor).toBe(5_000_000n);
    expect(sale.position).toEqual({ quantityScaled: q('9'), costBasisMinor: 64_500_000n });
  });
  it('removes the whole cost when selling everything, even with rounding remainders', () => {
    const position = { quantityScaled: q('3'), costBasisMinor: 100n };
    const first = applySell(position, q('1'), 40n); // 100 x 1/3 = 33.33 -> 33
    expect(first.costRemovedMinor).toBe(33n);
    const rest = applySell(first.position, q('2'), 80n);
    expect(rest.costRemovedMinor).toBe(67n);
    expect(rest.position).toEqual({ quantityScaled: 0n, costBasisMinor: 0n });
    expect(first.realizedMinor + rest.realizedMinor).toBe(120n - 100n);
  });
  it('realizes a loss', () => {
    const sale = applySell({ quantityScaled: q('1'), costBasisMinor: 1_000n }, q('1'), 700n);
    expect(sale.realizedMinor).toBe(-300n);
  });
  it('refuses to sell more than held', () => {
    expect(() => applySell({ quantityScaled: q('1'), costBasisMinor: 10n }, q('1.00000001'), 10n)).toThrow('INVESTMENT_OVERSELL');
  });
});

describe('savings deposit interest', () => {
  it('100.000.000 at 12%/year for 365 days is 12.000.000', () => {
    expect(depositInterest(100_000_000n, 1200, '2026-01-01', null, '2027-01-01')).toBe(12_000_000n);
  });
  it('100.000.000 at 12% for 30 days rounds half up', () => {
    // 100m x 1200 x 30 / 3_650_000 = 986_301.37 -> 986_301
    expect(depositInterest(100_000_000n, 1200, '2026-01-01', null, '2026-01-31')).toBe(986_301n);
  });
  it('stops accruing at maturity', () => {
    expect(depositInterest(100_000_000n, 1200, '2026-01-01', '2026-07-01', '2030-01-01'))
      .toBe(depositInterest(100_000_000n, 1200, '2026-01-01', null, '2026-07-01'));
  });
  it('is zero before the start date', () => {
    expect(depositInterest(100_000_000n, 1200, '2026-06-01', null, '2026-01-01')).toBe(0n);
  });
});

describe('valuation', () => {
  it('uses the latest price', () => {
    const v = valuate(record({ latestPrice: { priceMinor: 8_000_000n, source: 'manual', quotedAt: new Date(0) } }), '2026-11-06');
    expect(v).toEqual({ basis: 'price', currentValueMinor: 80_000_000n, unrealizedMinor: 10_000_000n });
  });
  it('falls back to cost with no price', () => {
    expect(valuate(record({}), '2026-11-06')).toEqual({ basis: 'cost', currentValueMinor: 70_000_000n, unrealizedMinor: null });
  });
  it('values a deposit as principal plus accrued interest', () => {
    const v = valuate(record({ kind: 'savings_deposit', unit: 'deposit', quantityScaled: QUANTITY_SCALE, costBasisMinor: 100_000_000n,
      interestRateBps: 1200, startDate: '2026-01-01', maturityDate: null }), '2027-01-01');
    expect(v).toEqual({ basis: 'deposit', currentValueMinor: 112_000_000n, unrealizedMinor: 12_000_000n });
  });
  it('sums totals per currency and counts unpriced positions', () => {
    const priced = record({ latestPrice: { priceMinor: 8_000_000n, source: 'manual', quotedAt: new Date(0) } });
    const unpriced = record({ id: 'u', costBasisMinor: 5n });
    const totals = investmentTotals([priced, unpriced].map(investment => ({ investment, valuation: valuate(investment, '2026-11-06') })));
    expect(totals).toEqual([{ currencyCode: 'VND', costBasisMinor: 70_000_005n, currentValueMinor: 80_000_005n, unrealizedMinor: 10_000_000n, unpricedCount: 1, unrealizedBps: 1429n }]);
  });
  it('ignores sold-out positions in totals', () => {
    const empty = record({ quantityScaled: 0n, costBasisMinor: 0n });
    expect(investmentTotals([{ investment: empty, valuation: valuate(empty, '2026-11-06') }])).toEqual([]);
  });
});

describe('rules', () => {
  it('buy is a negative wallet leg and sell positive', () => {
    expect(tradeLegMinor('buy', 5n)).toBe(-5n);
    expect(tradeLegMinor('sell', 5n)).toBe(5n);
  });
  it('indivisible kinds need quantity 1 and a single buy', () => {
    expect(() => validateTradeQuantity('real_estate', 'buy', q('2'), 0n)).toThrow('VALIDATION_ERROR');
    expect(() => validateTradeQuantity('savings_deposit', 'buy', q('1'), q('1'))).toThrow('INVESTMENT_UNSUPPORTED');
    expect(() => validateTradeQuantity('crypto', 'buy', q('0.5'), q('1'))).not.toThrow();
  });
  it('requires deposit terms only for deposits', () => {
    expect(() => validateDepositTerms('savings_deposit', { interestRateBps: null, startDate: null, maturityDate: null })).toThrow();
    expect(() => validateDepositTerms('gold', { interestRateBps: 100, startDate: null, maturityDate: null })).toThrow();
    expect(() => validateDepositTerms('savings_deposit', { interestRateBps: 600, startDate: '2026-01-01', maturityDate: '2026-12-31' })).not.toThrow();
    expect(() => validateDepositTerms('savings_deposit', { interestRateBps: 600, startDate: '2026-01-01', maturityDate: '2025-12-31' })).toThrow();
  });
});

describe('BE-P4-E03 helpers', () => {
  it('ratioBps rounds half away from zero and needs a positive base', () => {
    expect(ratioBps(5_000_000n, 35_000_000n)).toBe(1429n);
    expect(ratioBps(-450_000n, 9_750_000n)).toBe(-462n);
    expect(ratioBps(0n, 10n)).toBe(0n);
    expect(ratioBps(1n, 20_000n)).toBe(1n);
    expect(ratioBps(-1n, 20_000n)).toBe(-1n);
    expect(ratioBps(5n, 0n)).toBeNull();
  });
  it('unit price and average cost round half up', () => {
    expect(unitPriceOf(35_000_000n, q('5'))).toBe(7_000_000n);
    expect(averageCostOf({ quantityScaled: q('7'), costBasisMinor: 50_000_000n })).toBe(7_142_857n);
    expect(averageCostOf({ quantityScaled: 0n, costBasisMinor: 0n })).toBeNull();
  });
  it('resolveAmount prefers the amount, else quantity x price', () => {
    expect(resolveAmount(q('3'), 21_600_000n, 1n)).toBe(21_600_000n);
    expect(resolveAmount(q('3'), null, 7_200_000n)).toBe(21_600_000n);
    expect(resolveAmount(q('0.5'), null, 3n)).toBe(2n);
    expect(() => resolveAmount(q('1'), null, null)).toThrow(InvestmentError);
    expect(() => resolveAmount(q('0.00000001'), null, 1n)).toThrow(InvestmentError);
  });
});

describe('replayTrades', () => {
  const at = (day: string, minute = 0) => new Date(`${day}T01:${String(minute).padStart(2, '0')}:00Z`);
  const t = (id: string, side: 'buy' | 'sell', qty: string, amount: bigint, day: string, minute = 0): ReplayTrade =>
    ({ id, side, quantityScaled: q(qty), amountMinor: amount, tradedOn: day, createdAt: at(day, minute) });

  it('applies trades in trade order, not entry order, and keeps realized per sell', () => {
    const { position, realizedById } = replayTrades('gold', [
      t('s1', 'sell', '6', 48_000_000n, '2026-10-14'),
      t('b2', 'buy', '5', 37_500_000n, '2026-09-25'),
      t('b1', 'buy', '10', 70_000_000n, '2026-09-10'),
    ]);
    expect(position).toEqual({ quantityScaled: q('9'), costBasisMinor: 64_500_000n });
    expect(realizedById.get('s1')).toBe(5_000_000n);
  });
  it('a backdated buy changes the realized gain of a later sell', () => {
    const before = replayTrades('gold', [t('b1', 'buy', '10', 70_000_000n, '2026-09-10'), t('s1', 'sell', '6', 48_000_000n, '2026-10-14')]);
    expect(before.realizedById.get('s1')).toBe(6_000_000n);
    const after = replayTrades('gold', [
      t('b1', 'buy', '10', 70_000_000n, '2026-09-10'), t('s1', 'sell', '6', 48_000_000n, '2026-10-14', 5),
      t('b0', 'buy', '5', 40_000_000n, '2026-09-01', 9),
    ]);
    expect(after.realizedById.get('s1')).toBe(48_000_000n - 44_000_000n);
  });
  it('removing a buy that a sell relied on is an oversell', () => {
    expect(() => replayTrades('gold', [t('b2', 'buy', '5', 37_500_000n, '2026-09-25'), t('s1', 'sell', '6', 48_000_000n, '2026-10-14')]))
      .toThrow(new InvestmentError('INVESTMENT_OVERSELL'));
  });
  it('same day uses entry time, then id', () => {
    const { realizedById } = replayTrades('stock', [
      t('s', 'sell', '1', 10n, '2026-01-01', 2), t('b', 'buy', '2', 10n, '2026-01-01', 1),
    ]);
    expect(realizedById.get('s')).toBe(5n);
  });
  it('indivisible kinds still allow one buy only', () => {
    expect(() => replayTrades('real_estate', [t('a', 'buy', '1', 5n, '2026-01-01'), t('b', 'buy', '1', 5n, '2026-01-02')]))
      .toThrow(new InvestmentError('INVESTMENT_UNSUPPORTED'));
  });
});

describe('lotValuation and kindTotals', () => {
  const priced = (over: Partial<InvestmentRecord>) => record({ latestPrice: { priceMinor: 8_000_000n, source: 'manual', quotedAt: new Date(0) }, ...over });

  it('values one buy at the latest price, for reference', () => {
    expect(lotValuation(priced({}), q('5'), 35_000_000n)).toEqual({ currentValueMinor: 40_000_000n, unrealizedMinor: 5_000_000n, unrealizedBps: 1429n });
    expect(lotValuation(record({}), q('5'), 35_000_000n)).toBeNull();
    expect(lotValuation(priced({ kind: 'savings_deposit', unit: 'deposit' }), q('1'), 5n)).toBeNull();
  });
  it('groups held positions per kind with shares of the currency total', () => {
    const items = [
      priced({ id: 'g1', quantityScaled: q('7'), costBasisMinor: 50_000_000n }),
      priced({ id: 'g2', quantityScaled: q('2'), costBasisMinor: 12_000_000n }),
      record({ id: 'c', kind: 'crypto', unit: 'coin', quantityScaled: q('0.5'), costBasisMinor: 38_500_000n }),
      record({ id: 'empty', kind: 'stock', unit: 'share', quantityScaled: 0n, costBasisMinor: 0n }),
    ].map(investment => ({ investment, valuation: valuate(investment, '2026-11-06') }));
    const rows = kindTotals(items);
    expect(rows.map(row => [row.kind, row.investmentCount, row.currentValueMinor, row.unrealizedBps, row.unpricedCount, row.shareBps])).toEqual([
      ['gold', 2, 72_000_000n, 1613n, 0, 6516n],
      ['crypto', 1, 38_500_000n, null, 1, 3484n],
    ]);
  });
});
