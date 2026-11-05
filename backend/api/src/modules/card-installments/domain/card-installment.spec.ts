import {
  buildSchedule, CardInstallmentError, defaultInstallmentMinor, dueForRange, remainingPeriods, validatePlan,
  type CardInstallmentRecord,
} from './card-installment';

const plan = (over: Partial<CardInstallmentRecord> = {}): CardInstallmentRecord => ({
  id: 'p1', clientId: 'c1', transactionId: 't1', accountId: 'a1', currencyCode: 'VND',
  totalMinor: 12_000_000n, installmentMinor: 1_000_000n, installmentCount: 12, firstDueOn: '2026-12-15',
  status: 'active', closedAt: null, version: 1, createdAt: new Date(0), updatedAt: new Date(0), ...over,
});

describe('card installments', () => {
  it.each([
    [12_000_000n, 12], [10_000_000n, 3], [10n, 3], [1n, 2], [999_999_999_999n, 60], [7_000_001n, 7],
  ])('periods add up to the purchase price (%s over %s)', (total, count) => {
    const installment = defaultInstallmentMinor(total, count);
    if (total < BigInt(count)) return;
    validatePlan(total, count, installment, '2026-11-01', '2026-12-01');
    const periods = buildSchedule(plan({ totalMinor: total, installmentMinor: installment, installmentCount: count }));
    expect(periods).toHaveLength(count);
    expect(periods.reduce((sum, p) => sum + p.amountMinor, 0n)).toBe(total);
    expect(periods.every(p => p.amountMinor > 0n)).toBe(true);
  });

  it('gives the remainder to the last period', () => {
    const periods = buildSchedule(plan({ totalMinor: 10_000_000n, installmentMinor: 3_333_334n, installmentCount: 3 }));
    expect(periods.map(p => p.amountMinor)).toEqual([3_333_334n, 3_333_334n, 3_333_332n]);
  });

  it('rejects counts, amounts and dates that do not make a valid schedule', () => {
    const bad = (...args: Parameters<typeof validatePlan>) => expect(() => validatePlan(...args)).toThrow(CardInstallmentError);
    bad(1_000n, 1, 1_000n, '2026-11-01', '2026-12-01');
    bad(1_000n, 61, 100n, '2026-11-01', '2026-12-01');
    bad(1_000n, 4, 100n, '2026-11-01', '2026-12-01'); // would not reach the price
    bad(1_000n, 4, 500n, '2026-11-01', '2026-12-01'); // last period would be negative
    bad(1_000n, 4, 250n, '2026-11-02', '2026-11-01'); // first period before the purchase
    bad(1_000n, 4, 250n, '2026-11-01', '2026-02-30');
  });

  it('clamps the day of month in short months and returns to it afterwards', () => {
    const periods = buildSchedule(plan({ firstDueOn: '2027-01-31', installmentCount: 3, totalMinor: 3_000n, installmentMinor: 1_000n }));
    expect(periods.map(p => p.dueOn)).toEqual(['2027-01-31', '2027-02-28', '2027-03-31']);
  });

  it('lists only the periods still ahead, none once closed', () => {
    expect(remainingPeriods(plan(), '2027-03-15').map(p => p.index)).toEqual([4, 5, 6, 7, 8, 9, 10, 11, 12]);
    expect(remainingPeriods(plan({ status: 'closed' }), '2026-01-01')).toEqual([]);
  });

  it('sums what falls due per card in a range and skips closed plans', () => {
    const plans = [plan(), plan({ id: 'p2', accountId: 'a2', totalMinor: 600n, installmentMinor: 300n, installmentCount: 2, firstDueOn: '2026-12-20' }), plan({ id: 'p3', status: 'closed' })];
    expect(dueForRange(plans, '2026-12-01', '2026-12-31')).toEqual([
      { accountId: 'a1', currencyCode: 'VND', dueMinor: 1_000_000n, planCount: 1 },
      { accountId: 'a2', currencyCode: 'VND', dueMinor: 300n, planCount: 1 },
    ]);
    expect(dueForRange(plans, '2027-01-01', '2027-01-31')).toEqual([
      { accountId: 'a1', currencyCode: 'VND', dueMinor: 1_000_000n, planCount: 1 },
      { accountId: 'a2', currencyCode: 'VND', dueMinor: 300n, planCount: 1 },
    ]);
  });
});
