import { appConfigReaderFor } from '../app-config/testing';
import type { BudgetService } from '../budgets/budget.service';
import type { AutoSuggestPolicy } from '../category-suggestions/auto-suggest.policy';
import { balanceOutlook, dailySpend, goalForecast, spendForecast, type ForecastTransaction, type SpendInput } from './domain/spend-forecast';
import type { Outlook, SpendForecastRepository } from './domain/spend-forecast.repository';
import { SpendForecastService } from './spend-forecast.service';

const tx = (occurredOn: string, amount: number, categoryId: string | null = 'food', type: 'expense' | 'refund' = 'expense'): ForecastTransaction =>
  ({ type, amountMinor: BigInt(amount), categoryId, occurredOn });
const categories = [
  { id: 'food', name: 'Ăn uống', parentId: null, iconToken: 'food', colorToken: null },
  { id: 'coffee', name: 'Cà phê', parentId: 'food', iconToken: 'coffee', colorToken: null },
  { id: 'shop', name: 'Mua sắm', parentId: null, iconToken: 'shopping', colorToken: null },
  { id: 'car', name: 'Đi lại', parentId: null, iconToken: 'transport', colorToken: null },
  { id: 'home', name: 'Nhà ở', parentId: null, iconToken: 'housing', colorToken: null },
];
const settings = { minDays: 3, mediumRiskPercent: 90, highRiskPercent: 100 };
const base: SpendInput = {
  today: '2026-11-10', current: { from: '2026-11-01', to: '2026-11-30' }, previous: { from: '2026-10-01', to: '2026-10-31' },
  transactions: [], categories, budgetLimitMinor: 15_000_000n, settings,
};
// Board S.3: 5.400.000 after 10 days, budget 15.000.000.
const board = [tx('2026-11-02', 1_500_000, 'food'), tx('2026-11-04', 660_000, 'coffee'), tx('2026-11-06', 1_800_000, 'shop'),
  tx('2026-11-08', 620_000, 'car'), tx('2026-11-09', 820_000, 'home'), tx('2026-10-15', 11_480_000, 'food')];

describe('BE-P5-E06 spendForecast', () => {
  it('projects the daily pace to the month end and compares with the budget (board S.3)', () => {
    const result = spendForecast({ ...base, transactions: board });
    expect(result).toMatchObject({
      status: 'ok', daysElapsed: 10, daysInPeriod: 30, spentMinor: 5_400_000n, forecastMinor: 16_200_000n,
      dailyAverageMinor: 540_000n, risk: 'high', overBudgetMinor: 1_200_000n, dailyAllowanceMinor: 480_000n, previousMonthMinor: 11_480_000n,
    });
    expect(result.cumulative).toHaveLength(10);
    expect(result.cumulative[1]).toEqual({ date: '2026-11-02', spentMinor: 1_500_000n });
    expect(result.cumulative[9].spentMinor).toBe(5_400_000n);
    expect(result.topCategories.map(t => [t.category.name, t.spentMinor, t.sharePercent])).toEqual([
      ['Ăn uống', 2_160_000n, 40], ['Mua sắm', 1_800_000n, 33], ['Nhà ở', 820_000n, 15],
    ]);
  });

  it('grades risk against the thresholds and drops it without a budget', () => {
    const at = (limit: bigint) => spendForecast({ ...base, transactions: board, budgetLimitMinor: limit }).risk;
    expect(at(16_200_000n)).toBe('medium');
    expect(at(18_000_000n)).toBe('medium');
    expect(at(18_000_001n)).toBe('low');
    const none = spendForecast({ ...base, transactions: board, budgetLimitMinor: null });
    expect(none).toMatchObject({ risk: null, overBudgetMinor: null, dailyAllowanceMinor: null, budgetLimitMinor: null });
  });

  it('waits for the minimum days, nets refunds, and hides the allowance once over budget or on the last day', () => {
    expect(spendForecast({ ...base, today: '2026-11-02', transactions: board })).toMatchObject({ status: 'insufficient', forecastMinor: null, risk: null, daysElapsed: 2 });
    const refunded = spendForecast({ ...base, transactions: [...board, tx('2026-11-09', 400_000, 'shop', 'refund')] });
    expect(refunded.spentMinor).toBe(5_000_000n);
    expect(spendForecast({ ...base, transactions: board, budgetLimitMinor: 5_000_000n }).dailyAllowanceMinor).toBeNull();
    expect(spendForecast({ ...base, today: '2026-11-30', transactions: board }).dailyAllowanceMinor).toBeNull();
  });
});

describe('balance at the end of the month', () => {
  const outlookBase = { today: '2026-11-10', periodTo: '2026-11-30', balanceMinor: 10_000_000n, events: [], dailySpendMinor: 500_000n };

  it('takes recurring spending out of the day-to-day pace', () => {
    const recurringHome = board.map(row => (row.categoryId === 'home' ? { ...row, recurring: true } : row));
    expect(dailySpend({ ...base, transactions: board })).toBe(540_000n);
    expect(dailySpend({ ...base, transactions: recurringHome })).toBe(458_000n);
    expect(dailySpend({ ...base, transactions: [tx('2026-11-02', 100_000, 'shop', 'refund')] })).toBe(0n);
  });

  it('walks income, bills and the pace day by day to the last day', () => {
    const result = balanceOutlook({
      ...outlookBase,
      events: [{ date: '2026-11-25', amountMinor: 20_000_000n }, { date: '2026-11-15', amountMinor: -3_000_000n }],
    });
    // 20 days after today at 500.000 = 10.000.000 of day-to-day spending.
    expect(result).toMatchObject({
      incomeAheadMinor: 20_000_000n, billsAheadMinor: 3_000_000n, variableAheadMinor: 10_000_000n,
      endMinor: 17_000_000n, endLowMinor: 14_500_000n, endHighMinor: 19_500_000n, runsOutOn: null,
    });
  });

  it('names the first day the money runs out', () => {
    expect(balanceOutlook({ ...outlookBase, balanceMinor: 2_000_000n }).runsOutOn).toBe('2026-11-15');
    // Income that lands in time keeps the balance up.
    expect(balanceOutlook({ ...outlookBase, balanceMinor: 2_000_000n, events: [{ date: '2026-11-12', amountMinor: 9_000_000n }] }).runsOutOn).toBeNull();
  });

  it('shows only what is certain while the pace is unknown, and counts events dated today', () => {
    const result = balanceOutlook({ ...outlookBase, dailySpendMinor: null, events: [{ date: '2026-11-10', amountMinor: -1_000_000n }, { date: '2026-12-02', amountMinor: 5n }] });
    expect(result).toMatchObject({ variableAheadMinor: null, billsAheadMinor: 1_000_000n, incomeAheadMinor: 0n, endMinor: 9_000_000n, endLowMinor: 9_000_000n, endHighMinor: 9_000_000n });
  });
});

describe('BE-P5-E06 goalForecast', () => {
  const entries = [
    { kind: 'contribute' as const, amountMinor: 5_000_000n, occurredOn: '2026-08-01' },
    { kind: 'contribute' as const, amountMinor: 5_000_000n, occurredOn: '2026-09-01' },
    { kind: 'contribute' as const, amountMinor: 5_000_000n, occurredOn: '2026-10-01' },
  ];
  const goal = { today: '2026-11-10', targetMinor: 120_000_000n, currentMinor: 40_000_000n, targetDate: '2027-08-31', entries, months: 3 };

  it('uses completed months only and says how late the goal will be (board T.1)', () => {
    expect(goalForecast(goal)).toEqual({ status: 'ok', months: 3, averageMonthlyMinor: 5_000_000n, expectedMonth: '2028-02', targetMonth: '2027-08', monthsLate: 6 });
    const thisMonth = [...entries, { kind: 'contribute' as const, amountMinor: 9_000_000n, occurredOn: '2026-11-01' }];
    expect(goalForecast({ ...goal, entries: thisMonth })).toMatchObject({ averageMonthlyMinor: 5_000_000n });
  });

  it('counts withdrawals, handles early goals, no target date, reached and no data', () => {
    const withdrawn = [...entries, { kind: 'withdraw' as const, amountMinor: 3_000_000n, occurredOn: '2026-10-20' }];
    expect(goalForecast({ ...goal, entries: withdrawn })).toMatchObject({ averageMonthlyMinor: 4_000_000n, expectedMonth: '2028-06' });
    expect(goalForecast({ ...goal, targetDate: '2029-01-01' })).toMatchObject({ monthsLate: -11 });
    expect(goalForecast({ ...goal, targetDate: null })).toMatchObject({ targetMonth: null, monthsLate: null });
    expect(goalForecast({ ...goal, currentMinor: 120_000_000n })).toEqual({ status: 'reached' });
    expect(goalForecast({ ...goal, entries: [] })).toEqual({ status: 'insufficient', months: 3 });
    expect(goalForecast({ ...goal, entries: [{ kind: 'withdraw', amountMinor: 1n, occurredOn: '2026-10-01' }] })).toEqual({ status: 'insufficient', months: 3 });
  });
});

describe('BE-P5-E06 SpendForecastService', () => {
  const salary = { type: 'income', amountMinor: 20_000_000n, unit: 'month' as const, interval: 1, startDate: '2026-01-25', endDate: null, nextExecutionDate: '2026-11-25' };
  const repo = (
    goal: Awaited<ReturnType<SpendForecastRepository['goal']>> = null,
    outlook: Outlook = { walletCount: 2, balanceMinor: 10_000_000n, rules: [salary] },
  ): SpendForecastRepository => ({
    profile: jest.fn().mockResolvedValue({ timezone: 'Asia/Ho_Chi_Minh', fiscalMonthStartDay: 1, defaultCurrencyCode: 'VND' }),
    ledger: jest.fn().mockResolvedValue({ transactions: board, categories }),
    goal: jest.fn().mockResolvedValue(goal),
    outlook: jest.fn().mockResolvedValue(outlook),
  });
  const policy = (on: boolean) => ({ allows: jest.fn().mockResolvedValue(on) }) as unknown as AutoSuggestPolicy;
  const budgets = (budget: object | null) => ({ current: jest.fn().mockResolvedValue({ budget }) }) as unknown as BudgetService;
  const now = new Date('2026-11-10T03:00:00Z');

  it('returns null forecasts when off, without reading the ledger', async () => {
    const r = repo({ targetMinor: 2n, currentMinor: 1n, targetDate: null, entries: [] });
    const service = new SpendForecastService(r, policy(false), budgets(null), appConfigReaderFor());
    expect(await service.spending('u1', now)).toEqual({ currencyCode: 'VND', period: null, forecast: null });
    expect(r.ledger).not.toHaveBeenCalled();
    expect(await service.goal('u1', 'g1', now)).toEqual({ forecast: null });
  });

  it('reads from last month to today, uses only a profile-currency budget, and serialises money', async () => {
    const r = repo();
    const result = await new SpendForecastService(r, policy(true), budgets({ currencyCode: 'VND', limitMinor: '15000000' }), appConfigReaderFor()).spending('u1', now);
    expect(r.ledger).toHaveBeenCalledWith('u1', 'VND', '2026-10-01', '2026-11-10');
    expect(result.forecast).toMatchObject({ forecastMinor: '16200000', risk: 'high', dailyAllowanceMinor: '480000' });
    const usd = await new SpendForecastService(repo(), policy(true), budgets({ currencyCode: 'USD', limitMinor: '100' }), appConfigReaderFor()).spending('u1', now);
    expect(usd.forecast).toMatchObject({ risk: null, budgetLimitMinor: null });
  });

  it('adds the balance outlook: wallets, recurring income still to come and the daily pace', async () => {
    const result = await new SpendForecastService(repo(), policy(true), budgets(null), appConfigReaderFor()).spending('u1', now);
    // 540.000 a day for 20 more days = 10.800.000; 10.000.000 + 20.000.000 - 10.800.000.
    expect(result.forecast?.balance).toMatchObject({
      balanceMinor: '10000000', incomeAheadMinor: '20000000', billsAheadMinor: '0', dailySpendMinor: '540000',
      variableAheadMinor: '10800000', endMinor: '19200000', runsOutOn: null,
    });
    const none = await new SpendForecastService(repo(null, { walletCount: 0, balanceMinor: 0n, rules: [] }), policy(true), budgets(null), appConfigReaderFor()).spending('u1', now);
    expect(none.forecast?.balance).toBeNull();
  });

  it('404s for a goal that is not the user’s and reads entries since the averaging window', async () => {
    await expect(new SpendForecastService(repo(null), policy(true), budgets(null), appConfigReaderFor()).goal('u1', 'g1', now)).rejects.toThrow();
    const r = repo({ targetMinor: 120_000_000n, currentMinor: 40_000_000n, targetDate: '2027-08-31', entries: [] });
    expect(await new SpendForecastService(r, policy(true), budgets(null), appConfigReaderFor()).goal('u1', 'g1', now)).toEqual({ forecast: { status: 'insufficient', months: 3 } });
    expect(r.goal).toHaveBeenCalledWith('u1', 'g1', '2026-08-01');
  });
});
