import { assertTransferBalanced, parseMinor } from '../../../core/money/money';
import { convertedMinor } from './transaction-money';

type ExpectedResult = 'accept' | 'reject';

type TransferLeg = {
  role: 'source' | 'destination';
  accountId?: string;
  occurredOn?: string;
  deletedAt?: string | null;
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

export type TransferFixture = {
  schemaVersion: number;
  currencies: Record<string, { minorDigits: number }>;
  fxQuotes: FxQuote[];
  cases: TransferCase[];
};

type Evaluation = {
  result: ExpectedResult;
  reasonCode: string;
};

export function evaluateTransfer(
  testCase: Pick<TransferCase, 'legs'>,
  contract: Pick<TransferFixture, 'currencies' | 'fxQuotes'>,
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

  if (source.accountId && source.accountId === destination.accountId) return reject('SELF_TRANSFER');
  if (source.occurredOn !== destination.occurredOn) return reject('DATE_MISMATCH');
  if (source.deletedAt !== destination.deletedAt) return reject('DELETE_STATE_MISMATCH');

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
  if (!sourceCurrency || !destinationCurrency) return reject('FX_QUOTE_CURRENCY_MISMATCH');

  let expectedDestinationMinor: bigint;
  try {
    expectedDestinationMinor = convertedMinor(sourceMinor, quote.rate, sourceCurrency.minorDigits, destinationCurrency.minorDigits);
  } catch { return reject('FX_AMOUNT_MISMATCH'); }
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
