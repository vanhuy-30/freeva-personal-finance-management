import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { CashflowQueryDto } from './report.dto';
import { ReportService } from './report.service';
import type { ReportRepository } from './domain/report.repository';
import {
  buildCashflow, buildNetWorth, ReportError, resolvePeriod, todayInTimeZone,
  type CashflowSource, type ReportProfile,
} from './domain/report';

const profile = (fiscalMonthStartDay = 1, timezone = 'Asia/Ho_Chi_Minh'): ReportProfile => ({ timezone, fiscalMonthStartDay });
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
      { currency: 'VND', categoryId: child, parentId: parent, type: 'expense', total: -400n },
      { currency: 'VND', categoryId: null, parentId: null, type: 'income', total: 9007199254740993n },
      { currency: 'USD', categoryId: food, parentId: null, type: 'income', total: 2500n },
      { currency: 'USD', categoryId: food, parentId: null, type: 'expense', total: -500n },
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
      { currency: 'USD', incomeMinor: '2500', expenseMinor: '-500', netMinor: '2000' },
      { currency: 'VND', incomeMinor: '9007199254740993', expenseMinor: '-400', netMinor: '9007199254740593' },
    ]);
    expect(report.byCategory.map(row => row.categoryId)).toEqual([food, child, null]);
    expect(report.byCategory.find(row => row.categoryId === child)).toEqual({
      categoryId: child, parentId: parent, currency: 'VND', incomeMinor: '0', expenseMinor: '-400',
    });
    expect(report.byCategory.find(row => row.categoryId === parent)).toBeUndefined();
    expect(report.byAccount.find(row => row.accountId === cash)).toMatchObject({ transferMinor: '-1500', netMinor: '9007199254739493' });
    expect(report.byAccount.find(row => row.accountId === card)?.netMinor).toBe('1100');
    expect(report.byAccount.find(row => row.accountId === archived)?.transferMinor).toBe('-20');
    expect(report.byAccount.find(row => row.accountId === usd)?.incomeMinor).toBe('2500');
    expect(report.totals).toHaveLength(2);
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

describe('BE-P1-007 report HTTP contract', () => {
  it('rejects unknown periods and malformed dates before calendar checks', async () => {
    for (const plain of [{}, { period: 'year' }, { period: 'month', on: '2026-10-08\n' }, { period: 'range', owner: 'x' }]) {
      expect(await validate(plainToInstance(CashflowQueryDto, plain), { whitelist: true, forbidNonWhitelisted: true })).not.toHaveLength(0);
    }
    expect(await validate(plainToInstance(CashflowQueryDto, { period: 'month', on: '2026-02-29' }))).toHaveLength(0);
  });

  it('resolves the period inside the repository snapshot', async () => {
    const repository: ReportRepository = {
      async cashflow(_userId, periodOf) {
        return { period: periodOf(profile(15)), source: { categories: [], accounts: [], movements: [] } };
      },
      async netWorth() { return [{ currency: 'VND', bucket: 'asset', total: 10n }]; },
    };
    const service = new ReportService(repository);
    await expect(service.cashflow('user', { period: 'month', on: '2026-10-08' })).resolves.toMatchObject({ period: { from: '2026-09-15', to: '2026-10-14' } });
    await expect(service.netWorth('user')).resolves.toEqual({ items: [{ currency: 'VND', assetsMinor: '10', liabilitiesMinor: '0', netWorthMinor: '10' }] });
  });
});
