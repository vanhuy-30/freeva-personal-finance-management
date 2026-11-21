import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { PeriodQueryDto } from './report.dto';
import {
  balanceDays, buildCashflow, buildFlow, flowBuckets, holdingsDays, resolvePeriod,
  type PeriodBalanceRow, type ReportProfile,
} from './domain/report';

const profile = (fiscalMonthStartDay = 1): ReportProfile => ({ timezone: 'Asia/Ho_Chi_Minh', fiscalMonthStartDay });
const period = (query: Parameters<typeof resolvePeriod>[0], fiscalMonthStartDay = 1) => resolvePeriod(query, profile(fiscalMonthStartDay));

describe('report flow buckets', () => {
  it('goes day by day through a week and stops at today while it is running', () => {
    const week = period({ period: 'week', on: '2026-11-18' }); // Mon 16 – Sun 22
    const running = flowBuckets(week, '2026-11-18');
    expect(running.granularity).toBe('day');
    expect(running.buckets.map(b => b.from)).toEqual(['2026-11-16', '2026-11-17', '2026-11-18']);
    expect(flowBuckets(week, '2026-12-01').buckets).toHaveLength(7);
  });

  it('goes day by day through a month, the whole of a finished one and up to today in the running one', () => {
    const november = period({ period: 'month', on: '2026-11-21' });
    const running = flowBuckets(november, '2026-11-21');
    expect(running.buckets).toHaveLength(21);
    expect(running.buckets[0]).toEqual({ from: '2026-11-01', to: '2026-11-01' });
    expect(running.buckets[20]).toEqual({ from: '2026-11-21', to: '2026-11-21' });
    const finished = flowBuckets(period({ period: 'month', on: '2026-02-10' }), '2026-11-21');
    expect(finished.buckets).toHaveLength(28);
    // A fiscal month that starts on the 15th follows its own bounds.
    expect(flowBuckets(period({ period: 'month', on: '2026-10-20' }, 15), '2026-10-20').buckets[0].from).toBe('2026-10-15');
  });

  it('goes month by month through a year and clips the running month to today', () => {
    const running = flowBuckets(period({ period: 'year', on: '2026-11-21' }), '2026-11-21');
    expect(running.granularity).toBe('month');
    expect(running.buckets).toHaveLength(11);
    expect(running.buckets[0]).toEqual({ from: '2026-01-01', to: '2026-01-31' });
    expect(running.buckets[1]).toEqual({ from: '2026-02-01', to: '2026-02-28' });
    expect(running.buckets[10]).toEqual({ from: '2026-11-01', to: '2026-11-21' });
    const finished = flowBuckets(period({ period: 'year', on: '2024-06-01' }), '2026-11-21');
    expect(finished.buckets).toHaveLength(12);
    expect(finished.buckets[1]).toEqual({ from: '2024-02-01', to: '2024-02-29' });
  });

  it('keeps a custom range daily up to 31 days and weekly beyond that', () => {
    const short = flowBuckets(period({ period: 'range', from: '2026-10-01', to: '2026-10-31' }), '2026-11-21');
    expect(short.granularity).toBe('day');
    expect(short.buckets).toHaveLength(31);
    const long = flowBuckets(period({ period: 'range', from: '2026-10-01', to: '2026-11-15' }), '2026-11-21');
    expect(long.granularity).toBe('week');
    expect(long.buckets.map(b => b.from)).toEqual(['2026-10-01', '2026-10-08', '2026-10-15', '2026-10-22', '2026-10-29', '2026-11-05', '2026-11-12']);
    expect(long.buckets[6]).toEqual({ from: '2026-11-12', to: '2026-11-15' });
    const clipped = flowBuckets(period({ period: 'range', from: '2026-10-01', to: '2026-12-31' }), '2026-11-21');
    expect(clipped.buckets[clipped.buckets.length - 1].to).toBe('2026-11-21');
    expect(flowBuckets(period({ period: 'range', from: '2026-11-05', to: '2026-11-05' }), '2026-11-21').buckets).toEqual([{ from: '2026-11-05', to: '2026-11-05' }]);
  });

  it('has no buckets for a period that has not started, but still says how it would be cut', () => {
    expect(flowBuckets(period({ period: 'month', on: '2026-12-10' }), '2026-11-21')).toEqual({ granularity: 'day', buckets: [] });
    expect(flowBuckets(period({ period: 'year', on: '2027-03-01' }), '2026-11-21')).toEqual({ granularity: 'month', buckets: [] });
  });

  it('sums each bucket per currency and keeps empty buckets', () => {
    const p = period({ period: 'week', on: '2026-11-18' });
    const shape = flowBuckets(p, '2026-11-18');
    const flow = buildFlow(p, shape.granularity, {
      buckets: shape.buckets,
      rows: [
        { index: 1, currency: 'VND', type: 'income', total: 26_000_000n },
        { index: 1, currency: 'VND', type: 'expense', total: -500_000n },
        { index: 1, currency: 'USD', type: 'expense', total: -1_000n },
      ],
    });
    expect(flow.period).toEqual({ kind: 'week', from: '2026-11-16', to: '2026-11-22' });
    expect(flow.buckets[0].totals).toEqual([]);
    expect(flow.buckets[1].totals).toEqual([
      { currency: 'USD', incomeMinor: '0', expenseMinor: '-1000' },
      { currency: 'VND', incomeMinor: '26000000', expenseMinor: '-500000' },
    ]);
  });
});

describe('report balances and holdings days', () => {
  it('reads balances on the last day of the period and the previous one, never after today', () => {
    expect(balanceDays(period({ period: 'month', on: '2026-11-21' }), '2026-11-21')).toEqual({ endDay: '2026-11-21', previousEndDay: '2026-10-31' });
    expect(balanceDays(period({ period: 'month', on: '2026-02-10' }), '2026-11-21')).toEqual({ endDay: '2026-02-28', previousEndDay: '2026-01-31' });
    expect(balanceDays(period({ period: 'week', on: '2026-11-18' }), '2026-11-18')).toEqual({ endDay: '2026-11-18', previousEndDay: '2026-11-15' });
  });

  it('values holdings from the evening before the period to its last day', () => {
    expect(holdingsDays(period({ period: 'month', on: '2026-11-21' }), '2026-11-21')).toEqual({ startDay: '2026-10-31', endDay: '2026-11-21' });
    expect(holdingsDays(period({ period: 'month', on: '2026-12-10' }), '2026-11-21')).toEqual({ startDay: '2026-11-21', endDay: '2026-11-21' });
  });

  it('puts the wallet balances in the cashflow report, per currency, without credit wallets', () => {
    const p = period({ period: 'month', on: '2026-11-21' });
    const balances: PeriodBalanceRow[] = [
      { index: 0, currency: 'VND', bucket: 'asset', total: 48_250_000n },
      { index: 1, currency: 'VND', bucket: 'asset', total: 41_639_000n },
      { index: 0, currency: 'VND', bucket: 'liability', total: -8_965_000n },
      { index: 1, currency: 'VND', bucket: 'liability', total: -3_000_000n },
      { index: 0, currency: 'USD', bucket: 'asset', total: 1_000n },
    ];
    const report = buildCashflow(p, { categories: [], accounts: [], movements: [] }, {
      previous: { from: '2026-10-01', to: '2026-10-31', categories: [] }, merchants: [], balances,
    });
    expect(report.walletBalances).toEqual([
      { currency: 'USD', endMinor: '1000', previousEndMinor: '0' },
      { currency: 'VND', endMinor: '48250000', previousEndMinor: '41639000' },
    ]);
    expect(buildCashflow(p, { categories: [], accounts: [], movements: [] }).walletBalances).toEqual([]);
  });
});

describe('report flow and holdings queries', () => {
  const options = { whitelist: true, forbidNonWhitelisted: true };

  it('takes a period like the cashflow report but no display currency', async () => {
    expect(await validate(plainToInstance(PeriodQueryDto, { period: 'month', on: '2026-11-21' }), options)).toHaveLength(0);
    expect(await validate(plainToInstance(PeriodQueryDto, { period: 'range', from: '2026-10-01', to: '2026-10-31' }), options)).toHaveLength(0);
    for (const plain of [{}, { period: 'decade' }, { period: 'month', displayCurrency: 'VND' }, { period: 'month', on: '2026-11-21\n' }]) {
      expect(await validate(plainToInstance(PeriodQueryDto, plain), options)).not.toHaveLength(0);
    }
  });
});
