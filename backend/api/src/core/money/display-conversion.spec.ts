import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { convertGroups, convertMinor, convertWithBook, parseRate, type RateBook } from './convert';

interface Cases {
  digits: Record<string, number>;
  rates: { from: string; to: string; rate: string; quotedAt: string }[];
  single: Single[];
  groups: GroupCase[];
}
interface Single { id: string; note: string; amount: string; from: string; to: string; expect?: string; expectNull?: boolean }
interface GroupCase {
  id: string; note: string; target: string; width: number;
  groups: { currency: string; amounts: string[] }[];
  expectTotals: string[]; expectUnconverted: { currency: string; reason: string }[];
}
const cases = JSON.parse(readFileSync(resolve(__dirname, '../../../test/fixtures/display-conversion-cases.json'), 'utf8')) as Cases;
const singles = cases.single;
const groupCases = cases.groups;
const rates = new Map(cases.rates.map(item => [`${item.from}>${item.to}`, { rate: item.rate, quotedAt: item.quotedAt }]));
const book: RateBook = {
  rate: (from, to) => rates.get(`${from}>${to}`) ?? null,
  digits: code => cases.digits[code] ?? null,
};

describe('BE-P2-013 display conversion', () => {
  it.each(singles.filter(item => item.expect !== undefined))('$id $note', item => {
    expect(convertWithBook(BigInt(item.amount), item.from, item.to, book)?.amountMinor.toString()).toBe(item.expect);
  });

  it.each(singles.filter(item => item.expectNull))('$id $note returns null, never a rounded number', item => {
    expect(convertWithBook(BigInt(item.amount), item.from, item.to, book)).toBeNull();
  });

  it.each(groupCases)('$id $note', item => {
    const result = convertGroups(item.groups.map(group => ({ currency: group.currency, amounts: group.amounts.map(BigInt) })), item.target, item.width, book);
    expect(result.totals.map(String)).toEqual(item.expectTotals);
    expect(result.unconverted).toEqual(item.expectUnconverted);
  });

  it('returns the stored rate and quotedAt next to the converted number', () => {
    expect(convertWithBook(1234n, 'USD', 'VND', book)).toEqual({ amountMinor: 308500n, rate: '25000', quotedAt: '2026-10-30T02:00:00.000Z' });
  });

  it.each(['0', '0.00000000', '-1', '1e3', '12345678901', '1.123456789', ' 1', '1\n'])('rejects rate %j', value => {
    expect(parseRate(value)).toBeNull();
    expect(convertMinor(1n, value, 0, 0)).toBeNull();
  });

  it('rejects digits outside 0..18', () => {
    expect(convertMinor(1n, '1', -1, 0)).toBeNull();
    expect(convertMinor(1n, '1', 0, 19)).toBeNull();
  });
});
