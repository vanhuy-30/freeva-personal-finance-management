import 'reflect-metadata';
import { randomUUID } from 'node:crypto';
import { plainToInstance } from 'class-transformer';
import { validateSync } from 'class-validator';
import { occurrenceClientId } from './domain/occurrence-id';
import { RecurringError, remindFlags, validateRecurringInput, type RecurringInput } from './domain/recurring';
import { CreateRecurringDto } from './recurring.dto';

const day = (value: string) => new Date(`${value}T00:00:00.000Z`);

function base(patch: Partial<RecurringInput> = {}): RecurringInput {
  return {
    clientId: randomUUID(),
    type: 'expense',
    mode: 'auto',
    name: null,
    amountKind: 'fixed',
    remindDaysBefore: 3,
    unit: 'month',
    interval: 1,
    amountMinor: -500000n,
    currencyCode: 'VND',
    accountId: randomUUID(),
    categoryId: randomUUID(),
    counterAccountId: null,
    counterAmountMinor: null,
    counterCurrencyCode: null,
    fxRate: null,
    startDate: day('2026-01-31'),
    endDate: null,
    nextExecutionDate: day('2026-01-31'),
    active: true,
    ...patch,
  };
}

describe('BE-P2-E01 recurring validation', () => {
  it('accepts expense and income templates', () => {
    expect(() => validateRecurringInput(base(), { VND: 0 })).not.toThrow();
    expect(() => validateRecurringInput(base({
      type: 'income', amountMinor: 15000000n, categoryId: null,
    }), { VND: 0 })).not.toThrow();
  });

  it('requires a balanced transfer and rejects self-transfer', () => {
    const source = randomUUID();
    const destination = randomUUID();
    expect(() => validateRecurringInput(base({
      type: 'transfer',
      categoryId: null,
      amountMinor: -100000n,
      counterAccountId: destination,
      counterAmountMinor: 100000n,
      counterCurrencyCode: 'VND',
    }), { VND: 0 })).not.toThrow();
    expect(() => validateRecurringInput(base({
      type: 'transfer',
      categoryId: null,
      amountMinor: -100000n,
      accountId: source,
      counterAccountId: source,
      counterAmountMinor: 100000n,
      counterCurrencyCode: 'VND',
    }), { VND: 0 })).toThrow(RecurringError);
    expect(() => validateRecurringInput(base({
      type: 'transfer',
      categoryId: null,
      amountMinor: -100000n,
      counterAccountId: destination,
      counterAmountMinor: 90000n,
      counterCurrencyCode: 'VND',
    }), { VND: 0 })).toThrow(RecurringError);
  });

  it('rejects next before start and inactive-irrelevant field errors', () => {
    expect(() => validateRecurringInput(base({
      nextExecutionDate: day('2025-12-31'),
    }), { VND: 0 })).toThrow(RecurringError);
    expect(() => validateRecurringInput(base({ interval: 0 }), { VND: 0 })).toThrow(RecurringError);
    expect(() => validateRecurringInput(base({ categoryId: null }), { VND: 0 })).toThrow(RecurringError);
  });

  it('builds stable occurrence client ids', () => {
    const ruleId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    const first = occurrenceClientId(ruleId, '2026-01-31', 0);
    const second = occurrenceClientId(ruleId, '2026-01-31', 1);
    expect(first).toMatch(/^[0-9a-f-]{36}$/);
    expect(first).toBe(occurrenceClientId(ruleId, '2026-01-31', 0));
    expect(first).not.toBe(second);
  });

  it('validates create DTO shapes', () => {
    const ok = plainToInstance(CreateRecurringDto, {
      clientId: randomUUID(),
      type: 'expense',
      unit: 'month',
      interval: 1,
      amountMinor: '-120000',
      currencyCode: 'vnd',
      accountId: randomUUID(),
      categoryId: randomUUID(),
      startDate: '2026-01-31',
      nextExecutionDate: '2026-01-31',
    });
    expect(validateSync(ok)).toHaveLength(0);
    expect(ok.currencyCode).toBe('VND');
  });

  describe('BE-P3-001 remind mode', () => {
    const remind = (patch: Partial<RecurringInput> = {}) => base({
      mode: 'remind', name: 'Tiền điện', accountId: null, categoryId: null, ...patch,
    });

    it('accepts a bill-style rule without wallet or category', () => {
      expect(() => validateRecurringInput(remind(), { VND: 0 })).not.toThrow();
    });

    it('requires a name, expense type and a wallet for auto', () => {
      expect(() => validateRecurringInput(remind({ name: null }), { VND: 0 })).toThrow(RecurringError);
      expect(() => validateRecurringInput(remind({ name: '  ' }), { VND: 0 })).toThrow(RecurringError);
      expect(() => validateRecurringInput(remind({ type: 'income', amountMinor: 1n }), { VND: 0 })).toThrow(RecurringError);
      expect(() => validateRecurringInput(base({ accountId: null }), { VND: 0 })).toThrow(RecurringError);
    });

    it('bounds the reminder lead time', () => {
      expect(() => validateRecurringInput(remind({ remindDaysBefore: 31 }), { VND: 0 })).toThrow(RecurringError);
      expect(() => validateRecurringInput(remind({ remindDaysBefore: -1 }), { VND: 0 })).toThrow(RecurringError);
    });

    it('derives overdue from the due day, never for auto or inactive rules', () => {
      const rule = { mode: 'remind' as const, active: true, nextExecutionDate: day('2026-02-10') };
      expect(remindFlags(rule, '2026-02-10')).toEqual({ pending: true, overdue: false });
      expect(remindFlags(rule, '2026-02-11')).toEqual({ pending: true, overdue: true });
      expect(remindFlags({ ...rule, active: false }, '2026-03-01')).toEqual({ pending: false, overdue: false });
      expect(remindFlags({ ...rule, mode: 'auto' }, '2026-03-01')).toEqual({ pending: false, overdue: false });
    });
  });
});
