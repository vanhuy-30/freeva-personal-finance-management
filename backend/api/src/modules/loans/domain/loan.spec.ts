import {
  addPeriod,
  dueInMonth,
  scheduleDueDates,
  annuityPayment,
  loanStatus,
  paidMinor,
  percentBps,
  periodInterest,
  schedule,
  splitPayment,
  totalInterest,
  LoanError,
} from './loan';

describe('BE-P3-E02 loan formulas', () => {
  it('period interest on 100.000.000 at 12%/year monthly is 1.000.000', () => {
    expect(periodInterest(100_000_000n, 1200, 'monthly')).toBe(1_000_000n);
  });

  it('rounds half up and handles zero rate / zero balance', () => {
    expect(periodInterest(1_000n, 1200, 'monthly')).toBe(10n);
    expect(periodInterest(50n, 1200, 'monthly')).toBe(1n); // 0.5 -> 1
    expect(periodInterest(49n, 1200, 'monthly')).toBe(0n);
    expect(periodInterest(100_000_000n, 0, 'monthly')).toBe(0n);
    expect(periodInterest(0n, 1200, 'monthly')).toBe(0n);
  });

  it('annuity for 100.000.000, 12%, 12 months is 8.884.879 (rounded up)', () => {
    expect(annuityPayment(100_000_000n, 1200, 'monthly', 12)).toBe(8_884_879n);
    expect(annuityPayment(12_000n, 0, 'monthly', 12)).toBe(1_000n);
  });

  it('schedule clears the balance: principal sums to the loan, interest first row is 1.000.000', () => {
    const rows = schedule(100_000_000n, 1200, 'monthly', 8_884_879n)!;
    expect(rows).toHaveLength(12);
    expect(rows[0]!.interestMinor).toBe(1_000_000n);
    expect(rows.reduce((sum, row) => sum + row.principalMinor, 0n)).toBe(100_000_000n);
    expect(rows.at(-1)!.outstandingAfterMinor).toBe(0n);
    const interest = totalInterest(rows)!;
    expect(interest).toBeGreaterThan(6_000_000n);
    expect(interest).toBeLessThan(6_700_000n);
  });

  it('schedule is null when the payment never covers interest', () => {
    expect(schedule(100_000_000n, 1200, 'monthly', 1_000_000n)).toBeNull();
  });

  it('splits a payment interest first and rejects overpayment', () => {
    expect(splitPayment(100_000_000n, 1200, 'monthly', 8_884_879n)).toEqual({
      interestMinor: 1_000_000n,
      principalMinor: 7_884_879n,
    });
    expect(splitPayment(100_000_000n, 1200, 'monthly', 400_000n)).toEqual({ interestMinor: 400_000n, principalMinor: 0n });
    expect(() => splitPayment(1_000n, 0, 'monthly', 1_001n)).toThrow(LoanError);
  });

  it('progress and status', () => {
    expect(paidMinor(100n, 40n)).toBe(60n);
    expect(percentBps(120_000_000n, 30_000_000n)).toBe(7500);
    expect(loanStatus(0n, '2026-01-01', '2026-11-02')).toBe('paid_off');
    expect(loanStatus(10n, '2026-10-01', '2026-11-02')).toBe('overdue');
    expect(loanStatus(10n, '2026-11-02', '2026-11-02')).toBe('active');
    expect(loanStatus(10n, null, '2026-11-02')).toBe('active');
  });

  it('adds a period and clamps to month end', () => {
    expect(addPeriod('2026-01-31', 'monthly')).toBe('2026-02-28');
    expect(addPeriod('2026-11-30', 'quarterly')).toBe('2027-02-28');
    expect(addPeriod('2026-12-15', 'monthly')).toBe('2027-01-15');
    expect(addPeriod('2026-12-28', 'weekly')).toBe('2027-01-04');
    expect(addPeriod('2024-02-29', 'yearly')).toBe('2025-02-28');
  });

  it('dates each schedule row one period apart from the next due date', () => {
    expect(scheduleDueDates('2026-01-31', 'monthly', 3)).toEqual(['2026-01-31', '2026-02-28', '2026-03-28']);
    expect(scheduleDueDates(null, 'monthly', 2)).toEqual([null, null]);
  });

  it('sums only the payments due in the current month', () => {
    const rows = schedule(1_000_000n, 0, 'weekly', 100_000n)!;
    // weekly from 2026-11-04: 04, 11, 18, 25 November fall in the month
    expect(dueInMonth(rows, '2026-11-04', 'weekly', '2026-11-04')).toBe(400_000n);
    expect(dueInMonth(rows, '2026-12-01', 'weekly', '2026-11-04')).toBe(0n);
    expect(dueInMonth(rows, null, 'weekly', '2026-11-04')).toBe(0n);
    expect(dueInMonth(null, '2026-11-04', 'weekly', '2026-11-04')).toBe(0n);
    // overdue rows from an earlier month are not counted
    expect(dueInMonth(schedule(300_000n, 0, 'monthly', 100_000n), '2026-10-25', 'monthly', '2026-11-04')).toBe(100_000n);
  });
});
