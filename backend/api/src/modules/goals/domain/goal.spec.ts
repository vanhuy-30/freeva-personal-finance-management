import {
  goalStatus,
  incomeShareBps,
  monthsLeft,
  percentBps,
  remainingMinor,
  requiredPerMonth,
  validateLook,
  GoalError,
} from './goal';

describe('BE-P3-E01 goal formulas', () => {
  it('target 120000000, current 40000000, 10 months left → 8000000 per month', () => {
    expect(requiredPerMonth(120_000_000n, 40_000_000n, 10)).toBe(8_000_000n);
  });

  it('rounds the monthly amount up so the goal is not missed', () => {
    expect(requiredPerMonth(100n, 0n, 3)).toBe(34n);
  });

  it('is 0 when reached, null when no future date', () => {
    expect(requiredPerMonth(100n, 100n, 0)).toBe(0n);
    expect(requiredPerMonth(100n, 50n, 0)).toBeNull();
    expect(requiredPerMonth(100n, 50n, null)).toBeNull();
  });

  it.each([
    ['2026-11-02', '2026-12-02', 1],
    ['2026-11-02', '2026-12-03', 2],
    ['2026-11-02', '2027-09-02', 10],
    ['2026-11-02', '2026-11-02', 0],
    ['2026-11-02', '2026-10-01', 0],
  ])('monthsLeft %s → %s = %i', (today, target, expected) => {
    expect(monthsLeft(today, target)).toBe(expected);
  });

  it('percent and remaining', () => {
    expect(percentBps(120_000_000n, 40_000_000n)).toBe(3333);
    expect(percentBps(100n, 150n)).toBe(15000);
    expect(remainingMinor(100n, 150n)).toBe(0n);
    expect(remainingMinor(100n, 40n)).toBe(60n);
  });

  it('status', () => {
    expect(goalStatus(100n, 100n, null, '2026-11-02')).toBe('reached');
    expect(goalStatus(100n, 10n, '2026-11-02', '2026-11-02')).toBe('overdue');
    expect(goalStatus(100n, 10n, '2026-12-01', '2026-11-02')).toBe('active');
    expect(goalStatus(100n, 10n, null, '2026-11-02')).toBe('active');
  });

  it('income share', () => {
    expect(incomeShareBps(8_000_000n, 40_000_000n)).toBe(2000);
    expect(incomeShareBps(8_000_000n, null)).toBeNull();
    expect(incomeShareBps(null, 40_000_000n)).toBeNull();
    expect(incomeShareBps(1n, 0n)).toBeNull();
  });

  it('icon and colour must be catalog tokens', () => {
    expect(() => validateLook('housing', 'color.brand.primary')).not.toThrow();
    expect(() => validateLook('housing', null)).not.toThrow();
    expect(() => validateLook('nope', null)).toThrow(GoalError);
    expect(() => validateLook('housing', '#ff0000')).toThrow(GoalError);
  });
});
