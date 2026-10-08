import 'reflect-metadata';
import { randomUUID } from 'node:crypto';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { calendarDate, convertedMinor, minor, normalizeRate, validateInput, type TransactionInput } from './domain/transaction';
import { CreateTransactionDto, UpdateTransactionDto } from './transaction.dto';
const input = (): TransactionInput => ({ type: 'transfer', occurredOn: calendarDate('2026-09-25'), categoryId: null, notes: null, tagIds: [], fx: null,
  legs: [{ clientId: randomUUID(), accountId: randomUUID(), currencyCode: 'VND', amountMinor: -9007199254740993n },
    { clientId: randomUUID(), accountId: randomUUID(), currencyCode: 'VND', amountMinor: 9007199254740993n }] });
describe('BE-P1-005 transaction money and DTO rules', () => {
  it.each(['0', '-1', '-9223372036854775808', '9223372036854775807', '9007199254740993'])('preserves %s', value => expect(minor(value).toString()).toBe(value));
  it.each(['9223372036854775808', '-9223372036854775809', '1.1', '1e3', '1\n', '+1', ''])('rejects %j', value => expect(() => minor(value)).toThrow('VALIDATION_ERROR'));
  it.each(['2026-02-29', '2026-04-31', '2026-01-01T00:00:00Z', '0000-01-01', '2026-09-25\n'])('rejects invalid calendar %j', value => expect(() => calendarDate(value)).toThrow('VALIDATION_ERROR'));
  it('accepts leap dates and exact decimal FX beyond JS safe integer', () => {
    expect(calendarDate('2024-02-29').toISOString()).toBe('2024-02-29T00:00:00.000Z');
    expect(normalizeRate('00001.25')).toBe('1.25000000');
    expect(convertedMinor(-900719925474099200n, '1.25', 2, 0)).toBe(11258999068426240n);
  });
  it('rejects fractional FX, zero/negative/oversized rates', () => {
    expect(() => convertedMinor(-1n, '1.25', 2, 0)).toThrow('VALIDATION_ERROR');
    for (const rate of ['0', '-1', '10000000000', '0.000000001', '1e2', '1\n']) expect(() => normalizeRate(rate)).toThrow('VALIDATION_ERROR');
    expect(convertedMinor(-100n, '25000', 2, 0)).toBe(25000n);
  });
  it('rejects zero, self-transfer, duplicate clientIds, wrong sign, count, category and unbalanced legs', () => {
    expect(() => validateInput(input(), { VND: 0 })).not.toThrow();
    for (const change of [
      (x: TransactionInput) => { x.legs[0].amountMinor = 0n; },
      (x: TransactionInput) => { x.legs[1].accountId = x.legs[0].accountId; },
      (x: TransactionInput) => { x.legs[1].clientId = x.legs[0].clientId; },
      (x: TransactionInput) => { x.legs.reverse(); },
      (x: TransactionInput) => { x.legs.pop(); },
      (x: TransactionInput) => { x.categoryId = randomUUID(); },
      (x: TransactionInput) => { x.legs[1].amountMinor -= 1n; },
    ]) { const value = input(); change(value); expect(() => validateInput(value, { VND: 0 })).toThrow('VALIDATION_ERROR'); }
  });
  it('validates income and expense signs', () => {
    for (const type of ['income', 'expense'] as const) {
      const value = input(); value.type = type; value.categoryId = type === 'expense' ? randomUUID() : null; value.legs = [value.legs[type === 'income' ? 1 : 0]];
      expect(() => validateInput(value, { VND: 0 })).not.toThrow();
      value.legs[0].amountMinor *= -1n;
      expect(() => validateInput(value, { VND: 0 })).toThrow('VALIDATION_ERROR');
    }
  });
  it('rejects malformed nested input and unsupported patch properties', async () => {
    const value = input(); const valid = { ...value, occurredOn: '2026-09-25', legs: value.legs.map(leg => ({ ...leg, amountMinor: leg.amountMinor.toString() })) };
    expect(await validate(plainToInstance(CreateTransactionDto, valid))).toHaveLength(0);
    for (const patch of [{ version: null }, { version: 1, legs: null }, { version: 1, deleted: null }, { version: 1, type: 'income' }, { version: 1, fx: [] }, { version: 1, tagIds: null }, { version: 1, fx: { rate: '1', quotedAt: '2026-09-25' } }]) {
      expect((await validate(plainToInstance(UpdateTransactionDto, patch), { whitelist: true, forbidNonWhitelisted: true })).length).toBeGreaterThan(0);
    }
    expect(await validate(plainToInstance(UpdateTransactionDto, { version: 1, notes: null, categoryId: null, fx: null, tagIds: [] }))).toHaveLength(0);
  });
});
