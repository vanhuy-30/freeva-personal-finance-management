import {
  debtStatus,
  debtTotals,
  openingLegMinor,
  outstandingAfter,
  paymentLegMinor,
  validateDueDate,
  PersonalDebtError,
} from './personal-debt';

describe('personal debt', () => {
  it('moves money out when lending and in when borrowing', () => {
    expect(openingLegMinor('lent', 5_000_000n)).toBe(-5_000_000n);
    expect(openingLegMinor('borrowed', 5_000_000n)).toBe(5_000_000n);
    expect(paymentLegMinor('lent', 2_000_000n)).toBe(2_000_000n);
    expect(paymentLegMinor('borrowed', 2_000_000n)).toBe(-2_000_000n);
  });

  it('settles over several partial payments without interest', () => {
    let outstanding = 5_000_000n;
    outstanding = outstandingAfter(outstanding, 2_000_000n);
    expect(outstanding).toBe(3_000_000n);
    outstanding = outstandingAfter(outstanding, 1_000_000n);
    expect(outstanding).toBe(2_000_000n);
    expect(outstandingAfter(outstanding, 2_000_000n)).toBe(0n);
  });

  it('rejects paying more than is left and non-positive amounts', () => {
    expect(() => outstandingAfter(1_000n, 1_001n)).toThrow(new PersonalDebtError('DEBT_OVERPAYMENT'));
    expect(() => outstandingAfter(1_000n, 0n)).toThrow(new PersonalDebtError('VALIDATION_ERROR'));
  });

  it('flags overdue only while something is left and the due date has passed', () => {
    expect(debtStatus(0n, '2026-01-01', '2026-02-01')).toBe('settled');
    expect(debtStatus(1n, '2026-01-31', '2026-02-01')).toBe('overdue');
    expect(debtStatus(1n, '2026-02-01', '2026-02-01')).toBe('open');
    expect(debtStatus(1n, null, '2026-02-01')).toBe('open');
  });

  it('rejects a due date before the debt date', () => {
    expect(() => validateDueDate('2026-02-01', '2026-01-31')).toThrow(PersonalDebtError);
    expect(() => validateDueDate('2026-02-01', null)).not.toThrow();
  });

  it('totals receivable and payable per currency and skips settled debts', () => {
    const rows = [
      { direction: 'lent' as const, currencyCode: 'VND', outstandingMinor: 3_000_000n },
      { direction: 'lent' as const, currencyCode: 'VND', outstandingMinor: 0n },
      { direction: 'borrowed' as const, currencyCode: 'VND', outstandingMinor: 1_000_000n },
      { direction: 'lent' as const, currencyCode: 'USD', outstandingMinor: 500n },
    ];
    expect(debtTotals(rows)).toEqual([
      { currencyCode: 'USD', receivableMinor: 500n, payableMinor: 0n, receivableCount: 1, payableCount: 0 },
      { currencyCode: 'VND', receivableMinor: 3_000_000n, payableMinor: 1_000_000n, receivableCount: 1, payableCount: 1 },
    ]);
  });
});
