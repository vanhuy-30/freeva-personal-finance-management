import { appConfigReaderFor } from '../app-config/testing';
import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { buildForecast, forecastRange, ForecastError } from './domain/forecast';
import { ForecastQueryDto } from './forecast.dto';
import { ForecastService } from './forecast.service';
import type { ForecastRepository, ForecastRule, ForecastSource } from './domain/forecast.repository';

const rule = (over: Partial<ForecastRule> & { id: string }): ForecastRule => ({
  mode: 'auto', type: 'expense', amountMinor: -8_000_000n, currencyCode: 'VND', unit: 'month', interval: 1,
  startDate: '2026-11-01', endDate: null, nextExecutionDate: '2026-11-01', ...over,
});

function service(rules: ForecastRule[], balance = 10_000_000n) {
  const source: ForecastSource = {
    timezone: 'Asia/Ho_Chi_Minh', today: '2026-11-03', defaultCurrencyCode: 'VND',
    balanceByCurrency: new Map([['VND', balance]]), rules,
  };
  const repository: ForecastRepository = { load: async () => source };
  return new ForecastService(repository, appConfigReaderFor());
}

describe('BE-P3-E04 forecast domain', () => {
  it('builds the month list and end date', () => {
    expect(forecastRange('2026-11-03', 3)).toEqual({ from: '2026-11-03', to: '2027-01-31', months: ['2026-11', '2026-12', '2027-01'] });
    expect(forecastRange('2026-12-15', 2).months).toEqual(['2026-12', '2027-01']);
    expect(() => forecastRange('2026-11-03', 0)).toThrow(ForecastError);
    expect(() => forecastRange('2026-11-03', 13)).toThrow(ForecastError);
  });

  it('chains closing into the next opening with fixed numbers', () => {
    const rows = buildForecast({
      startingBalanceMinor: 10_000_000n,
      months: ['2026-11', '2026-12'],
      events: [
        { ruleId: 'a', date: '2026-11-05', amountMinor: 20_000_000n },
        { ruleId: 'b', date: '2026-11-30', amountMinor: -8_000_000n },
        { ruleId: 'b', date: '2026-12-30', amountMinor: -8_000_000n },
      ],
    });
    expect(rows[0]).toMatchObject({ openingMinor: 10_000_000n, incomeMinor: 20_000_000n, expenseMinor: -8_000_000n, closingMinor: 22_000_000n });
    expect(rows[1]).toMatchObject({ openingMinor: 22_000_000n, incomeMinor: 0n, expenseMinor: -8_000_000n, closingMinor: 14_000_000n });
  });
});

describe('BE-P3-E04 forecast service', () => {
  const salary = rule({ id: 'salary', type: 'income', amountMinor: 20_000_000n, startDate: '2026-11-05', nextExecutionDate: '2026-11-05' });
  const rent = rule({ id: 'rent', nextExecutionDate: '2026-12-01' });

  it('projects recurring flows from the wallet balance', async () => {
    const out = await service([salary, rent]).forecast('u', { months: 3 });
    expect(out.startingBalanceMinor).toBe('10000000');
    expect(out.months.map(m => m.closingMinor)).toEqual(['30000000', '42000000', '54000000']);
    expect(out.assumptions.includedRuleIds.sort()).toEqual(['rent', 'salary']);
  });

  it('clamps day 31 and stops at endDate', async () => {
    const out = await service([rule({ id: 'x', startDate: '2026-10-31', nextExecutionDate: '2026-11-30', endDate: '2026-12-31', amountMinor: -1_000n })], 0n)
      .forecast('u', { months: 3 });
    expect(out.months.map(m => m.expenseMinor)).toEqual(['-1000', '-1000', '0']);
  });

  it('honours excluded rules, balance override and other currencies', async () => {
    const usd = rule({ id: 'usd', currencyCode: 'USD' });
    const out = await service([salary, rent, usd]).forecast('u', {
      months: 1, startingBalanceMinor: '5000000', excludeRuleIds: ['salary'],
    });
    expect(out.months[0].closingMinor).toBe('5000000');
    expect(out.assumptions).toMatchObject({ balanceSource: 'user', excludedRuleIds: ['salary'], otherCurrencyRuleIds: ['usd'] });
  });

  it('skips transfers', async () => {
    const out = await service([rule({ id: 't', type: 'transfer' })]).forecast('u', { months: 1 });
    expect(out.months[0].closingMinor).toBe('10000000');
  });
});

describe('BE-P3-E04 forecast query', () => {
  const errors = (raw: object) => validateSync(plainToInstance(ForecastQueryDto, raw), { whitelist: true, forbidNonWhitelisted: true });
  it('validates input', () => {
    expect(errors({ months: '6', currencyCode: 'VND', startingBalanceMinor: '-100' })).toHaveLength(0);
    expect(errors({ months: '13' })).not.toHaveLength(0);
    expect(errors({ startingBalanceMinor: '1.5' })).not.toHaveLength(0);
    expect(errors({ excludeRuleIds: 'nope' })).not.toHaveLength(0);
  });
});
