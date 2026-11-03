import { assertWithinRefundCap, refundCap, validateRefundAmount } from './domain/refund';
import { TransactionError, validateInput, type TransactionInput } from './domain/transaction';
import { categorySpent, totalSpent, type ExpenseRow } from '../budgets/domain/budget';

const food = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const row = (type: ExpenseRow['type'], amountMinor: bigint): ExpenseRow =>
  ({ type, amountMinor, currencyCode: 'VND', categoryId: food, deletedAt: null });

describe('BE-P3-008 refund rules', () => {
  it('caps total refunds at the absolute amount of the expense', () => {
    expect(refundCap(-500000n)).toBe(500000n);
    expect(() => assertWithinRefundCap(-500000n, 500000n)).not.toThrow();
    expect(() => assertWithinRefundCap(-500000n, 500001n)).toThrow(TransactionError);
    expect(() => assertWithinRefundCap(-9007199254740993n, 9007199254740993n)).not.toThrow();
    expect(() => assertWithinRefundCap(-9007199254740993n, 9007199254740994n)).toThrow(TransactionError);
  });

  it('rejects a zero or negative refund', () => {
    expect(() => validateRefundAmount(1n)).not.toThrow();
    expect(() => validateRefundAmount(0n)).toThrow(TransactionError);
    expect(() => validateRefundAmount(-1n)).toThrow(TransactionError);
  });

  it('validates a refund leg: positive, with the category of the original, no merchant or FX', () => {
    const input = (over: Partial<TransactionInput>): TransactionInput => ({
      type: 'refund', occurredOn: new Date('2026-11-03'), occurredTime: null, categoryId: food, notes: null, merchant: null, tagIds: [], fx: null,
      legs: [{ clientId: 'c1', accountId: 'a1', currencyCode: 'VND', amountMinor: 100000n }], ...over,
    });
    expect(() => validateInput(input({}), { VND: 0 })).not.toThrow();
    expect(() => validateInput(input({ categoryId: null }), { VND: 0 })).toThrow(TransactionError);
    expect(() => validateInput(input({ merchant: 'Shopee' }), { VND: 0 })).toThrow(TransactionError);
    expect(() => validateInput(input({ legs: [{ clientId: 'c1', accountId: 'a1', currencyCode: 'VND', amountMinor: -1n }] }), { VND: 0 })).toThrow(TransactionError);
  });

  it('nets refunds out of budget spend, total and per category', () => {
    const rows = [row('expense', -1000000n), row('expense', -200000n), row('refund', 300000n)];
    expect(totalSpent(rows, 'VND')).toBe(900000n);
    expect(categorySpent(rows, 'VND', food, new Set())).toBe(900000n);
    expect(totalSpent([row('expense', -1000000n), { ...row('refund', 300000n), deletedAt: new Date() }], 'VND')).toBe(1000000n);
  });
});
