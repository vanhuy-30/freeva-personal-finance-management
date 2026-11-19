import { bandFromColumns, incomeBandMidpoint, isValidIncomeBand } from './declared-income';

describe('declared income band (BE-P6-002)', () => {
  it('takes the middle of a closed band and min * 5/4 for the open top band', () => {
    expect(incomeBandMidpoint({ minMinor: 10_000_000n, maxMinor: 20_000_000n })).toBe(15_000_000n);
    expect(incomeBandMidpoint({ minMinor: 0n, maxMinor: 5_000_000n })).toBe(2_500_000n);
    expect(incomeBandMidpoint({ minMinor: 40_000_000n, maxMinor: null })).toBe(50_000_000n);
    expect(incomeBandMidpoint({ minMinor: 12_345_678n, maxMinor: 12_345_678n })).toBe(12_345_678n);
    expect(incomeBandMidpoint({ minMinor: 0n, maxMinor: 3n })).toBe(1n);
  });

  it('accepts only bands the DB check accepts', () => {
    expect(isValidIncomeBand({ minMinor: 0n, maxMinor: 5n })).toBe(true);
    expect(isValidIncomeBand({ minMinor: 5n, maxMinor: 5n })).toBe(true);
    expect(isValidIncomeBand({ minMinor: 1n, maxMinor: null })).toBe(true);
    expect(isValidIncomeBand({ minMinor: 0n, maxMinor: null })).toBe(false);
    expect(isValidIncomeBand({ minMinor: 6n, maxMinor: 5n })).toBe(false);
    expect(isValidIncomeBand({ minMinor: -1n, maxMinor: 5n })).toBe(false);
  });

  it('reads the two columns', () => {
    expect(bandFromColumns(null, null)).toBeNull();
    expect(bandFromColumns(40n, null)).toEqual({ minMinor: 40n, maxMinor: null });
  });
});
