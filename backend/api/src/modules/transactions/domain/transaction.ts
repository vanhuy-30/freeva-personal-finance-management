import { TransactionError } from './transaction-error';
import { evaluateTransfer } from './transfer-balance';
export { TransactionError } from './transaction-error';
export { normalizeRate, convertedMinor } from './transaction-money';
export const TRANSACTION_TYPES = ['income', 'expense', 'transfer'] as const;
export type TransactionType = typeof TRANSACTION_TYPES[number];
export interface LegInput {
  clientId: string;
  accountId: string;
  currencyCode: string;
  amountMinor: bigint;
}
export interface ManualFx { rate: string; quotedAt: Date }
export interface TransactionInput {
  type: TransactionType;
  occurredOn: Date;
  legs: LegInput[];
  categoryId: string | null;
  notes: string | null;
  tagIds: string[];
  fx: ManualFx | null;
}
export type TransactionPatch = Partial<Omit<TransactionInput, 'type'>> & { version: number; deleted?: boolean };
export interface TransactionLeg extends LegInput {
  id: string;
  type: TransactionType;
  occurredOn: Date;
  categoryId: string | null;
  notes: string | null;
  tagIds: string[];
  transferGroupId: string | null;
  fxQuoteId: string | null;
  deletedAt: Date | null;
  version: number;
  createdAt: Date;
  updatedAt: Date;
}
export interface TransactionBundle { legs: TransactionLeg[]; fx: (ManualFx & { id: string; fromCode: string; toCode: string }) | null }
export interface TransactionQuery {
  page: number; pageSize: number; status: 'active' | 'deleted' | 'all';
  accountId?: string; categoryId?: string; type?: TransactionType; from?: string; to?: string; search?: string;
}
export function minor(value: string): bigint {
  if (!/^-?[0-9]+(?![\s\S])/.test(value) || value.length > 20) throw new TransactionError('VALIDATION_ERROR');
  const amount = BigInt(value);
  if (amount < -9223372036854775808n || amount > 9223372036854775807n) throw new TransactionError('VALIDATION_ERROR');
  return amount;
}
export function calendarDate(value: string): Date {
  const date = new Date(value);
  if (!/^\d{4}-\d{2}-\d{2}(?![\s\S])/.test(value) || value < '0001-01-01' ||
    !Number.isFinite(date.getTime()) || date.toISOString().slice(0, 10) !== value) throw new TransactionError('VALIDATION_ERROR');
  return date;
}
export function validateInput(input: TransactionInput, digits: Record<string, number>): void {
  const { legs, type, fx } = input;
  if (legs.length !== (type === 'transfer' ? 2 : 1)) throw new TransactionError('VALIDATION_ERROR');
  if (new Set(legs.map(leg => leg.clientId)).size !== legs.length || new Set(legs.map(leg => leg.accountId)).size !== legs.length) throw new TransactionError('VALIDATION_ERROR');
  for (const leg of legs) minor(leg.amountMinor.toString());
  const [source, destination] = legs;
  if (type === 'expense' && input.categoryId === null) throw new TransactionError('VALIDATION_ERROR');
  if (type !== 'transfer') {
    if (fx || (type === 'income' ? source.amountMinor <= 0n : source.amountMinor >= 0n)) throw new TransactionError('VALIDATION_ERROR');
    return;
  }
  if (input.categoryId !== null || source.amountMinor >= 0n || destination.amountMinor <= 0n) throw new TransactionError('VALIDATION_ERROR');
  if (source.currencyCode === destination.currencyCode && fx) throw new TransactionError('VALIDATION_ERROR');
  const result = evaluateTransfer({ legs: legs.map((item, index) => ({ role: index === 0 ? 'source' : 'destination', type, amountMinor: item.amountMinor.toString(),
      accountId: item.accountId, occurredOn: input.occurredOn.toISOString(), currencyCode: item.currencyCode, transferGroupId: 'request', fxQuoteId: fx ? 'quote' : null })) }, {
    currencies: Object.fromEntries(Object.entries(digits).map(([code, minorDigits]) => [code, { minorDigits }])),
    fxQuotes: fx ? [{ id: 'quote', fromCurrency: source.currencyCode, toCurrency: destination.currencyCode, rate: fx.rate, quotedAt: fx.quotedAt.toISOString() }] : [],
  });
  if (result.result !== 'accept') throw new TransactionError('VALIDATION_ERROR');
}
