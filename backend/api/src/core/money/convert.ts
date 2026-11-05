/**
 * Display-only conversion (BE-P2-013). Exact bigint math, sign-agnostic.
 * Returns null instead of rounding when the result is not a whole minor unit.
 */
export function parseRate(value: string): bigint | null {
  if (!/^\d{1,10}(?:\.\d{1,8})?(?![\s\S])/.test(value)) return null;
  const [whole, fraction = ''] = value.split('.');
  const scaled = BigInt(whole + fraction.padEnd(8, '0'));
  return scaled > 0n ? scaled : null;
}

export function convertMinor(source: bigint, rate: string, fromDigits: number, toDigits: number): bigint | null {
  if (![fromDigits, toDigits].every(digits => Number.isInteger(digits) && digits >= 0 && digits <= 18)) return null;
  const scaled = parseRate(rate);
  if (scaled === null) return null;
  const numerator = source * scaled * 10n ** BigInt(toDigits);
  const denominator = 100000000n * 10n ** BigInt(fromDigits);
  return numerator % denominator === 0n ? numerator / denominator : null;
}

export interface RateEntry { rate: string; quotedAt: string }
export interface RateBook {
  /** Only the stored direction; the opposite is never derived. */
  rate(from: string, to: string): RateEntry | null;
  digits(code: string): number | null;
}
export type UnconvertedReason = 'MISSING_RATE' | 'FRACTIONAL';
export interface Unconverted { currency: string; reason: UnconvertedReason }

/** One amount into `to`. Null when there is no rate or the result is not a whole minor unit. */
export function convertWithBook(amount: bigint, from: string, to: string, book: RateBook): { amountMinor: bigint; rate: string | null; quotedAt: string | null } | null {
  if (from === to) return { amountMinor: amount, rate: null, quotedAt: null };
  const entry = book.rate(from, to);
  const fromDigits = book.digits(from);
  const toDigits = book.digits(to);
  if (!entry || fromDigits === null || toDigits === null) return null;
  const converted = convertMinor(amount, entry.rate, fromDigits, toDigits);
  return converted === null ? null : { amountMinor: converted, rate: entry.rate, quotedAt: entry.quotedAt };
}

/**
 * Sums per-currency groups into `target`. A group joins the totals only if every one of its amounts
 * converts exactly; otherwise it is listed in `unconverted` and adds nothing.
 */
export function convertGroups(groups: { currency: string; amounts: bigint[] }[], target: string, width: number, book: RateBook): { totals: bigint[]; unconverted: Unconverted[] } {
  const totals = Array<bigint>(width).fill(0n);
  const unconverted: Unconverted[] = [];
  for (const group of groups) {
    const missing = group.currency !== target && (!book.rate(group.currency, target) || book.digits(group.currency) === null || book.digits(target) === null);
    const converted = missing ? null : group.amounts.map(amount => convertWithBook(amount, group.currency, target, book)?.amountMinor ?? null);
    if (converted === null) { unconverted.push({ currency: group.currency, reason: 'MISSING_RATE' }); continue; }
    if (converted.some(value => value === null)) { unconverted.push({ currency: group.currency, reason: 'FRACTIONAL' }); continue; }
    converted.forEach((value, index) => { totals[index] += value as bigint; });
  }
  return { totals, unconverted: unconverted.sort((a, b) => a.currency.localeCompare(b.currency)) };
}
