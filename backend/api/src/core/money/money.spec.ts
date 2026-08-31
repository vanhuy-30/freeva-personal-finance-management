import {
  addMinor,
  assertTransferBalanced,
  formatMinor,
  parseMinor,
} from './money';

describe('money minor units', () => {
  it('parses and formats integer strings', () => {
    expect(formatMinor(parseMinor('150000'))).toBe('150000');
  });

  it('adds without floating point', () => {
    expect(addMinor(100n, 25n)).toBe(125n);
  });

  it('rejects non-integers', () => {
    expect(() => parseMinor('1.5')).toThrow('INVALID_MINOR_UNITS');
  });

  it('requires balanced transfer legs', () => {
    expect(() => assertTransferBalanced(-50000n, 50000n)).not.toThrow();
    expect(() => assertTransferBalanced(-50000n, 40000n)).toThrow(
      'UNBALANCED_TRANSFER',
    );
  });
});
