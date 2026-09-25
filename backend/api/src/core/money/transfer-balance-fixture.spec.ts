import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { parseMinor } from './money';

import { evaluateTransfer, type TransferFixture } from '../../modules/transactions/domain/transfer-balance';

const fixturePath = resolve(
  __dirname,
  '../../../test/fixtures/transfer-balance-cases.json',
);
const fixture = JSON.parse(readFileSync(fixturePath, 'utf8')) as TransferFixture;

describe('QA-P0-002 transfer balance fixture', () => {
  it('uses a versioned contract with unique case IDs', () => {
    expect(fixture.schemaVersion).toBe(1);
    expect(fixture.cases.length).toBeGreaterThan(0);
    const ids = fixture.cases.map((testCase) => testCase.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it('stores every money amount as an integer string', () => {
    for (const testCase of fixture.cases) {
      for (const leg of testCase.legs) {
        expect(typeof leg.amountMinor).toBe('string');
        expect(leg.amountMinor).toMatch(/^-?\d+$/);
        expect(() => parseMinor(leg.amountMinor)).not.toThrow();
      }
    }
    for (const quote of fixture.fxQuotes) {
      expect(typeof quote.rate).toBe('string');
      expect(quote.rate).toMatch(/^\d+(?:\.\d+)?$/);
      expect(Number.isNaN(Date.parse(quote.quotedAt))).toBe(false);
    }
  });

  it.each(fixture.cases)('$id — $description', (testCase) => {
    expect(evaluateTransfer(testCase, fixture)).toEqual({
      result: testCase.expected,
      reasonCode: testCase.reasonCode,
    });
  });
});
