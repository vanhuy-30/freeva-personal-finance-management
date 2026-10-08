import { TransactionError } from './transaction-error';
export function normalizeRate(value: string): string {
  if (!/^\d{1,10}(?:\.\d{1,8})?(?![\s\S])/.test(value)) throw new TransactionError('VALIDATION_ERROR');
  const [whole, fraction = ''] = value.split('.');
  const normalized = `${BigInt(whole)}.${fraction.padEnd(8, '0')}`;
  if (BigInt(whole + fraction.padEnd(8, '0')) <= 0n) throw new TransactionError('VALIDATION_ERROR');
  return normalized;
}
/** Exact rational conversion: reject fractional minor units rather than silently round. */
export function convertedMinor(source: bigint, rate: string, fromDigits: number, toDigits: number): bigint {
  if (![fromDigits, toDigits].every(digits => Number.isInteger(digits) && digits >= 0 && digits <= 18)) throw new TransactionError('VALIDATION_ERROR');
  const numerator = -source * BigInt(normalizeRate(rate).replace('.', '')) * 10n ** BigInt(toDigits);
  const denominator = 100000000n * 10n ** BigInt(fromDigits);
  if (numerator % denominator !== 0n) throw new TransactionError('VALIDATION_ERROR');
  return numerator / denominator;
}
