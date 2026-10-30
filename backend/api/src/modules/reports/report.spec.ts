import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CashflowQueryDto, MonthReviewQueryDto, SeriesQueryDto } from './report.dto';
import { FxRateService } from '../fx-rates/fx-rate.service';
import { ReportService } from './report.service';
import type { ReportRepository } from './domain/report.repository';
import {
  buildCashflow, buildMonthReview, buildNetWorth, buildSeries, buildTrend, convertCashflow, convertNetWorth, expenseDeltaBps, previousPeriod, ReportError,
  resolvePeriod, savingsRateBps, seriesBuckets, todayInTimeZone, trendBuckets,
  type CashflowSource, type ReportProfile,
} from './domain/report';

const profile = (fiscalMonthStartDay = 1, timezone = 'Asia/Ho_Chi_Minh'): ReportProfile => ({ timezone, fiscalMonthStartDay });
const noRates = { rate: () => null, digits: () => 0 };
const day = (days: number) => new Date(Date.UTC(2020, 0, 1) + days * 86_400_000).toISOString().slice(0, 10);

describe('BE-P1-007 report periods', () => {
  it('uses Monday weeks and does not shift calendar dates through UTC', () => {
    expect(resolvePeriod({ period: 'week', on: '2024-01-01' }, profile())).toMatchObject({ from: '2024-01-01', to: '2024-01-07' });
    expect(resolvePeriod({ period: 'week', on: '2023-12-31' }, profile())).toMatchObject({ from: '2023-12-25', to: '2023-12-31' });
    expect(resolvePeriod({ period: 'week', on: '2024-02-29' }, profile())).toMatchObject({ from: '2024-02-26', to: '2024-03-03' });
    expect(resolvePeriod({ period: 'week', on: '2026-10-08' }, profile())).toMatchObject({ from: '2026-10-05', to: '2026-10-11' });
  });

  it('resolves fiscal months across month, year, and leap-day boundaries', () => {
    expect(resolvePeriod({ period: 'month', on: '2026-10-08' }, profile(15))).toMatchObject({ from: '2026-09-15', to: '2026-10-14', fiscalMonthStartDay: 15 });
    expect(resolvePeriod({ period: 'month', on: '2026-10-15' }, profile(15))).toMatchObject({ from: '2026-10-15', to: '2026-11-14' });
    expect(resolvePeriod({ period: 'month', on: '2026-10-08' }, profile(1))).toMatchObject({ from: '2026-10-01', to: '2026-10-31' });
    expect(resolvePeriod({ period: 'month', on: '2026-01-10' }, profile(28))).toMatchObject({ from: '2025-12-28', to: '2026-01-27' });
    expect(resolvePeriod({ period: 'month', on: '2026-01-28' }, profile(28))).toMatchObject({ from: '2026-01-28', to: '2026-02-27' });
    expect(resolvePeriod({ period: 'month', on: '2024-02-29' }, profile(1))).toMatchObject({ from: '2024-02-01', to: '2024-02-29' });
    expect(resolvePeriod({ period: 'month', on: '2024-02-29' }, profile(28))).toMatchObject({ from: '2024-02-28', to: '2024-03-27' });
  });

  it('defaults the anchor to the user timezone calendar date', () => {
    const evening = new Date('2026-10-08T17:30:00Z');
    const early = new Date('2026-10-08T03:00:00Z');
    expect(todayInTimeZone('Asia/Ho_Chi_Minh', evening)).toBe('2026-10-09');
    expect(todayInTimeZone('America/New_York', early)).toBe('2026-10-07');
    expect(resolvePeriod({ period: 'month' }, profile(1, 'Asia/Ho_Chi_Minh'), evening)).toMatchObject({ from: '2026-10-01', to: '2026-10-31' });
    expect(resolvePeriod({ period: 'week' }, profile(1, 'America/New_York'), early)).toMatchObject({ from: '2026-10-05', to: '2026-10-11', timezone: 'America/New_York' });
  });

  it('accepts an inclusive range up to 3660 days apart and rejects invalid bounds', () => {
    expect(resolvePeriod({ period: 'range', from: '2024-02-29', to: '2024-02-29' }, profile())).toMatchObject({ from: '2024-02-29', to: '2024-02-29' });
    expect(resolvePeriod({ period: 'range', from: day(0), to: day(3660) }, profile()).to).toBe(day(3660));
    for (const query of [
      { period: 'range' as const, from: day(0), to: day(3661) },
      { period: 'range' as const, from: '2026-10-02', to: '2026-10-01' },
      { period: 'range' as const, from: '2026-02-29', to: '2026-03-01' },
      { period: 'range' as const, from: '2026-04-31', to: '2026-05-01' },
      { period: 'range' as const, from: '2026-01-01' },
      { period: 'range' as const, from: '2026-01-01', to: '2026-01-02', on: '2026-01-01' },
      { period: 'week' as const, on: '2026-10-08', from: '2026-10-01' },
      { period: 'month' as const, on: '2026-02-29' },
      { period: 'month' as const, on: '0001-01-01' },
      { period: 'week' as const, to: '2026-10-11' },
    ]) expect(() => resolvePeriod(query, query.on === '0001-01-01' ? profile(15) : profile())).toThrow(ReportError);
    expect(() => resolvePeriod({ period: 'month', on: '2026-10-08' }, profile(29))).toThrow('Invalid fiscal month');
  });
});

describe('BE-P1-007 report totals', () => {
  const parent = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const child = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  const food = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  const cash = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
  const card = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
  const archived = 'ffffffff-ffff-4fff-8fff-ffffffffffff';
  const usd = '99999999-9999-4999-8999-999999999999';
  const period = resolvePeriod({ period: 'month', on: '2026-10-08' }, profile());
  const source = (): CashflowSource => ({
    categories: [
      { currency: 'VND', categoryId: child, parentId: parent, type: 'expense', total: -400n, count: 2 },
      { currency: 'VND', categoryId: null, parentId: null, type: 'income', total: 9007199254740993n, count: 1 },
      { currency: 'USD', categoryId: food, parentId: null, type: 'income', total: 2500n, count: 3 },
      { currency: 'USD', categoryId: food, parentId: null, type: 'expense', total: -500n, count: 1 },
    ],
    accounts: [
      { accountId: cash, currency: 'VND', archived: false },
      { accountId: card, currency: 'VND', archived: false },
      { accountId: archived, currency: 'VND', archived: true },
      { accountId: usd, currency: 'USD', archived: false },
    ],
    movements: [
      { accountId: cash, currency: 'VND', type: 'income', total: 9007199254740993n },
      { accountId: cash, currency: 'VND', type: 'transfer', total: -1500n },
      { accountId: card, currency: 'VND', type: 'expense', total: -400n },
      { accountId: card, currency: 'VND', type: 'transfer', total: 1500n },
      { accountId: archived, currency: 'VND', type: 'transfer', total: -20n },
      { accountId: usd, currency: 'USD', type: 'income', total: 2500n },
      { accountId: usd, currency: 'USD', type: 'expense', total: -500n },
    ],
  });

  it('keeps currencies separate, excludes transfers from cashflow, and does not roll categories up', () => {
    const report = buildCashflow(period, source());
    expect(report.totals).toEqual([
      { currency: 'USD', incomeMinor: '2500', expenseMinor: '-500', netMinor: '2000', savingsRateBps: 8000 },
      { currency: 'VND', incomeMinor: '9007199254740993', expenseMinor: '-400', netMinor: '9007199254740593', savingsRateBps: 9999 },
    ]);
    expect(report.byCategory.map(row => row.categoryId)).toEqual([food, child, null]);
    expect(report.byCategory.find(row => row.categoryId === child)).toEqual({
      categoryId: child, parentId: parent, currency: 'VND', incomeMinor: '0', expenseMinor: '-400', transactionCount: 2,
    });
    expect(report.byCategory.find(row => row.categoryId === food)?.transactionCount).toBe(4);
    expect(report.byCategory.find(row => row.categoryId === parent)).toBeUndefined();
    expect(report.byAccount.find(row => row.accountId === cash)).toMatchObject({ transferMinor: '-1500', netMinor: '9007199254739493' });
    expect(report.byAccount.find(row => row.accountId === card)?.netMinor).toBe('1100');
    expect(report.byAccount.find(row => row.accountId === archived)?.transferMinor).toBe('-20');
    expect(report.byAccount.find(row => row.accountId === usd)?.incomeMinor).toBe('2500');
    expect(report.totals).toHaveLength(2);
    expect(report.comparison.totals).toEqual([]);
    expect(report.comparison.expenseDeltaBps).toEqual([
      { currency: 'USD', deltaBps: null },
      { currency: 'VND', deltaBps: null },
    ]);
    expect(report.topMerchants).toEqual([]);
  });

  it('includes idle active accounts and omits archived accounts without period activity', () => {
    const idle = '12121212-1212-4121-8121-121212121212';
    const hidden = '34343434-3434-4343-8343-343434343434';
    const report = buildCashflow(period, { categories: [], accounts: [
      { accountId: idle, currency: 'VND', archived: false },
      { accountId: hidden, currency: 'USD', archived: true },
    ], movements: [] });
    expect(report.totals).toEqual([]);
    expect(report.byCategory).toEqual([]);
    expect(report.byAccount).toEqual([{
      accountId: idle, currency: 'VND', incomeMinor: '0', expenseMinor: '0', transferMinor: '0', netMinor: '0',
    }]);
  });

  it('keeps overdraft in assets and credit overpayment in liabilities', () => {
    expect(buildNetWorth([
      { currency: 'USD', bucket: 'asset', total: -150n },
      { currency: 'VND', bucket: 'asset', total: 9007199254740993n },
      { currency: 'VND', bucket: 'liability', total: -700n },
      { currency: 'EUR', bucket: 'liability', total: 40n },
    ]).items).toEqual([
      { currency: 'EUR', assetsMinor: '0', liabilitiesMinor: '40', netWorthMinor: '40' },
      { currency: 'USD', assetsMinor: '-150', liabilitiesMinor: '0', netWorthMinor: '-150' },
      { currency: 'VND', assetsMinor: '9007199254740993', liabilitiesMinor: '-700', netWorthMinor: '9007199254740293' },
    ]);
  });
});

describe('DS-P2-003 year period and trend', () => {
  it('resolves a calendar year and rejects the year trend for range', () => {
    expect(resolvePeriod({ period: 'year', on: '2026-10-08' }, profile(15))).toMatchObject({ kind: 'year', from: '2026-01-01', to: '2026-12-31' });
    expect(resolvePeriod({ period: 'year', on: '2024-02-29' }, profile())).toMatchObject({ from: '2024-01-01', to: '2024-12-31' });
    expect(() => resolvePeriod({ period: 'year', from: '2026-01-01' }, profile())).toThrow(ReportError);
  });

  it('lists oldest-first buckets: 8 Monday weeks, 6 fiscal months, 5 years', () => {
    const weeks = trendBuckets({ period: 'week', on: '2026-10-08' }, profile());
    expect(weeks).toHaveLength(8);
    expect(weeks[7]).toEqual({ from: '2026-10-05', to: '2026-10-11' });
    expect(weeks[0]).toEqual({ from: '2026-08-17', to: '2026-08-23' });
    const months = trendBuckets({ period: 'month', on: '2026-10-08' }, profile(15));
    expect(months.map(bucket => bucket.from)).toEqual(['2026-04-15', '2026-05-15', '2026-06-15', '2026-07-15', '2026-08-15', '2026-09-15']);
    expect(months[5].to).toBe('2026-10-14');
    expect(trendBuckets({ period: 'year', on: '2026-10-08' }, profile()).map(bucket => bucket.from.slice(0, 4))).toEqual(['2022', '2023', '2024', '2025', '2026']);
  });

  it('stops at the earliest supported year instead of failing', () => {
    expect(trendBuckets({ period: 'year', on: '0100-05-05' }, profile()).map(bucket => bucket.from)).toEqual(['0100-01-01']);
    expect(trendBuckets({ period: 'year', on: '0101-05-05' }, profile()).map(bucket => bucket.from)).toEqual(['0100-01-01', '0101-01-01']);
  });

  it('sums per currency, drops empty years before the first transaction, and keeps the current one', () => {
    const buckets = trendBuckets({ period: 'year', on: '2026-10-08' }, profile());
    const trend = buildTrend('year', { buckets, firstOn: '2024-03-01', rows: [
      { index: 2, currency: 'VND', type: 'expense', total: -300n },
      { index: 2, currency: 'VND', type: 'expense', total: -200n },
      { index: 4, currency: 'USD', type: 'income', total: 50n },
    ] });
    expect(trend.buckets.map(bucket => bucket.from.slice(0, 4))).toEqual(['2024', '2025', '2026']);
    expect(trend.buckets[0].totals).toEqual([{ currency: 'VND', incomeMinor: '0', expenseMinor: '-500' }]);
    expect(trend.buckets[1].totals).toEqual([]);
    expect(trend.buckets[2].totals).toEqual([{ currency: 'USD', incomeMinor: '50', expenseMinor: '0' }]);
    const empty = buildTrend('year', { buckets, firstOn: null, rows: [] });
    expect(empty.buckets).toHaveLength(1);
  });
});

describe('BE-P2-E06 comparison, savings rate, merchants, and series', () => {
  it('resolves the adjacent previous period for week, fiscal month, year, and range', () => {
    expect(previousPeriod(resolvePeriod({ period: 'week', on: '2026-10-08' }, profile()))).toEqual({ from: '2026-09-28', to: '2026-10-04' });
    expect(previousPeriod(resolvePeriod({ period: 'month', on: '2026-10-08' }, profile(15)))).toEqual({ from: '2026-08-15', to: '2026-09-14' });
    expect(previousPeriod(resolvePeriod({ period: 'year', on: '2026-10-08' }, profile()))).toEqual({ from: '2025-01-01', to: '2025-12-31' });
    expect(previousPeriod(resolvePeriod({ period: 'range', from: '2026-10-01', to: '2026-10-07' }, profile()))).toEqual({ from: '2026-09-24', to: '2026-09-30' });
    expect(() => previousPeriod(resolvePeriod({ period: 'year', on: '0001-06-01' }, profile()))).toThrow(ReportError);
  });

  it('computes savings rate and expense delta in integer basis points', () => {
    expect(savingsRateBps(118n, 300n)).toBe(3933);
    expect(savingsRateBps(-50n, 0n)).toBeNull();
    expect(savingsRateBps(10n, -1n)).toBeNull();
    expect(expenseDeltaBps(-106n, -100n)).toBe(600);
    expect(expenseDeltaBps(-50n, 0n)).toBeNull();
    expect(expenseDeltaBps(0n, -100n)).toBe(-10000);
  });

  it('attaches previous totals, expense deltas, and top merchants per currency', () => {
    const report = buildCashflow(resolvePeriod({ period: 'month', on: '2026-10-08' }, profile()), {
      categories: [
        { currency: 'VND', categoryId: null, parentId: null, type: 'income', total: 300n, count: 1 },
        { currency: 'VND', categoryId: null, parentId: null, type: 'expense', total: -182n, count: 2 },
        { currency: 'USD', categoryId: null, parentId: null, type: 'expense', total: -10n, count: 1 },
      ],
      accounts: [],
      movements: [],
    }, {
      previous: {
        from: '2026-09-01', to: '2026-09-30',
        categories: [
          { currency: 'VND', categoryId: null, parentId: null, type: 'income', total: 200n, count: 1 },
          { currency: 'VND', categoryId: null, parentId: null, type: 'expense', total: -100n, count: 1 },
        ],
      },
      merchants: [
        { currency: 'VND', merchant: 'WinMart', expense: -80n, count: 2 },
        { currency: 'VND', merchant: 'Grab', expense: -100n, count: 1 },
        { currency: 'VND', merchant: 'Cafe', expense: -2n, count: 1 },
        { currency: 'USD', merchant: 'Amazon', expense: -10n, count: 1 },
        { currency: 'VND', merchant: 'grab', expense: -5n, count: 1 },
      ],
    });
    expect(report.totals).toEqual([
      { currency: 'USD', incomeMinor: '0', expenseMinor: '-10', netMinor: '-10', savingsRateBps: null },
      { currency: 'VND', incomeMinor: '300', expenseMinor: '-182', netMinor: '118', savingsRateBps: 3933 },
    ]);
    expect(report.comparison).toEqual({
      from: '2026-09-01',
      to: '2026-09-30',
      totals: [{ currency: 'VND', incomeMinor: '200', expenseMinor: '-100', netMinor: '100', savingsRateBps: 5000 }],
      expenseDeltaBps: [
        { currency: 'USD', deltaBps: null },
        { currency: 'VND', deltaBps: 8200 },
      ],
    });
    expect(report.topMerchants).toEqual([
      { currency: 'USD', merchant: 'Amazon', expenseMinor: '-10', transactionCount: 1 },
      { currency: 'VND', merchant: 'Grab', expenseMinor: '-100', transactionCount: 1 },
      { currency: 'VND', merchant: 'WinMart', expenseMinor: '-80', transactionCount: 2 },
      { currency: 'VND', merchant: 'grab', expenseMinor: '-5', transactionCount: 1 },
      { currency: 'VND', merchant: 'Cafe', expenseMinor: '-2', transactionCount: 1 },
    ]);
  });

  it('builds 7d day buckets, fiscal month windows, and all-time years', () => {
    expect(seriesBuckets({ window: '7d', on: '2026-10-08' }, profile()).map(bucket => bucket.from)).toEqual([
      '2026-10-02', '2026-10-03', '2026-10-04', '2026-10-05', '2026-10-06', '2026-10-07', '2026-10-08',
    ]);
    expect(seriesBuckets({ window: '3m', on: '2026-10-08' }, profile(15)).map(bucket => `${bucket.from}/${bucket.to}`)).toEqual([
      '2026-07-15/2026-08-14', '2026-08-15/2026-09-14', '2026-09-15/2026-10-14',
    ]);
    expect(seriesBuckets({ window: '1y', on: '2026-10-08' }, profile(1))).toHaveLength(12);
    expect(seriesBuckets({ window: 'all', on: '2026-10-08' }, profile(), '2024-03-01').map(bucket => bucket.from)).toEqual([
      '2024-01-01', '2025-01-01', '2026-01-01',
    ]);
    expect(seriesBuckets({ window: 'all', on: '2026-10-08' }, profile(), null)).toEqual([
      { from: '2026-01-01', to: '2026-12-31' },
    ]);
    const series = buildSeries('7d', {
      buckets: seriesBuckets({ window: '7d', on: '2026-10-08' }, profile()),
      firstOn: null,
      rows: [
        { index: 6, currency: 'VND', type: 'expense', total: -40n },
        { index: 0, currency: 'VND', type: 'income', total: 10n },
      ],
    });
    expect(series.window).toBe('7d');
    expect(series.buckets[0].totals).toEqual([{ currency: 'VND', incomeMinor: '10', expenseMinor: '0' }]);
    expect(series.buckets[6].totals).toEqual([{ currency: 'VND', incomeMinor: '0', expenseMinor: '-40' }]);
  });
});

describe('BE-P2-E08 month review', () => {
  const parent = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const housing = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  const food = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  const transit = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
  const other = 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
  const period = resolvePeriod({ period: 'month', on: '2026-10-08' }, profile(15));

  it('projects savings and rate from the same cashflow totals', () => {
    const categories = [
      { currency: 'VND', categoryId: housing, parentId: parent, type: 'expense' as const, total: -700n, count: 2 },
      { currency: 'VND', categoryId: food, parentId: null, type: 'expense' as const, total: -320n, count: 4 },
      { currency: 'VND', categoryId: transit, parentId: null, type: 'expense' as const, total: -150n, count: 3 },
      { currency: 'VND', categoryId: null, parentId: null, type: 'income' as const, total: 3000n, count: 1 },
    ];
    const cashflow = buildCashflow(period, { categories, accounts: [], movements: [] });
    const review = buildMonthReview(period, { categories, accounts: [], movements: [] });
    expect(review.period).toEqual({
      kind: 'month', from: '2026-09-15', to: '2026-10-14', timezone: 'Asia/Ho_Chi_Minh', fiscalMonthStartDay: 15,
    });
    expect(review.currencies).toEqual([{
      currency: 'VND',
      incomeMinor: cashflow.totals[0].incomeMinor,
      expenseMinor: cashflow.totals[0].expenseMinor,
      savingsMinor: cashflow.totals[0].netMinor,
      savingsRateBps: cashflow.totals[0].savingsRateBps,
      topCategories: [
        { categoryId: housing, parentId: parent, expenseMinor: '-700', transactionCount: 2 },
        { categoryId: food, parentId: null, expenseMinor: '-320', transactionCount: 4 },
        { categoryId: transit, parentId: null, expenseMinor: '-150', transactionCount: 3 },
      ],
    }]);
    expect(review.currencies[0].savingsMinor).toBe('1830');
    expect(review.currencies[0].savingsRateBps).toBe(6100);
  });

  it('keeps top 3 expenses, ranks ties by categoryId with null last, and nulls rate without income', () => {
    const a = '11111111-1111-4111-8111-111111111111';
    const b = '22222222-2222-4222-8222-222222222222';
    const categories = [
      { currency: 'VND', categoryId: a, parentId: null, type: 'expense' as const, total: -100n, count: 1 },
      { currency: 'VND', categoryId: b, parentId: null, type: 'expense' as const, total: -100n, count: 1 },
      { currency: 'VND', categoryId: null, parentId: null, type: 'expense' as const, total: -100n, count: 1 },
      { currency: 'VND', categoryId: other, parentId: null, type: 'expense' as const, total: -50n, count: 1 },
      { currency: 'USD', categoryId: food, parentId: null, type: 'expense' as const, total: -15n, count: 1 },
    ];
    const review = buildMonthReview(period, { categories, accounts: [], movements: [] });
    expect(review.currencies).toEqual([
      {
        currency: 'USD',
        incomeMinor: '0',
        expenseMinor: '-15',
        savingsMinor: '-15',
        savingsRateBps: null,
        topCategories: [{ categoryId: food, parentId: null, expenseMinor: '-15', transactionCount: 1 }],
      },
      {
        currency: 'VND',
        incomeMinor: '0',
        expenseMinor: '-350',
        savingsMinor: '-350',
        savingsRateBps: null,
        topCategories: [
          { categoryId: a, parentId: null, expenseMinor: '-100', transactionCount: 1 },
          { categoryId: b, parentId: null, expenseMinor: '-100', transactionCount: 1 },
          { categoryId: null, parentId: null, expenseMinor: '-100', transactionCount: 1 },
        ],
      },
    ]);
  });
});

describe('BE-P1-007 report HTTP contract', () => {
  it('rejects unknown periods and malformed dates before calendar checks', async () => {
    for (const plain of [{}, { period: 'decade' }, { period: 'month', on: '2026-10-08\n' }, { period: 'range', owner: 'x' }]) {
      expect(await validate(plainToInstance(CashflowQueryDto, plain), { whitelist: true, forbidNonWhitelisted: true })).not.toHaveLength(0);
    }
    expect(await validate(plainToInstance(CashflowQueryDto, { period: 'month', on: '2026-02-29' }))).toHaveLength(0);
    expect(await validate(plainToInstance(SeriesQueryDto, { window: '7d', on: '2026-10-08' }))).toHaveLength(0);
    expect(await validate(plainToInstance(SeriesQueryDto, { window: 'decade' }), { whitelist: true, forbidNonWhitelisted: true })).not.toHaveLength(0);
    expect(await validate(plainToInstance(MonthReviewQueryDto, { on: '2026-10-08' }))).toHaveLength(0);
    expect(await validate(plainToInstance(MonthReviewQueryDto, {}), { whitelist: true, forbidNonWhitelisted: true })).toHaveLength(0);
    expect(await validate(plainToInstance(MonthReviewQueryDto, { on: '2026-10-08\n' }), { whitelist: true, forbidNonWhitelisted: true })).not.toHaveLength(0);
    expect(await validate(plainToInstance(MonthReviewQueryDto, { period: 'month' }), { whitelist: true, forbidNonWhitelisted: true })).not.toHaveLength(0);
  });

  it('resolves the period inside the repository snapshot', async () => {
    const repository: ReportRepository = {
      async cashflow(_userId, periodOf) {
        const period = periodOf(profile(15));
        return {
          period,
          source: { categories: [], accounts: [], movements: [] },
          previous: { from: '2026-08-15', to: '2026-09-14', categories: [] },
          merchants: [],
        };
      },
      async monthReview(_userId, periodOf) {
        return { period: periodOf(profile(15)), categories: [] };
      },
      async trend() { return { buckets: [], rows: [], firstOn: null }; },
      async series() { return { buckets: [], rows: [], firstOn: null }; },
      async netWorth() { return [{ currency: 'VND', bucket: 'asset', total: 10n }]; },
    };
    const service = new ReportService(repository, { book: async () => noRates } as unknown as FxRateService);
    await expect(service.cashflow('user', { period: 'month', on: '2026-10-08' })).resolves.toMatchObject({
      period: { from: '2026-09-15', to: '2026-10-14' },
      comparison: { from: '2026-08-15', to: '2026-09-14' },
      topMerchants: [],
    });
    await expect(service.monthReview('user', { on: '2026-10-08' })).resolves.toEqual({
      period: { kind: 'month', from: '2026-09-15', to: '2026-10-14', timezone: 'Asia/Ho_Chi_Minh', fiscalMonthStartDay: 15 },
      currencies: [],
    });
    await expect(service.series('user', { window: '7d', on: '2026-10-08' })).resolves.toEqual({ window: '7d', buckets: [] });
    await expect(service.netWorth('user')).resolves.toEqual({ items: [{ currency: 'VND', assetsMinor: '10', liabilitiesMinor: '0', netWorthMinor: '10' }] });
  });
  describe('BE-P2-013 display totals', () => {
    const rates: Record<string, { rate: string; quotedAt: string }> = {
      'USD>VND': { rate: '25000', quotedAt: '2026-10-30T02:00:00.000Z' },
      'JPY>VND': { rate: '170.5', quotedAt: '2026-10-30T02:00:00.000Z' },
    };
    const digits: Record<string, number> = { VND: 0, USD: 2, JPY: 0, EUR: 2 };
    const book = { rate: (from: string, to: string) => rates[`${from}>${to}`] ?? null, digits: (code: string) => digits[code] ?? null };

    it('adds assets, debt and net of each convertible currency, and leaves the rest out', () => {
      const items = buildNetWorth([
        { currency: 'VND', bucket: 'asset', total: 10_000_000n },
        { currency: 'VND', bucket: 'liability', total: -2_000_000n },
        { currency: 'USD', bucket: 'asset', total: 120_000n },
        { currency: 'USD', bucket: 'liability', total: -5_000n },
        { currency: 'EUR', bucket: 'asset', total: 100n },
        { currency: 'JPY', bucket: 'asset', total: 3n },
      ]).items;
      expect(convertNetWorth(items, 'VND', book)).toEqual({
        currency: 'VND', assetsMinor: '40000000', liabilitiesMinor: '-3250000', netWorthMinor: '36750000',
        unconverted: [{ currency: 'EUR', reason: 'MISSING_RATE' }, { currency: 'JPY', reason: 'FRACTIONAL' }],
      });
      expect(items.find(item => item.currency === 'USD')).toEqual({ currency: 'USD', assetsMinor: '120000', liabilitiesMinor: '-5000', netWorthMinor: '115000' });
    });

    it('converts month income and expense with the same rule', () => {
      const totals = [
        { currency: 'USD', incomeMinor: '200000', expenseMinor: '-35000' },
        { currency: 'VND', incomeMinor: '1000', expenseMinor: '-500' },
      ];
      expect(convertCashflow(totals, 'VND', book)).toEqual({
        currency: 'VND', incomeMinor: '50001000', expenseMinor: '-8750500', netMinor: '41250500', unconverted: [],
      });
      expect(convertCashflow(totals, 'USD', book)).toEqual({
        currency: 'USD', incomeMinor: '200000', expenseMinor: '-35000', netMinor: '165000', unconverted: [{ currency: 'VND', reason: 'MISSING_RATE' }],
      });
    });

    it('converts nothing for an empty ledger', () => {
      expect(convertNetWorth([], 'VND', book)).toEqual({ currency: 'VND', assetsMinor: '0', liabilitiesMinor: '0', netWorthMinor: '0', unconverted: [] });
    });
  });
});
