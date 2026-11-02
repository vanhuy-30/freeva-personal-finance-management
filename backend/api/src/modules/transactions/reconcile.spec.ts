import { reconcileDelta, reconcileTarget } from './domain/reconcile';
import { validateInput, type TransactionInput } from './domain/transaction';

const leg = (amountMinor: bigint) => ({ clientId: 'c', accountId: 'a', currencyCode: 'VND', amountMinor });
const adjustment = (patch: Partial<TransactionInput> = {}): TransactionInput => ({
  type: 'adjustment', occurredOn: new Date('2026-10-05'), occurredTime: null, categoryId: null, notes: null,
  merchant: null, tagIds: [], fx: null, legs: [leg(-100n)], ...patch,
});

describe('BE-P3-005 reconcile maths', () => {
  it('raises or lowers a normal wallet to the real balance', () => {
    expect(reconcileDelta('cash', 1_000_000n, 900_000n)).toBe(-100_000n);
    expect(reconcileDelta('bank', 1_000_000n, 1_250_000n)).toBe(250_000n);
    expect(reconcileDelta('ewallet', 5n, 5n)).toBe(0n);
  });
  it('reconciles credit wallets against debt', () => {
    expect(reconcileTarget('credit', 3_000_000n)).toBe(-3_000_000n);
    expect(reconcileDelta('credit', -3_000_000n, 2_000_000n)).toBe(1_000_000n);
    expect(reconcileDelta('credit', 0n, 3_000_000n)).toBe(-3_000_000n);
  });
  it('keeps exact bigint beyond 2^53', () => {
    expect(reconcileDelta('cash', 9_007_199_254_740_993n, 9_007_199_254_740_995n)).toBe(2n);
  });
  it('rejects a delta outside bigint range', () => {
    expect(() => reconcileDelta('cash', 9_223_372_036_854_775_807n, -9_223_372_036_854_775_808n)).toThrow();
  });
});

describe('adjustment validation', () => {
  it('allows either sign, not zero, one leg, no category, merchant or FX', () => {
    expect(() => validateInput(adjustment({ legs: [leg(-100n)] }), { VND: 0 })).not.toThrow();
    expect(() => validateInput(adjustment({ legs: [leg(100n)] }), { VND: 0 })).not.toThrow();
    expect(() => validateInput(adjustment({ legs: [leg(0n)] }), { VND: 0 })).toThrow();
    expect(() => validateInput(adjustment({ categoryId: 'x' }), { VND: 0 })).toThrow();
    expect(() => validateInput(adjustment({ merchant: 'x' }), { VND: 0 })).toThrow();
    expect(() => validateInput(adjustment({ fx: { rate: '1', quotedAt: new Date() } }), { VND: 0 })).toThrow();
    expect(() => validateInput(adjustment({ legs: [leg(1n), { ...leg(2n), clientId: 'd', accountId: 'b' }] }), { VND: 0 })).toThrow();
  });
});
