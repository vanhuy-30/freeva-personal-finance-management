import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { assertTransferBalanced, parseMinor } from './money';

type ExpectedResult = 'accept' | 'reject';

type TransferLeg = {
  role: 'source' | 'destination';
  type: 'income' | 'expense' | 'transfer';
  amountMinor: string;
  currencyCode: string;
  transferGroupId: string;
  fxQuoteId: string | null;
};

type TransferCase = {
  id: string;
  description: string;
  expected: ExpectedResult;
  reasonCode: string;
  legs: TransferLeg[];
};

type FxQuote = {
  id: string;
  fromCurrency: string;
  toCurrency: string;
  rate: string;
  quotedAt: string;
};

type TransferFixture = {
  schemaVersion: number;
  currencies: Record<string, { minorDigits: number }>;
  fxQuotes: FxQuote[];
  cases: TransferCase[];
};

type Evaluation = {
  result: ExpectedResult;
  reasonCode: string;
};

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
    expect(evaluate(testCase, fixture)).toEqual({
      result: testCase.expected,
      reasonCode: testCase.reasonCode,
    });
  });
});

function evaluate(
  testCase: TransferCase,
  contract: TransferFixture,
): Evaluation {
  if (testCase.legs.length !== 2) {
    return reject('REQUIRES_EXACTLY_TWO_LEGS');
  }
  if (testCase.legs.some((leg) => leg.type !== 'transfer')) {
    return reject('NON_TRANSFER_LEG');
  }

  const [first, second] = testCase.legs;
  if (first.transferGroupId !== second.transferGroupId) {
    return reject('GROUP_MISMATCH');
  }

  const source = testCase.legs.find((leg) => leg.role === 'source');
  const destination = testCase.legs.find(
    (leg) => leg.role === 'destination',
  );
  if (!source || !destination) {
    return reject('INVALID_SIGN_DIRECTION');
  }

  const sourceMinor = parseMinor(source.amountMinor);
  const destinationMinor = parseMinor(destination.amountMinor);
  if (sourceMinor >= 0n || destinationMinor <= 0n) {
    return reject('INVALID_SIGN_DIRECTION');
  }

  if (source.currencyCode === destination.currencyCode) {
    try {
      assertTransferBalanced(sourceMinor, destinationMinor);
      return accept('BALANCED_SAME_CURRENCY');
    } catch {
      return reject('UNBALANCED_SAME_CURRENCY');
    }
  }

  if (
    !source.fxQuoteId ||
    !destination.fxQuoteId ||
    source.fxQuoteId !== destination.fxQuoteId
  ) {
    return reject('FX_QUOTE_REQUIRED_ON_BOTH_LEGS');
  }

  const quote = contract.fxQuotes.find(
    (candidate) => candidate.id === source.fxQuoteId,
  );
  if (
    !quote ||
    quote.fromCurrency !== source.currencyCode ||
    quote.toCurrency !== destination.currencyCode
  ) {
    return reject('FX_QUOTE_CURRENCY_MISMATCH');
  }

  const sourceCurrency = contract.currencies[source.currencyCode];
  const destinationCurrency = contract.currencies[destination.currencyCode];
  if (!sourceCurrency || !destinationCurrency || !/^\d+$/.test(quote.rate)) {
    throw new Error('Fixture only supports exact FX cases with integer rates');
  }

  const sourceScale = 10n ** BigInt(sourceCurrency.minorDigits);
  const destinationScale = 10n ** BigInt(destinationCurrency.minorDigits);
  const convertedNumerator =
    -sourceMinor * BigInt(quote.rate) * destinationScale;
  if (convertedNumerator % sourceScale !== 0n) {
    throw new Error('Fixture FX case requires an unspecified rounding rule');
  }
  const expectedDestinationMinor = convertedNumerator / sourceScale;
  if (destinationMinor !== expectedDestinationMinor) {
    return reject('FX_AMOUNT_MISMATCH');
  }
  return accept('BALANCED_EXACT_FX');
}

function accept(reasonCode: string): Evaluation {
  return { result: 'accept', reasonCode };
}

function reject(reasonCode: string): Evaluation {
  return { result: 'reject', reasonCode };
}
