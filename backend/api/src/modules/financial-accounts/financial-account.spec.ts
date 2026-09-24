import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { randomUUID } from 'node:crypto';
import { minor, sameCreate, updatedFields, validateCredit, type FinancialAccount } from './domain/financial-account';
import { CreateAccountDto, UpdateAccountDto } from './financial-account.dto';

const current: FinancialAccount = {
  id: randomUUID(), clientId: randomUUID(), name: 'Ví', type: 'cash', currencyCode: 'VND',
  initialBalanceMinor: 0n, balanceMinor: 0n, sortOrder: 0, creditLimitMinor: null,
  statementCloseDay: null, paymentDueDay: null, version: 1, archivedAt: null,
  createdAt: new Date(), updatedAt: new Date(),
};
describe('BE-P1-004 account rules', () => {
  it.each(['0', '-1', '9007199254740993', '-9223372036854775808', '9223372036854775807'])('preserves integer %s', value => {
    expect(minor(value).toString()).toBe(value);
  });
  it.each(['9223372036854775808', '-9223372036854775809', '1.5', '1e5', '+1', ' 1', '1\n', ''])('rejects invalid money %j', value => {
    expect(() => minor(value)).toThrow('VALIDATION_ERROR');
  });
  it('normalizes integer spellings for replay', () => {
    expect(minor('-0')).toBe(0n);
    expect(sameCreate(current, {
      clientId: current.clientId, name: 'Ví', type: 'cash', currencyCode: 'VND', initialBalanceMinor: minor('00'),
      sortOrder: 0, creditLimitMinor: null, statementCloseDay: null, paymentDueDay: null,
    })).toBe(true);
  });
  it('locks denomination and type with history but allows correction of initial balance', () => {
    expect(() => updatedFields(current, { version: 1, type: 'credit' }, true)).toThrow('ACCOUNT_CONFLICT');
    expect(() => updatedFields(current, { version: 1, currencyCode: 'USD' }, true)).toThrow('ACCOUNT_CONFLICT');
    expect(updatedFields(current, { version: 1, initialBalanceMinor: -500n }, true).initialBalanceMinor).toBe(-500n);
    expect(() => updatedFields(current, { version: 2 }, false)).toThrow('ACCOUNT_CONFLICT');
  });
  it('clears old credit config and rejects contradictory config', () => {
    const card = { ...current, type: 'credit' as const, creditLimitMinor: 1000n, statementCloseDay: 12, paymentDueDay: 20 };
    expect(updatedFields(card, { version: 1, type: 'bank' }, false)).toMatchObject({
      creditLimitMinor: null, statementCloseDay: null, paymentDueDay: null,
    });
    expect(() => updatedFields(card, { version: 1, type: 'bank', paymentDueDay: 5 }, false)).toThrow('VALIDATION_ERROR');
    expect(() => validateCredit({ ...card, creditLimitMinor: -1n })).toThrow('VALIDATION_ERROR');
    expect(() => validateCredit({ ...current, paymentDueDay: 1 })).toThrow('VALIDATION_ERROR');
  });
  it('trims names and rejects null in nonnullable fields or unknown input', async () => {
    const dto = plainToInstance(CreateAccountDto, { clientId: randomUUID(), name: ' Ví ', type: 'cash', currencyCode: 'VND', initialBalanceMinor: '0' });
    expect(dto.name).toBe('Ví');
    expect(await validate(dto)).toHaveLength(0);
    for (const patch of [{ name: null }, { initialBalanceMinor: null }, { sortOrder: null }, { archived: null }, { name: '  ' }, { statementCloseDay: 29 }, { sortOrder: 0.5 }, { currencyCode: 'VN\n' }]) {
      expect((await validate(plainToInstance(UpdateAccountDto, { version: 1, ...patch }))).length).toBeGreaterThan(0);
    }
    expect(await validate(plainToInstance(UpdateAccountDto, { version: 1, creditLimitMinor: null, statementCloseDay: null }))).toHaveLength(0);
    expect((await validate(plainToInstance(UpdateAccountDto, { version: 1, userId: randomUUID() }), { whitelist: true, forbidNonWhitelisted: true })).length).toBeGreaterThan(0);
  });
});
